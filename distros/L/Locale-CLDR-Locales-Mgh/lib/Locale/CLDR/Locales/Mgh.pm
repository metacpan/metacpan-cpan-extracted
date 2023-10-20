=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mgh - Package for language Makhuwa-Meetto

=cut

package Locale::CLDR::Locales::Mgh;
# This file auto generated from Data\common\main\mgh.xml
#	on Fri 13 Oct  9:26:41 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
				'ak' => 'Ikan',
 				'am' => 'Imhari',
 				'ar' => 'Iarabu',
 				'be' => 'Ibelausi',
 				'bg' => 'Ibulgaria',
 				'bn' => 'Ibangla',
 				'cs' => 'Icheki',
 				'de' => 'Ijerimani',
 				'el' => 'Igiriki',
 				'en' => 'Ingilishi',
 				'es' => 'Ihispaniola',
 				'fa' => 'Iajemi',
 				'fr' => 'Ifaransa',
 				'ha' => 'Ihausa',
 				'hi' => 'Ihindi',
 				'hu' => 'Ihungari',
 				'ig' => 'Igbo',
 				'it' => 'Italiano',
 				'ja' => 'Ijapani',
 				'jv' => 'Ijava',
 				'km' => 'Ikambodia',
 				'ko' => 'Ikorea',
 				'mgh' => 'Makua',
 				'ms' => 'Imalesia',
 				'my' => 'Iburma',
 				'ne' => 'Inepali',
 				'nl' => 'Iholanzi',
 				'pa' => 'Ipunjabi',
 				'pl' => 'Ipolandi',
 				'pt' => 'Nreno',
 				'ro' => 'Iromania',
 				'ru' => 'Irisi',
 				'rw' => 'Inyaranda',
 				'so' => 'Isomali',
 				'sv' => 'Iswidi',
 				'ta' => 'Itamil',
 				'th' => 'Itailandi',
 				'tr' => 'Ituruki',
 				'uk' => 'Iukran',
 				'ur' => 'Ihurdu',
 				'vi' => 'Ivyetinamu',
 				'yo' => 'Iyoruba',
 				'zh' => 'Ichina',
 				'zu' => 'Izulu',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'AD' => 'Uandora',
 			'AF' => 'Ufugustani',
 			'AL' => 'Ualbania',
 			'AS' => 'Usamoa ya Marekani',
 			'AZ' => 'Uazabajani',
 			'BI' => 'Urundi',
 			'BJ' => 'Ubelin',
 			'CA' => 'Ukanada',
 			'CG' => 'Ukongo',
 			'CH' => 'Uswisi',
 			'CI' => 'Ukodiva',
 			'CL' => 'Uchile',
 			'CN' => 'Uchina',
 			'CO' => 'Ukolombia',
 			'CU' => 'Ukuba',
 			'CY' => 'Ukuprosi',
 			'CZ' => 'Ucheki',
 			'DJ' => 'Ujibuti',
 			'DK' => 'Udenimaka',
 			'DM' => 'Udominika',
 			'DZ' => 'Alujeria',
 			'EG' => 'Umisiri',
 			'ER' => 'Uriterea',
 			'ES' => 'Uhispania',
 			'ET' => 'Uhabeshi',
 			'FI' => 'Ufini',
 			'FJ' => 'Ufiji',
 			'FR' => 'Ufaransa',
 			'GA' => 'Ugaboni',
 			'GD' => 'Ugrenada',
 			'GE' => 'Ujojia',
 			'GF' => 'Ufaransa yo Gwaya',
 			'GH' => 'Ugana',
 			'GI' => 'Ujibralta',
 			'GL' => 'Ugrinlandi',
 			'GM' => 'Ugambia',
 			'GN' => 'Ugine',
 			'GP' => 'Ugwadelupe',
 			'GT' => 'Ugwatemala',
 			'GU' => 'Ugwam',
 			'GW' => 'Uginebisau',
 			'GY' => 'Uguyana',
 			'HN' => 'Uhondurasi',
 			'HR' => 'Ukorasia',
 			'HT' => 'Uhaiti',
 			'HU' => 'Uhungaria',
 			'ID' => 'Undonesia',
 			'IE' => 'Uayalandi',
 			'IL' => 'Uisraeli',
 			'IN' => 'Uhindini',
 			'IQ' => 'Wiraki',
 			'IT' => 'Italia',
 			'JM' => 'Ujamaika',
 			'JO' => 'Uyordani',
 			'JP' => 'Ujapani',
 			'KE' => 'Ukenya',
 			'KH' => 'Ukambodia',
 			'KM' => 'Ukomoro',
 			'KN' => 'Usantakitzi na Nevis',
 			'KP' => 'Ukorea Kaskazini',
 			'KR' => 'Ukorea Kusini',
 			'KZ' => 'Ukazakistani',
 			'LB' => 'Ulebanoni',
 			'LC' => 'Usantalusia',
 			'LI' => 'Ushenteni',
 			'LK' => 'Usirilanka',
 			'LR' => 'Uliberia',
 			'LS' => 'Ulesoto',
 			'LT' => 'Utwania',
 			'LU' => 'Usembaji',
 			'LV' => 'Ulativia',
 			'LY' => 'Ulibya',
 			'ME' => 'Umantegro',
 			'MG' => 'Ubukini',
 			'MK' => 'Umasedonia',
 			'MW' => 'Umalawi',
 			'MZ' => 'Umozambiki',
 			'NE' => 'Unijeri',
 			'NG' => 'Unijeria',
 			'NO' => 'Unorwe',
 			'OM' => 'Uomani',
 			'PA' => 'Upanama',
 			'PE' => 'Uperuu',
 			'PF' => 'Ufaransa yo Potina',
 			'PG' => 'Upapua',
 			'PH' => 'Ufilipino',
 			'PK' => 'Upakistani',
 			'PL' => 'Upolandi',
 			'PM' => 'Usantapieri na Mikeloni',
 			'PN' => 'Upitkairni',
 			'PR' => 'Upwetoriko',
 			'PY' => 'Paragwai',
 			'QA' => 'Ukatari',
 			'RE' => 'Uriyunioni',
 			'RO' => 'Uromania',
 			'RW' => 'Urwanda',
 			'SA' => 'Usaudi',
 			'SC' => 'Ushelisheli',
 			'SD' => 'Usudani',
 			'SE' => 'Uswidi',
 			'SG' => 'Usingapoo',
 			'SH' => 'Usantahelena',
 			'SI' => 'Uslovenia',
 			'SK' => 'Uslovakia',
 			'SM' => 'Usamarino',
 			'SN' => 'Usenegali',
 			'SO' => 'Usomalia',
 			'SR' => 'Usurinamu',
 			'ST' => 'Usao Tome na Principe',
 			'SV' => 'Usalavado',
 			'SY' => 'Usiria',
 			'SZ' => 'Uswazi',
 			'TD' => 'Uchadi',
 			'TG' => 'Utogo',
 			'TH' => 'Utailandi',
 			'TJ' => 'Ujikistani',
 			'TK' => 'Utokelau',
 			'TL' => 'Utimo Mashariki',
 			'TM' => 'Uturukimenistani',
 			'TN' => 'Utunisia',
 			'TO' => 'Utonga',
 			'TR' => 'Utuki',
 			'TT' => 'Utrinidad na Tobago',
 			'TV' => 'Utuvalu',
 			'TZ' => 'Utanzania',
 			'US' => 'Umarekani',
 			'VA' => 'Uvatikani',
 			'VC' => 'Usantavisenti na Grenadini',
 			'VE' => 'Uvenezuela',
 			'VN' => 'Uvietinamu',
 			'VU' => 'Uvanuatu',
 			'WF' => 'Uwalis na Futuna',
 			'WS' => 'Usamoa',
 			'YE' => 'Uyemeni',
 			'ZA' => 'Afrika du Sulu',
 			'ZM' => 'Uzambia',
 			'ZW' => 'Uzimbabwe',

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
			auxiliary => qr{[q x]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p r s t u v w y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:eyo|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:akin’tuna|a|no|n)$' }
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

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'MZN' => {
			symbol => 'MTn',
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
							'Kwa',
							'Una',
							'Rar',
							'Che',
							'Tha',
							'Moc',
							'Sab',
							'Nan',
							'Tis',
							'Kum',
							'Moj',
							'Yel'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mweri wo kwanza',
							'Mweri wo unayeli',
							'Mweri wo uneraru',
							'Mweri wo unecheshe',
							'Mweri wo unethanu',
							'Mweri wo thanu na mocha',
							'Mweri wo saba',
							'Mweri wo nane',
							'Mweri wo tisa',
							'Mweri wo kumi',
							'Mweri wo kumi na moja',
							'Mweri wo kumi na yel’li'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'K',
							'U',
							'R',
							'C',
							'T',
							'M',
							'S',
							'N',
							'T',
							'K',
							'M',
							'Y'
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
						mon => 'Jtt',
						tue => 'Jnn',
						wed => 'Jtn',
						thu => 'Ara',
						fri => 'Iju',
						sat => 'Jmo',
						sun => 'Sab'
					},
					wide => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Arahamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Sabato'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'J',
						tue => 'J',
						wed => 'J',
						thu => 'A',
						fri => 'I',
						sat => 'J',
						sun => 'S'
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
					'am' => q{wichishu},
					'pm' => q{mchochil’l},
				},
				'wide' => {
					'am' => q{wichishu},
					'pm' => q{mchochil’l},
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
				'0' => 'HY',
				'1' => 'YY'
			},
			wide => {
				'0' => 'Hinapiya yesu',
				'1' => 'Yopia yesu'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
		},
		'gregorian' => {
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
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMd => q{MMM d},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d, y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E d},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMd => q{MMM d},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d, y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
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

no Moo;

1;

# vim: tabstop=4
