=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Za - Package for language Zhuang

=cut

package Locale::CLDR::Locales::Za;
# This file auto generated from Data\common\main\za.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'Vah Ahlahbwz',
 				'az' => 'Vah Ahsaibaigyangh',
 				'be' => 'Vah Bwzngozlozswh',
 				'bg' => 'Vah Baujgyahliya',
 				'bn' => 'Vah Munggyahlah',
 				'bo' => 'Cangyij',
 				'bs' => 'Vah Bohswhnizya',
 				'ca' => 'Vah Gyahdailoznizya',
 				'cs' => 'Vah Cezgwz',
 				'da' => 'Vah Danhmwz',
 				'de' => 'Dwzyij',
 				'el' => 'Vah Hihlaz',
 				'en' => 'Yinghyij',
 				'eo' => 'Sigaiyij',
 				'es' => 'Vah Sihbanhyaz',
 				'et' => 'Vah Aisahnizya',
 				'eu' => 'Vah Bahswhgwz',
 				'fa' => 'Vah Bohswh',
 				'fi' => 'Vah Fwnhlanz',
 				'fil' => 'Vah Feihlizbinh',
 				'fj' => 'Vah Feijci',
 				'fo' => 'Vah Fazloz',
 				'fr' => 'Fazyij',
 				'ga' => 'Vah Aiwjlanz',
 				'gl' => 'Vah Gyahlisihya',
 				'haw' => 'Vah Yaveihyiz',
 				'he' => 'Vah Hihbwzlaiz',
 				'hi' => 'Vah Yindi',
 				'hmn' => 'Myauzyij',
 				'hr' => 'Vah Gwzlozdiya',
 				'hu' => 'Vah Yunghyazli',
 				'hy' => 'Vah Yameijnizya',
 				'id' => 'Vah Yindunizsihya',
 				'is' => 'Vah Binghdauj',
 				'it' => 'Vah Yidali',
 				'ja' => 'Yizyij',
 				'jbo' => 'Vah Lozciz',
 				'ka' => 'Vah Gwzlujgizya',
 				'kk' => 'Vah Hahsahgwz',
 				'km' => 'Vah Gauhmenz',
 				'ko' => 'Hanzyij',
 				'ky' => 'Vah Gizwjgizswh',
 				'la' => 'Vah Lahdingh',
 				'lb' => 'Vah Luzswnhbauj',
 				'lo' => 'Vah Laojvoh',
 				'lt' => 'Vah Lizdauzvanj',
 				'lv' => 'Vah Lahdozveizya',
 				'mi' => 'Vah Mauzli',
 				'mn' => 'Vah Mungzguj',
 				'ms' => 'Vah Majlaiz',
 				'mt' => 'Vah Majwjdah',
 				'my' => 'Vah Menjden',
 				'ne' => 'Vah Nizbozwj',
 				'nl' => 'Vah Hozlanz',
 				'no' => 'Vah Nozveih',
 				'pl' => 'Vah Bohlanz',
 				'pt' => 'Vah Buzdauzyaz',
 				'ro' => 'Vah Lozmajnizya',
 				'ru' => 'Ngozyij',
 				'sa' => 'Fanzyij',
 				'sk' => 'Vah Swhlozfazgwz',
 				'sl' => 'Vah Swhlozvwnznizya',
 				'sm' => 'Vah Sazmozya',
 				'so' => 'Vah Sozmajlij',
 				'sq' => 'Vah Ahwjbahnizya',
 				'sr' => 'Saiwjveizya',
 				'sv' => 'Vah Suidenj',
 				'sw' => 'Vah swhvajhihlij',
 				'tg' => 'Vah Dazgizgwz',
 				'th' => 'Daiyij',
 				'tk' => 'Vah Dujguman',
 				'tr' => 'Vah Dujwjgiz',
 				'ug' => 'Vah Veizvuzwj',
 				'uk' => 'Vah Vuhgwzlanz',
 				'und' => 'Vah caengz rox',
 				'uz' => 'Vah Vuhsihbezgwz',
 				'vi' => 'Vah Yeznanz',
 				'yue' => 'Yezyij',
 				'za' => 'Vahcuengh',
 				'zh' => 'Vahgun',
 				'zh@alt=menu' => 'Bujdunghva',

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
			'Arab' => 'Saw Ahlahbwz',
 			'Bopo' => 'Cuyinh Fuzhau',
 			'Brai' => 'Sawmengz',
 			'Grek' => 'Saw Hihlaz',
 			'Hani' => 'Sawgun',
 			'Jpan' => 'Yizvwnz',
 			'Kore' => 'Hanzvwnz',
 			'Laoo' => 'Saw Laojvoh',
 			'Latn' => 'Lahdinghvwnz',
 			'Mong' => 'Saw Mungzguj',
 			'Thai' => 'Daivwnz',
 			'Tibt' => 'Cangvwnz',
 			'Zsym' => 'Fouzhauh',
 			'Zyyy' => 'Doengyungh',
 			'Zzzz' => 'Saw caengz rox',

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
			'001' => 'seiqgyaiq',
 			'002' => 'Feihcouh',
 			'003' => 'Bwz Meijcouh',
 			'005' => 'Nanz Meijcouh',
 			'009' => 'Dayangzcouh',
 			'011' => 'Sih Feih',
 			'013' => 'Cungh Meijcouh',
 			'014' => 'Dungh Feih',
 			'015' => 'Bwz Feih',
 			'017' => 'Cungh Feih',
 			'018' => 'Nanz Feihcouh',
 			'019' => 'Meijcouh',
 			'029' => 'Dieg Gyahlwzbij',
 			'030' => 'Dungh Ya',
 			'034' => 'Nanz Ya',
 			'035' => 'Dunghnanzya',
 			'039' => 'Nanz Ouh',
 			'142' => 'Yacouh',
 			'143' => 'Cungh Ya',
 			'145' => 'Sih Ya',
 			'150' => 'Ouhcouh',
 			'151' => 'Dungh Ouh',
 			'154' => 'Bwz Ouh',
 			'155' => 'Sih Ouh',
 			'419' => 'Lahdingh Meihcouh',
 			'AD' => 'Anhdauwj',
 			'AE' => 'Azlenzciuz',
 			'AF' => 'Ahfuhan',
 			'AI' => 'Anhgveihlah',
 			'AL' => 'Ahwjbahnizya',
 			'AM' => 'Yameijnizya',
 			'AO' => 'Anhgohlah',
 			'AR' => 'Ahgwnhdingz',
 			'AT' => 'Audili',
 			'AU' => 'Audaliya',
 			'AW' => 'Ahlujbah',
 			'AZ' => 'Ahsaibaigyangh',
 			'BA' => 'Bohswhnizya caeuq Hwzsaigohveizna',
 			'BB' => 'Bahbahdohswh',
 			'BD' => 'Munggyahlahgoz',
 			'BE' => 'Bijlisiz',
 			'BG' => 'Baujgyahliya',
 			'BH' => 'Bahlinz',
 			'BJ' => 'Beiningz',
 			'BM' => 'Bwzmuda',
 			'BN' => 'Vwnzlaiz',
 			'BO' => 'Bohliveizya',
 			'BR' => 'Bahsih',
 			'BS' => 'Bahhahmaj',
 			'BT' => 'Budanh',
 			'BW' => 'Bozswvajnaz',
 			'BY' => 'Bwzngozlozswh',
 			'BZ' => 'Bwzlizswh',
 			'CA' => 'Gyahnazda',
 			'CH' => 'Suisw',
 			'CL' => 'Cili',
 			'CM' => 'Gahmwzlungz',
 			'CN' => 'Cunghgoz',
 			'CO' => 'Gohlunzbijya',
 			'CR' => 'Gohswhdazlizgyah',
 			'CU' => 'Gujbah',
 			'CV' => 'Fozdwzgoz',
 			'CY' => 'Saibujluswh',
 			'CZ' => 'Cezgwz',
 			'DE' => 'Dwzgoz',
 			'DK' => 'Danhmwz',
 			'DM' => 'Dohmijnizgwz',
 			'DO' => 'Dohmijnizgyah Gunghozgoz',
 			'DZ' => 'Ahwjgizliya',
 			'EC' => 'Ngwzgyahdohwj',
 			'EE' => 'Aisahnizya',
 			'EG' => 'Aihgiz',
 			'EH' => 'Sih Sahhahlah',
 			'ES' => 'Sihbanhyaz',
 			'ET' => 'Aihsaiwzbizya',
 			'EU' => 'Ouhmungz',
 			'FI' => 'Fwnhlanz',
 			'FJ' => 'Feijci',
 			'FR' => 'Fazgoz',
 			'GA' => 'Gyahbungz',
 			'GB' => 'Yinghgoz',
 			'GD' => 'Gwzlinznazdaz',
 			'GE' => 'Gwzlujgizya',
 			'GH' => 'Gyahnaz',
 			'GI' => 'Cizbulozdoz',
 			'GL' => 'Gwzlingzlanz',
 			'GM' => 'Ganghbijya',
 			'GN' => 'Gijneiya',
 			'GQ' => 'Cizdau Gijneiya',
 			'GR' => 'Hihlaz',
 			'GT' => 'Veizdimajlah',
 			'GU' => 'Gvanhdauj',
 			'GW' => 'Gijneiyabijsau',
 			'GY' => 'Gveihyana',
 			'HK' => 'Yanghgangj Dwzbez Hingzcwnggih Cunghgoz',
 			'HK@alt=short' => 'Yanghgangj',
 			'HN' => 'Hungzduhlahswh',
 			'HR' => 'Gwzlozdiya',
 			'HT' => 'Haijdi',
 			'HU' => 'Yunghyazli',
 			'ID' => 'Yindunizsihya',
 			'IE' => 'Aiwjlanz',
 			'IL' => 'Yijswzlez',
 			'IN' => 'Yindu',
 			'IQ' => 'Yihlahgwz',
 			'IR' => 'Yihlangj',
 			'IS' => 'Binghdauj',
 			'IT' => 'Yidali',
 			'JM' => 'Yazmaijgyah',
 			'JO' => 'Yozdan',
 			'JP' => 'Yizbwnj',
 			'KE' => 'Gwnjnizya',
 			'KG' => 'Gizwjgizswhswhdanj',
 			'KH' => 'Genjbujsai',
 			'KM' => 'Gohmozloz',
 			'KP' => 'Cauzsenh',
 			'KR' => 'Hanzgoz',
 			'KW' => 'Gohveihdwz',
 			'KZ' => 'Hahsahgwzswhdanj',
 			'LA' => 'Laojvoh',
 			'LB' => 'Lizbahnwn',
 			'LI' => 'Lezcihdunhswdwngh',
 			'LK' => 'Swhlijlanzgaj',
 			'LR' => 'Libijlijya',
 			'LS' => 'Laizsozdoz',
 			'LT' => 'Lizdauzvanj',
 			'LU' => 'Luzswnhbauj',
 			'LV' => 'Lahdozveizya',
 			'LY' => 'Libijya',
 			'MA' => 'Mohlozgoh',
 			'MC' => 'Mohnazgoh',
 			'MD' => 'Mohwjdohvaj',
 			'ME' => 'Hwzsanh',
 			'MG' => 'Majdazgyahswhgyah',
 			'MK' => 'Bwz Majgizdun',
 			'ML' => 'Majlij',
 			'MM' => 'Menjden',
 			'MN' => 'Mungzguj',
 			'MO' => 'Aumwnz Dwzbez Hingzcwnggih Cunghgoz',
 			'MO@alt=short' => 'Aumwnz',
 			'MR' => 'Mauzlijdaznizya',
 			'MT' => 'Majwjdah',
 			'MV' => 'Majwjdaifuh',
 			'MW' => 'Majlahveiz',
 			'MX' => 'Mwzsihgoh',
 			'MY' => 'Majlaizsihya',
 			'NA' => 'Nazmijbijya',
 			'NE' => 'Nizyizwj',
 			'NG' => 'Nizyizliyah',
 			'NI' => 'Nizgyahlahgvah',
 			'NL' => 'Hozlanz',
 			'NO' => 'Nozveih',
 			'NP' => 'Nizbozwj',
 			'NR' => 'Naujluj',
 			'NU' => 'Niujaih',
 			'NZ' => 'Sinhsihlanz',
 			'OM' => 'Ahman',
 			'PA' => 'Bahnazmaj',
 			'PE' => 'Biluj',
 			'PG' => 'Bahbuyasinhgijneiya',
 			'PH' => 'Feihlizbinh',
 			'PK' => 'Bahgihswhdanj',
 			'PL' => 'Bohlanz',
 			'PR' => 'Bohdohlizgoz',
 			'PS' => 'Dieg Bahlwzswhdanj',
 			'PS@alt=short' => 'Bahlwzswhdanj',
 			'PT' => 'Buzdauzyaz',
 			'PW' => 'Bwzlauh',
 			'PY' => 'Bahlahgveih',
 			'QA' => 'Gajdajwj',
 			'RO' => 'Lozmajnizya',
 			'RS' => 'Saiwjveizya',
 			'RU' => 'Ngozlozswh',
 			'RW' => 'Luzvangdaz',
 			'SA' => 'Sahdwz Ahlahbwz',
 			'SD' => 'Suhdanh',
 			'SE' => 'Suidenj',
 			'SG' => 'Sinhgyahboh',
 			'SH' => 'Swnghwzlwznaz',
 			'SI' => 'Swhlozvwnznizya',
 			'SK' => 'Swhlozfazgwz',
 			'SM' => 'Swngmajlinoz',
 			'SN' => 'Saineigyahwj',
 			'SO' => 'Sozmajlij',
 			'SR' => 'Suhlijnanz',
 			'SS' => 'Nanz Suhdanh',
 			'SV' => 'Sazwjvajdoh',
 			'SY' => 'Siliya',
 			'SZ' => 'Swhveihswlanz',
 			'TD' => 'Cadwz',
 			'TG' => 'Dohgoh',
 			'TH' => 'Daigoz',
 			'TJ' => 'Dazgizgwzswhdanj',
 			'TL' => 'Dunghdivwn',
 			'TM' => 'Dujgumanswhdanj',
 			'TN' => 'Duznizswh',
 			'TO' => 'Tanghgyah',
 			'TR' => 'Dujwjgiz',
 			'TW' => 'Daizvanh',
 			'TZ' => 'Dajsanghnizya',
 			'UA' => 'Vuhgwzlanz',
 			'UG' => 'Vuhganhdaz',
 			'UN' => 'Lenzhozgoz',
 			'US' => 'Meijgoz',
 			'UY' => 'Vuhlahgveih',
 			'UZ' => 'Vuhsihbezgwzswhdanj',
 			'VA' => 'Fanzdigangh',
 			'VE' => 'Veijneisuilah',
 			'VN' => 'Yeznanz',
 			'VU' => 'Vajnujahduz',
 			'WS' => 'Sazmozya',
 			'XK' => 'Gohsozvo',
 			'YE' => 'Yejmwnz',
 			'ZA' => 'Nanz Feih',
 			'ZM' => 'Canbijya',
 			'ZW' => 'Cinhbahbuveiz',

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
 				'chinese' => q{liggaeuq},
 				'gregorian' => q{ligmoq},
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
			'metric' => q{gunghci},
 			'UK' => q{yinghci},
 			'US' => q{meijci},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Vah: {0}',
 			'script' => 'Saw: {0}',
 			'region' => 'Dieg: {0}',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'name' => q(cujfanghyang),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(cujfanghyang),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(fanghyang),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(fanghyang),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(dunghgingh {0}),
						'north' => q(bwzveij {0}),
						'south' => q(nanzveij {0}),
						'west' => q(sihgingh {0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(dunghgingh {0}),
						'north' => q(bwzveij {0}),
						'south' => q(nanzveij {0}),
						'west' => q(sihgingh {0}),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} caeuq {1}),
				2 => q({0} caeuq {1}),
		} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'CNH' => {
			display_name => {
				'currency' => q(yinzminzbi \(lizan\)),
			},
		},
		'CNY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(yinzminzbi),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(meijyenz),
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
					wide => {
						nonleap => [
							'ndwenit',
							'ndwenngeih',
							'ndwensam',
							'ndwenseiq',
							'ndwenngux',
							'ndwenloeg',
							'ndwencaet',
							'ndwenbet',
							'ndwengouj',
							'ndwencib',
							'ndwencib’it',
							'ndwencibngeih'
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
					wide => {
						mon => 'singhgizit',
						tue => 'singhgizngeih',
						wed => 'singhgizsam',
						thu => 'singhgizseiq',
						fri => 'singhgizhaj',
						sat => 'singhgizroek',
						sun => 'ngoenzsinghgiz'
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
					'am' => q{banhaet},
					'pm' => q{banringzgvaq},
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
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Hmsv => q{v HH:mm:ss},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			hmsv => q{v a h:mm:ss},
			yMMMd => q{'bi' y 'ndwen' M 'ngoenz' d},
			yMd => q{y/M/d},
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
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Sizgenh),
		regionFormat => q({0} Yaling Sizgenh),
		regionFormat => q({0} Byauhcunj Sizgenh),
		'GMT' => {
			long => {
				'standard' => q#Gwzlinzveihci Byauhcunj Sizgenh#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
