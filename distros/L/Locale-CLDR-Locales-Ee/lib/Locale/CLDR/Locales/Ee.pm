=head1

Locale::CLDR::Locales::Ee - Package for language Ewe

=cut

package Locale::CLDR::Locales::Ee;
# This file auto generated from Data\common\main\ee.xml
#	on Fri 29 Apr  6:58:19 pm GMT

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'after-billions' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' kpakple =%spellout-cardinal=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(' kple =%spellout-cardinal=),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(' kple =%spellout-cardinal=),
				},
				'100000000000' => {
					base_value => q(100000000000),
					divisor => q(100000000000),
					rule => q(' =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100000000000),
					divisor => q(100000000000),
					rule => q(' =%spellout-cardinal=),
				},
			},
		},
		'after-hundred-thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' kpakple =%spellout-cardinal=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal=),
				},
			},
		},
		'after-hundreds' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(kple =%spellout-cardinal=),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'after-millions' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' kpakple =%spellout-cardinal=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(' kple =%spellout-cardinal=),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(' =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(' =%spellout-cardinal=),
				},
			},
		},
		'after-thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' kple =%spellout-cardinal=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal=),
				},
			},
		},
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0= lia),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=#,##0= tɔ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=#,##0= lia),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=#,##0= lia),
				},
			},
		},
		'spellout-base' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ɖekeo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ɖekɛ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(eve),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(etɔ̃),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ene),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(atɔ̃),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ade),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(adre),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(enyi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(asieke),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ewo),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(wui→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(bla←←[ vɔ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(alafa ←%spellout-cardinal←[ →%%after-hundreds→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(akpe ←%spellout-cardinal←[→%%after-thousands→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(1000),
					rule => q(akpe ←%spellout-cardinal←[→%%after-hundred-thousands→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miliɔn ←%spellout-cardinal←[→%%after-millions→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miliɔn akpe ←%spellout-cardinal←[→%%after-millions→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biliɔn ←%spellout-cardinal←[→%%after-billions→]),
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
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(→→ xlẽyimegbee),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ɖekeo),
				},
				'0.x' => {
					divisor => q(1),
					rule => q(kakɛ →→),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← kple kakɛ →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ɖeka),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-base=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-base=),
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
					rule => q(=#,###0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,###0.#=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(→→ xlẽyimegbee),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ɖekeolia),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.0=lia),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(gbãtɔ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal=lia),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal=lia),
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
				'ab' => 'abkhaziagbe',
 				'ady' => 'adyghegbe',
 				'af' => 'afrikaangbe',
 				'agq' => 'aghemgbe',
 				'ak' => 'blugbe',
 				'am' => 'amhariagbe',
 				'ar' => 'Arabiagbe',
 				'as' => 'assamegbe',
 				'asa' => 'asagbe',
 				'ast' => 'asturiagbe',
 				'av' => 'avariagbe',
 				'ay' => 'aymargbe',
 				'az' => 'azerbaijangbe',
 				'ba' => 'bashkigbe',
 				'bas' => 'basaagbe',
 				'bax' => 'bamugbe',
 				'bbj' => 'ghomalagbe',
 				'be' => 'belarusiagbe',
 				'bem' => 'bembagbe',
 				'bez' => 'benagbe',
 				'bfd' => 'bafutgbe',
 				'bg' => 'bulgariagbe',
 				'bi' => 'bislamagbe',
 				'bkm' => 'komgbe',
 				'bm' => 'bambaragbe',
 				'bn' => 'Bengaligbe',
 				'bo' => 'tibetagbe',
 				'br' => 'bretongbe',
 				'brx' => 'bodogbe',
 				'bs' => 'bosniagbe',
 				'bss' => 'akoosiagbe',
 				'bum' => 'bulugbe',
 				'byv' => 'medumbagbe',
 				'ca' => 'katalagbe',
 				'ceb' => 'Sebuanogbe',
 				'ch' => 'kamorrogbe',
 				'chk' => 'tsukesegbe',
 				'chm' => 'tsetsniagbe',
 				'cs' => 'tsɛkgbe',
 				'cy' => 'walesgbe',
 				'da' => 'denmarkgbe',
 				'de' => 'Germaniagbe',
 				'de_AT' => 'Germaniagbe (Austria)',
 				'de_CH' => 'Germaniagbe (Switzerland)',
 				'dje' => 'zamagbe',
 				'dua' => 'dualagbe',
 				'dv' => 'divehgbe',
 				'dyo' => 'dzola-fonyigbe',
 				'dz' => 'dzongkhagbe',
 				'ebu' => 'embugbe',
 				'ee' => 'Eʋegbe',
 				'efi' => 'efigbe',
 				'el' => 'grisigbe',
 				'en' => 'Yevugbe',
 				'en_AU' => 'Yevugbe (Australia)',
 				'en_CA' => 'Yevugbe (Canada)',
 				'en_GB' => 'Yevugbe (Britain)',
 				'en_GB@alt=short' => 'Yevugbe (GB)',
 				'en_US' => 'Yevugbe (America)',
 				'en_US@alt=short' => 'Yevugbe (US)',
 				'eo' => 'esperantogbe',
 				'es' => 'Spanishgbe',
 				'es_419' => 'Spanishgbe (Latin America)',
 				'es_ES' => 'Spanishgbe (Europe)',
 				'es_MX' => 'Spanishgbe (Mexico)',
 				'et' => 'estoniagbe',
 				'eu' => 'basqugbe',
 				'ewo' => 'ewondogbe',
 				'fa' => 'persiagbe',
 				'fan' => 'fangbe',
 				'ff' => 'fulagbe',
 				'fi' => 'finlanɖgbe',
 				'fil' => 'filipingbe',
 				'fj' => 'fidzigbe',
 				'fo' => 'faroegbe',
 				'fr' => 'Fransegbe',
 				'fr_CA' => 'Fransegbe (Canada)',
 				'fr_CH' => 'Fransegbe (Switzerland)',
 				'fy' => 'ɣetoɖoƒe frisiagbe',
 				'ga' => 'irelanɖgbe',
 				'gaa' => 'gɛgbe',
 				'gd' => 'skɔtlanɖ gaeliagbe',
 				'gil' => 'gilbertgbe',
 				'gl' => 'galatagbe',
 				'gn' => 'guarangbe',
 				'gsw' => 'swizerlanɖtɔwo ƒe germaniagbe',
 				'gu' => 'gujarati',
 				'ha' => 'hausagbe',
 				'haw' => 'hawaigbe',
 				'he' => 'hebrigbe',
 				'hi' => 'Hindigbe',
 				'hil' => 'hiligenɔgbe',
 				'ho' => 'hiri motugbe',
 				'hr' => 'kroatiagbe',
 				'ht' => 'haitigbe',
 				'hu' => 'hungarigbe',
 				'hy' => 'armeniagbe',
 				'ibb' => 'ibibiogbe',
 				'id' => 'Indonesiagbe',
 				'ig' => 'igbogbe',
 				'ilo' => 'ilikogbe',
 				'inh' => 'ingusigbe',
 				'is' => 'icelanɖgbe',
 				'it' => 'Italiagbe',
 				'ja' => 'Japangbe',
 				'jv' => 'dzavangbe',
 				'ka' => 'gɔgiagbe',
 				'kbd' => 'kabardiagbe',
 				'kea' => 'cape verdegbe',
 				'kg' => 'kongogbe',
 				'kha' => 'khasigbe',
 				'kj' => 'kunyamagbe',
 				'kk' => 'kazakhstangbe',
 				'kkj' => 'kakogbe',
 				'kl' => 'kalaalisugbe',
 				'km' => 'khmergbe',
 				'kn' => 'kannadagbe',
 				'ko' => 'Koreagbe',
 				'kok' => 'konkaniagbe',
 				'kos' => 'kosraeagbe',
 				'kr' => 'kanuriagbe',
 				'krc' => 'karakay-bakargbe',
 				'ks' => 'kashmirgbe',
 				'ksf' => 'bafiagbe',
 				'ku' => 'kurdiagbe',
 				'kum' => 'kumikagbe',
 				'ky' => 'kirghistangbe',
 				'la' => 'latin',
 				'lah' => 'lahndagbe',
 				'lb' => 'laksembɔggbe',
 				'lez' => 'lezghiagbe',
 				'ln' => 'lingala',
 				'lo' => 'laogbe',
 				'lt' => 'lithuaniagbe',
 				'lu' => 'luba-katangagbe',
 				'lua' => 'luba-lulugbe',
 				'luy' => 'luyiagbe',
 				'lv' => 'latviagbe',
 				'maf' => 'mafagbe',
 				'mai' => 'maitiligbe',
 				'mdf' => 'moktsiagbe',
 				'mg' => 'malagasegbe',
 				'mgh' => 'makuwa-mitogbe',
 				'mh' => 'marshalgbe',
 				'mi' => 'maorgbe',
 				'mk' => 'makedoniagbe',
 				'ml' => 'malayagbe',
 				'mn' => 'mongoliagbe',
 				'mr' => 'marathiagbe',
 				'ms' => 'malaygbe',
 				'mt' => 'maltagbe',
 				'mua' => 'mundangbe',
 				'mul' => 'gbegbɔgblɔ sɔgbɔwo',
 				'my' => 'burmagbe',
 				'mye' => 'myenegbe',
 				'myv' => 'erziyagbe',
 				'na' => 'naurugbe',
 				'nb' => 'nɔweigbe bokmål',
 				'nd' => 'dziehe ndebelegbe',
 				'ne' => 'nepalgbe',
 				'niu' => 'niuegbe',
 				'nl' => 'Hollandgbe',
 				'nl_BE' => 'Flemishgbe',
 				'nmg' => 'kwasiogbe',
 				'nn' => 'nɔweigbe ninɔsk',
 				'nnh' => 'ngiemboongbe',
 				'no' => 'nɔweigbe',
 				'nr' => 'anyiehe ndebelegbe',
 				'nso' => 'dziehe sothogbe',
 				'nus' => 'nuergbe',
 				'ny' => 'nyanjagbe',
 				'or' => 'oriyagbe',
 				'os' => 'ossetiagbe',
 				'pa' => 'pundzabgbe',
 				'pag' => 'pangsinagbe',
 				'pap' => 'papiamentogbe',
 				'pau' => 'paluagbe',
 				'pl' => 'Polishgbe',
 				'pon' => 'ponpeiagbe',
 				'ps' => 'pashtogbe',
 				'pt' => 'Portuguesegbe',
 				'pt_BR' => 'Portuguesegbe (Brazil)',
 				'pt_PT' => 'Portuguesegbe (Europe)',
 				'qu' => 'kwetsuagbe',
 				'rm' => 'romanshgbe',
 				'rn' => 'rundigbe',
 				'ro' => 'romaniagbe',
 				'rof' => 'rombogbe',
 				'ru' => 'Russiagbe',
 				'rw' => 'ruwandagbe',
 				'rwk' => 'rwagbe',
 				'sa' => 'sanskrigbe',
 				'sah' => 'sakagbe',
 				'sat' => 'santaligbe',
 				'sbp' => 'sangugbe',
 				'sd' => 'sindhgbe',
 				'se' => 'dziehe samigbe',
 				'sg' => 'sangogbe',
 				'sh' => 'serbo-croatiagbe',
 				'si' => 'sinhalgbe',
 				'sk' => 'slovakiagbe',
 				'sl' => 'sloveniagbe',
 				'sm' => 'samoagbe',
 				'sn' => 'shonagbe',
 				'so' => 'somaliagbe',
 				'sq' => 'albaniagbe',
 				'sr' => 'serbiagbe',
 				'ss' => 'swatgbe',
 				'st' => 'anyiehe sothogbe',
 				'sv' => 'swedengbe',
 				'sw' => 'swahili',
 				'swb' => 'komorogbe',
 				'ta' => 'tamilgbe',
 				'te' => 'telegugbe',
 				'tet' => 'tetumgbe',
 				'tg' => 'tadzikistangbe',
 				'th' => 'Thailandgbe',
 				'ti' => 'tigrinyagbe',
 				'tk' => 'tɛkmengbe',
 				'tkl' => 'tokelaugbe',
 				'tl' => 'tagalogbe',
 				'tn' => 'tswanagbe',
 				'to' => 'tongagbe',
 				'tpi' => 'tok pisigbe',
 				'tr' => 'Turkishgbe',
 				'ts' => 'tsongagbe',
 				'tt' => 'tatargbe',
 				'tvl' => 'tuvalugbe',
 				'twq' => 'tasawakgbe',
 				'ty' => 'tahitigbe',
 				'tyv' => 'tuviniagbe',
 				'udm' => 'udmurtgbe',
 				'ug' => 'uighurgbe',
 				'uk' => 'ukraingbe',
 				'und' => 'gbegbɔgblɔ manya',
 				'ur' => 'urdugbe',
 				'uz' => 'uzbekistangbe',
 				'vai' => 'vaigbe',
 				've' => 'vendagbe',
 				'vi' => 'vietnamgbe',
 				'wae' => 'walsegbe',
 				'war' => 'waraygbe',
 				'wo' => 'wolofgbe',
 				'xh' => 'xhosagbe',
 				'yap' => 'yapesigbe',
 				'yav' => 'yangbengbe',
 				'ybb' => 'yembagbe',
 				'yo' => 'yorubagbe',
 				'yue' => 'cantongbe',
 				'za' => 'zhuangbe',
 				'zh' => 'Chinagbe',
 				'zh_Hans' => 'tsainagbe',
 				'zh_Hant' => 'blema tsainagbe',
 				'zu' => 'zulugbe',
 				'zxx' => 'gbegbɔgblɔ manɔmee',

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
			'Arab' => 'Arabiagbeŋɔŋlɔ',
 			'Armi' => 'aramia gbeŋɔŋlɔ',
 			'Armn' => 'armeniagbeŋɔŋlɔ',
 			'Avst' => 'avesta gbeŋɔŋlɔ',
 			'Bali' => 'balini gbeŋɔŋlɔ',
 			'Bamu' => 'bamum gbeŋɔŋlɔ',
 			'Batk' => 'batak gbeŋɔŋlɔ',
 			'Beng' => 'bengaligbeŋɔŋlɔ',
 			'Blis' => 'bliss ŋɔŋlɔdzesi',
 			'Bopo' => 'bopomfogbeŋɔŋlɔ',
 			'Brah' => 'brami gbeŋɔŋlɔ',
 			'Brai' => 'braillegbeŋɔŋlɔ',
 			'Buhd' => 'buhid gbeŋɔŋlɔ',
 			'Cakm' => 'tsakma gbeŋɔŋlɔ',
 			'Cans' => 'kanada wɔɖeka ƒe abɔridzin gbedodo',
 			'Cari' => 'karia gbeŋɔŋlɔ',
 			'Cham' => 'tsam gbeŋɔŋlɔ',
 			'Cher' => 'tseroke gbeŋɔŋlɔ',
 			'Cirt' => 'seif gbeŋɔŋlɔ',
 			'Copt' => 'koptia gbeŋɔŋlɔ',
 			'Cprt' => 'saipriot gbeŋɔŋlɔ',
 			'Cyrl' => 'Cyrillicgbeŋɔŋlɔ',
 			'Cyrs' => 'slavonia sirillia sɔleme gbeŋɔŋlɔ xoxotɔ',
 			'Deva' => 'devanagarigbeŋɔŋlɔ',
 			'Dsrt' => 'deseret gbeŋɔŋlɔ',
 			'Egyd' => 'egypte demotia gbeŋɔŋlɔ',
 			'Egyh' => 'egypte hieratia gbeŋɔŋlɔ',
 			'Egyp' => 'egypte hieroglif nuŋɔŋlɔ',
 			'Ethi' => 'ethiopiagbeŋɔŋlɔ',
 			'Geok' => 'dzɔdzia khutsiria gbeŋɔŋlɔ',
 			'Geor' => 'gɔgiagbeŋɔŋlɔ',
 			'Glag' => 'glagolitia gbeŋɔŋlɔ',
 			'Goth' => 'gothia gbeŋɔŋlɔ',
 			'Gran' => 'grantha gbeŋɔŋlɔ',
 			'Grek' => 'grisigbeŋɔŋlɔ',
 			'Gujr' => 'gudzaratigbeŋɔŋlɔ',
 			'Guru' => 'gurmukhigbeŋɔŋlɔ',
 			'Hang' => 'hangulgbeŋɔŋlɔ',
 			'Hani' => 'hangbeŋɔŋlɔ',
 			'Hano' => 'hanuno gbeŋɔŋlɔ',
 			'Hans' => 'Chinesegbeŋɔŋlɔ',
 			'Hans@alt=stand-alone' => 'Hansgbeŋɔŋlɔ',
 			'Hant' => 'Blema Chinesegbeŋɔŋlɔ',
 			'Hant@alt=stand-alone' => 'Blema Hantgbeŋcŋlɔ',
 			'Hebr' => 'hebrigbeŋɔŋlɔ',
 			'Hira' => 'hiraganagbeŋɔŋlɔ',
 			'Hmng' => 'pahawh hmong gbeŋɔŋlɔ',
 			'Hrkt' => 'dzapan gbedodo tɔxee',
 			'Hung' => 'hungaria gbeŋɔŋlɔ xoxotɔ',
 			'Inds' => 'indus gbeŋɔŋlɔ',
 			'Ital' => 'aitalik xoxotɔ',
 			'Java' => 'dzavanese gbeŋɔŋlɔ',
 			'Jpan' => 'Japanesegbeŋɔŋlɔ',
 			'Kali' => 'kayah li gbeŋɔŋlɔ',
 			'Kana' => 'katakanagbeŋɔŋlɔ',
 			'Khar' => 'kharoshthi gbeŋɔŋlɔ',
 			'Khmr' => 'khmergbeŋɔŋlɔ',
 			'Khoj' => 'khodziki gbeŋɔŋlɔ',
 			'Knda' => 'kannadagbeŋɔŋlɔ',
 			'Kore' => 'Koreagbeŋɔŋlɔ',
 			'Kthi' => 'kaithi gbeŋɔŋlɔ',
 			'Lana' => 'lanna gbeŋɔŋlɔ',
 			'Laoo' => 'laogbeŋɔŋlɔ',
 			'Latf' => 'fraktur latin gbeŋɔŋlɔ',
 			'Latg' => 'gaelia latin gbeŋɔŋlɔ',
 			'Latn' => 'Latingbeŋɔŋlɔ',
 			'Lepc' => 'leptsa gbeŋɔŋlɔ',
 			'Limb' => 'limbu gbeŋɔŋlɔ',
 			'Lina' => 'linia a gbeŋɔŋlɔ',
 			'Linb' => 'linea b gbeŋɔŋlɔ',
 			'Lisu' => 'fraser gbeŋɔŋlɔ',
 			'Lyci' => 'lisia gbeŋɔŋlɔ',
 			'Lydi' => 'lidia gbeŋɔŋlɔ',
 			'Mand' => 'mandae gbeŋɔŋlɔ',
 			'Mani' => 'manitsia gbeŋɔŋlɔ',
 			'Maya' => 'mayan hieroglif gbeŋɔŋlɔ',
 			'Merc' => 'meroitia atsyia gbeŋɔŋlɔ',
 			'Mero' => 'meroitia gbeŋɔŋlɔ',
 			'Mlym' => 'malayagbeŋɔŋlɔ',
 			'Mong' => 'mongoliagbeŋɔŋlɔ',
 			'Moon' => 'moon gbeŋɔŋlɔ',
 			'Mtei' => 'meitei mayek gbeŋɔŋlɔ',
 			'Mymr' => 'myanmargbeŋɔŋlɔ',
 			'Nkgb' => 'naxi geba gbeŋɔŋlɔ',
 			'Nkoo' => 'n’ko gbeŋɔŋlɔ',
 			'Ogam' => 'ogham gbeŋɔŋlɔ',
 			'Olck' => 'ol tsiki gbeŋɔŋlɔ',
 			'Orkh' => 'orkhon gbeŋɔŋlɔ',
 			'Orya' => 'oriyagbeŋɔŋlɔ',
 			'Osma' => 'osmaya gbeŋɔŋlɔ',
 			'Perm' => 'permia gbeŋɔŋlɔ xoxotɔ',
 			'Phag' => 'phags-pa gbeŋɔŋlɔ',
 			'Phli' => 'pahlavi gbeŋɔŋlɔ tɔxee',
 			'Phlp' => 'psamta pahlavi gbeŋɔŋlɔ',
 			'Phlv' => 'agbaleme pahlavi gbeŋɔŋlɔ',
 			'Phnx' => 'foenesia gbeŋɔŋlɔ',
 			'Plrd' => 'pollard gbegbɔgblɔ',
 			'Prti' => 'parthia gbeŋɔŋlɔ tɔxee',
 			'Rjng' => 'redza gbeŋɔŋlɔ',
 			'Roro' => 'rongorongo gbeŋɔŋlɔ',
 			'Runr' => 'runia gbeŋɔŋlɔ',
 			'Samr' => 'samaria gbeŋɔŋlɔ',
 			'Sara' => 'sarati gbeŋɔŋlɔ',
 			'Sarb' => 'anyiehe arabia gbeŋɔŋlɔ xoxotɔ',
 			'Saur' => 'saurashtra gbeŋɔŋlɔ',
 			'Sgnw' => 'atsyia nuŋɔŋlɔ',
 			'Shaw' => 'tsavia gbeŋɔŋlɔ',
 			'Sinh' => 'sinhalagbeŋɔŋlɔ',
 			'Sund' => 'sundana gbeŋɔŋlɔ',
 			'Sylo' => 'sailoti nagri gbeŋɔŋlɔ',
 			'Syrc' => 'siriak gbeŋɔŋlɔ',
 			'Syre' => 'estrangelo siria gbeŋɔŋlɔ',
 			'Syrj' => 'ɣetoɖoƒe siria gbeŋɔŋlɔ',
 			'Syrn' => 'ɣedzeƒe siria gbeŋɔŋlɔ',
 			'Tagb' => 'tagbanwa gbeŋɔŋlɔ',
 			'Tale' => 'tai le gbeŋɔŋlɔ',
 			'Talu' => 'tail lue gbeŋɔŋlɔ yeye',
 			'Taml' => 'tamilgbeŋɔŋlɔ',
 			'Tavt' => 'tai viet gbeŋɔŋlɔ',
 			'Telu' => 'telegugbeŋɔŋlɔ',
 			'Teng' => 'tengwar gbeŋɔŋlɔ',
 			'Tfng' => 'tifinagh gbeŋɔŋlɔ',
 			'Tglg' => 'tagalog gbeŋɔŋlɔ',
 			'Thaa' => 'thaanagbeŋɔŋlɔ',
 			'Thai' => 'taigbeŋɔŋlɔ',
 			'Tibt' => 'tibetgbeŋɔŋlɔ',
 			'Tirh' => 'tirhuta gbeŋɔŋlɔ',
 			'Ugar' => 'ugaritia gbeŋɔŋlɔ',
 			'Vaii' => 'vai gbeŋɔŋlɔ',
 			'Visp' => 'gbegbɔgblɔ si dzena',
 			'Wara' => 'varang kshiti gbeŋɔŋlɔ',
 			'Xpeo' => 'persia gbeŋɔŋlɔ xoxotɔ',
 			'Xsux' => 'sumero-akkadia kunei gbeŋɔŋlɔ',
 			'Yiii' => 'yi gbeŋɔŋlɔ',
 			'Zinh' => 'gbeŋɔŋlɔ si wo dzɔ va tu',
 			'Zmth' => 'akɔnta nuŋɔŋlɔ',
 			'Zsym' => 'ŋɔŋlɔdzesiwo',
 			'Zxxx' => 'gbemaŋlɔ',
 			'Zyyy' => 'gbeŋɔŋlɔ bɔbɔ',
 			'Zzzz' => 'gbeŋɔŋlɔ manya',

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
			'001' => 'xexeme',
 			'002' => 'Afrika nutome',
 			'003' => 'Dziehe Amerika nutome',
 			'005' => 'Anyiehe Amerika nutome',
 			'009' => 'Oceania nutome',
 			'011' => 'Ɣetoɖoƒelɔƒo Afrika nutome',
 			'013' => 'Titina Amerika nutome',
 			'014' => 'Ɣedzeƒe Afrika nutome',
 			'015' => 'Dziehe Afrika nutome',
 			'017' => 'Titina Afrika nutome',
 			'018' => 'Anyiehelɔƒo Afrika nutome',
 			'019' => 'Amerika nutome',
 			'021' => 'Dziehelɔƒo Amerika nutome',
 			'029' => 'Karibbea nutome',
 			'030' => 'Ɣedzeƒe Asia nutome',
 			'034' => 'Anyiehelɔƒo Asia nutome',
 			'035' => 'Anyiehe Ɣedzeƒe Afrika nutome',
 			'039' => 'Anyiehelɔƒo Europa nutome',
 			'053' => 'Australia kple New Zealand nutome',
 			'054' => 'Melanesia nutome',
 			'057' => 'Mikronesia',
 			'061' => 'Pɔlinesia nutome',
 			'142' => 'Asia nutome',
 			'143' => 'Titina Asia nutome',
 			'145' => 'Ɣetoɖoƒelɔƒo Asia nutome',
 			'150' => 'Europa nutome',
 			'151' => 'Ɣedzeƒe Europa nutome',
 			'154' => 'Dziehelɔƒo Europa nutome',
 			'155' => 'Ɣetoɖoƒelɔƒo Europa nutome',
 			'419' => 'Latin Amerika nutome',
 			'AC' => 'Ascension ƒudomekpo nutome',
 			'AD' => 'Andorra nutome',
 			'AE' => 'United Arab Emirates nutome',
 			'AF' => 'Afghanistan nutome',
 			'AG' => '́Antigua kple Barbuda nutome',
 			'AI' => 'Anguilla nutome',
 			'AL' => 'Albania nutome',
 			'AM' => 'Armenia nutome',
 			'AO' => 'Angola nutome',
 			'AQ' => 'Antartica nutome',
 			'AR' => 'Argentina nutome',
 			'AS' => 'Amerika Samoa nutome',
 			'AT' => 'Austria nutome',
 			'AU' => 'Australia nutome',
 			'AW' => 'Aruba nutome',
 			'AX' => 'Åland ƒudomekpo nutome',
 			'AZ' => 'Azerbaijan nutome',
 			'BA' => 'Bosnia kple Herzergovina nutome',
 			'BB' => 'Barbados nutome',
 			'BD' => 'Bangladesh nutome',
 			'BE' => 'Belgium nutome',
 			'BF' => 'Burkina Faso nutome',
 			'BG' => 'Bulgaria nutome',
 			'BH' => 'Bahrain nutome',
 			'BI' => 'Burundi nutome',
 			'BJ' => 'Benin nutome',
 			'BL' => 'Saint Barthélemy nutome',
 			'BM' => 'Bermuda nutome',
 			'BN' => 'Brunei nutome',
 			'BO' => 'Bolivia nutome',
 			'BQ' => 'Karibbeatɔwo ƒe Nedalanɖs nutome',
 			'BR' => 'Brazil nutome',
 			'BS' => 'Bahamas nutome',
 			'BT' => 'Bhutan nutome',
 			'BV' => 'Bouvet ƒudomekpo nutome',
 			'BW' => 'Botswana nutome',
 			'BY' => 'Belarus nutome',
 			'BZ' => 'Belize nutome',
 			'CA' => 'Canada nutome',
 			'CC' => 'Kokos (Kiling) fudomekpo nutome',
 			'CD' => 'Kongo Kinshasa nutome',
 			'CD@alt=variant' => 'Kongo demokratik repɔblik nutome',
 			'CF' => 'Titina Afrika repɔblik nutome',
 			'CG' => 'Kongo Brazzaville nutome',
 			'CG@alt=variant' => 'Kongo repɔblik nutome',
 			'CH' => 'Switzerland nutome',
 			'CI' => 'Kote d’Ivoire nutome',
 			'CI@alt=variant' => 'Ivory Kost nutome',
 			'CK' => 'Kook ƒudomekpo nutome',
 			'CL' => 'Tsile nutome',
 			'CM' => 'Kamerun nutome',
 			'CN' => 'Tsaina nutome',
 			'CO' => 'Kolombia nutome',
 			'CP' => 'Klipaton ƒudomekpo nutome',
 			'CR' => 'Kosta Rika nutome',
 			'CU' => 'Kuba nutome',
 			'CV' => 'Kape Verde nutome',
 			'CW' => 'Kurakao nutome',
 			'CX' => 'Kristmas ƒudomekpo nutome',
 			'CY' => 'Saiprus nutome',
 			'CZ' => 'Tsɛk repɔblik nutome',
 			'DE' => 'Germania nutome',
 			'DG' => 'Diego Garsia nutome',
 			'DJ' => 'Dzibuti nutome',
 			'DK' => 'Denmark nutome',
 			'DM' => 'Dominika nutome',
 			'DO' => 'Dominika repɔblik nutome',
 			'DZ' => 'Algeria nutome',
 			'EA' => 'Keuta and Melilla nutome',
 			'EC' => 'Ekuadɔ nutome',
 			'EE' => 'Estonia nutome',
 			'EG' => 'Egypte nutome',
 			'EH' => 'Ɣetoɖoƒe Sahara nutome',
 			'ER' => 'Eritrea nutome',
 			'ES' => 'Spain nutome',
 			'ET' => 'Etiopia nutome',
 			'EU' => 'Europa Wɔɖeka nutome',
 			'FI' => 'Finland nutome',
 			'FJ' => 'Fidzi nutome',
 			'FK' => 'Falkland ƒudomekpowo nutome',
 			'FK@alt=variant' => 'Falkland ƒudomekpowo (Islas Malvinas) nutome',
 			'FM' => 'Mikronesia nutome',
 			'FO' => 'Faroe ƒudomekpowo nutome',
 			'FR' => 'France nutome',
 			'GA' => 'Gabɔn nutome',
 			'GB' => 'United Kingdom nutome',
 			'GD' => 'Grenada nutome',
 			'GE' => 'Georgia nutome',
 			'GF' => 'Frentsi Gayana nutome',
 			'GG' => 'Guernse nutome',
 			'GH' => 'Ghana nutome',
 			'GI' => 'Gibraltar nutome',
 			'GL' => 'Grinland nutome',
 			'GM' => 'Gambia nutome',
 			'GN' => 'Guini nutome',
 			'GP' => 'Guadelupe nutome',
 			'GQ' => 'Ekuatorial Guini nutome',
 			'GR' => 'Greece nutome',
 			'GS' => 'Anyiehe Georgia kple Anyiehe Sandwich ƒudomekpowo nutome',
 			'GT' => 'Guatemala nutome',
 			'GU' => 'Guam nutome',
 			'GW' => 'Gini-Bisao nutome',
 			'GY' => 'Guyanadu',
 			'HK' => 'Hɔng Kɔng SAR Tsaina nutome',
 			'HK@alt=short' => 'Hɔng Kɔng nutome',
 			'HM' => 'Heard kple Mcdonald ƒudomekpowo nutome',
 			'HN' => 'Hondurasdu',
 			'HR' => 'Kroatsia nutome',
 			'HT' => 'Haiti nutome',
 			'HU' => 'Hungari nutome',
 			'IC' => 'Kanari ƒudomekpowo nutome',
 			'ID' => 'Indonesia nutome',
 			'IE' => 'Ireland nutome',
 			'IL' => 'Israel nutome',
 			'IM' => 'Aisle of Man nutome',
 			'IN' => 'India nutome',
 			'IO' => 'Britaintɔwo ƒe india ƒudome nutome',
 			'IQ' => 'iraqdukɔ',
 			'IR' => 'Iran nutome',
 			'IS' => 'Aiseland nutome',
 			'IT' => 'Italia nutome',
 			'JE' => 'Dzɛse nutome',
 			'JM' => 'Dzamaika nutome',
 			'JO' => 'Yordan nutome',
 			'JP' => 'Dzapan nutome',
 			'KE' => 'Kenya nutome',
 			'KG' => 'Kirgizstan nutome',
 			'KH' => 'Kambodia nutome',
 			'KI' => 'Kiribati nutome',
 			'KM' => 'Komoros nutome',
 			'KN' => 'Saint Kitis kple Nevis nutome',
 			'KP' => 'Dziehe Korea nutome',
 			'KR' => 'Anyiehe Korea nutome',
 			'KW' => 'Kuwait nutome',
 			'KY' => 'Kayman ƒudomekpowo nutome',
 			'KZ' => 'Kazakstan nutome',
 			'LA' => 'Laos nutome',
 			'LB' => 'Lebanɔn nutome',
 			'LC' => 'Saint Lusia nutome',
 			'LI' => 'Litsenstein nutome',
 			'LK' => 'Sri Lanka nutome',
 			'LR' => 'Liberia nutome',
 			'LS' => 'Lɛsoto nutome',
 			'LT' => 'Lituania nutome',
 			'LU' => 'Lazembɔg nutome',
 			'LV' => 'Latvia nutome',
 			'LY' => 'Libya nutome',
 			'MA' => 'Moroko nutome',
 			'MC' => 'Monako nutome',
 			'MD' => 'Moldova nutome',
 			'ME' => 'Montenegro nutome',
 			'MF' => 'Saint Martin nutome',
 			'MG' => 'Madagaska nutome',
 			'MH' => 'Marshal ƒudomekpowo nutome',
 			'MK' => 'Makedonia nutome',
 			'MK@alt=variant' => 'Makedonia (FYROM) nutome',
 			'ML' => 'Mali nutome',
 			'MM' => 'Myanmar (Burma) nutome',
 			'MN' => 'Mongolia nutome',
 			'MO' => 'Macau SAR Tsaina nutome',
 			'MO@alt=short' => 'Macau nutome',
 			'MP' => 'Dziehe Marina ƒudomekpowo nutome',
 			'MQ' => 'Martiniki nutome',
 			'MR' => 'Mauritania nutome',
 			'MS' => 'Montserrat nutome',
 			'MT' => 'Malta nutome',
 			'MU' => 'mauritiusdukɔ',
 			'MV' => 'maldivesdukɔ',
 			'MW' => 'Malawi nutome',
 			'MX' => 'Mexico nutome',
 			'MY' => 'Malaysia nutome',
 			'MZ' => 'Mozambiki nutome',
 			'NA' => 'Namibia nutome',
 			'NC' => 'New Kaledonia nutome',
 			'NE' => 'Niger nutome',
 			'NF' => 'Norfolk ƒudomekpo nutome',
 			'NG' => 'Nigeria nutome',
 			'NI' => 'Nicaraguadukɔ',
 			'NL' => 'Netherlands nutome',
 			'NO' => 'Norway nutome',
 			'NP' => 'Nepal nutome',
 			'NR' => 'Nauru nutome',
 			'NU' => 'Niue nutome',
 			'NZ' => 'New Zealand nutome',
 			'OM' => 'Oman nutome',
 			'PA' => 'Panama nutome',
 			'PE' => 'Peru nutome',
 			'PF' => 'Frentsi Pɔlinesia nutome',
 			'PG' => 'Papua New Gini nutome',
 			'PH' => 'Filipini nutome',
 			'PK' => 'Pakistan nutome',
 			'PL' => 'Poland nutome',
 			'PM' => 'Saint Pierre kple Mikelɔn nutome',
 			'PN' => 'Pitkairn ƒudomekpo nutome',
 			'PR' => 'Puerto Riko nutome',
 			'PS' => 'Palestinia nutome',
 			'PT' => 'Portugal nutome',
 			'PW' => 'Palau nutome',
 			'PY' => 'Paragua nutome',
 			'QA' => 'Katar nutome',
 			'QO' => 'Outlaying Oceania nutome',
 			'RE' => 'Réunion nutome',
 			'RO' => 'Romania nutome',
 			'RS' => 'Serbia nutome',
 			'RU' => 'Russia nutome',
 			'RW' => 'Rwanda nutome',
 			'SA' => 'Saudi Arabia nutome',
 			'SB' => 'Solomon ƒudomekpowo nutome',
 			'SC' => 'Seshɛls nutome',
 			'SD' => 'Sudan nutome',
 			'SE' => 'Sweden nutome',
 			'SG' => 'Singapɔr nutome',
 			'SH' => 'Saint Helena nutome',
 			'SI' => 'Slovenia nutome',
 			'SJ' => 'Svalbard kple Yan Mayen nutome',
 			'SK' => 'Slovakia nutome',
 			'SL' => 'Sierra Leone nutome',
 			'SM' => 'San Marino nutome',
 			'SN' => 'Senegal nutome',
 			'SO' => 'Somalia nutome',
 			'SR' => 'Suriname nutome',
 			'SS' => 'Anyiehe Sudan nutome',
 			'ST' => 'São Tomé kple Príncipe nutome',
 			'SV' => 'El Salvadɔ nutome',
 			'SX' => 'Sint Maarten nutome',
 			'SY' => 'Siria nutome',
 			'SZ' => 'Swaziland nutome',
 			'TA' => 'Tristan da Kunha nutome',
 			'TC' => 'Tɛks kple Kaikos ƒudomekpowo nutome',
 			'TD' => 'Tsad nutome',
 			'TF' => 'Anyiehe Franseme nutome',
 			'TG' => 'Togo nutome',
 			'TH' => 'Thailand nutome',
 			'TJ' => 'Tajikistan nutome',
 			'TK' => 'Tokelau nutome',
 			'TL' => 'Timor-Leste nutome',
 			'TL@alt=variant' => 'Ɣedzeƒe Timɔ nutome',
 			'TM' => 'Tɛkmenistan nutome',
 			'TN' => 'Tunisia nutome',
 			'TO' => 'Tonga nutome',
 			'TR' => 'Tɛki nutome',
 			'TT' => 'Trinidad kple Tobago nutome',
 			'TV' => 'Tuvalu nutome',
 			'TW' => 'Taiwan nutome',
 			'TZ' => 'Tanzania nutome',
 			'UA' => 'Ukraine nutome',
 			'UG' => 'Uganda nutome',
 			'UM' => 'U.S. Minor Outlaying ƒudomekpowo nutome',
 			'US' => 'USA nutome',
 			'UY' => 'uruguaydukɔ',
 			'UZ' => 'Uzbekistan nutome',
 			'VA' => 'Vatikandu nutome',
 			'VC' => 'Saint Vincent kple Grenadine nutome',
 			'VE' => 'Venezuela nutome',
 			'VG' => 'Britaintɔwo ƒe Virgin ƒudomekpowo nutome',
 			'VI' => 'U.S. Vɛrgin ƒudomekpowo nutome',
 			'VN' => 'Vietnam nutome',
 			'VU' => 'Vanuatu nutome',
 			'WF' => 'Wallis kple Futuna nutome',
 			'WS' => 'Samoa nutome',
 			'YE' => 'Yemen nutome',
 			'YT' => 'Mayotte nutome',
 			'ZA' => 'Anyiehe Africa nutome',
 			'ZM' => 'Zambia nutome',
 			'ZW' => 'Zimbabwe nutome',
 			'ZZ' => 'nutome manya',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'ALALC97' => 'ALALC9',
 			'BISCAYAN' => 'BISCAYA',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'kalenda',
 			'collation' => 'tutuɖo',
 			'currency' => 'gaɖuɖu',
 			'numbers' => 'nɔmbawo',

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
 				'buddhist' => q{buddha subɔlawo ƒe kalenda},
 				'chinese' => q{chinatɔwo ƒe kalenda},
 				'coptic' => q{coptia kalenda},
 				'ethiopic' => q{ethiopiatɔwo ƒe kalenda},
 				'ethiopic-amete-alem' => q{ethiopia amate alemtɔwo ƒe kalenda},
 				'gregorian' => q{Gregorian kalenda},
 				'hebrew' => q{hebritɔwo ƒe kalenda},
 				'indian' => q{india dukɔ ƒe kalenda},
 				'islamic' => q{islam subɔlawo ƒe kalenda},
 				'islamic-civil' => q{islam subɔlawo ƒe sivil kalenda},
 				'japanese' => q{japantɔwo ƒe kalenda},
 				'persian' => q{persiatɔwo ƒe kalenda},
 				'roc' => q{china repɔbliktɔwo ƒe kalenda tso 1912},
 			},
 			'collation' => {
 				'big5han' => q{blema chinatɔwo ƒe ɖoɖomɔ nu},
 				'dictionary' => q{nuɖoɖo ɖe nyagɔmeɖegbalẽ ƒe ɖoɖomɔ nu},
 				'ducet' => q{nuɖoɖo ɖe unicode ƒe ɖoɖo nu},
 				'gb2312han' => q{chinagbe yeye ƒe ɖoɖomɔ nu},
 				'phonebook' => q{fonegbalẽ me ɖoɖomɔ nu},
 				'pinyin' => q{pinyin ɖoɖomɔ nu},
 				'reformed' => q{nugbugbɔtoɖo ƒe ɖoɖomɔ nu},
 				'search' => q{nudidi hena zazã gbadza},
 				'searchjl' => q{nudidi le hangul ƒe ɖoɖo gbãtɔ nu},
 				'standard' => q{standard},
 				'stroke' => q{stroke ɖoɖomɔ nu},
 				'traditional' => q{blema ɖoɖomɔ nu},
 				'unihan' => q{ɖoɖomɔnutɔxɛ manɔŋu stroke ƒe ɖoɖo nu},
 			},
 			'numbers' => {
 				'arab' => q{india ƒe arabia digitwo},
 				'arabext' => q{india ƒe arabia digitwo dzi yiyi},
 				'armn' => q{armeniatɔwo ƒe numeralwo},
 				'armnlow' => q{armeniatɔwo ƒe numeral suetɔwo},
 				'bali' => q{balina digitwo},
 				'beng' => q{bengalitɔwo ƒe digitwo},
 				'cham' => q{tsam digitwo},
 				'deva' => q{devanagari digitwo},
 				'ethi' => q{ethiopia numeralwo},
 				'fullwide' => q{digit kekeme blibotɔwo},
 				'geor' => q{georgiatɔwo ƒe numeralwo},
 				'grek' => q{greecetɔwo ƒe nemeralwo},
 				'greklow' => q{greecetɔwo ƒe numeral suetɔwo},
 				'gujr' => q{gujarati digitwo},
 				'guru' => q{gurmukhi digitwo},
 				'hanidec' => q{chinatɔwo ƒe nɔmba madeblibowo},
 				'hans' => q{chinatɔwo ƒe numeralwo},
 				'hansfin' => q{chinatɔwo ƒe gadzikpɔ numeralwo},
 				'hant' => q{blema chinatɔwo ƒe numeralwo},
 				'hantfin' => q{blema chinatɔwo ƒe gadzikpɔ numeralwo},
 				'hebr' => q{hebritɔwo ƒe numeralwo},
 				'java' => q{dzava digitwo},
 				'jpan' => q{japantɔwo ƒe numeralwo},
 				'jpanfin' => q{japantɔwo ƒe gadzikpɔnumeralwo},
 				'kali' => q{kali digitwo},
 				'khmr' => q{khmertɔwo ƒe nɔmbawo},
 				'knda' => q{kannadatɔwo ƒe digitwo},
 				'lana' => q{lana digitwo},
 				'lanatham' => q{lanatham digitwo},
 				'laoo' => q{laotɔwo ƒe digitwo},
 				'latn' => q{Nɔmbawo le Latingbe ƒe ɖoɖo nu},
 				'lepc' => q{leptsa digitwo},
 				'limb' => q{limbu digitwo},
 				'mlym' => q{malaya digitwo},
 				'mong' => q{mongolia digitwo},
 				'mtei' => q{meetei mayek digitwo},
 				'mymr' => q{myanmar digitwo},
 				'mymrshan' => q{myanmar shan digitwo},
 				'nkoo' => q{n’ko digitwo},
 				'olck' => q{ol tsiki digitwo},
 				'orya' => q{oriya digitwo},
 				'roman' => q{romatɔwo ƒe numeralwo},
 				'romanlow' => q{romatɔwo ƒe numeral suetɔwo},
 				'saur' => q{saurashtra digitwo},
 				'sund' => q{sundana digitwo},
 				'talu' => q{tai lue digit yeye wo},
 				'taml' => q{tamil numeralwo},
 				'tamldec' => q{tamil digitwo},
 				'telu' => q{telegu digitwo},
 				'thai' => q{thai digitwo},
 				'tibt' => q{tibet digitwo},
 				'vaii' => q{vaii digitwo},
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
			'metric' => q{metric},
 			'UK' => q{uk},
 			'US' => q{us},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'gbegbɔgblɔ {0}',
 			'script' => 'gbeŋɔŋlɔ {0}',
 			'region' => 'memama {0}',

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
			auxiliary => qr{(?^u:[ă â å ä ā æ c ç ĕ ê ë ĭ î ï j ñ ŏ ô ö ø œ q ŭ û ü ÿ])},
			index => ['A', 'B', 'D', 'Ɖ', 'E', 'Ɛ', 'F', 'Ƒ', 'G', 'Ɣ', 'H', 'X', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'Ʋ', 'W', 'Y', 'Z'],
			main => qr{(?^u:[a á à ã b d ɖ e é è ẽ ɛ {ɛ́} {ɛ̀} {ɛ̃} f ƒ g ɣ h x i í ì ĩ k l m n ŋ o ó ò õ ɔ {ɔ́} {ɔ̀} {ɔ̃} p r s t u ú ù ũ v ʋ w y z])},
			punctuation => qr{(?^u:[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] \{ \} § @ * / \& # † ‡ ′ ″])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'Ɖ', 'E', 'Ɛ', 'F', 'Ƒ', 'G', 'Ɣ', 'H', 'X', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'Ʋ', 'W', 'Y', 'Z'], };
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
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{...},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
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
				hm => '\'ga\' h:mm',
				hms => '\'ga\' h:mm:ss',
				ms => 'aɖabaƒoƒo m:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(ŋkekewo),
						'one' => q(ŋkeke {0}),
						'other' => q(ŋkeke {0}),
					},
					'hour' => {
						'name' => q(gaƒoƒowo),
						'one' => q(gaƒoƒo {0}),
						'other' => q(gaƒoƒo {0}),
					},
					'kilometer' => {
						'name' => q(agbadroƒe),
						'one' => q(agbadroƒe {0}),
						'other' => q(agbadroƒe {0}),
					},
					'meter' => {
						'name' => q(abɔ),
						'one' => q(abɔ {0}),
						'other' => q(abɔ {0}),
					},
					'minute' => {
						'name' => q(aɖabaƒoƒowo),
						'one' => q(aɖabaƒoƒo {0}),
						'other' => q(aɖabaƒoƒo {0}),
					},
					'month' => {
						'name' => q(ɣletiwo),
						'one' => q(ɣleti {0}),
						'other' => q(ɣleti {0}),
					},
					'second' => {
						'name' => q(sekend),
						'one' => q(sekend {0} wo),
						'other' => q(sekend {0} wo),
					},
					'week' => {
						'name' => q(kɔsiɖawo),
						'one' => q(kɔsiɖa {0}),
						'other' => q(kɔsiɖa {0}),
					},
					'year' => {
						'name' => q(ƒewo),
						'one' => q(ƒe {0}),
						'other' => q(ƒe {0}),
					},
				},
				'narrow' => {
					'day' => {
						'name' => q(ŋkeke),
						'one' => q(ŋkeke {0}),
						'other' => q(ŋkeke {0}),
					},
					'hour' => {
						'name' => q(gaƒoƒo),
						'one' => q(gaƒoƒo {0}),
						'other' => q(gaƒoƒo {0}),
					},
					'minute' => {
						'name' => q(aɖabaƒoƒo),
						'one' => q(a {0}),
						'other' => q(a {0}),
					},
					'month' => {
						'name' => q(ɣletiwo),
						'one' => q(ɣleti {0}),
						'other' => q(ɣleti {0}),
					},
					'second' => {
						'one' => q(s {0}),
						'other' => q(s {0}),
					},
					'week' => {
						'name' => q(kɔsiɖa),
						'one' => q(kɔsiɖa {0}),
						'other' => q(kɔsiɖa {0}),
					},
					'year' => {
						'name' => q(ƒe),
						'one' => q(ƒe {0}),
						'other' => q(ƒe {0}),
					},
				},
				'short' => {
					'day' => {
						'name' => q(ŋkekewo),
						'one' => q(ŋkeke {0}),
						'other' => q(ŋkeke {0}),
					},
					'hour' => {
						'name' => q(gaƒoƒowo),
						'one' => q(gaƒoƒo {0}),
						'other' => q(gaƒoƒo {0}),
					},
					'minute' => {
						'name' => q(aɖabaƒoƒowo),
						'one' => q(aɖabaƒoƒo {0}),
						'other' => q(aɖabaƒoƒo {0}),
					},
					'month' => {
						'name' => q(ɣletiwo),
						'one' => q(ɣleti {0}),
						'other' => q(ɣleti {0}),
					},
					'second' => {
						'one' => q(sekend {0}),
						'other' => q(sekend {0}),
					},
					'week' => {
						'name' => q(kɔsiɖawo),
						'one' => q(kɔsiɖa {0}),
						'other' => q(kɔsiɖa {0}),
					},
					'year' => {
						'name' => q(ƒewo),
						'one' => q(ƒe {0}),
						'other' => q(ƒe {0}),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ɛ|Ɛ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ao|A|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, kple {1}),
				2 => q({0} kple {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'nan' => q(mnn),
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
					'one' => 'akpe 0',
					'other' => 'akpe 0',
				},
				'10000' => {
					'one' => 'akpe 00',
					'other' => 'akpe 00',
				},
				'100000' => {
					'one' => 'akpe 000',
					'other' => 'akpe 000',
				},
				'1000000' => {
					'one' => 'miliɔn 0',
					'other' => 'miliɔn 0',
				},
				'10000000' => {
					'one' => 'miliɔn 00',
					'other' => 'miliɔn 00',
				},
				'100000000' => {
					'one' => 'miliɔn 000',
					'other' => 'miliɔn 000',
				},
				'1000000000' => {
					'one' => 'miliɔn 0000',
					'other' => 'miliɔn 0000',
				},
				'10000000000' => {
					'one' => 'miliɔn 00000',
					'other' => 'miliɔn 00000',
				},
				'100000000000' => {
					'one' => 'miliɔn 000000',
					'other' => 'miliɔn 000000',
				},
				'1000000000000' => {
					'one' => 'biliɔn 0',
					'other' => 'biliɔn 0',
				},
				'10000000000000' => {
					'one' => 'biliɔn 00',
					'other' => 'biliɔn 00',
				},
				'100000000000000' => {
					'one' => 'biliɔn 000',
					'other' => 'biliɔn 000',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0000M',
					'other' => '0000M',
				},
				'10000000000' => {
					'one' => '00000M',
					'other' => '00000M',
				},
				'100000000000' => {
					'one' => '000000M',
					'other' => '000000M',
				},
				'1000000000000' => {
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000000' => {
					'one' => '000B',
					'other' => '000B',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(andorraga peseta),
				'one' => q(andorraga peseta),
				'other' => q(andorraga peseta),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(united arab emiratesga dirham),
				'one' => q(united arab emiratesga dirham),
				'other' => q(united arab emiratesga dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghanistanga afghani \(1927–2002\)),
				'one' => q(afghanistanga afghani \(1927–2002\)),
				'other' => q(afghanistanga afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghanistanga afghani),
				'one' => q(afghanistanga afghani),
				'other' => q(afghanistanga afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(albaniaga lek \(1946–1965\)),
				'one' => q(albaniaga lek \(1946–1965\)),
				'other' => q(albaniaga lek \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albaniaga lek),
				'one' => q(albaniaga lek),
				'other' => q(albaniaga lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armeniaga dram),
				'one' => q(armeniaga dram),
				'other' => q(armeniaga dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nedalands antilleaga guilder),
				'one' => q(nedalands antilleaga guilder),
				'other' => q(nedalands antilleaga guilder),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolaga kwanza),
				'one' => q(angolaga kwanza),
				'other' => q(angolaga kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolaga kwanza \(1977–1991\)),
				'one' => q(angolaga kwanza \(1977–1991\)),
				'other' => q(angolaga kwanza \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolaga kwanza \(1990–2000\)),
				'one' => q(angolaga kwanza \(1990–2000\)),
				'other' => q(angolaga kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolaga kwanza xoxotɔ \(1995–1999\)),
				'one' => q(angolaga kwanza xoxotɔ \(1995–1999\)),
				'other' => q(angolaga kwanza xoxotɔ \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinaga austral),
				'one' => q(argentinaga austral),
				'other' => q(argentinaga austral),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(argentinaga peso ley \(1970–1983\)),
				'one' => q(argentinaga peso ley \(1970–1983\)),
				'other' => q(argentinaga peso ley \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(argentinaga peso \(1881–1970\)),
				'one' => q(argentinaga peso \(1881–1970\)),
				'other' => q(argentinaga peso \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinaga peso \(1983–1985\)),
				'one' => q(argentinaga peso \(1983–1985\)),
				'other' => q(argentinaga peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinaga peso),
				'one' => q(argentinaga peso),
				'other' => q(argentinaga peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(ɔstriaga schilling),
				'one' => q(ɔstriaga schilling),
				'other' => q(ɔstriaga schilling),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Australiaga dollar),
				'one' => q(Australiaga dollar),
				'other' => q(Australiaga dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubaga lorin),
				'one' => q(arubaga florin),
				'other' => q(arubaga florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbaidzanga manat \(1993–2006\)),
				'one' => q(azerbaidzanga manat \(1993–2006\)),
				'other' => q(azerbaidzanga manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbaidzanga manat),
				'one' => q(azerbaidzanga manat),
				'other' => q(azerbaidzanga manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosnia-herzegovinaga dinar \(1992–1994\)),
				'one' => q(bosnia-herzegovinaga dinar \(1992–1994\)),
				'other' => q(bosnia-herzegovinaga dinar \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosnia-herzegovinaga convertible mark),
				'one' => q(bosnia-herzegovinaga convertible mark),
				'other' => q(bosnia-herzegovinaga convertible mark),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(bosnia kple herzegovinaga dinar yeyètɔ \(1994–1997\)),
				'one' => q(bosnia kple herzegovinaga dinar yeyètɔ \(1994–1997\)),
				'other' => q(bosnia kple herzegovinaga dinar yeyètɔ \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadiaga dollar),
				'one' => q(barbadiaga dollar),
				'other' => q(barbadiaga dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeshga taka),
				'one' => q(bangladeshga taka),
				'other' => q(bangladeshga taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(beldziumga franc \(convertible\)),
				'one' => q(beldziumga franc \(convertible\)),
				'other' => q(beldziumga franc \(convertible\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(beldziumga franc),
				'one' => q(beldziumga franc),
				'other' => q(beldziumga franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(beldziumga franc \(financial\)),
				'one' => q(beldziumga franc \(financial\)),
				'other' => q(beldziumga franc \(financial\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bɔlgariaga hard lev),
				'one' => q(bɔlgariaga hard lev),
				'other' => q(bɔlgariaga hard lev),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(bɔlgariaga socialist lev),
				'one' => q(bɔlgariaga socialist lev),
				'other' => q(bɔlgariaga socialist lev),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgariaga lev),
				'one' => q(bulgariaga lev),
				'other' => q(bulgariaga lev),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bulgariaga lev \(1879–1952\)),
				'one' => q(bulgariaga lev \(1879–1952\)),
				'other' => q(bulgariaga lev \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainga dinar),
				'one' => q(bahrainga dinar),
				'other' => q(bahrainga dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundiga franc),
				'one' => q(burundiga franc),
				'other' => q(burundiga franc),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudaga dollar),
				'one' => q(bermudaga dollar),
				'other' => q(bermudaga dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneiga dollar),
				'one' => q(bruneiga dollar),
				'other' => q(bruneiga dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviaga boliviano),
				'one' => q(boliviaga boliviano),
				'other' => q(boliviaga boliviano),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(boliviaga boliviano \(1863–1963\)),
				'one' => q(boliviaga boliviano \(1863–1963\)),
				'other' => q(boliviaga boliviano \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(boliviaga peso),
				'one' => q(boliviaga peso),
				'other' => q(boliviaga peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(boliviaga mvdol),
				'one' => q(boliviaga mvdol),
				'other' => q(boliviaga mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(braziliaga cruzeiro xoxotɔ \(1967–1986\)),
				'one' => q(braziliaga cruzeiro xoxotɔ \(1967–1986\)),
				'other' => q(braziliaga cruzeiro xoxotɔ \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazilia cruzado \(1986–1989\)),
				'one' => q(brazilia cruzado \(1986–1989\)),
				'other' => q(brazilia cruzado \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(braziliaga cruzeiro xoxotɔ gbãtɔ \(1990–1993\)),
				'one' => q(braziliaga cruzeiro xoxotɔ gbãtɔ \(1990–1993\)),
				'other' => q(braziliaga cruzeiro xoxotɔ gbãtɔwo \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Braziliaga real),
				'one' => q(Brazilga real),
				'other' => q(Braziliaga real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brazilia cruzado xoxotɔ \(1989–1990\)),
				'one' => q(brazilia cruzado xoxotɔ \(1989–1990\)),
				'other' => q(brazilia cruzado xoxotɔ \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(braziliaga cruzeiro \(1993–1994\)),
				'one' => q(braziliaga cruzeiro \(1993–1994\)),
				'other' => q(braziliaga cruzeiro \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(braziliaga cruzeiro \(1942–1967\)),
				'one' => q(braziliaga cruzeiro \(1942–1967\)),
				'other' => q(braziliaga cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamiaga dollar),
				'one' => q(bahamiaga dollar),
				'other' => q(bahamiaga dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutanga ngultrum),
				'one' => q(bhutanga ngultrum),
				'other' => q(bhutanga ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmaga kyat),
				'one' => q(burmaga kyat),
				'other' => q(burmaga kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswanaga pula),
				'one' => q(botswanaga pula),
				'other' => q(botswanaga pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(belarusiaga ruble yeytɔ \(1994–1999\)),
				'one' => q(belarusiaga ruble yeytɔ \(1994–1999\)),
				'other' => q(belarusiaga ruble yeyetɔ \(1994–1999\)),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(belarusiaga ruble),
				'one' => q(belarusiaga ruble),
				'other' => q(belarusiaga rublewo),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizega dollar),
				'one' => q(belizega dollar),
				'other' => q(belizega dollar),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Canadaga dollar),
				'one' => q(Canadaga dollar),
				'other' => q(Canadaga dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongoga franc),
				'one' => q(kongoga franc),
				'other' => q(kongoga franc),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro CHE),
				'one' => q(WIR euro CHE),
				'other' => q(WIR eurowo CHE),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Swissga franc),
				'one' => q(Swissga franc),
				'other' => q(Swissga franc),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR euro CHW),
				'one' => q(WIR euro CHW),
				'other' => q(WIR eurowo CHW),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(tsilega escudo),
				'one' => q(tsilega escudo),
				'other' => q(tsilega escudo),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(tsilegakɔnta dzidzenu UF),
				'one' => q(tsilegakɔnta dzidzenu UF),
				'other' => q(tsilegakɔnta dzidzenu UF),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(tsilega peso),
				'one' => q(tsilega peso),
				'other' => q(tsilega pesowo),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(tsainatɔwo ƒe gadzraɖoƒe dollar),
				'one' => q(tsainatɔwo ƒe gadzraɖoƒe dollar),
				'other' => q(tsainatɔwo ƒe gadzraɖoƒe dollarwo),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Chinesega yuan),
				'one' => q(Chinesega yuan),
				'other' => q(Chinesega yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolombiaga peso),
				'one' => q(kolombiaga peso),
				'other' => q(kolombiaga peso),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(kolombiaga vavãtɔ),
				'one' => q(kolombiaga vavãtɔ),
				'other' => q(kolombiaga vavãtɔ),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kosta rikaga kolón),
				'one' => q(kosta rikaga kolón),
				'other' => q(kosta rikaga kolón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(serbiaga dinar \(2002–2006\)),
				'one' => q(serbiaga dinar \(2002–2006\)),
				'other' => q(serbiaga dinar \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(tsɛkoslovakiaga hard koruna),
				'one' => q(tsɛkoslovakiaga hard koruna),
				'other' => q(tsɛkoslovakiaga hard koruna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubaga convertible peso),
				'one' => q(kubaga convertible peso),
				'other' => q(kubaga convertible peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubaga peso),
				'one' => q(kubaga peso),
				'other' => q(kubaga peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kape verdega escudo),
				'one' => q(kape verdega escudo),
				'other' => q(kape verdega escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(saipriɔtga pound),
				'one' => q(saipriɔtga pound),
				'other' => q(saipriɔtga pound),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(tsɛk repɔblikga koruna),
				'one' => q(tsɛk repɔblikga koruna),
				'other' => q(tsɛk repɔblikga koruna),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(ɣedzeƒe germaniaga mark),
				'one' => q(ɣedzeƒe germaniaga mark),
				'other' => q(ɣedzeƒe germaniaga mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(germaniaga mark),
				'one' => q(germaniaga mark),
				'other' => q(germaniaga markwo),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(dziboutiga franc),
				'one' => q(dziboutiga franc),
				'other' => q(dzibutiga franc),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Denmarkga krone),
				'one' => q(Denmarkga krone),
				'other' => q(Denmarkga krone),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominicaga peso),
				'one' => q(dominikaga peso),
				'other' => q(dominikaga peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(aldzeriaga dinar),
				'one' => q(aldzeriaga dinar),
				'other' => q(aldzeriaga dinar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ekuadɔga sucre),
				'one' => q(ekuadɔga sucre),
				'other' => q(ekuadɔga sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ekuadɔ dzidzenu matrɔmatrɔ),
				'one' => q(ekuadɔ dzidzenu matrɔmatrɔ),
				'other' => q(ekuadɔ dzidzenu matrɔmatrɔ),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(estoniaga kroon),
				'one' => q(estoniaga kroon),
				'other' => q(estoniaga kroon),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptega pound),
				'one' => q(egyptega pound),
				'other' => q(egyptega pound),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritreaga nakfa),
				'one' => q(eritreaga nakfa),
				'other' => q(eritreaga nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(spaniaga peseta \(A\)),
				'one' => q(spaniaga peseta \(A\)),
				'other' => q(spaniaga peseta \(A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(spaniaga peseta \(Convertible\)),
				'one' => q(spaniaga peseta \(Convertible\)),
				'other' => q(spaniaga pesetas \(Convertible\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(spaniaga peseta),
				'one' => q(spaniaga peseta),
				'other' => q(spaniaga pesetas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(ethiopiaga birr),
				'one' => q(ethiopiaga birr),
				'other' => q(ethiopiaga birr),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(EUR),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(finlandga markka),
				'one' => q(finlandga markka),
				'other' => q(finlandga markka),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidziga dollar),
				'one' => q(fidziga dollar),
				'other' => q(fidziga dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklanɖ ƒudomekpo dukɔwo ƒe ga pound),
				'one' => q(falkland ƒudomekpo dukɔwo ƒe ga pound),
				'other' => q(falkland ƒudomekpo dukɔwo ƒe ga pound),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(frentsiga franc),
				'one' => q(frentsiga franc),
				'other' => q(frentsiga franc),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Britishga pound),
				'one' => q(Britishga pound),
				'other' => q(Britishga pound),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(dzɔdziaga kupon larit),
				'one' => q(dzɔdziaga kupon larit),
				'other' => q(dzɔdziaga kupon larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(dzɔdziaga lari),
				'one' => q(dzɔdziaga larit),
				'other' => q(dzɔdziaga larit),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghana siɖi \(1979–2007\)),
				'one' => q(ghana siɖi \(1979–2007\)),
				'other' => q(ghana siɖi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GH₵',
			display_name => {
				'currency' => q(ghana siɖi),
				'one' => q(ghana siɖi),
				'other' => q(ghana siɖi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gilbrataga pound),
				'one' => q(gilbrataga pound),
				'other' => q(gilbrataga pound),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambiaga dalasi),
				'one' => q(gambiaga dalasi),
				'other' => q(gambiaga dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(giniga franc),
				'one' => q(giniga franc),
				'other' => q(giniga franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(giniga syli),
				'one' => q(giniga syli),
				'other' => q(giniga syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekuatorial giniga ekwele),
				'one' => q(ekuatorial giniga ekwele),
				'other' => q(ekuatorial giniga ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(grisiga drachma),
				'one' => q(grisiga drachma),
				'other' => q(grisiga drachma),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalaga quetzal),
				'one' => q(guatemalaga quetzal),
				'other' => q(guatemalaga quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(pɔtugaltɔwo ƒe giniga escudo),
				'one' => q(pɔtugaltɔwo ƒe giniga escudo),
				'other' => q(pɔtugaltɔwo ƒe giniga escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(gini-bisau peso),
				'one' => q(gini-bisau peso),
				'other' => q(gini-bisau peso),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyanaga dollar),
				'one' => q(guyanaga dollar),
				'other' => q(guyanaga dollar),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hong Kongga dollar),
				'one' => q(Hong Kongga dollar),
				'other' => q(Hong Kongga dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduraga lempira),
				'one' => q(honduraga lempira),
				'other' => q(honduraga lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(kroatiaga dinar),
				'one' => q(kroatiaga dinar),
				'other' => q(kroatiaga dinar),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kroatiaga kuna),
				'one' => q(kroatiaga kuna),
				'other' => q(kroatiaga kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitiga gourde),
				'one' => q(haitiga gourde),
				'other' => q(haitiga gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(hungariaga forint),
				'one' => q(hungariaga forint),
				'other' => q(hungariaga forint),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonesiaga rupiah),
				'one' => q(Indonesiaga rupiah),
				'other' => q(Indonesiaga rupiah),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(ireland pound),
				'one' => q(ireland pound),
				'other' => q(ireland pound),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(israelga pound),
				'one' => q(israelga pound),
				'other' => q(israelga pound),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(israelga sheqel \(1980–1985\)),
				'one' => q(israelga sheqel \(1980–1985\)),
				'other' => q(israelga sheqel \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(israelga yeyetɔ sheqel),
				'one' => q(israelga yeyetɔ sheqel),
				'other' => q(israelga yeyetɔ sheqel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Indiaga rupee),
				'one' => q(Indiaga rupee),
				'other' => q(Indiaga rupee),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakga dinar),
				'one' => q(irakga dinar),
				'other' => q(irakga dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranga rial),
				'one' => q(iranga rial),
				'other' => q(iranga rial),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(aiselandga króna \(1918–1981\)),
				'one' => q(aiselandga króna \(1918–1981\)),
				'other' => q(aiselandga krónur \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(aiselandga króna),
				'one' => q(aiselandga króna),
				'other' => q(aiselandga krónur),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(italiaga lira),
				'one' => q(italiaga lira),
				'other' => q(italiaga lira),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dzamaikaga dollar),
				'one' => q(dzamaikaga dollar),
				'other' => q(dzamaikaga dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(yɔdanga dinar),
				'one' => q(yɔdanga dinar),
				'other' => q(yɔdanga dinar),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Japanesega yen),
				'one' => q(Japanesega yen),
				'other' => q(Japanesega yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenyaga shilling),
				'one' => q(kenyaga shilling),
				'other' => q(kenyaga shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgistanga som),
				'one' => q(kirgistanga som),
				'other' => q(kirgistanga som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodiaga riel),
				'one' => q(kambodiaga riel),
				'other' => q(kambodiaga riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komoroga franc),
				'one' => q(komoroga franc),
				'other' => q(komoroga franc),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(dziehe koreaga won),
				'one' => q(dziehe koreaga won),
				'other' => q(dziehe koreaga won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(anyiehe koreaga hwan \(1953–1962\)),
				'one' => q(anyiehe koreaga hwan \(1953–1962\)),
				'other' => q(anyiehe koreaga hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(anyiehe koreaga won \(1945–1953\)),
				'one' => q(anyiehe koreaga won \(1945–1953\)),
				'other' => q(anyiehe koreaga won \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(South Koreaga won),
				'one' => q(South Koreaga won),
				'other' => q(South Koreaga won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitga dinar),
				'one' => q(kuwaitga dinar),
				'other' => q(kuwaitga dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kayman ƒudomekpoga dollar),
				'one' => q(kayman ƒudomekpoga dollar),
				'other' => q(kayman ƒudomekpoga dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazakhstanga tenge),
				'one' => q(kazakhstanga tenge),
				'other' => q(kazakhstanga tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laosga kip),
				'one' => q(laosga kip),
				'other' => q(laosga kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(lebanonga pound),
				'one' => q(lebanonga pound),
				'other' => q(lebanonga pound),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(sri lankaga rupee),
				'one' => q(sri lankaga rupee),
				'other' => q(sri lankaga rupee),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberiaga dollar),
				'one' => q(liberiaga dollar),
				'other' => q(liberiaga dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesotoga loti),
				'one' => q(lesotoga loti),
				'other' => q(lesotoga loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(lithuaniaga litas),
				'one' => q(lithuaniaga litas),
				'other' => q(lithuaniaga litai),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(lithuaniaga talonas),
				'one' => q(lithuaniaga talonas),
				'other' => q(lithuaniaga talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(lazembɔgga convertible franc),
				'one' => q(lazembɔgga convertible franc),
				'other' => q(lazembɔgga convertible franc),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(lazembɔgga franc),
				'one' => q(lazembɔgga franc),
				'other' => q(lazembɔgga franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(lazembɔgga gadzikpɔ franc),
				'one' => q(lazembɔgga gadzikpɔ franc),
				'other' => q(lazembɔgga gadzikpɔ franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(latviaga lats),
				'one' => q(latviaga lats),
				'other' => q(latviaga lati),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(latviaga ruble),
				'one' => q(latviaga ruble),
				'other' => q(latviaga ruble),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libyaga dinar),
				'one' => q(libyaga dinar),
				'other' => q(libyaga dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(morokoga dirham),
				'one' => q(morokoga dirham),
				'other' => q(morokoga dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(morokoga franc),
				'one' => q(morokoga franc),
				'other' => q(morokoga franc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(monegaskga franc),
				'one' => q(monegaskga franc),
				'other' => q(monegaskga franc),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldovaga cupon),
				'one' => q(moldovaga cupon),
				'other' => q(moldovaga cupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldovaga leu),
				'one' => q(moldovaga leu),
				'other' => q(moldovaga leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(malagasega ariary),
				'one' => q(malagasega ariary),
				'other' => q(malagasega ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(malagasega franc),
				'one' => q(malagasega franc),
				'other' => q(malagasega franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedoniaga denar),
				'one' => q(makedoniaga denar),
				'other' => q(makedoniaga denari),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(makedoniaga denar \(1992–1993\)),
				'one' => q(makedoniaga denar \(1992–1993\)),
				'other' => q(makedoniaga denari \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(maliga franc),
				'one' => q(maliga franc),
				'other' => q(maliga franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmaga kyat),
				'one' => q(myanmaga kyat),
				'other' => q(myanmaga kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongoliaga tugrik),
				'one' => q(mongoliaga tugrik),
				'other' => q(mongoliaga tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makanesega pataca),
				'one' => q(makanesega pataca),
				'other' => q(makanesega pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mɔritaniaga ouguiya),
				'one' => q(mɔritaniaga ouguiya),
				'other' => q(mɔritaniaga ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(maltaga lira),
				'one' => q(maltaga lira),
				'other' => q(maltaga lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(maltaga pound),
				'one' => q(maltaga pound),
				'other' => q(maltaga pound),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mɔritiusga rupee),
				'one' => q(mɔritiusga rupee),
				'other' => q(mɔritiusga rupee),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldiviaga rufiyaa),
				'one' => q(maldiviaga rufiyaa),
				'other' => q(maldiviaga rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawiga kwacha),
				'one' => q(malawiga kwacha),
				'other' => q(malawiga kwacha),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Mexicoga peso),
				'one' => q(Mexicoga peso),
				'other' => q(Mexicoga peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malaysiaga ringit),
				'one' => q(malaysiaga ringit),
				'other' => q(malaysiaga ringit),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambikga metikal),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibiaga dollar),
				'one' => q(namibiaga dollar),
				'other' => q(namibiaga dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naidzeriaga naira),
				'one' => q(naidzeriaga naira),
				'other' => q(naidzeriaga naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nikaraguaga córdoba \(1988–1991\)),
				'one' => q(nikaraguaga córdoba \(1988–1991\)),
				'other' => q(nikaraguaga córdoba \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaraguaga córdoba),
				'one' => q(nikaraguaga córdoba),
				'other' => q(nikaraguaga córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(hollandga guilder),
				'one' => q(hollandga guilder),
				'other' => q(hollandga guilder),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norwayga krone),
				'one' => q(Norwayga krone),
				'other' => q(Norwayga krone),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalga rupee),
				'one' => q(nepalga rupee),
				'other' => q(nepalga rupee),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(new zealanɖga dollar),
				'one' => q(new zealanɖga dollar),
				'other' => q(new zealanɖga dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omanga rial),
				'one' => q(omanga rial),
				'other' => q(omanga rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamaga balboa),
				'one' => q(panamaga balboa),
				'other' => q(panamaga balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruga inti),
				'one' => q(peruga inti),
				'other' => q(peruga inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruga nuevo sol),
				'one' => q(peruga nuevo sol),
				'other' => q(peruga nuevo sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruga nuevo sol \(1863–1965\)),
				'one' => q(peruga nuevo sol \(1863–1965\)),
				'other' => q(peruga nuevo sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papua new guineaga kina),
				'one' => q(papua new giniga kina),
				'other' => q(papua new giniga kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(filipiniga peso),
				'one' => q(filipinga peso),
				'other' => q(filipinga peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistaniga rupee),
				'one' => q(pakistanga rupee),
				'other' => q(pakistanga rupee),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polanɖga zloty),
				'one' => q(polandga zloty),
				'other' => q(polandga zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(polanɖga zloty \(1950–1995\)),
				'one' => q(polandga zloty \(1950–1995\)),
				'other' => q(polandga zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(pɔtugalga escudo),
				'one' => q(pɔtugalga escudo),
				'other' => q(pɔtugalga escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayga guarani),
				'one' => q(paraguayga guarani),
				'other' => q(paraguayga guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarga rial),
				'one' => q(katarga rial),
				'other' => q(katarga rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodesiaga dollar),
				'one' => q(rhodesiaga dollar),
				'other' => q(rhodesiaga dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(romaniaga leu \(1952–2006\)),
				'one' => q(romaniaga leu \(1952–2006\)),
				'other' => q(romaniaga leu \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(romaniaga leu),
				'one' => q(romaniaga leu),
				'other' => q(romaniaga leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbiaga dinar),
				'one' => q(serbiaga dinar),
				'other' => q(serbiaga dinar),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Russiaga ruble),
				'one' => q(Russiaga ruble),
				'other' => q(Russiaga ruble),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(rɔtsiaga ruble \(1991–1998\)),
				'one' => q(rɔtsiaga ruble \(1991–1998\)),
				'other' => q(rɔtsiaga ruble \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandaga franc),
				'one' => q(rwandaga franc),
				'other' => q(rwandaga franc),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saudi Arabiaga riyal),
				'one' => q(Saudi Arabiaga riyal),
				'other' => q(Saudi Arabiaga riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(solomon ƒudomekpo dukɔwo ƒe ga dollar),
				'one' => q(solomon ƒudomekpo dukɔwo ƒe ga dollar),
				'other' => q(solomon ƒudomekpo dukɔwo ƒe ga dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(sɛtselsga rupee),
				'one' => q(sɛtselsga rupee),
				'other' => q(sɛtselsga rupee),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(sudanga dinar \(1992–2007\)),
				'one' => q(sudanga dinar \(1992–2007\)),
				'other' => q(sudanga dinar \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudanga pound),
				'one' => q(sudanga pound),
				'other' => q(sudanga pound),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(sudanga pound \(1957–1998\)),
				'one' => q(sudanga pound \(1957–1998\)),
				'other' => q(sudanga pound \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Swedishga krone),
				'one' => q(Swedishga krone),
				'other' => q(Swedishga krone),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapɔga dollar),
				'one' => q(singapɔga dollar),
				'other' => q(singapɔga dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(saint helenaga pound),
				'one' => q(saint helenaga pound),
				'other' => q(saint helenaga pound),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovaniaga tolar),
				'one' => q(slovaniaga tolar),
				'other' => q(slovaniaga tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovakga koruna),
				'one' => q(slovakiaga koruna),
				'other' => q(slovakiaga koruna),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierra leonega leone),
				'one' => q(sierra leonega leone),
				'other' => q(sierra leonega leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somaliaga shilling),
				'one' => q(somaliaga shilling),
				'other' => q(somaliaga shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamga dollar),
				'one' => q(surinamga dollar),
				'other' => q(surinamga dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamega guilder),
				'one' => q(surinamega guilder),
				'other' => q(surinamega guilder),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(anyiehe sudanga pound),
				'one' => q(anyiehe sudanga pound),
				'other' => q(anyiehe sudanga pound),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(são tomé kple príncipega dobra),
				'one' => q(são tomé kple príncipega dobra),
				'other' => q(são tomé kple príncipega dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovietga rouble),
				'one' => q(sovietga rouble),
				'other' => q(sovietga rouble),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvadɔga colón),
				'one' => q(salvadɔga colón),
				'other' => q(salvadɔga colón),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syriaga pound),
				'one' => q(syriaga pound),
				'other' => q(syriaga pound),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swaziga lilangeni),
				'one' => q(swaziga lilangeni),
				'other' => q(swaziga lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thailandga baht),
				'one' => q(Thailandga baht),
				'other' => q(Thailandga baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tajikistanga ruble),
				'one' => q(tajikistanga ruble),
				'other' => q(tajikistanga ruble),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tajikistanga somoni),
				'one' => q(tajikistanga somoni),
				'other' => q(tajikistanga somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmenistanga manat \(1993–2009\)),
				'one' => q(turkmenistanga manat \(1993–2009\)),
				'other' => q(turkmenistanga manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmenistanga manat),
				'one' => q(turkmenistanga manat),
				'other' => q(turkmenistanga manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunisiaga dinar),
				'one' => q(tunisiaga dinar),
				'other' => q(tunisiaga dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tonagaga pa’anga),
				'one' => q(tonagaga pa’anga),
				'other' => q(tonagaga pa’anga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timɔga escudo),
				'one' => q(timɔga escudo),
				'other' => q(timɔga escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(tɛkiiga lira \(1922–2005\)),
				'one' => q(tɛkiiga lira \(1922–2005\)),
				'other' => q(tɛkiiga lira \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Turkishga lira),
				'one' => q(Turkishga lira),
				'other' => q(Turkishga lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidad kple tobagoga dollar),
				'one' => q(trinidad kple tobagoga dollar),
				'other' => q(trinidad kple tobagoga dollar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Taiwanga dollar),
				'one' => q(Taiwanga dollar),
				'other' => q(Taiwanga dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaniatɔwofɛgadudu),
				'one' => q(tanzaniaga shilling),
				'other' => q(tanzaniaga shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainega hryvnia),
				'one' => q(ukrainega hryvnia),
				'other' => q(ukrainega hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrainega karbovanet),
				'one' => q(ukrainega karbovanet),
				'other' => q(ukrainega karbovantsiv),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(ugandaga shilling \(1966–1987\)),
				'one' => q(ugandaga shilling \(1966–1987\)),
				'other' => q(ugandaga shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandaga shilling),
				'one' => q(ugandaga shilling),
				'other' => q(ugandaga shilling),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(US ga dollar),
				'one' => q(US ga dollar),
				'other' => q(US ga dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(us ga dollar \(ŋkeke si gbɔna tɔ\)),
				'one' => q(us ga dollar \(ŋkeke si gbɔna tɔ\)),
				'other' => q(us ga dollar \(ŋkeke si gbɔna tɔ\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(us ga dollar \(ŋkeke ma ke tɔ\)),
				'one' => q(us ga dollar \(ŋkeke ma ke tɔ\)),
				'other' => q(us ga dollar \(ŋkeke ma ke tɔ\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguayga peso UYI),
				'one' => q(uruguayga peso UYI),
				'other' => q(uruguayga peso UYI),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguayga peso \(1975–1993\)),
				'one' => q(uruguayga peso \(1975–1993\)),
				'other' => q(uruguayga peso \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayga peso),
				'one' => q(uruguayga peso),
				'other' => q(uruguayga peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbekistanga som),
				'one' => q(uzbekistanga som),
				'other' => q(uzbekistanga som),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelaga bolívar \(1871–2008\)),
				'one' => q(venezuelaga bolívar \(1871–2008\)),
				'other' => q(venezuelaga bolívar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelaga bolívar),
				'one' => q(venezuelaga bolívar),
				'other' => q(venezuelaga bolívar),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(vietnamga dong),
				'one' => q(vietnamga dong),
				'other' => q(vietnamga dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vietnamga dong \(1978–1985\)),
				'one' => q(vietnamga dong \(1978–1985\)),
				'other' => q(vietnamga dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatuga vatu),
				'one' => q(vanuatuga vatu),
				'other' => q(vanuatuga vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samaoga tala),
				'one' => q(samaoga tala),
				'other' => q(samaoga tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(ɣetoɖofe afrikaga CFA franc BEAC),
				'one' => q(ɣetoɖofe afrikaga CFA franc BEAC),
				'other' => q(ɣetoɖofe afrikaga CFA franc BEAC),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(klosalo),
				'one' => q(klosalo),
				'other' => q(klosalo),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(sika),
				'one' => q(sika),
				'other' => q(sika),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(europa dzidzenu xba),
				'one' => q(europa dzidzenu xba),
				'other' => q(europa dzidzenu xba),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(europa gadzidzenu xbb),
				'one' => q(europa gadzidzenu xbb),
				'other' => q(europa gadzidzenu xbb),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(europa kɔnta dzidzenu xbc),
				'one' => q(europa kɔnta dzidzenu),
				'other' => q(europa kɔnta dzidzenu),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(europa kɔnta dzidzenu xbd),
				'one' => q(europaga \(XBD\)),
				'other' => q(europaga \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(ɣedzeƒe caribbeaga dollar),
				'one' => q(ɣedzeƒe karibbeaga dollar),
				'other' => q(ɣedzeƒe karibbeaga dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(gaɖuɖu ɖoɖo tɔxɛ),
				'one' => q(gaɖuɖu ɖoɖo tɔxɛ),
				'other' => q(gaɖuɖu ɖoɖo tɔxɛ),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(europa gaɖuɖu),
				'one' => q(europa gaɖuɖu),
				'other' => q(europa gaɖuɖu),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(fransemega sika franc),
				'one' => q(frentsiga sika franc),
				'other' => q(frentsiga sika franc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(frentsi UIC-franc),
				'one' => q(frentsi UIC-franc),
				'other' => q(frentsi UIC-franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(ɣetoɖofe afrikaga CFA franc BCEAO),
				'one' => q(ɣetoɖofe afrikaga CFA franc BCEAO),
				'other' => q(ɣetoɖofe afrikaga CFA franc BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladiumga),
				'one' => q(palladiumga),
				'other' => q(palladiumga),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP ga franc),
				'one' => q(CFP ga franc),
				'other' => q(CFP ga franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platinum),
				'one' => q(platinum),
				'other' => q(platinum),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET gadodo XRE),
				'one' => q(RINET gadodo XRE),
				'other' => q(RINET gadodo XRE),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(gaɖuɖu dodokpɔ dzesi xts),
				'one' => q(gaɖuɖu dodokpɔ dzesi),
				'other' => q(gaɖuɖu dodokpɔ dzesi),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(gaɖuɖu manya),
				'one' => q(gaɖuɖu manya),
				'other' => q(gaɖuɖu manya),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(yemeniga dinar),
				'one' => q(yemeniga dinar),
				'other' => q(yemeniga dinar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(yemeniga rial),
				'one' => q(yemeniga rial),
				'other' => q(yemeniga rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(yugoslaviaga hard dinar \(1966–1990\)),
				'one' => q(yugoslaviaga hard dinar \(1966–1990\)),
				'other' => q(yugoslaviaga hard dinar \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(yugoslaviaga yeyetɔ dinar \(1994–2002\)),
				'one' => q(yugoslaviaga yeyetɔ dinar \(1994–2002\)),
				'other' => q(yugoslaviaga yeyetɔ dinar \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(yugoslaviaga convertible dinar \(1990–1992\)),
				'one' => q(yugoslaviaga convertible dinar \(1990–1992\)),
				'other' => q(yugoslaviaga convertible dinar \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(yugoslaviaga dinar \(1992–1993\)),
				'one' => q(yugoslaviaga dinar \(1992–1993\)),
				'other' => q(yugoslaviaga dinar \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(anyiehe afrikaga rand \(gadzikpɔtɔ\)),
				'one' => q(anyiehe afrikaga rand \(gadzikpɔtɔ\)),
				'other' => q(anyiehe afrikaga rand \(gadzikpɔtɔ\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(South Africaga rand),
				'one' => q(South Africaga rand),
				'other' => q(South Africaga rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambiaga kwacha \(1968–2012\)),
				'one' => q(zambiaga kwacha \(1968–2012\)),
				'other' => q(zambiaga kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambiaga kwacha),
				'one' => q(zambiaga kwacha),
				'other' => q(zambiaga kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairega yeyetɔ zaire),
				'one' => q(zairega yeyetɔ zaire),
				'other' => q(zairega yeyetɔ zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairega zaire \(1971–1993\)),
				'one' => q(zairega zaire \(1971–1993\)),
				'other' => q(zairega zaires \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabwega dollar \(1980–2008\)),
				'one' => q(zimbabwega dollar \(1980–2008\)),
				'other' => q(zimbabwega dollar \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(zimbabwega dollar \(2009\)),
				'one' => q(zimbabwega dollar \(2009\)),
				'other' => q(zimbabwega dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(zimbabwega dollar \(2008\)),
				'one' => q(zimbabwega dollar \(2008\)),
				'other' => q(zimbabwega dollar \(2008\)),
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
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kele',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
			},
			'coptic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm',
							'foa'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm',
							'foa'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
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
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm',
							'ƒoa'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfie',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
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
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'd',
							'd',
							't',
							'a',
							'd',
							'm',
							's',
							'd',
							'a',
							'k',
							'a',
							'd'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfĩe',
							'dama',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'd',
							'd',
							't',
							'a',
							'd',
							'm',
							's',
							'd',
							'a',
							'k',
							'a',
							'd'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfĩe',
							'dama',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
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
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'siamlɔm'
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'siamlɔm'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm',
							'foa'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'sia'
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'dasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'siamlɔm'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
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
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
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
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
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
						mon => 'dzo',
						tue => 'bla',
						wed => 'kuɖ',
						thu => 'yaw',
						fri => 'fiɖ',
						sat => 'mem',
						sun => 'kɔs'
					},
					narrow => {
						mon => 'd',
						tue => 'b',
						wed => 'k',
						thu => 'y',
						fri => 'f',
						sat => 'm',
						sun => 'k'
					},
					short => {
						mon => 'dzo',
						tue => 'bla',
						wed => 'kuɖ',
						thu => 'yaw',
						fri => 'fiɖ',
						sat => 'mem',
						sun => 'kɔs'
					},
					wide => {
						mon => 'dzoɖa',
						tue => 'blaɖa',
						wed => 'kuɖa',
						thu => 'yawoɖa',
						fri => 'fiɖa',
						sat => 'memleɖa',
						sun => 'kɔsiɖa'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'dzo',
						tue => 'bla',
						wed => 'kuɖ',
						thu => 'yaw',
						fri => 'fiɖ',
						sat => 'mem',
						sun => 'kɔs'
					},
					narrow => {
						mon => 'd',
						tue => 'b',
						wed => 'k',
						thu => 'y',
						fri => 'f',
						sat => 'm',
						sun => 'k'
					},
					short => {
						mon => 'dzo',
						tue => 'bla',
						wed => 'kuɖ',
						thu => 'yaw',
						fri => 'fiɖ',
						sat => 'mem',
						sun => 'kɔs'
					},
					wide => {
						mon => 'dzoɖa',
						tue => 'blaɖa',
						wed => 'kuɖa',
						thu => 'yawoɖa',
						fri => 'fiɖa',
						sat => 'memleɖa',
						sun => 'kɔsiɖa'
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
					abbreviated => {0 => 'k1',
						1 => 'k2',
						2 => 'k3',
						3 => 'k4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'kɔta gbãtɔ',
						1 => 'kɔta evelia',
						2 => 'kɔta etɔ̃lia',
						3 => 'kɔta enelia'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'k1',
						1 => 'k2',
						2 => 'k3',
						3 => 'k4'
					},
					wide => {0 => 'kɔta gbãtɔ',
						1 => 'kɔta evelia',
						2 => 'kɔta etɔ̃lia',
						3 => 'kɔta enelia'
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
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 500;
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
					'afternoon2' => q{ɣetrɔ},
					'morning2' => q{ŋdi},
					'night1' => q{zã},
					'morning1' => q{fɔŋli},
					'evening1' => q{fiẽ},
					'afternoon1' => q{ŋdɔ},
					'am' => q{ŋdi},
					'pm' => q{ɣetrɔ},
				},
				'wide' => {
					'afternoon1' => q{ŋdɔ},
					'evening1' => q{fiẽ},
					'am' => q{ŋdi},
					'pm' => q{ɣetrɔ},
					'afternoon2' => q{ɣetrɔ},
					'morning2' => q{ŋdi},
					'morning1' => q{fɔŋli},
					'night1' => q{zã},
				},
				'narrow' => {
					'pm' => q{ɣ},
					'am' => q{ŋ},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'pm' => q{ɣ},
					'am' => q{ŋ},
				},
				'wide' => {
					'am' => q{ŋdi},
					'pm' => q{ɣetrɔ},
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
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'hY',
				'1' => 'Yŋ'
			},
			narrow => {
				'0' => 'hY',
				'1' => 'Yŋ'
			},
			wide => {
				'0' => 'Hafi Yesu Va Do ŋgɔ',
				'1' => 'Yesu Ŋɔli'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'ŋdi'
			},
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
			abbreviated => {
				'0' => 'hafi R.O.C.'
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
			'full' => q{EEEE, U MMMM dd 'lia'},
			'long' => q{U MMMM d 'lia'},
			'medium' => q{U MMM d 'lia'},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, MMMM d 'lia' y G},
			'long' => q{MMMM d 'lia' y G},
			'medium' => q{MMM d 'lia', y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d 'lia' y},
			'long' => q{MMMM d 'lia' y},
			'medium' => q{MMM d 'lia', y},
			'short' => q{M/d/yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, MMMM dd 'lia', G y},
			'long' => q{MMMM d 'lia', G y},
			'medium' => q{MMM d 'lia', G y},
			'short' => q{dd-MM-GGGGG yy},
		},
		'persian' => {
		},
		'roc' => {
			'full' => q{EEEE, MMMM dd 'lia', G y},
			'long' => q{MMMM d 'lia', G y},
			'medium' => q{MMM d 'lia', G y},
			'short' => q{dd-MM-GGGGG y},
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
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{a 'ga' h:mm:ss zzzz},
			'long' => q{a 'ga' h:mm:ss z},
			'medium' => q{a 'ga' h:mm:ss},
			'short' => q{a 'ga' h:mm},
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
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{0} {1}},
			'long' => q{{0} {1}},
			'medium' => q{{0} {1}},
			'short' => q{{0} {1}},
		},
		'gregorian' => {
			'full' => q{{0} {1}},
			'long' => q{{0} {1}},
			'medium' => q{{0} {1}},
			'short' => q{{0} {1}},
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
		'generic' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d 'lia' y G},
			GyMMMd => q{MMM d 'lia', y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d 'lia'},
			MMMMEd => q{E, MMMM d 'lia'},
			MMMMd => q{MMMM d 'lia'},
			MMMd => q{MMM d 'lia'},
			Md => q{M/d},
			d => q{d},
			h => q{a 'ga' h},
			hm => q{a 'ga' h:mm},
			hms => q{a 'ga' h:mm:ss},
			ms => q{'aɖabaƒoƒo' mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E, M/d/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d 'lia' y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d 'lia', y G},
			yyyyMd => q{M/d/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E a 'ga' h:mm},
			Ehms => q{E a 'ga' h:mm:ss},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d 'lia' y G},
			GyMMMd => q{MMM d 'lia', y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d 'lia'},
			MMMMEd => q{E, MMMM d 'lia'},
			MMMMd => q{MMMM d 'lia'},
			MMMd => q{MMM d 'lia'},
			Md => q{M/d},
			d => q{d},
			h => q{a 'ga' h},
			hm => q{a 'ga' h:mm},
			hms => q{a 'ga' h:mm:ss},
			ms => q{'aɖabaƒoƒo' mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d 'lia', y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'buddhist' => {
			h => q{a 'ga' h},
			hm => q{a 'ga' h: 'aɖabaƒoƒo' mm},
			hms => q{a 'ga' h: 'aɖabaƒoƒo' mm:ss},
			ms => q{'ga' mm:ss},
		},
		'japanese' => {
			MMMEd => q{E MMM d 'lia'},
			hms => q{a 'ga' h:mm:ss},
			ms => q{'aɖabaƒoƒo' mm:ss},
		},
		'roc' => {
			MMMEd => q{E MMM d 'lia'},
			h => q{a 'ga' h},
			hm => q{a 'ga' h:mm},
			hms => q{a 'ga' h:mm:ss},
			ms => q{'aɖabaƒoƒo' mm:ss},
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
				M => q{'ɣleti' M 'lia' – 'ɣleti' M 'lia'},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM d 'lia' – E, MMM d 'lia'},
				d => q{E, MMM d 'lia' – E, MMM d 'lia'},
			},
			MMMd => {
				M => q{MMM d 'lia' – MMM d 'lia'},
				d => q{MMM d 'lia' – d 'lia'},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a 'ga' h:mm – a 'ga' h:mm},
				h => q{a 'ga' h:mm - 'ga' h:mm},
				m => q{a 'ga' h:mm – 'ga' h:mm},
			},
			hmv => {
				a => q{a 'ga' h:mm – a 'ga' h:mm v},
				h => q{a 'ga' h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a 'ga' h–h v},
			},
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y G},
				d => q{E, M/d/y – E, M/d/y G},
				y => q{E, M/d/y – E, M/d/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d 'lia' – E, MMM d 'lia', y G},
				d => q{E, MMM d 'lia' – E, MMM d 'lia', y G},
				y => q{E, MMM d 'lia', y – E, MMM d 'lia', y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d 'lia' – MMM d 'lia', y G},
				d => q{MMM d 'lia' – d 'lia' , y G},
				y => q{MMM d 'lia' , y – MMM d 'lia', y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y G},
				d => q{M/d/y – M/d/y G},
				y => q{M/d/y – M/d/y G},
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
				M => q{'ɣleti' M 'lia' – 'ɣleti' M 'lia'},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM d 'lia' – E, MMM d 'lia'},
				d => q{E, MMM d 'lia' – E, MMM d 'lia'},
			},
			MMMd => {
				M => q{MMM d 'lia' – MMM d 'lia'},
				d => q{MMM d 'lia' – d 'lia'},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a 'ga' h:mm – a 'ga' h:mm},
				h => q{a 'ga' h:mm - 'ga' h:mm},
				m => q{a 'ga' h:mm – 'ga' h:mm},
			},
			hmv => {
				a => q{a 'ga' h:mm – a 'ga' h:mm v},
				h => q{a 'ga' h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a 'ga' h–h v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d 'lia' – E, MMM d 'lia', y},
				d => q{E, MMM d 'lia' – E, MMM d 'lia', y},
				y => q{E, MMM d 'lia', y – E, MMM d 'lia', y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d 'lia' – MMM d 'lia', y},
				d => q{MMM d 'lia' – d 'lia' , y},
				y => q{MMM d 'lia' , y – MMM d 'lia', y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
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
		regionFormat => q({0}),
		regionFormat => q({0}),
		regionFormat => q({0}),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q(Eker dzomeŋɔli gaƒoƒome),
				'generic' => q(Eker gaƒoƒome),
				'standard' => q(Eker gaƒoƒoɖoanyime),
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidzan nutomegaƒoƒome#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Gɛ̃ nutomegaƒoƒome#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababa nutomegaƒoƒome#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algiers nutomegaƒoƒome#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara nutomegaƒoƒome#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako nutomegaƒoƒome#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui nutomegaƒoƒome#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Bandzul nutomegaƒoƒome#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisao nutomegaƒoƒome#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantaire nutomegaƒoƒome#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville nutomegaƒoƒome#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Budzumbura nutomegaƒoƒome#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo nutomegaƒoƒome#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka nutomegaƒoƒome#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Keuta nutomegaƒoƒome#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakry nutomegaƒoƒome#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar nutomegaƒoƒome#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salam nutomegaƒoƒome#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dzibuti nutomegaƒoƒome#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Doula nutomegaƒoƒome#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiun nutomegaƒoƒome#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown nutomegaƒoƒome#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone nutomegaƒoƒome#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare nutomegaƒoƒome#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Yohannesburg nutomegaƒoƒome#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala nutomegaƒoƒome#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoum nutomegaƒoƒome#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali nutomegaƒoƒome#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa nutomegaƒoƒome#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos nutomegaƒoƒome#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Libreville nutomegaƒoƒome#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome nutomegaƒoƒome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda nutomegaƒoƒome#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi nutomegaƒoƒome#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka nutomegaƒoƒome#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo nutomegaƒoƒome#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo nutomegaƒoƒome#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru nutomegaƒoƒome#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane nutomegaƒoƒome#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadishu nutomegaƒoƒome#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia nutomegaƒoƒome#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi nutomegaƒoƒome#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndzamena nutomegaƒoƒome#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey nutomegaƒoƒome#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott nutomegaƒoƒome#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadugu nutomegaƒoƒome#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Pɔto-Novo nutomegaƒoƒome#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome nutomegaƒoƒome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli nutomegaƒoƒome#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis nutomegaƒoƒome#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek nutomegaƒoƒome#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q(Titina Afrika gaƒoƒome),
			},
			short => {
				'standard' => q(CAT),
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q(Ɣedzeƒe Africa gaƒoƒome),
			},
			short => {
				'standard' => q(EAT),
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q(Anyiehe Africa gaƒoƒome),
			},
			short => {
				'standard' => q(SAST),
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q(Ɣetoɖoƒe Africa ŋkekeme gaƒoƒome),
				'generic' => q(Ɣetoɖoƒe Africa gaƒoƒome),
				'standard' => q(Ɣetoɖoƒe Afrika gaƒoƒoɖoanyime),
			},
			short => {
				'daylight' => q(WAST),
				'generic' => q(WAT),
				'standard' => q(WAT),
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q(Alaska ŋkekeme gaƒoƒome),
				'generic' => q(Alaska gaƒoƒome),
				'standard' => q(Alaska gaƒoƒoɖoanyime),
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q(Almati dzomeŋɔli gaƒoƒome),
				'generic' => q(Almati gaƒoƒome),
				'standard' => q(Almati gaƒoƒoɖoanyime),
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q(Amazon dzomeŋɔli gaƒoƒome),
				'generic' => q(Amazon gaƒoƒome),
				'standard' => q(Amazon gaƒoƒoɖoanyime),
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak nutomegaƒoƒome#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage nutomegaƒoƒome#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilla nutomegaƒoƒome#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua nutomegaƒoƒome#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina nutomegaƒoƒome#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioha nutomegaƒoƒome#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos nutomegaƒoƒome#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta nutomegaƒoƒome#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Dzuan nutomegaƒoƒome#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis nutomegaƒoƒome#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman nutomegaƒoƒome#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia nutomegaƒoƒome#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba nutomegaƒoƒome#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsion nutomegaƒoƒome#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia nutomegaƒoƒome#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados nutomegaƒoƒome#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem nutomegaƒoƒome#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize nutomegaƒoƒome#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon nutomegaƒoƒome#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista nutomegaƒoƒome#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota nutomegaƒoƒome#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise nutomegaƒoƒome#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires nutomegaƒoƒome#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kambridge Bay nutomegaƒoƒome#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampo Grande nutomegaƒoƒome#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun nutomegaƒoƒome#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas nutomegaƒoƒome#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamaka nutomegaƒoƒome#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayenne nutomegaƒoƒome#,
		},
		'America/Cayman' => {
			exemplarCity => q#Keman nutomegaƒoƒome#,
		},
		'America/Chicago' => {
			exemplarCity => q#Tsikago nutomegaƒoƒome#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Tsihuahua nutomegaƒoƒome#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokannutomegaƒoƒome#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kɔdoba nutomegaƒoƒome#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kɔsta Rika nutomegaƒoƒome#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuiaba nutomegaƒoƒome#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurakao nutomegaƒoƒome#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn nutomegaƒoƒome#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dɔwson nutomegaƒoƒome#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Krik nutomegaƒoƒome#,
		},
		'America/Denver' => {
			exemplarCity => q#Denva nutomegaƒoƒome#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detrɔit nutomegaƒoƒome#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika nutomegaƒoƒome#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton nutomegaƒoƒome#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe nutomegaƒoƒome#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvadɔ nutomegaƒoƒome#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza nutomegaƒoƒome#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glaise Bay nutomegaƒoƒome#,
		},
		'America/Godthab' => {
			exemplarCity => q#Godthab nutomegaƒoƒome#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Guse Bay nutomegaƒoƒome#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Tɛk nutomegaƒoƒome#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada nutomegaƒoƒome#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadelupe nutomegaƒoƒome#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala nutomegaƒoƒome#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayakuil nutomegaƒoƒome#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gayana nutomegaƒoƒome#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifaks nutomegaƒoƒome#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana nutomegaƒoƒome#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo nutomegaƒoƒome#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana nutomegaƒoƒome#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana nutomegaƒoƒome#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana nutomegaƒoƒome#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Telldugã, Indiana nutomegaƒoƒome#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana nutomegaƒoƒome#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vinsennes, Indiana nutomegaƒoƒome#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamak, Indiana nutomegaƒoƒome#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis nutomegaƒoƒome#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik nutomegaƒoƒome#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluit nutomegaƒoƒome#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Dzamaika nutomegaƒoƒome#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Dzudzoi nutomegaƒoƒome#,
		},
		'America/Juneau' => {
			exemplarCity => q#Dzuneau nutomegaƒoƒome#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montisello, Kentaki nutomegaƒoƒome#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz nutomegaƒoƒome#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima nutomegaƒoƒome#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles nutomegaƒoƒome#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville nutomegaƒoƒome#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lowa Prins Kɔta nutomegaƒoƒome#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maseio nutomegaƒoƒome#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua nutomegaƒoƒome#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus nutomegaƒoƒome#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot nutomegaƒoƒome#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik nutomegaƒoƒome#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan nutomegaƒoƒome#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza nutomegaƒoƒome#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini nutomegaƒoƒome#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida nutomegaƒoƒome#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksikodugã nutomegaƒoƒome#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon nutomegaƒoƒome#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton nutomegaƒoƒome#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey nutomegaƒoƒome#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo nutomegaƒoƒome#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat nutomegaƒoƒome#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau nutomegaƒoƒome#,
		},
		'America/New_York' => {
			exemplarCity => q#New York nutomegaƒoƒome#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon nutomegaƒoƒome#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome nutomegaƒoƒome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha nutomegaƒoƒome#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota nutomegaƒoƒome#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Titina, North Dakota nutomegaƒoƒome#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota nutomegaƒoƒome#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama nutomegaƒoƒome#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung nutomegaƒoƒome#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo nutomegaƒoƒome#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Foenix nutomegaƒoƒome#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Pɔrt-au-Princenutomegaƒoƒome#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Pɔrt of Spain nutomegaƒoƒome#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Pɔrto Velho nutomegaƒoƒome#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Riko nutomegaƒoƒome#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Raini Riva nutomegaƒoƒome#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet nutomegaƒoƒome#,
		},
		'America/Recife' => {
			exemplarCity => q#Resife nutomegaƒoƒome#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina nutomegaƒoƒome#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute nutomegaƒoƒome#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branko nutomegaƒoƒome#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem nutomegaƒoƒome#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago nutomegaƒoƒome#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo nutomegaƒoƒome#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paulo nutomegaƒoƒome#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Skɔsbisund nutomegaƒoƒome#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthelemy nutomegaƒoƒome#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. Yohannes nutomegaƒoƒome#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitis nutomegaƒoƒome#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lusia nutomegaƒoƒome#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Toma nutomegaƒoƒome#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent nutomegaƒoƒome#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Kurrent nutomegaƒoƒome#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegukigalpa nutomegaƒoƒome#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule nutomegaƒoƒome#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay nutomegaƒoƒome#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tihuana nutomegaƒoƒome#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto nutomegaƒoƒome#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tɔtola nutomegaƒoƒome#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankouver nutomegaƒoƒome#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse nutomegaƒoƒome#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg nutomegaƒoƒome#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat nutomegaƒoƒome#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellownaif nutomegaƒoƒome#,
		},
		'America_Central' => {
			long => {
				'daylight' => q(Titina America ŋkekeme gaƒoƒome),
				'generic' => q(Titina America gaƒoƒome),
				'standard' => q(Titina America gaƒoƒoɖoanyime),
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q(Ɣedzeƒe America ŋkekeme gaƒoƒome),
				'generic' => q(Ɣedzeƒe America gaƒoƒome),
				'standard' => q(Ɣedzeƒe America gaƒoƒoɖoanyime),
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q(America Todzidukɔwo ƒe ŋkekme gaƒoƒome),
				'generic' => q(America Todzidukɔwo ƒe gaƒoƒome),
				'standard' => q(America Todzidukɔwo ƒe gaƒoƒoɖoanyime),
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q(Pacific ŋkekme gaƒoƒome),
				'generic' => q(Pacific gaƒoƒome),
				'standard' => q(Pacific gaƒoƒoɖoanyime),
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q(Anadir ŋkekeme gaƒoƒome),
				'generic' => q(Anadir gaƒoƒome),
				'standard' => q(Anadir gaƒoƒoɖoanyime),
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kasey nutomegaƒoƒome#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis nutomegaƒoƒome#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville nutomegaƒoƒome#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson nutomegaƒoƒome#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#MacMurdo nutomegaƒoƒome#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer nutomegaƒoƒome#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera nutomegaƒoƒome#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa nutomegaƒoƒome#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok nutomegaƒoƒome#,
		},
		'Aqtau' => {
			long => {
				'daylight' => q(Aktau dzomeŋɔli gaƒoƒome),
				'generic' => q(Aktau gaƒoƒome),
				'standard' => q(Aktau gaƒoƒoɖoanyime),
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q(Akttobe gaƒoƒome),
				'generic' => q(Aktobe gaƒoƒome),
				'standard' => q(Aktobe gaƒoƒoɖoanyime),
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q(Arabia ŋkekeme gaƒoƒome),
				'generic' => q(Arabia gaƒoƒome),
				'standard' => q(Arabia gaƒoƒoɖoanyime),
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbiyen nutomegaƒoƒome#,
		},
		'Argentina' => {
			long => {
				'daylight' => q(Argentina dzomeŋɔli gaƒoƒome),
				'generic' => q(Argentina gaƒoƒome),
				'standard' => q(Argentina gaƒoƒoɖoanyime),
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q(Ɣetoɖoƒe Argentina dzomeŋɔli gaƒoƒome),
				'generic' => q(Ɣetoɖoƒe Argentina gaƒoƒome),
				'standard' => q(Ɣetoɖoƒe Argentina gaƒoƒoɖoanyime),
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q(Armenia dzomeŋɔli gaƒoƒome),
				'generic' => q(Armenia gaƒoƒome),
				'standard' => q(Armenia gaƒoƒoɖoanyime),
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden nutomegaƒoƒome#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati nutomegaƒoƒome#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman nutomegaƒoƒome#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir nutomegaƒoƒome#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau nutomegaƒoƒome#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe nutomegaƒoƒome#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat nutomegaƒoƒome#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baghdad nutomegaƒoƒome#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain nutomegaƒoƒome#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku nutomegaƒoƒome#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok nutomegaƒoƒome#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut nutomegaƒoƒome#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek nutomegaƒoƒome#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei nutomegaƒoƒome#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata nutomegaƒoƒome#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tsoibalsan nutomegaƒoƒome#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo nutomegaƒoƒome#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus nutomegaƒoƒome#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka nutomegaƒoƒome#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili nutomegaƒoƒome#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai nutomegaƒoƒome#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dutsanbe nutomegaƒoƒome#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza nutomegaƒoƒome#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hɔng Kɔng nutomegaƒoƒome#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd nutomegaƒoƒome#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk nutomegaƒoƒome#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Dzakarta nutomegaƒoƒome#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Dzayapura nutomegaƒoƒome#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusalem nutomegaƒoƒome#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul nutomegaƒoƒome#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtsatka nutomegaƒoƒome#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karatsi nutomegaƒoƒome#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu nutomegaƒoƒome#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk nutomegaƒoƒome#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur nutomegaƒoƒome#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kutsing nutomegaƒoƒome#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwait nutomegaƒoƒome#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau nutomegaƒoƒome#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan nutomegaƒoƒome#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar nutomegaƒoƒome#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila nutomegaƒoƒome#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat nutomegaƒoƒome#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia nutomegaƒoƒome#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk nutomegaƒoƒome#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk nutomegaƒoƒome#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral nutomegaƒoƒome#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Nɔm Penh nutomegaƒoƒome#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak nutomegaƒoƒome#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Piongyang nutomegaƒoƒome#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar nutomegaƒoƒome#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilɔda nutomegaƒoƒome#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon nutomegaƒoƒome#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyadh nutomegaƒoƒome#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Tsi Minh nutomegaƒoƒome#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin nutomegaƒoƒome#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand nutomegaƒoƒome#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul nutomegaƒoƒome#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai nutomegaƒoƒome#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapore nutomegaƒoƒome#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei nutomegaƒoƒome#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent nutomegaƒoƒome#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi nutomegaƒoƒome#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehran nutomegaƒoƒome#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timfu nutomegaƒoƒome#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio nutomegaƒoƒome#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar nutomegaƒoƒome#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi nutomegaƒoƒome#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane nutomegaƒoƒome#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok nutomegaƒoƒome#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk nutomegaƒoƒome#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg nutomegaƒoƒome#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan nutomegaƒoƒome#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q(Atlantic ŋkekeme gaƒoƒome),
				'generic' => q(Atlantic gaƒoƒome),
				'standard' => q(Atlantic gaƒoƒoɖoanyime),
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores nutomegaƒoƒome#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda nutomegaƒoƒome#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari nutomegaƒoƒome#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kape Verde nutomegaƒoƒome#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe nutomegaƒoƒome#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira nutomegaƒoƒome#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik nutomegaƒoƒome#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Anyiehe Georgia nutomegaƒoƒome#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena nutomegaƒoƒome#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley nutomegaƒoƒome#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide nutomegaƒoƒome#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane nutomegaƒoƒome#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill nutomegaƒoƒome#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kurrie nutomegaƒoƒome#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin nutomegaƒoƒome#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla nutomegaƒoƒome#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart nutomegaƒoƒome#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman nutomegaƒoƒome#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lɔd Howe nutomegaƒoƒome#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melbourne nutomegaƒoƒome#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth nutomegaƒoƒome#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidney nutomegaƒoƒome#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q(Titina Australia ŋkekeme gaƒoƒome),
				'generic' => q(Titina Australia gaƒoƒome),
				'standard' => q(Titina Australia gaƒoƒoɖoanyime),
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q(Australia ɣetoɖofe ŋkekeme gaƒoƒome),
				'generic' => q(Australia ɣetoɖofe gaƒoƒome),
				'standard' => q(Australia ɣetoɖofe gaƒoƒoɖoanyime),
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q(Ɣedzeƒe Australia ŋkekeme gaƒoƒome),
				'generic' => q(Ɣedzeƒe Australia gaƒoƒome),
				'standard' => q(Ɣedzeƒe Australia gaƒoƒoɖoanyime),
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q(Ɣetoɖoƒe Australia ŋkekeme gaƒoƒome),
				'generic' => q(Ɣetoɖoƒe Australia gaƒoƒome),
				'standard' => q(Ɣetoɖoƒe Australia gaƒoƒoɖoanyime),
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q(Azerbaidzan dzomeŋɔli gaƒoƒome),
				'generic' => q(Azerbaidzan gaƒoƒome),
				'standard' => q(Azerbaidzan gaƒoƒoɖoanyime),
			},
		},
		'Azores' => {
			long => {
				'daylight' => q(Azores dzomeŋɔli gaƒoƒome),
				'generic' => q(Azores gaƒoƒome),
				'standard' => q(Azores gaƒoƒoɖoanyime),
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q(Bolivia gaƒoƒome),
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q(Brasilia dzomeŋɔli gaƒoƒome),
				'generic' => q(Brasilia gaƒoƒome),
				'standard' => q(Brasilia gaƒoƒoɖoanyime),
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q(Kep Verde dzomeŋɔli gaƒoƒome),
				'generic' => q(Kep Verde gaƒoƒome),
				'standard' => q(Kep Verde gaƒoƒoɖoanyime),
			},
		},
		'Chile' => {
			long => {
				'daylight' => q(Tsile dzomeŋɔli gaƒoƒome),
				'generic' => q(Tsile gaƒoƒo me),
				'standard' => q(Tsile gaƒoƒoɖoanyime),
			},
		},
		'China' => {
			long => {
				'daylight' => q(China ŋkekeme gaƒoƒome),
				'generic' => q(China gaƒoƒome),
				'standard' => q(China gaƒoƒoɖoanyime),
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q(Tsoibalsan dzomeŋɔli gaƒoƒome),
				'generic' => q(Tsoibalsan gaƒoƒome),
				'standard' => q(Tsoibalsan gaƒoƒoɖoanyime),
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q(Kolombia dzomeŋɔli gaƒoƒome),
				'generic' => q(Kolombia gaƒoƒome),
				'standard' => q(Kolombia gaƒoƒoɖoanyime),
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q(Kuba ŋkekeme gaƒoƒome),
				'generic' => q(Kuba gaƒoƒome),
				'standard' => q(Kuba gaƒoƒoɖoanyime),
			},
		},
		'Easter' => {
			long => {
				'daylight' => q(Easter Ƒudomekpodukɔ ƒe dzomeŋɔli gaƒoƒome),
				'generic' => q(Easter Ƒudomekpodukɔ ƒe gaƒoƒome),
				'standard' => q(Easter Ƒudomekpodukɔ ƒe gaƒoƒoɖoanyime),
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q(Ikuedɔ dzomeŋɔli gaƒoƒome),
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#du manya#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam nutomegaƒoƒome#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra nutomegaƒoƒome#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atens nutomegaƒoƒome#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade nutomegaƒoƒome#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin nutomegaƒoƒome#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava nutomegaƒoƒome#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussels nutomegaƒoƒome#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest nutomegaƒoƒome#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest nutomegaƒoƒome#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Tsisinau nutomegaƒoƒome#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen nutomegaƒoƒome#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin nutomegaƒoƒome#,
			long => {
				'daylight' => q(Irelanɖ dzomeŋɔli gaƒoƒome),
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar nutomegaƒoƒome#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernse nutomegaƒoƒome#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki nutomegaƒoƒome#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Aisle of Man nutomegaƒoƒome#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul nutomegaƒoƒome#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jɛse nutomegaƒoƒome#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad nutomegaƒoƒome#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev nutmegaƒoƒome#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbon nutomegaƒoƒome#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubliana nutomegaƒoƒome#,
		},
		'Europe/London' => {
			exemplarCity => q#London nutomegaƒoƒome#,
			long => {
				'daylight' => q(Britain dzomeŋɔli gaƒoƒome),
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lazembɔg nutomegaƒoƒome#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid nutomegaƒoƒome#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta nutomegaƒoƒome#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn nutomegaƒoƒome#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk nutomegaƒoƒome#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco nutomegaƒoƒome#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscow nutomegaƒoƒome#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo nutomegaƒoƒome#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris nutomegaƒoƒome#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorika nutomegaƒoƒome#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prague nutomegaƒoƒome#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga nutomegaƒoƒome#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma nutomegaƒoƒome#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara nutomegaƒoƒome#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino nutomegaƒoƒome#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayevo nutomegaƒoƒome#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol nutomegaƒoƒome#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopie nutomegaƒoƒome#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia nutomegaƒoƒome#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm nutomegaƒoƒome#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn nutomegaƒoƒome#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane nutomegaƒoƒome#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod nutomegaƒoƒome#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz nutomegaƒoƒome#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan nutomegaƒoƒome#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienna nutomegaƒoƒome#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius nutomegaƒoƒome#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd nutomegaƒoƒome#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Wɔsɔw nutomegaƒoƒome#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb nutomegaƒoƒome#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhiye nutomegaƒoƒome#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich nutomegaƒoƒome#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q(Titina Europe ŋkekeme gaƒoƒome),
				'generic' => q(Titina Europe gaƒoƒome),
				'standard' => q(Titina Europe gaƒoƒoɖoanyime),
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q(Ɣedzeƒe Europe ŋkekeme gaƒoƒome),
				'generic' => q(Ɣedzeƒe Europe gaƒoƒome),
				'standard' => q(Ɣedzeƒe Europe gaƒoƒoɖoanyime),
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q(Ɣetoɖoƒe Europe ŋkekeme gaƒoƒome),
				'generic' => q(Ɣetoɖoƒe Europe gaƒoƒome),
				'standard' => q(Ɣetoɖoƒe Europe gaƒoƒoɖoanyime),
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q(Fɔlklanɖ Ƒudomekpodukɔ ƒe dzomeŋɔli gaƒoƒome),
				'generic' => q(Fɔlklanɖ Ƒudomekpodukɔ ƒe gaƒoƒome),
				'standard' => q(Fɔlklanɖ Ƒudomekpodukɔ ƒe gaƒoƒoɖoanyime),
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q(Frentsi Guiana gaƒoƒome),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(Greenwich gaƒoƒome),
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q(Galapagos gaƒoƒome),
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q(Dzɔdzia dzomeŋɔli gaƒoƒome),
				'generic' => q(Dzɔdzia gaƒoƒome),
				'standard' => q(Dzɔdzia gaƒoƒoɖoanyime),
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q(Ɣedzeƒe Grinlanɖ dzomeŋɔli gaƒoƒome),
				'generic' => q(Ɣedzeƒe Grinlanɖ gaƒoƒome),
				'standard' => q(Ɣedzeƒe Grinlanɖ gaƒoƒoɖoanyime),
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q(Ɣetoɖoƒe Grinlanɖ dzomeŋɔli gaƒoƒome),
				'generic' => q(Ɣetoɖoƒe Grinlanɖ gaƒoƒome),
				'standard' => q(Ɣetoɖoƒe Grinlanɖ gaƒoƒoɖoanyime),
			},
		},
		'Gulf' => {
			long => {
				'standard' => q(Gulf gaƒoƒome),
			},
		},
		'Guyana' => {
			long => {
				'standard' => q(Gayana gaƒoƒome),
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q(Hawaii-Aleutia ŋkekeme gaƒoƒome),
				'generic' => q(Hawaii-Aleutia gaƒoƒome),
				'standard' => q(Hawaii-Aleutia gaƒoƒoɖoanyime),
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q(Hɔng Kɔng dzomeŋɔli gaƒoƒome),
				'generic' => q(Hɔng Kɔng gaƒoƒome),
				'standard' => q(Hɔng Kɔng gaƒoƒoɖoanyi me),
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q(Hoved dzomeŋɔli gaƒoƒome),
				'generic' => q(Hoved gaƒoƒome),
				'standard' => q(Hoved gaƒoƒoɖoanyime),
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo nutomegaƒoƒome#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Tsagos nutomegaƒoƒome#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Kristmas nutomegaƒoƒome#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos nutomegaƒoƒome#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro nutomegaƒoƒome#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen nutomegaƒoƒome#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe nutomegaƒoƒome#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldives nutomegaƒoƒome#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius nutomegaƒoƒome#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte nutomegaƒoƒome#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion nutomegaƒoƒome#,
		},
		'Irkutsk' => {
			long => {
				'daylight' => q(Irkusk dzomeŋɔli gaƒoƒome),
				'generic' => q(Irkusk gaƒoƒome),
				'standard' => q(Irkusk gaƒoƒoɖoanyime),
			},
		},
		'Israel' => {
			long => {
				'daylight' => q(Israel ŋkekeme gaƒoƒome),
				'generic' => q(Israel gaƒoƒome),
				'standard' => q(Israel gaƒoƒoɖoanyime),
			},
		},
		'Japan' => {
			long => {
				'daylight' => q(Japan ŋkekeme gaƒoƒome),
				'generic' => q(Japan gaƒoƒome),
				'standard' => q(Japan gaƒoƒoɖanyime),
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q(Petropavlovsk-Kamtsatski ŋkekeme gaƒoƒome),
				'generic' => q(Petropavlovsk-Kamtsatski gaƒoƒome),
				'standard' => q(Petropavlovsk-Kamtsatski gaƒoƒoɖoanyime),
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q(Ɣedzeƒe Kazakstan gaƒoƒome),
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q(Ɣetoɖoƒe Kazakstan gaƒoƒome),
			},
		},
		'Korea' => {
			long => {
				'daylight' => q(Korea ŋkekeme gaƒoƒome),
				'generic' => q(Korea gaƒoƒome),
				'standard' => q(Korea gaƒoƒoɖoanyime),
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q(Krasnoyarsk dzomeŋɔli gaƒoƒome),
				'generic' => q(Krasnoyarsk gaƒoƒome),
				'standard' => q(Krasnoyarsk gaƒoƒoɖoanyime),
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q(Kirgistan gaƒoƒome),
			},
		},
		'Macau' => {
			long => {
				'daylight' => q(Makau ŋkekeme gaƒoƒome),
				'generic' => q(Makau gaƒoƒome),
				'standard' => q(Makau gaƒoƒoɖoanyime),
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q(Magadan dzomeŋɔli gaƒoƒome),
				'generic' => q(Magadan gaƒoƒome),
				'standard' => q(Magadan gaƒoƒoɖoanyime),
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q(Mɔritius dzomeŋɔli gaƒoƒome),
				'generic' => q(Mɔritius gaƒoƒome),
				'standard' => q(Mɔritius gaƒoƒoɖoanyime),
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q(Ulan Batɔ dzomeŋɔli gaƒoƒome),
				'generic' => q(Ulan Batɔ gaƒoƒome),
				'standard' => q(Ulan Batɔ gaƒoƒoɖoanyime),
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q(Moscow ŋkekeme gaƒoƒome),
				'generic' => q(Moscow gaƒoƒome),
				'standard' => q(Moscow gaƒoƒoɖoanyime),
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q(Niufaunɖlanɖ ŋkekeme gaƒoƒome),
				'generic' => q(Niufaunɖlanɖ gaƒoƒome),
				'standard' => q(Niufaunɖlanɖ gaƒoƒoɖoanyime),
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q(Fernando de Noronha dzomeŋɔli gaƒoƒome),
				'generic' => q(Fernando de Noronha gaƒoƒome),
				'standard' => q(Fernando de Noronha gaƒoƒoɖoanyime),
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q(Novosibirsk dzomeŋɔli gaƒoƒome),
				'generic' => q(Novosibirsk gaƒoƒome),
				'standard' => q(Novosibirsk gaƒoƒoɖoanyime),
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q(Omsk dzomeŋɔli gaƒoƒome),
				'generic' => q(Omsk gaƒoƒome),
				'standard' => q(Omsk gaƒoƒoɖoanyime),
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia nutomegaƒoƒome#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Tsatham nutomegaƒoƒome#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Easter nutomegaƒoƒome#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate nutomegaƒoƒome#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderburi nutomegaƒoƒome#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo nutomegaƒoƒome#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidzi nutomegaƒoƒome#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti nutomegaƒoƒome#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos nutomegaƒoƒome#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier nutomegaƒoƒome#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalkanal nutomegaƒoƒome#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam nutomegaƒoƒome#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu nutomegaƒoƒome#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Yohanneston nutomegaƒoƒome#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati nutomegaƒoƒome#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae nutomegaƒoƒome#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwadzalein nutomegaƒoƒome#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markuesas nutomegaƒoƒome#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway nutomegaƒoƒome#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru nutomegaƒoƒome#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niue nutomegaƒoƒome#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nɔfɔlk nutomegaƒoƒome#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numea nutomegaƒoƒome#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago nutomegaƒoƒome#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau nutomegaƒoƒome#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkairn nutomegaƒoƒome#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei nutomegaƒoƒome#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pɔrt Moresbynutomegaƒoƒome#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga nutomegaƒoƒome#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan nutomegaƒoƒome#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa nutomegaƒoƒome#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu nutomegaƒoƒome#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Tsuuk nutomegaƒoƒome#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake nutomegaƒoƒome#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis nutomegaƒoƒome#,
		},
		'Paraguay' => {
			long => {
				'daylight' => q(Paraguai dzomeŋɔli gaƒoƒome),
				'generic' => q(Paraguai gaƒoƒome),
				'standard' => q(Paraguai gaƒoƒoɖoanyime),
			},
		},
		'Peru' => {
			long => {
				'daylight' => q(Peru dzomeŋɔli gaƒoƒome),
				'generic' => q(Peru gaƒoƒome),
				'standard' => q(Peru gaƒoƒoɖoanyime),
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q(Saint Pierre kple Mikuelon ŋkekeme gaƒoƒome),
				'generic' => q(Saint Pierre kple Mikuelon gaƒoƒome),
				'standard' => q(Saint Pierre kple Mikuelon gaƒoƒoɖoanyime),
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q(Kizilɔrda dzomeŋɔli gaƒoƒome),
				'generic' => q(Kizilɔrda gaƒoƒome),
				'standard' => q(Kizilɔrda gaƒoƒoɖoanyime),
			},
		},
		'Reunion' => {
			long => {
				'standard' => q(Reunion gaƒoƒome),
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q(Sahalin dzomeŋɔli gaƒoƒome),
				'generic' => q(Sahalin gaƒoƒome),
				'standard' => q(Sakhalin gaƒoƒoɖoanyime),
			},
		},
		'Samara' => {
			long => {
				'daylight' => q(Samara ŋkekeme gaƒoƒome),
				'generic' => q(Samara gaƒoƒome),
				'standard' => q(Samara gaƒoƒoɖoanyime),
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q(Sɛtsels gaƒoƒome),
			},
		},
		'Suriname' => {
			long => {
				'standard' => q(Suriname gaƒoƒome),
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q(Taipei ŋkekeme gaƒoƒome),
				'generic' => q(Taipei gaƒoƒome),
				'standard' => q(Taipei gaƒoƒoɖoanyime),
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q(Tadzikistan gaƒoƒome),
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q(Tɛkmenistan dzomeŋɔli gaƒoƒome),
				'generic' => q(Tɛkmenistan gaƒoƒome),
				'standard' => q(Tɛkmenistan gaƒoƒoɖoanyime),
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q(Uruguai dzomeŋɔli gaƒoƒome),
				'generic' => q(Uruguai gaƒoƒome),
				'standard' => q(Uruguai gaƒoƒoɖoanyime),
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q(Uzbekistan dzomeŋɔli gaƒoƒome),
				'generic' => q(Uzbekistan gaƒoƒome),
				'standard' => q(Uzbekistan gaƒoƒoɖoanyime),
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q(Venezuela gaƒoƒome),
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q(Vladivostok dzomeŋɔli gaƒoƒome),
				'generic' => q(Vladivostok gaƒoƒome),
				'standard' => q(Vladivostok gaƒoƒoɖoanyime),
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q(Vogograd dzomeŋɔli gaƒoƒome),
				'generic' => q(Vogograd gaƒoƒome),
				'standard' => q(Vogograd gaƒoƒoɖoanyime),
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q(Yakutsk dzomeŋɔli gaƒoƒome),
				'generic' => q(Yakutsk gaƒoƒome),
				'standard' => q(Yakutsk gaƒoƒoɖoanyime),
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q(Yekaterinburg dzomeŋɔli gaƒoƒome),
				'generic' => q(Yekateringburg gaƒoƒome),
				'standard' => q(Yekateringburg gaƒoƒoɖoanyime),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
