=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sw::Any::Ke - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw::Any::Ke;
# This file auto generated from Data\common\main\sw_KE.xml
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

extends('Locale::CLDR::Locales::Sw::Any');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar_001' => 'Kiarabu sanifu',
 				'arq' => 'Kiarabu cha Aljeria',
 				'as' => 'Kiasamisi',
 				'chr' => 'Kicheroki',
 				'cu' => 'Kislovakia cha Kanisa la Jadi',
 				'gaa' => 'Kiga',
 				'grc' => 'Kigiriki cha Kale',
 				'gwi' => 'Kigwichʼin',
 				'hsb' => 'Kisorbia cha Juu',
 				'hup' => 'Kihupa',
 				'hy' => 'Kiamenia',
 				'inh' => 'Kiingushi',
 				'jbo' => 'Kilojbani',
 				'kac' => 'Kikachini',
 				'khq' => 'Kikoyrachiini',
 				'kkj' => 'Kikako',
 				'km' => 'Kikhmeri',
 				'kn' => 'Kikanada',
 				'koi' => 'Kikomipermyak',
 				'kru' => 'Kikurukh',
 				'lag' => 'Kilangi',
 				'lam' => 'Kilamba',
 				'li' => 'Kilimbugishi',
 				'mdf' => 'Kimoksha',
 				'mic' => 'Kimi\'kmak',
 				'mk' => 'Kimasedonia',
 				'moh' => 'Kimohoki',
 				'nnh' => 'Kiingiemboon',
 				'nqo' => 'Kiin’ko',
 				'or' => 'Kiodia',
 				'pcm' => 'Kipijini cha Nigeria',
 				'ro_MD' => 'Kimoldova cha Romania',
 				'ses' => 'Kikoyraborosenni',
 				'shu' => 'Kiarabu cha Chadi',
 				'srn' => 'Kisranantongo',
 				'sw_CD' => 'Kiswahili cha Kongo',
 				'swb' => 'Kikomoro',
 				'syr' => 'Kisiria',
 				'tw' => 'Kitwi',
 				'udm' => 'Kiudumurti',
 				'ug' => 'Kiuiguri',
 				'zgh' => 'Kitamazighati Sanifu cha Moroko',
 				'zh@alt=menu' => 'Kichina, Kimandarini',
 				'zh_Hans@alt=long' => 'Kichina cha Kimandarini Rahisi',
 				'zh_Hant@alt=long' => 'Kichina cha Kimandarini cha Jadi',

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
			'Brai' => 'Breli',
 			'Ethi' => 'Kihabeshi',
 			'Hebr' => 'Kihibrania',
 			'Hira' => 'Kihiragana',
 			'Jamo' => 'Kijamo',
 			'Mymr' => 'Kimyama',
 			'Orya' => 'Kiodia',
 			'Taml' => 'Kitamili',

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
			'202' => 'Kusini mwa Jangwa la Sahara',
 			'AF' => 'Afghanistani',
 			'AI' => 'Anguila',
 			'AQ' => 'Antaktika',
 			'AZ' => 'Azabajani',
 			'BJ' => 'Benini',
 			'BT' => 'Bhutani',
 			'BY' => 'Belarusi',
 			'CC' => 'Visiwa vya Kokos (Keeling)',
 			'CD' => 'Kongo - Kinshasa',
 			'CV' => 'Kepuvede',
 			'EA' => 'Keuta na Melilla',
 			'EC' => 'Ekwado',
 			'GA' => 'Gaboni',
 			'GL' => 'Grinilandi',
 			'GP' => 'Gwadelupe',
 			'GS' => 'Visiwa vya Jojia ya Kusini na Sandwich ya Kusini',
 			'GU' => 'Guami',
 			'HR' => 'Kroashia',
 			'IO' => 'Himaya ya Uingereza katika Bahari Hindi',
 			'JO' => 'Yordani',
 			'KY' => 'Visiwa vya Kaimani',
 			'LA' => 'Laosi',
 			'LB' => 'Lebanoni',
 			'LI' => 'Lishenteni',
 			'LS' => 'Lesotho',
 			'LU' => 'Lasembagi',
 			'LV' => 'Lativia',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MK' => 'Masedonia',
 			'MM' => 'Myama (Burma)',
 			'MQ' => 'Martiniki',
 			'MS' => 'Montserati',
 			'NC' => 'Nyukaledonia',
 			'NE' => 'Nijeri',
 			'NO' => 'Norwe',
 			'NP' => 'Nepali',
 			'OM' => 'Omani',
 			'PF' => 'Polinesia ya Ufaransa',
 			'PG' => 'Papua Guinea Mpya',
 			'PL' => 'Polandi',
 			'PR' => 'Puetoriko',
 			'PS' => 'Himaya za Palestina',
 			'PY' => 'Paragwai',
 			'QA' => 'Katari',
 			'SG' => 'Singapuri',
 			'SR' => 'Surinamu',
 			'ST' => 'Sao Tome na Prinsipe',
 			'SY' => 'Shamu',
 			'TD' => 'Chadi',
 			'TH' => 'Thailandi',
 			'TM' => 'Turukimenstani',
 			'TW' => 'Taiwani',
 			'UA' => 'Ukreni',
 			'UY' => 'Urugwai',
 			'VA' => 'Mji wa Vatikani',
 			'VG' => 'Visiwa vya Virgin vya Uingereza',
 			'VI' => 'Visiwa vya Virgin vya Marekani',
 			'XA' => 'Kiinitoni cha kigeni',
 			'XB' => 'Pseudo-Bidi',
 			'YT' => 'Mayote',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'hc' => 'Kipindi cha saa (12 dhidi ya 24)',
 			'va' => 'Tofauti ya Lugha',

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
 				'dangi' => q{Kalenda ya Kidangi},
 				'ethiopic' => q{Kalenda ya Kihabeshi},
 				'hebrew' => q{Kalenda ya kihibrania},
 			},
 			'numbers' => {
 				'ethi' => q{Nambari za Kihabeshi},
 				'geor' => q{Nambari za Kijiojia},
 				'hebr' => q{Nambari za Kihibrania},
 				'mlym' => q{Nambari za Kimalayalam},
 				'mymr' => q{Nambari za Kimyama},
 				'tamldec' => q{Nambari za Kitamili},
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
			'metric' => q{Kipimo},

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
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(mwongo),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(mwongo),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(maikrosekunde),
						'one' => q(maikroseunde {0}),
						'other' => q(maikrosekunde {0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(maikrosekunde),
						'one' => q(maikroseunde {0}),
						'other' => q(maikrosekunde {0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(nukta kwa kila sentimita),
						'one' => q(nukta {0} kwa kila sentimita),
						'other' => q(nukta {0} kwa kila sentimita),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(nukta kwa kila sentimita),
						'one' => q(nukta {0} kwa kila sentimita),
						'other' => q(nukta {0} kwa kila sentimita),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(nukta kwa kila inchi),
						'one' => q(nuka {0} kwa kila inchi),
						'other' => q(nukta {0} kwa kila inchi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(nukta kwa kila inchi),
						'one' => q(nuka {0} kwa kila inchi),
						'other' => q(nukta {0} kwa kila inchi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ukubwa wa nafasi ya fonti),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ukubwa wa nafasi ya fonti),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q(pikseli {0} kwa kila sekunde),
						'other' => q(pikseli {0} kwa kila sekunde),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q(pikseli {0} kwa kila sekunde),
						'other' => q(pikseli {0} kwa kila sekunde),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q(miaka {0} ya mwanga),
						'other' => q(miaka {0} ya mwanga),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q(miaka {0} ya mwanga),
						'other' => q(miaka {0} ya mwanga),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(maikromita),
						'one' => q(maikromita {0}),
						'other' => q(maikromita {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(maikromita),
						'one' => q(maikromita {0}),
						'other' => q(maikromita {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q(nusu kipenyo {0} cha jua),
						'other' => q(nusu vipenyo {0} vya jua),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q(nusu kipenyo {0} cha jua),
						'other' => q(nusu vipenyo {0} vya jua),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(baa),
						'one' => q(baa {0}),
						'other' => q(baa {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(baa),
						'one' => q(baa {0}),
						'other' => q(baa {0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q(mm{0}),
						'other' => q(mm{0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q(mm{0}),
						'other' => q(mm{0}),
					},
				},
				'short' => {
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(maili/gal Imp),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(maili/gal Imp),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(mwongo),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(mwongo),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikseli),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikseli),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q(pikseli {0}),
						'other' => q(pikseli {0}),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q(pikseli {0}),
						'other' => q(pikseli {0}),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(kipimo cha astronomia),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(kipimo cha astronomia),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(maikromita),
						'one' => q(maikromita {0}),
						'other' => q(maikromita {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(maikromita),
						'one' => q(maikromita {0}),
						'other' => q(maikromita {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q(pc {0}),
						'other' => q(kila sekunde {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q(pc {0}),
						'other' => q(kila sekunde {0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(baa),
						'one' => q(baa {0}),
						'other' => q(baa {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(baa),
						'one' => q(baa {0}),
						'other' => q(baa {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q(mmHg {0}),
						'other' => q(mm Hg {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q(mmHg {0}),
						'other' => q(mm Hg {0}),
					},
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
					'one' => 'elfu 0;elfu -0',
					'other' => 'elfu 0;elfu -0',
				},
				'10000' => {
					'one' => 'elfu 00;elfu -00',
					'other' => 'elfu 00',
				},
				'100000' => {
					'one' => 'elfu 000',
					'other' => 'elfu 000',
				},
				'1000000' => {
					'one' => 'milioni 0',
					'other' => 'milioni 0',
				},
				'10000000' => {
					'one' => 'milioni 00',
					'other' => 'milioni 00',
				},
				'100000000' => {
					'one' => 'milioni 000',
					'other' => 'milioni 000',
				},
				'1000000000' => {
					'one' => 'bilioni 0',
					'other' => 'bilioni 0',
				},
				'10000000000' => {
					'one' => 'bilioni 00',
					'other' => 'bilioni 00',
				},
				'100000000000' => {
					'one' => 'bilioni 000',
					'other' => 'bilioni 000',
				},
				'1000000000000' => {
					'one' => 'trilioni 0',
					'other' => 'trilioni 0',
				},
				'10000000000000' => {
					'one' => 'trilioni 00',
					'other' => 'trilioni 00',
				},
				'100000000000000' => {
					'one' => 'trilioni 000',
					'other' => 'trilioni 000',
				},
			},
			'short' => {
				'1000' => {
					'one' => 'elfu 0',
					'other' => 'elfu 0',
				},
				'10000' => {
					'one' => 'elfu 00',
					'other' => 'elfu 00',
				},
				'100000' => {
					'one' => 'elfu 000',
					'other' => 'elfu 000',
				},
				'1000000' => {
					'one' => 'M0',
					'other' => 'M0',
				},
				'10000000' => {
					'one' => 'M00',
					'other' => 'M00',
				},
				'100000000' => {
					'one' => 'M000',
					'other' => 'M000',
				},
				'1000000000' => {
					'one' => 'B0',
					'other' => 'B0',
				},
				'10000000000' => {
					'one' => 'B00',
					'other' => 'B00',
				},
				'100000000000' => {
					'one' => 'B000',
					'other' => 'B000',
				},
				'1000000000000' => {
					'one' => 'T0',
					'other' => 'T0',
				},
				'10000000000000' => {
					'one' => 'T00',
					'other' => 'T00',
				},
				'100000000000000' => {
					'one' => 'T000',
					'other' => 'T000',
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
				'currency' => q(Diramu ya Falme za Kiarabu),
				'one' => q(diramu ya Falme za Kiarabu),
				'other' => q(diramu za Falme za Kiarabu),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani ya Afghanistani),
				'one' => q(afghani ya Afghanistani),
				'other' => q(afghani za Afghanistani),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Gilda ya Antili ya Uholanzi),
				'one' => q(gilda ya Antili ya Uholanzi),
				'other' => q(gilda za Antili ya Uholanzi),
			},
		},
		'AWG' => {
			display_name => {
				'one' => q(florin ya Aruba),
				'other' => q(florin ya Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manati ya Azabajani),
				'one' => q(manati ya Azabajani),
				'other' => q(manati za Azabajani),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Maki ya Bosnia na Hezegovina Inayoweza Kubadilishwa),
				'one' => q(maki ya Bosnia na Hezegovina inayoweza kubadilishwa),
				'other' => q(maki za Bosnia na Hezegovina zinazoweza kubadilishwa),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dola ya Babadosi),
				'one' => q(dola ya Babadosi),
				'other' => q(dola za Babadosi),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka ya Bangladeshi),
				'one' => q(taka ya Bangladeshi),
				'other' => q(taka za Bangladeshi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dola ya Bamuda),
				'one' => q(dola ya Bamuda),
				'other' => q(dola za Bamuda),
			},
		},
		'BOB' => {
			display_name => {
				'one' => q(boliviano ya Bolivia),
				'other' => q(boliviano za Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Reale ya Brazili),
				'one' => q(reale ya Brazili),
				'other' => q(reale za Brazili),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dola ya Bahama),
				'one' => q(dola ya Bahama),
				'other' => q(dola za Bahama),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrumi ya Bhutani),
				'one' => q(ngultrumi ya Bhutani),
				'other' => q(ngultrumi za Bhutani),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Ruble ya Belarusi),
				'one' => q(ruble ya Belarusi),
				'other' => q(ruble za Belarusi),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dola ya Kanada),
				'one' => q(dola ya Kanada),
				'other' => q(dola za Kanada),
			},
		},
		'CLP' => {
			display_name => {
				'one' => q(peso ya Chile),
				'other' => q(peso za Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan ya China \(huru\)),
				'one' => q(yuan ya China \(huru\)),
				'other' => q(yuan ya China \(huru\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan ya China),
				'one' => q(yuan ya China),
				'other' => q(yuan za China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Eskudo ya Kepuvede),
				'one' => q(eskudo ya Kepuvede),
				'other' => q(eskudo za Kepuvede),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna ya Cheki),
				'one' => q(koruna ya Cheki),
				'other' => q(koruna za Cheki),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Kroni ya Denmaki),
				'one' => q(kroni ya Denmaki),
				'other' => q(kroni za Denmaki),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinari ya Aljeria),
				'one' => q(dinari ya Aljeria),
				'other' => q(dinari za Aljeria),
			},
		},
		'FKP' => {
			display_name => {
				'one' => q(pauni ya Visiwa vya Falkland),
				'other' => q(pauni za Visiwa vya Falkland),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari ya Jiojia),
				'one' => q(lari ya Jiojia),
				'other' => q(lari za Jiojia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Sidi ya Ghana),
				'one' => q(sidi ya Ghana),
				'other' => q(sidi za Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pauni ya Jibrata),
				'one' => q(pauni ya Jibrata),
				'other' => q(pauni za Jibrata),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna ya Kroeshia),
				'one' => q(kuna ya Kroeshia),
				'other' => q(kuna za Kroeshia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Godi ya Haiti),
				'one' => q(godi ya Haiti),
				'other' => q(godi za Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forinti ya Hungaria),
				'one' => q(forinti ya Hungaria),
				'other' => q(forinti za Hungaria),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupia ya Indonesia),
				'one' => q(rupia ya Indonesia),
				'other' => q(rupia za Indonesia),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Riali ya Irani),
				'one' => q(riali ya Irani),
				'other' => q(riali za Irani),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinari ya Yordani),
				'one' => q(dinari ya Yordani),
				'other' => q(dinari za Yordani),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ya Japani),
				'one' => q(yeni ya japani),
				'other' => q(yeni za japani),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Rieli ya Kambodia),
				'one' => q(rieli ya Kambodia),
				'other' => q(rieli za Kambodia),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge ya Kazakistani),
				'one' => q(tenge ya Kazakistani),
				'other' => q(tenge za Kazakistani),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pauni ya Lebanoni),
				'one' => q(pauni ya Lebanoni),
				'other' => q(pauni za Lebanoni),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Diramu ya Moroko),
				'one' => q(diramu ya Moroko),
				'other' => q(diramu za Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'one' => q(ariari ya Madagaska),
				'other' => q(Ariari za Madagaska),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dinari ya Masedonia),
				'one' => q(dinari ya Masedonia),
				'other' => q(dinari za Masedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kiati ya Myama),
				'one' => q(kiati ya Myama),
				'other' => q(kiati za Myama),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataka ya Macau),
				'one' => q(pataka ya Macau),
				'other' => q(pataka za Macau),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa ya Maldivi),
				'one' => q(rufiyaa ya Maldivi),
				'other' => q(rufiyaa za Maldivi),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgiti ya Malesia),
				'one' => q(ringgiti ya Malesia),
				'other' => q(ringgiti za Malesia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira ya Naijeria),
				'one' => q(naira ya Naijeria),
				'other' => q(Naira za Naijeria),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Kroni ya Norwe),
				'one' => q(kroni ya Norwe),
				'other' => q(kroni za Norwe),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupia ya Nepali),
				'one' => q(rupia ya Nepali),
				'other' => q(rupia za Nepali),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Riali ya Omani),
				'one' => q(riali ya Omani),
				'other' => q(riali za Omani),
			},
		},
		'PAB' => {
			display_name => {
				'one' => q(balboa ya Panama),
				'other' => q(balboa za Panama),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupia ya Pakistani),
				'one' => q(rupia ya Pakistani),
				'other' => q(rupia za Pakistani),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloti ya Polandi),
				'one' => q(zloti ya Polandi),
				'other' => q(zloti za Polandi),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riali ya Katari),
				'one' => q(riali ya Katari),
				'other' => q(riali za Katari),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinari ya Serbia),
				'one' => q(dinari ya Serbia),
				'other' => q(dinari za Serbia),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyali ya Saudia),
				'one' => q(riyali ya Saudia),
				'other' => q(riyali za Saudia),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dola ya Visiwa vya Solomoni),
				'one' => q(dola ya Visiwa vya Solomoni),
				'other' => q(dola za Visiwa vya Solomoni),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pauni ya Sudani),
				'one' => q(pauni ya Sudani),
				'other' => q(pauni za Sudani),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dola ya Singapoo),
				'one' => q(dola ya Singapoo),
				'other' => q(dola za Singapoo),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leoni ya Siera Leoni),
				'one' => q(leoni ya Siera Leoni),
				'other' => q(leoni za Siera Leoni),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pauni ya Sudani Kusini),
				'one' => q(pauni ya Sudani Kusini),
				'other' => q(pauni za Sudani Kusini),
			},
		},
		'SZL' => {
			display_name => {
				'one' => q(lilangeni ya Uswazi),
				'other' => q(lilangeni za Uswazi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Bahti ya Tailandi),
				'one' => q(bahti ya Tailandi),
				'other' => q(bahti za Tailandi),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni ya Tajikistani),
				'one' => q(somoni ya Tajikistani),
				'other' => q(somoni za Tajikistani),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manati ya Turkmenistani),
				'one' => q(manati ya Turkmenistani),
				'other' => q(manati za Turkmenistani),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dola ya Trinidadi na Tobago),
				'one' => q(dola ya Trinidadi na Tobago),
				'other' => q(dola za Trinidadi na Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dola ya Taiwani),
				'one' => q(dola ya Taiwani),
				'other' => q(dola za Taiwani),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia ya Ukraini),
				'one' => q(hryvnia ya Ukraini),
				'other' => q(hryvnia za Ukraini),
			},
		},
		'USD' => {
			symbol => '$',
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som ya Uzbekistani),
				'one' => q(som ya Uzbekistani),
				'other' => q(som za Uzbekistani),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Boliva ya Venezuela),
				'one' => q(boliva ya Venezuele),
				'other' => q(boliva za Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong ya Vietnamu),
				'one' => q(dong ya Vietnamu),
				'other' => q(Dong za Vietnamu),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranga ya CFA ya Afrika ya Kati),
				'one' => q(faranga ya CFA ya Afrika ya Kati),
				'other' => q(faranga ya CFA ya Afrika ya Kati),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga ya CFA ya Afrika Magharibi),
				'one' => q(faranga ya CFA ya Afrika Magharibi),
				'other' => q(faranga za CFA ya Afrika Magharibi),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Sarafu Isiyojulikana),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Riali ya Yemeni),
				'one' => q(riali ya Yemeni),
				'other' => q(riali za Yemeni),
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
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
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

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
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
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} 'saa' {0}},
			'long' => q{{1} 'saa' {0}},
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
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Afghanistan' => {
			long => {
				'standard' => q#Saa za Afghanistani#,
			},
		},
		'America/Barbados' => {
			exemplarCity => q#Babadosi#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Elsalvado#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Martinique' => {
			exemplarCity => q#Matinikiu#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota Kaskazini#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota Kaskazini#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota Kaskazini#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Bandari ya au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Bandari ya Uhispania#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makwuarie#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Saa za Majira Joto za Ajentina#,
				'generic' => q#Saa za Ajentina#,
				'standard' => q#Saa za Wastani za Ajentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Magharibi mwa Ajentina#,
				'generic' => q#Saa za Magharibi mwa Ajentina#,
				'standard' => q#Saa za Wastani za Magharibi mwa Ajentina#,
			},
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Jiji la Ho Chi Minh#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapoo#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bamuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Saa za Mchana za Magharibi mwa Australia ya Kati#,
				'generic' => q#Saa za Magharibi mwa Austrialia ya Kati#,
				'standard' => q#Saa za Wastani za Magharibi mwa Australia ya Kati#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Azabajani#,
				'generic' => q#Saa za Azabajani#,
				'standard' => q#Saa za Wastani za Azabajani#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Bangladeshi#,
				'generic' => q#Saa za Bangladeshi#,
				'standard' => q#Saa za Wastani za Bangladeshi#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Saa za Butani#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Brazili#,
				'generic' => q#Saa za Brazili#,
				'standard' => q#Saa za Wastani za Brazili#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kepuvede#,
				'generic' => q#Saa za Kepuvede#,
				'standard' => q#Saa za Wastani za Kepuvede#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kolombia#,
				'generic' => q#Saa za Kolombia#,
				'standard' => q#Saa za Wastani za Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Saa za Majira Nusu ya Joto za Visiwa vya Cook#,
				'generic' => q#Saa za Visiwa vya Cook#,
				'standard' => q#Saa za Wastani za Visiwa vya Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Saa za Mchana za Kuba#,
				'generic' => q#Saa za Kuba#,
				'standard' => q#Saa za Wastani za Kuba#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kisiwa cha Easter#,
				'generic' => q#Saa za Kisiwa cha Easter#,
				'standard' => q#Saa za Wastani za Kisiwa cha Easter#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Saa ya Ulimwenguni#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Saa za Guiana#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Jiojia#,
				'generic' => q#Saa za Jiojia#,
				'standard' => q#Saa za Wastani za Jiojia#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Saa za Wastani za Ghuba#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Krismasi#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivi#,
		},
		'Iran' => {
			long => {
				'daylight' => q#Saa za Mchana za Irani#,
				'generic' => q#Saa za Irani#,
				'standard' => q#Saa za Wastani za Irani#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Saa za Mchana za Japani#,
				'generic' => q#Saa za Japani#,
				'standard' => q#Saa za Wastani za Japani#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Saa za Kazakistani Mashariki#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Saa za Kazakistani Magharibi#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Saa za Makwuarie#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Saa za Malesia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Saa za Maldivi#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Saa za Mchana za Kaskazini Magharibi mwa Meksiko#,
				'generic' => q#Saa za Kaskazini Magharibi mwa Meksiko#,
				'standard' => q#Saa za Wastani za Kaskazini Magharibi mwa Meksiko#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Ulaanbaatar#,
				'generic' => q#Saa za Ulaanbataar#,
				'standard' => q#Saa za Wastani za Ulaanbataar#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Saa za Myama#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Saa za Nepali#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kaledonia Mpya#,
				'generic' => q#Saa za Kaledonia Mpya#,
				'standard' => q#Saa za Wastani za Kaledonia Mpya#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Saa za Mchana za Nyuzilandi#,
				'generic' => q#Saa za Nyuzilandi#,
				'standard' => q#Saa za Wastani za Nyuzilandi#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Pakistani#,
				'generic' => q#Saa za Pakistani#,
				'standard' => q#Saa za Wastani za Pakistani#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Saa za Papua#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Paragwai#,
				'generic' => q#Saa za Paragwai#,
				'standard' => q#Saa za Wastani za Paragwai#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Saa za Visiwa vya Finiksi#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Saa za Wastani za Singapoo#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Saa za Jojia Kusini#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Saaza Tajikistani#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Turkmenistani#,
				'generic' => q#Saa za Turkmenistani#,
				'standard' => q#Saa za Wastani za Turkmenistani#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Urugwai#,
				'generic' => q#Saa za Uruagwai#,
				'standard' => q#Saa za Wastani za Urugwai#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Uzbekistani#,
				'generic' => q#Saa za Uzbekistani#,
				'standard' => q#Saa za wastani za Uzbekistani#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
