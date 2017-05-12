=head1

Locale::CLDR::Locales::Nn - Package for language Norwegian Nynorsk

=cut

package Locale::CLDR::Locales::Nn;
# This file auto generated from Data\common\main\nn.xml
#	on Fri 29 Apr  7:20:14 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
					rule => q(=#,###0.#=),
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
 				'ady' => 'adyghe',
 				'ae' => 'avestisk',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'akkadisk',
 				'ale' => 'aleutisk',
 				'alt' => 'sør-altai',
 				'am' => 'amharisk',
 				'an' => 'aragonsk',
 				'ang' => 'gammalengelsk',
 				'anp' => 'angika',
 				'ar' => 'arabisk',
 				'arc' => 'arameisk',
 				'arn' => 'araukansk',
 				'arp' => 'arapaho',
 				'arw' => 'arawak',
 				'as' => 'assamisk',
 				'asa' => 'asu (Tanzania)',
 				'ast' => 'asturisk',
 				'av' => 'avarisk',
 				'awa' => 'awadhi',
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
 				'car' => 'karibisk',
 				'cch' => 'atsam',
 				'ce' => 'tsjetsjensk',
 				'ceb' => 'cebuansk',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'chagatai',
 				'chk' => 'chuukesisk',
 				'chm' => 'mari',
 				'chn' => 'chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewiansk',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'co' => 'korsikansk',
 				'cop' => 'koptisk',
 				'cr' => 'cree',
 				'crh' => 'krimtatarisk',
 				'cs' => 'tsjekkisk',
 				'csb' => 'kasjubisk',
 				'cu' => 'kyrkjeslavisk',
 				'cv' => 'tsjuvansk',
 				'cy' => 'walisisk',
 				'da' => 'dansk',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'de' => 'tysk',
 				'de_AT' => 'austerriksk tysk',
 				'de_CH' => 'sveitsisk høgtysk',
 				'del' => 'delaware',
 				'den' => 'slavej',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'lågsorbisk',
 				'dua' => 'duala',
 				'dum' => 'mellumnederlandsk',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'ebu' => 'kiembu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'gammalegyptisk',
 				'eka' => 'ekajuk',
 				'el' => 'gresk',
 				'elx' => 'elamittisk',
 				'en' => 'engelsk',
 				'en_AU' => 'australisk engelsk',
 				'en_CA' => 'kanadisk engelsk',
 				'en_GB' => 'britisk engelsk',
 				'en_US' => 'engelsk (amerikansk)',
 				'enm' => 'mellomengelsk',
 				'eo' => 'esperanto',
 				'es' => 'spansk',
 				'es_419' => 'latinamerikansk spansk',
 				'es_ES' => 'iberisk spansk',
 				'et' => 'estisk',
 				'eu' => 'baskisk',
 				'ewo' => 'ewondo',
 				'fa' => 'persisk',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulani',
 				'fi' => 'finsk',
 				'fil' => 'filippinsk',
 				'fj' => 'fijiansk',
 				'fo' => 'færøysk',
 				'fon' => 'fon',
 				'fr' => 'fransk',
 				'fr_CA' => 'kanadisk fransk',
 				'fr_CH' => 'sveitsisk fransk',
 				'frm' => 'mellomfransk',
 				'fro' => 'gammalfransk',
 				'frr' => 'nordfrisisk',
 				'frs' => 'austfrisisk',
 				'fur' => 'friuliansk',
 				'fy' => 'vestfrisisk',
 				'ga' => 'irsk',
 				'gaa' => 'ga',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'skotsk-gælisk',
 				'gez' => 'ges',
 				'gil' => 'kiribatisk',
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
 				'jpr' => 'jødepersisk',
 				'jrb' => 'jødearabisk',
 				'jv' => 'javanesisk',
 				'ka' => 'georgisk',
 				'kaa' => 'karakalpakisk',
 				'kab' => 'kabylsk',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardisk',
 				'kcg' => 'tyap',
 				'kea' => 'kapverdisk',
 				'kfo' => 'koro',
 				'kg' => 'kikongo',
 				'kha' => 'khasi',
 				'kho' => 'khotanesisk',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kasakhisk',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut; grønlandsk',
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
 				'ksf' => 'bafia',
 				'ku' => 'kurdisk',
 				'kum' => 'kumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'kornisk',
 				'ky' => 'kirgisisk',
 				'la' => 'latin',
 				'lad' => 'ladinsk',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgsk',
 				'lez' => 'lezghian',
 				'lg' => 'ganda',
 				'li' => 'limburgisk',
 				'ln' => 'lingala',
 				'lo' => 'laotisk',
 				'lol' => 'mongo',
 				'loz' => 'lozi',
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
 				'mg' => 'madagassisk',
 				'mga' => 'mellomirsk',
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
 				'myv' => 'erzya',
 				'na' => 'nauru',
 				'nap' => 'napolitansk',
 				'nb' => 'bokmål',
 				'nd' => 'nord-ndebele',
 				'nds' => 'lågtysk',
 				'ne' => 'nepalsk',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueansk',
 				'nl' => 'nederlandsk',
 				'nl_BE' => 'flamsk',
 				'nmg' => 'kwasio',
 				'nn' => 'nynorsk',
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
 				'or' => 'oriya',
 				'os' => 'ossetisk',
 				'osa' => 'osage',
 				'ota' => 'ottomansk tyrkisk',
 				'pa' => 'panjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauisk',
 				'peo' => 'gammalpersisk',
 				'phn' => 'fønikisk',
 				'pi' => 'pali',
 				'pl' => 'polsk',
 				'pon' => 'ponapisk',
 				'pro' => 'gammalprovençalsk',
 				'ps' => 'pashto',
 				'pt' => 'portugisisk',
 				'pt_BR' => 'brasiliansk portugisisk',
 				'pt_PT' => 'europeisk portugisisk',
 				'qu' => 'quechua',
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
 				'rup' => 'aromansk',
 				'rw' => 'kinjarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'jakutsk',
 				'sam' => 'samaritansk arameisk',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sbp' => 'sangu',
 				'sc' => 'sardinsk',
 				'scn' => 'siciliansk',
 				'sco' => 'skotsk',
 				'sd' => 'sindhi',
 				'se' => 'nordsamisk',
 				'sel' => 'selkupisk',
 				'sg' => 'sango',
 				'sga' => 'gammalirsk',
 				'sh' => 'serbokroatisk',
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
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tatsjikisk',
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
 				'to' => 'tonga (Tonga-øyane)',
 				'tog' => 'tonga (Nyasa)',
 				'tpi' => 'tok pisin',
 				'tr' => 'tyrkisk',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatarisk',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitisk',
 				'tyv' => 'tuvinisk',
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
 				'wa' => 'vallonsk',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wo' => 'wolof',
 				'xal' => 'kalmyk',
 				'xh' => 'xhosa',
 				'yao' => 'yao',
 				'yap' => 'yapesisk',
 				'yav' => 'yangben',
 				'yi' => 'jiddisk',
 				'yo' => 'joruba',
 				'yue' => 'kantonesisk',
 				'za' => 'zhuang',
 				'zap' => 'zapotec',
 				'zbl' => 'blissymbol',
 				'zen' => 'zenaga',
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
 			'Beng' => 'bengali',
 			'Blis' => 'blissymbol',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille',
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
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'forenkla kinesisk',
 			'Hant' => 'tradisjonell kinesisk',
 			'Hebr' => 'hebraisk',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahawk hmong',
 			'Hrkt' => 'katakana eller hiragana',
 			'Hung' => 'gammalungarsk',
 			'Inds' => 'indus',
 			'Ital' => 'gammalitalisk',
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
 			'Mymr' => 'myanmar',
 			'Nkoo' => 'n’ko',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol-chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
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
 			'Sinh' => 'sinhala',
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
 			'Zsym' => 'symbol',
 			'Zxxx' => 'kode for språk utan skrift',
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
 			'053' => 'Australia og New Zealand',
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
 			'BA' => 'Bosnia og Hercegovina',
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
 			'BN' => 'Brunei Darussalam',
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
 			'CF' => 'Den sentralafrikanske republikken',
 			'CG' => 'Kongo-Brazzaville',
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
 			'EU' => 'Den europeiske unionen',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandsøyane',
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
 			'GS' => 'Sør-Georgia og Sør-Sandwich-øyane',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong S.A.R. Kina',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard- og McDonaldsøyane',
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
 			'IO' => 'Britiske område i Det indiske hav',
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
 			'KM' => 'Komorene',
 			'KN' => 'St. Christopher og Nevis',
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
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
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
 			'NF' => 'Norfolkøyane',
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
 			'PM' => 'St. Pierre og Miquelon',
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
 			'SA' => 'Saudi Arabia',
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
 			'SX' => 'Nederlandsk St. Martin',
 			'SY' => 'Syria',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- og Caicosøyane',
 			'TD' => 'Tchad',
 			'TF' => 'Franske sørområde',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadsjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Aust-Timor',
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
 			'US' => 'USA',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikanstaten',
 			'VC' => 'St. Vincent og Grenadinane',
 			'VE' => 'Venezuela',
 			'VG' => 'Dei britiske jomfruøyane',
 			'VI' => 'Dei amerikanske jomfruøyane',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis og Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
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
 			'collation' => 'kollasjon',
 			'currency' => 'valuta',
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
 				'ethiopic' => q{etiopisk kalender},
 				'ethiopic-amete-alem' => q{etiopisk amete-alem-kalender},
 				'gregorian' => q{gregoriansk kalender},
 				'hebrew' => q{hebraisk kalender},
 				'indian' => q{indisk nasjonalkalender},
 				'islamic' => q{islamsk kalender},
 				'islamic-civil' => q{islamsk sivil kalender},
 				'japanese' => q{japansk kalender},
 				'persian' => q{persisk kalender},
 				'roc' => q{kalender for Republikken Kina},
 			},
 			'collation' => {
 				'big5han' => q{tradisjonell kinesisk sortering},
 				'ducet' => q{grunnleggjande Unicode-sorteringsrekkjefølgje},
 				'eor' => q{sorteringsrekkefølge for flerspråklige europeiske dokumenter},
 				'gb2312han' => q{forenkla kinesisk sortering},
 				'phonebook' => q{telefonkatalogsortering},
 				'pinyin' => q{pinyin-sortering},
 				'search' => q{søksorteringsrekkjefølgje etter CLDR},
 				'stroke' => q{streksortering},
 				'traditional' => q{tradisjonell sortering},
 			},
 			'numbers' => {
 				'arab' => q{hindu-arabiske siffer (vestlige)},
 				'arabext' => q{hindu-arabiske siffer (østlige)},
 				'armn' => q{armenske numeraler},
 				'armnlow' => q{armenske numeraler i små bogstaver},
 				'beng' => q{bengalske siffer},
 				'deva' => q{devanagariske siffer},
 				'ethi' => q{etiopiske numeraler},
 				'fullwide' => q{vesterlandske siffer i fuld bredde},
 				'geor' => q{georgiske numeraler},
 				'grek' => q{græske numeraler},
 				'greklow' => q{græske numeraler i små bogstaver},
 				'gujr' => q{gujaratiske siffer},
 				'guru' => q{gurmukhiske siffer},
 				'hanidec' => q{kinesiskt stavede siffer},
 				'hans' => q{forenklet stavede kinesiske numeraler},
 				'hansfin' => q{forenklet stavede kinesiske financielle numeraler},
 				'hant' => q{traditionelt stavede kinesiske numeraler},
 				'hantfin' => q{traditionelt stavede kinesiske financielle numeraler},
 				'hebr' => q{hebæiske numeraler},
 				'java' => q{javanesiske siffer},
 				'jpan' => q{japanskt stavede numeraler},
 				'jpanfin' => q{japanskt stavede financielle numeraler},
 				'khmr' => q{kambodiske siffer},
 				'knda' => q{kannadiske siffer},
 				'laoo' => q{laotiske siffer},
 				'latn' => q{vesterlandske siffer},
 				'mlym' => q{malayalamiske siffer},
 				'mymr' => q{burmeske siffer},
 				'orya' => q{oryiske siffer},
 				'roman' => q{romernumeraler},
 				'romanlow' => q{romernumeraler i små bogstaver},
 				'taml' => q{traditionelle tamilske numeraler},
 				'tamldec' => q{tamilske siffer},
 				'telu' => q{telugiske siffer},
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
			auxiliary => qr{(?^u:[á ǎ č ç đ è ê ń ñ ŋ š ŧ ü ž ä ö])},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'],
			main => qr{(?^u:[a à b c d e é f g h i j k l m n o ó ò ô p q r s t u v w x y z æ ø å])},
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
						'name' => q(amerikanske tønneland),
						'one' => q({0} amerikanskt tønneland),
						'other' => q({0} amerikanske tønneland),
					},
					'arc-minute' => {
						'name' => q(bueminutter),
						'one' => q({0} bueminutt),
						'other' => q({0} bueminutter),
					},
					'arc-second' => {
						'name' => q(buesekunder),
						'one' => q({0} buesekund),
						'other' => q({0} buesekunder),
					},
					'celsius' => {
						'name' => q(grader Celsius),
						'one' => q({0} grad Celsius),
						'other' => q({0} grader Celsius),
					},
					'centimeter' => {
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
					},
					'cubic-kilometer' => {
						'name' => q(kubikkilometer),
						'one' => q({0} kubikkilometer),
						'other' => q({0} kubikkilometer),
					},
					'cubic-mile' => {
						'name' => q(kubikk-engelske mil),
						'one' => q({0} kubikk-engelsk mil),
						'other' => q({0} kubikk-engelske mil),
					},
					'day' => {
						'name' => q(døgn),
						'one' => q({0} døgn),
						'other' => q({0} døgn),
					},
					'degree' => {
						'name' => q(grader),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					'fahrenheit' => {
						'name' => q(grader Fahrenheit),
						'one' => q({0} grad Fahrenheit),
						'other' => q({0} grader Fahrenheit),
					},
					'foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
					},
					'g-force' => {
						'name' => q(Jordgravitasjoner),
						'one' => q({0} Jordgravitasjon),
						'other' => q({0} Jordgravitasjoner),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
					},
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					'hectopascal' => {
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					'horsepower' => {
						'name' => q(hestekrafter),
						'one' => q({0} hestekraft),
						'other' => q({0} hestekrafter),
					},
					'hour' => {
						'name' => q(timer),
						'one' => q({0} time),
						'other' => q({0} timer),
					},
					'inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
					},
					'inch-hg' => {
						'name' => q(tommer kvikksølv),
						'one' => q({0} tomme kvikksølv),
						'other' => q({0} tommer kvikksølv),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
					},
					'kilometer' => {
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer per time),
						'one' => q({0} kilometer per time),
						'other' => q({0} kilometer per time),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
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
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
					},
					'meter-per-second' => {
						'name' => q(meter per sekund),
						'one' => q({0} meter per sekund),
						'other' => q({0} meter per sekund),
					},
					'mile' => {
						'name' => q(engelske mil),
						'one' => q({0} engelsk mil),
						'other' => q({0} engelske mil),
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
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'millimeter' => {
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					'millisecond' => {
						'name' => q(millisekunder),
						'one' => q({0} millisekund),
						'other' => q({0} millisekunder),
					},
					'minute' => {
						'name' => q(minutter),
						'one' => q({0} minutt),
						'other' => q({0} minutter),
					},
					'month' => {
						'name' => q(måneder),
						'one' => q({0} måned),
						'other' => q({0} måneder),
					},
					'ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'picometer' => {
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					'pound' => {
						'name' => q(skålpund),
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					'second' => {
						'name' => q(sekunder),
						'one' => q({0} sekund),
						'other' => q({0} sekunder),
					},
					'square-foot' => {
						'name' => q(kvadratfot),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					'square-kilometer' => {
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
					},
					'square-meter' => {
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
					},
					'square-mile' => {
						'name' => q(kvadrat-engelske mil),
						'one' => q({0} kvadrat-engelsk mil),
						'other' => q({0} kvadrat-engelske mil),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					'week' => {
						'name' => q(uker),
						'one' => q({0} uke),
						'other' => q({0} uker),
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
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
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
						'one' => q({0}d),
						'other' => q({0}d),
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
						'one' => q({0}h),
						'other' => q({0}h),
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
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
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
						'one' => q({0}L),
						'other' => q({0}L),
					},
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
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
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'month' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'ounce' => {
						'one' => q({0} unse),
						'other' => q({0} unser),
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
						'one' => q({0}s),
						'other' => q({0}s),
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
						'one' => q({0}u),
						'other' => q({0}u),
					},
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'one' => q({0}å),
						'other' => q({0}å),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(amerikanske tønneland),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'arc-minute' => {
						'name' => q(bueminutter),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(buesekunder),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(grader Celsius),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(centimeter),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'cubic-kilometer' => {
						'name' => q(kubikkilometer),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'name' => q(kubikk-engelske mil),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(døgn),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					'degree' => {
						'name' => q(grader),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(grader Fahrenheit),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
					},
					'g-force' => {
						'name' => q(Jordgravitasjoner),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'name' => q(hektopascal),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'name' => q(hestekrafter),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					'hour' => {
						'name' => q(timer),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
					},
					'inch-hg' => {
						'name' => q(tommer kvikksølv),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(kilometer),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer per time),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kW),
						'other' => q({0} kW),
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
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'name' => q(meter per sekund),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'mile' => {
						'name' => q(engelske mil),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-hour' => {
						'name' => q(engelske mil per time),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'millimeter' => {
						'name' => q(millimeter),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(millisekunder),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(minutter),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'name' => q(måneder),
						'one' => q({0} mån),
						'other' => q({0} mån),
					},
					'ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pikometer),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pound' => {
						'name' => q(skålpund),
						'one' => q({0} skålpund),
						'other' => q({0} skålpund),
					},
					'second' => {
						'name' => q(sekunder),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'square-foot' => {
						'name' => q(kvadratfot),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					'square-kilometer' => {
						'name' => q(kvadratkilometer),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'name' => q(kvadratmeter),
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'name' => q(kvadrat-engelske mil),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(uker),
						'one' => q({0} u),
						'other' => q({0} u),
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
			'timeSeparator' => q(.),
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
					'' => '#,##0.###',
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
					'other' => '0 millioner',
				},
				'10000000' => {
					'one' => '00 million',
					'other' => '00 millioner',
				},
				'100000000' => {
					'one' => '000 million',
					'other' => '000 millioner',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliarder',
				},
				'10000000000' => {
					'one' => '00 milliard',
					'other' => '00 milliarder',
				},
				'100000000000' => {
					'one' => '000 milliard',
					'other' => '000 milliarder',
				},
				'1000000000000' => {
					'one' => '0 billion',
					'other' => '0 billioner',
				},
				'10000000000000' => {
					'one' => '00 billion',
					'other' => '00 billioner',
				},
				'100000000000000' => {
					'one' => '000 billion',
					'other' => '000 billioner',
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
					'' => '#,##0 %',
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
				'currency' => q(andorransk peseta),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(UAE dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albansk lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armensk dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nederlansk antillegylden),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolsk kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolsk kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolsk ny kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolsk kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentisk austral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinsk peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinsk peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(austerriksk schilling),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(australsk dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubisk gylden),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(aserbaijansk manat),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(aserbajdsjansk manat),
				'one' => q(aserbajdsjansk manat),
				'other' => q(aserbajdsjanske manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinsk dinar),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinsk mark \(konvertibel\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadisk dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeshisk taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgisk franc \(konvertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgisk franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgisk franc \(finansiell\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulgarsk hard lev),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgarsk ny lev),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainsk dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundisk franc),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudisk dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneisk dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(bolivisk peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(bolivisk mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brasiliansk cruzado),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brasiliansk real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brasiliansk cruzado novo),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamisk dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutansk ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmesisk kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswansk pula),
				'one' => q(botswansk pula),
				'other' => q(botswanske pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(kviterussisk ny rubel \(1994–1999\)),
				'one' => q(kviterussisk ny rubel \(BYB\)),
				'other' => q(kviterussiske nye rublar \(BYB\)),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(kviterussisk rubel),
				'one' => q(kviterussisk rubel),
				'other' => q(kviterussiske rublar),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizisk dollar),
				'one' => q(belizisk dollar),
				'other' => q(beliziske dollar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(kanadisk dollar),
				'one' => q(kanadisk dollar),
				'other' => q(kanadiske dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongolesisk franc),
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
			display_name => {
				'currency' => q(sveitsisk franc),
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
				'currency' => q(chilensk unidades de fomento),
				'one' => q(chilensk unidades de fomento),
				'other' => q(chilenske unidades de fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilensk peso),
				'one' => q(chilensk peso),
				'other' => q(chilenske peso),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(kinesisk yuan renminbi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(colombiansk peso),
				'one' => q(colombiansk peso),
				'other' => q(colombianske peso),
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
			display_name => {
				'currency' => q(costaricansk colon),
				'one' => q(costaricansk colon),
				'other' => q(costaricanske colon),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(gammal serbisk dinar),
				'one' => q(gammal serbisk dinar),
				'other' => q(gamle serbiske dinarar),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(tsjekkoslovakisk koruna \(hard\)),
				'one' => q(tsjekkoslovakisk koruna \(hard\)),
				'other' => q(tsjekkoslovakiske koruna \(hard\)),
			},
		},
		'CUC' => {
			display_name => {
				'one' => q(kubansk peso \(konvertibel\)),
				'other' => q(kubanska pesos \(konvertibla\)),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubansk peso),
				'one' => q(kubansk peso),
				'other' => q(kubanske peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kappverdisk escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(kypriotisk pund),
				'one' => q(kypriotisk pund),
				'other' => q(kypriotiske pund),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(tsjekkisk koruna),
				'one' => q(tsjekkisk koruna),
				'other' => q(tsjekkiske koruna),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(austtysk mark),
				'one' => q(austtysk mark),
				'other' => q(austtyske mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(tysk mark),
				'one' => q(tysk mark),
				'other' => q(tyske mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(djiboutisk franc),
				'one' => q(djiboutisk franc),
				'other' => q(djiboutiske franc),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(dansk krone),
				'one' => q(dansk krone),
				'other' => q(danske kroner),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikansk peso),
				'one' => q(dominikansk peso),
				'other' => q(dominikanske peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algerisk dinar),
				'one' => q(algerisk dinar),
				'other' => q(algeriske dinarar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ecuadoriansk sucre),
				'one' => q(ecuadoriansk sucre),
				'other' => q(ecuadorianske sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ecuadoriansk unidad de valor constante \(UVC\)),
				'one' => q(ecuadoriansk unidad de valor constante \(UVC\)),
				'other' => q(ecuadorianske unidad de valor constante \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(estisk kroon),
				'one' => q(estisk kroon),
				'other' => q(estiske kroon),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptisk pund),
				'one' => q(egyptisk pund),
				'other' => q(egyptiske pund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritreisk nakfa),
				'one' => q(eritreisk nakfa),
				'other' => q(eritreiske nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(spansk peseta \(A–konto\)),
				'one' => q(spansk peseta \(A–konto\)),
				'other' => q(spanske peseta \(A–konto\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(spansk peseta \(konvertibel konto\)),
				'one' => q(spansk peseta \(konvertibel konto\)),
				'other' => q(spanske peseta \(konvertibel konto\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(spansk peseta),
				'one' => q(spansk peseta),
				'other' => q(spanske peseta),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopisk birr),
				'one' => q(etiopisk birr),
				'other' => q(etiopiske birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(finsk mark),
				'one' => q(finsk mark),
				'other' => q(finske mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fijiansk dollar),
				'one' => q(fijiansk dollar),
				'other' => q(fijianske dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland-pund),
				'one' => q(Falkland-pund),
				'other' => q(Falkland-pund),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(fransk franc),
				'one' => q(fransk franc),
				'other' => q(franske franc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(britisk pund),
				'one' => q(britisk pund),
				'other' => q(britiske pund),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(georgisk kupon larit),
				'one' => q(georgisk kupon larit),
				'other' => q(georgiske kupon larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgisk lari),
				'one' => q(georgisk lari),
				'other' => q(georgiske lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghanesisk cedi \(1979–2007\)),
				'one' => q(ghanesisk cedi \(GHC\)),
				'other' => q(ghanesiske cedi \(GHC\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanesisk cedi),
				'one' => q(ghanesisk cedi),
				'other' => q(ghanesiske cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltarsk pund),
				'one' => q(gibraltarsk pund),
				'other' => q(gibraltarske pund),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambisk dalasi),
				'one' => q(gambisk dalasi),
				'other' => q(gambiske dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guineansk franc),
				'one' => q(guineansk franc),
				'other' => q(guineanske franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(guineansk syli),
				'one' => q(guineansk syli),
				'other' => q(guineanske syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekvatorialguineansk ekwele guineana),
				'one' => q(ekvatorialguineansk ekwele),
				'other' => q(ekvatorialguineanske ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(gresk drakme),
				'one' => q(gresk drakme),
				'other' => q(greske drakmer),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalansk quetzal),
				'one' => q(guatemalansk quetzal),
				'other' => q(guatemalanske quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(portugisisk guinea escudo),
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
			display_name => {
				'currency' => q(guyansk dollar),
				'one' => q(guyansk dollar),
				'other' => q(guyanske dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkong-dollar),
				'one' => q(Hongkong-dollar),
				'other' => q(Hongkong-dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduransk lempira),
				'one' => q(honduransk lempira),
				'other' => q(honduranske lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(kroatisk dinar),
				'one' => q(kroatisk dinar),
				'other' => q(kroatiske dinarar),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kroatisk kuna),
				'one' => q(kroatisk kuna),
				'other' => q(kroatiske kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitisk gourde),
				'one' => q(haitisk gourde),
				'other' => q(haitiske gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ungarsk forint),
				'one' => q(ungarsk forint),
				'other' => q(ungarske forintar),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonesisk rupi),
				'one' => q(indonesisk rupi),
				'other' => q(indonesiske rupiar),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(irsk pund),
				'one' => q(irsk pund),
				'other' => q(irske pund),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(israelsk pund),
				'one' => q(israelsk pund),
				'other' => q(israelske pund),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(israelsk ny shekel),
				'one' => q(israelsk ny shekel),
				'other' => q(israelske nye sheklar),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indisk rupi),
				'one' => q(indisk rupi),
				'other' => q(indiske rupier),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(iraksk dinar),
				'one' => q(irakisk dinar),
				'other' => q(irakiske dinarar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iransk rial),
				'one' => q(iransk rial),
				'other' => q(iranske rialar),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandsk krone),
				'one' => q(islandsk krone),
				'other' => q(islandske kroner),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(italiensk lire),
				'one' => q(italiensk lire),
				'other' => q(italienske lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaikansk dollar),
				'one' => q(jamaikansk dollar),
				'other' => q(jamaikanske dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordansk dinar),
				'one' => q(jordansk dinar),
				'other' => q(jordanske dinarar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(japansk yen),
				'one' => q(japansk yen),
				'other' => q(japanske yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenyansk shilling),
				'one' => q(kenyansk shilling),
				'other' => q(kenyanske shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgisisk som),
				'one' => q(kirgisisk som),
				'other' => q(kirgisiske som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodsjansk riel),
				'one' => q(kambodsjansk riel),
				'other' => q(kambodsjanske riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorisk franc),
				'one' => q(komorisk franc),
				'other' => q(komoriske franc),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(nordkoreansk won),
				'one' => q(nordkoreansk won),
				'other' => q(nordkoreanske won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(sørkoreansk won),
				'one' => q(sørkoreansk won),
				'other' => q(sørkoreanske won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitisk dinar),
				'one' => q(kuwaitisk dinar),
				'other' => q(kuwaitiske dinarar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(caymansk dollar),
				'one' => q(caymansk dollar),
				'other' => q(caymanske dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kasakhstansk tenge),
				'one' => q(kasakhstansk tenge),
				'other' => q(kasakhstanske tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laotisk kip),
				'one' => q(laotisk kip),
				'other' => q(laotiske kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanesisk pund),
				'one' => q(libanesisk pund),
				'other' => q(libanesiske pund),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(srilankisk rupi),
				'one' => q(srilankisk rupi),
				'other' => q(srilankiske rupiar),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberisk dollar),
				'one' => q(liberisk dollar),
				'other' => q(liberiske dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothisk loti),
				'one' => q(lesothisk loti),
				'other' => q(lesothiske loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litauisk lita),
				'one' => q(litauisk lita),
				'other' => q(litauiske lita),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(litauisk talona),
				'one' => q(litauisk talona),
				'other' => q(litauiske talona),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(luxemburgsk konvertibel franc),
				'one' => q(luxemburgsk konvertibel franc),
				'other' => q(luxemburgske konvertible franc),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(luxemburgsk franc),
				'one' => q(luxemburgsk franc),
				'other' => q(luxemburgske franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(luxemburgsk finansiell franc),
				'one' => q(luxemburgsk finansiell franc),
				'other' => q(luxemburgske finansielle franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(latvisk lat),
				'one' => q(latvisk lat),
				'other' => q(latviske lat),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(latvisk rubel),
				'one' => q(latvisk rubel),
				'other' => q(latviske rublar),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libysk dinar),
				'one' => q(libysk dinar),
				'other' => q(libyske dinarar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokkansk dirham),
				'one' => q(marokkansk dirham),
				'other' => q(marokkanske dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(marokkansk franc),
				'one' => q(marokkansk franc),
				'other' => q(marokkanske franc),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldovsk leu),
				'one' => q(moldovsk leu),
				'other' => q(moldovske lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagassisk ariary),
				'one' => q(madagassisk ariary),
				'other' => q(madagassiske ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(madagassisk franc),
				'one' => q(madagassisk franc),
				'other' => q(madagassiske franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonsk denar),
				'one' => q(makedonsk denar),
				'other' => q(makedonske denarar),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(malisk franc),
				'one' => q(malisk franc),
				'other' => q(maliske franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmarsk kyat),
				'one' => q(myanmarsk kyat),
				'other' => q(myanmarske kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolsk tugrik),
				'one' => q(mongolsk tugrik),
				'other' => q(mongolske tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makaosk pataca),
				'one' => q(makaosk pataca),
				'other' => q(makaoske pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauritansk ouguiya),
				'one' => q(mauritansk ouguiya),
				'other' => q(mauritanske ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(maltesisk lira),
				'one' => q(maltesisk lira),
				'other' => q(maltesiske lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(maltesisk pund),
				'one' => q(maltesisk pund),
				'other' => q(maltesiske pund),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauritansk rupi),
				'one' => q(mauritansk rupi),
				'other' => q(mauritanske rupiar),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldivisk rufiyaa),
				'one' => q(maldivisk rufiyaa),
				'other' => q(maldiviske rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawisk kwacha),
				'one' => q(malawisk kwacha),
				'other' => q(malawiske kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(meksikansk peso),
				'one' => q(meksikansk peso),
				'other' => q(meksikanske peso),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(meksikansk sølvpeso \(1861–1992\)),
				'one' => q(meksikansk sølvpeso \(MXP\)),
				'other' => q(meksikanske sølvpeso \(MXP\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(meksikansk unidad de inversion \(UDI\)),
				'one' => q(meksikansk unidad de inversion \(UDI\)),
				'other' => q(meksikanske unidad de inversion \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malaysisk ringgit),
				'one' => q(malaysisk ringgit),
				'other' => q(malaysiske ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(mosambikisk escudo),
				'one' => q(mosambikisk escudo),
				'other' => q(mosambikiske escudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(gammal mosambikisk metical),
				'one' => q(gammal mosambikisk metical),
				'other' => q(gamle mosambikiske metical),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mosambikisk metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibisk dollar),
				'one' => q(namibisk dollar),
				'other' => q(namibiske dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigeriansk naira),
				'one' => q(nigeriansk naira),
				'other' => q(nigerianske naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nicaraguansk cordoba),
				'one' => q(nicaraguansk cordoba),
				'other' => q(nicaraguanske cordoba),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nicaraguansk cordoba oro),
				'one' => q(nicaraguansk cordoba oro),
				'other' => q(nicaraguanske cordoba oro),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(nederlandsk gylden),
				'one' => q(nederlandsk gylden),
				'other' => q(nederlandske gylden),
			},
		},
		'NOK' => {
			symbol => 'kr',
			display_name => {
				'currency' => q(norsk krone),
				'one' => q(norsk krone),
				'other' => q(norske kroner),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalsk rupi),
				'one' => q(nepalsk rupi),
				'other' => q(nepalske rupiar),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(new zealandsk dollar),
				'one' => q(new zealandsk dollar),
				'other' => q(new zealandske dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omansk rial),
				'one' => q(omansk rial),
				'other' => q(omanske rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamansk balboa),
				'one' => q(panamansk balboa),
				'other' => q(panamanske balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruansk inti),
				'one' => q(peruansk inti),
				'other' => q(peruanske inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruansk nuevo sol),
				'one' => q(peruansk nuevo sol),
				'other' => q(peruanske nuevo sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruansk sol),
				'one' => q(peruansk sol),
				'other' => q(peruanske sol),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papuansk kina),
				'one' => q(papuansk kina),
				'other' => q(papuanske kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(filippinsk peso),
				'one' => q(filippinsk peso),
				'other' => q(filippinske peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistansk rupi),
				'one' => q(pakistansk rupi),
				'other' => q(pakistanske rupiar),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polsk zloty),
				'one' => q(polsk zloty),
				'other' => q(polske zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(polsk zloty \(1950–1995\)),
				'one' => q(polsk zloty \(PLZ\)),
				'other' => q(polske zloty \(PLZ\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(portugisisk escudo),
				'one' => q(portugisisk escudo),
				'other' => q(portugisiske escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayansk guarani),
				'one' => q(paraguayansk guarani),
				'other' => q(paraguayanske guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(qatarsk rial),
				'one' => q(qatarsk rial),
				'other' => q(qatarske rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodesisk dollar),
				'one' => q(rhodesisk dollar),
				'other' => q(rhodesiske dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(gammal rumensk leu),
				'one' => q(gammal rumensk leu),
				'other' => q(gamle rumenske lei),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rumensk leu),
				'one' => q(rumensk leu),
				'other' => q(rumenske lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbisk dinar),
				'one' => q(serbisk dinar),
				'other' => q(serbiske dinarar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(russisk rubel),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(russisk rubel \(1991–1998\)),
				'one' => q(russisk rubel \(RUR\)),
				'other' => q(russiske rublar \(RUR\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandisk franc),
				'one' => q(rwandisk franc),
				'other' => q(rwandiske franc),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudiarabisk rial),
				'one' => q(saudiarabisk rial),
				'other' => q(saudiarabiske rial),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salomonsk dollar),
				'one' => q(salomonsk dollar),
				'other' => q(salomonske dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychellisk rupi),
				'one' => q(seychellisk rupi),
				'other' => q(seychelliske rupiar),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(gammal sudanesisk dinar),
				'one' => q(gammal sudansk dinar),
				'other' => q(gamle sudanske dinarar),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudansk pund),
				'one' => q(sudansk pund),
				'other' => q(sudanske pund),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(gammalt sudanesisk pund),
				'one' => q(gammalt sudansk pund),
				'other' => q(gamle sudanske pund),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(svensk krone),
				'one' => q(svensk krone),
				'other' => q(svenske kroner),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singaporsk dollar),
				'one' => q(singaporsk dollar),
				'other' => q(singaporske dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(sankthelensk pund),
				'one' => q(sankthelensk pund),
				'other' => q(sankthelenske pund),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovensk tolar),
				'one' => q(slovensk tolar),
				'other' => q(slovenske tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovakisk koruna),
				'one' => q(slovakisk koruna),
				'other' => q(slovakiske koruna),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierraleonsk leone),
				'one' => q(sierraleonsk leone),
				'other' => q(sierraleonske leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somalisk shilling),
				'one' => q(somalisk shilling),
				'other' => q(somaliske shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamsk dollar),
				'one' => q(surinamsk dollar),
				'other' => q(surinamske dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamsk gylden),
				'one' => q(surinamsk gylden),
				'other' => q(surinamske gylden),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Sao Tome og Principe-dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovjetisk rubel),
				'one' => q(sovjetisk rubel),
				'other' => q(sovjetiske rublar),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvadoransk colon),
				'one' => q(salvadoransk colon),
				'other' => q(salvadoranske colon),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syrisk pund),
				'one' => q(syrisk pund),
				'other' => q(syriske pund),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swazilandsk lilangeni),
				'one' => q(swazilandsk lilangeni),
				'other' => q(swazilandske lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(thailandsk baht),
				'one' => q(thailandsk baht),
				'other' => q(thailandske baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tadsjikisk rubel),
				'one' => q(tadsjikisk rubel),
				'other' => q(tadsjikiske rublar),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadsjikisk somoni),
				'one' => q(tadsjikisk somoni),
				'other' => q(tadsjikiske somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmensk manat),
				'one' => q(turkmensk manat),
				'other' => q(turkmenske manat),
			},
		},
		'TMT' => {
			display_name => {
				'one' => q(turkmenistansk manat),
				'other' => q(turkmenistanska manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunisisk dinar),
				'one' => q(tunisisk dinar),
				'other' => q(tunisiske dinarar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongansk paʻanga),
				'one' => q(tongansk paʻanga),
				'other' => q(tonganske paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timoresisk escudo),
				'one' => q(timoresisk escudo),
				'other' => q(timoresiske escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(gammal tyrkiske lire),
				'one' => q(gammal tyrkisk lire),
				'other' => q(gamle tyrkiske lire),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(tyrkisk lire),
				'one' => q(tyrkisk lire),
				'other' => q(tyrkiske lire),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidadisk dollar),
				'one' => q(trinidadisk dollar),
				'other' => q(trinidadiske dollar),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(taiwansk ny dollar),
				'one' => q(taiwansk ny dollar),
				'other' => q(taiwanske nye dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzaniansk shilling),
				'one' => q(tanzaniansk shilling),
				'other' => q(tanzanianske shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainsk hryvnia),
				'one' => q(ukrainsk hryvnia),
				'other' => q(ukrainske hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrainsk karbovanetz),
				'one' => q(ukrainsk karbovanetz),
				'other' => q(ukrainske karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(ugandisk shilling \(1966–1987\)),
				'one' => q(ugandisk shilling \(UGS\)),
				'other' => q(ugandiske shilling \(UGS\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandisk shilling),
				'one' => q(ugandisk shilling),
				'other' => q(ugandiske shilling),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(amerikansk dollar),
				'one' => q(amerikansk dollar),
				'other' => q(amerikanske dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(amerikansk dollar \(neste dag\)),
				'one' => q(amerikansk dollar \(neste dag\)),
				'other' => q(amerikanske dollar \(neste dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(amerikansk dollar \(same dag\)),
				'one' => q(amerikansk dollar \(same dag\)),
				'other' => q(amerikanske dollar \(same dag\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguayansk peso en unidades indexadas),
				'one' => q(uruguayansk peso en unidades indexadas),
				'other' => q(uruguayanske peso en unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguayansk peso \(1975–1993\)),
				'one' => q(uruguayansk peso \(UYP\)),
				'other' => q(uruguayanske peso \(UYP\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayansk peso),
				'one' => q(uruguayansk peso),
				'other' => q(uruguayanske peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(usbekisk sum),
				'one' => q(usbekisk sum),
				'other' => q(usbekiske sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelansk bolivar \(1871–2008\)),
				'one' => q(venezuelansk bolivar \(1871–2008\)),
				'other' => q(venezuelanske bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelansk bolivar),
				'one' => q(venezuelansk bolivar),
				'other' => q(venezuelanske bolivar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(vietnamesisk dong),
				'one' => q(vietnamesisk dong),
				'other' => q(vietnamesiske dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatuisk vatu),
				'one' => q(vanuatuisk vatu),
				'other' => q(vanuatuiske vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(vestsamoisk tala),
				'one' => q(vestsamoisk tala),
				'other' => q(vestsamoiske tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA franc BEAC),
				'one' => q(CFA franc BEAC),
				'other' => q(CFA franc BEAC),
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
				'currency' => q(europeisk samansett eining),
				'one' => q(europeisk samansett eining),
				'other' => q(europeiske samansette einingar),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(europeisk monetær eining),
				'one' => q(europeisk monetær eining),
				'other' => q(europeiske monetære einingar),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(europeisk kontoeining \(XBC\)),
				'one' => q(europeisk kontoeining \(XBC\)),
				'other' => q(europeiske kontoeiningar \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(europeisk kontoeining \(XBD\)),
				'one' => q(europeisk kontoeining \(XBD\)),
				'other' => q(europeiske kontoeiningar \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(austkaribisk dollar),
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
				'currency' => q(europeisk valutaeining),
				'one' => q(europeisk valutaeining),
				'other' => q(europeiske valutaeiningar),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(fransk gullfranc),
				'one' => q(fransk gullfranc),
				'other' => q(franske gullfranc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(fransk UIC-franc),
				'one' => q(fransk UIC-franc),
				'other' => q(franske UIC-franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA franc BCEAO),
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
			display_name => {
				'currency' => q(CFP franc),
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
				'currency' => q(ukjend eller ugyldig valuta),
				'one' => q(ukjend/ugyldig valuta),
				'other' => q(ukjend eller ugyldig valuta),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(jemenittisk dinar),
				'one' => q(jemenittisk dinar),
				'other' => q(jemenittiske dinarar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenittisk rial),
				'one' => q(jemenittisk rial),
				'other' => q(jemenittiske rialar),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(jugoslavisk dinar \(hard\)),
				'one' => q(jugoslavisk dinar \(hard\)),
				'other' => q(jugoslaviske dinarar \(hard\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(jugoslavisk noviy-dinar),
				'one' => q(jugoslavisk noviy-dinarar),
				'other' => q(jugoslaviske noviy-dinar),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(jugoslavisk konvertibel dinar),
				'one' => q(jugoslavisk konvertibel dinar),
				'other' => q(jugoslaviske konvertible dinarar),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(sørafrikansk rand \(finansiell\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(sørafrikansk rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambisk kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambisk kwacha),
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
					'pm' => q{e.m.},
					'am' => q{f.m.},
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
			'short' => q{d.M y G},
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
			'full' => q{'kl'. HH.mm.ss zzzz},
			'long' => q{HH.mm.ss z},
			'medium' => q{HH.mm.ss},
			'short' => q{HH.mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
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
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			MEd => q{E d.M},
			MMMEd => q{E d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{d.M.},
			Md => q{d.M.},
			d => q{d.},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			ms => q{mm.ss},
			yM => q{M y},
			yMEd => q{E d.M.y},
			yMM => q{MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'generic' => {
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			M => q{L},
			MEd => q{E d.M},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMd => q{d. MMM},
			MMdd => q{d.M.},
			Md => q{d.M.},
			d => q{d.},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			ms => q{mm.ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M y G},
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
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Hm => {
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
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
				h => q{h–h a},
			},
			hm => {
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
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
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
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
				a => q{h.mm a – h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
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
		hourFormat => q(+HH.mm;-HH.mm),
		gmtFormat => q(GMT{0}),
		fallbackFormat => q({1} ({0})),
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q(sentralafrikansk tid),
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q(austafrikansk tid),
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q(sørafrikansk tid),
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q(vestafrikansk sommartid),
				'generic' => q(vestafrikansk tid),
				'standard' => q(vestafrikansk standardtid),
			},
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancún#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Godthab' => {
			exemplarCity => q#Godthåb#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico by#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Nord-Dakota#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh-byen#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tasjkent#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorane#,
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
		'Australia_Central' => {
			long => {
				'daylight' => q(sentralaustralsk sommartid),
				'generic' => q(sentralaustralsk tid),
				'standard' => q(sentralaustralsk standardtid),
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q(vest-sentralaustralsk sommartid),
				'generic' => q(vest-sentralaustralsk tid),
				'standard' => q(vest-sentralaustralsk standardtid),
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q(austaustralsk sommartid),
				'generic' => q(austaustralsk tid),
				'standard' => q(austaustralsk standardtid),
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q(vestaustralsk sommartid),
				'generic' => q(vestaustralsk tid),
				'standard' => q(vestaustralsk standardtid),
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ukjend#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#København#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q(sentraleuropeisk sommartid),
				'generic' => q(sentraleuropeisk tid),
				'standard' => q(sentraleuropeisk standardtid),
			},
			short => {
				'daylight' => q(CEST),
				'generic' => q(CET),
				'standard' => q(CET),
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q(austeuropeisk sommartid),
				'generic' => q(austeuropeisk tid),
				'standard' => q(austeuropeisk standardtid),
			},
			short => {
				'daylight' => q(EEST),
				'generic' => q(EET),
				'standard' => q(EET),
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q(Kaliningradtid),
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q(vesteuropeisk sommartid),
				'generic' => q(vesteuropeisk tid),
				'standard' => q(vesteuropeisk standardtid),
			},
			short => {
				'daylight' => q(WEST),
				'generic' => q(WET),
				'standard' => q(WET),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(greenwich middeltid),
			},
			short => {
				'standard' => q(GMT),
			},
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivane#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Påskeøya#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
