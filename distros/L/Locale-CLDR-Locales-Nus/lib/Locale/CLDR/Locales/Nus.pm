=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Nus - Package for language Nuer

=cut

package Locale::CLDR::Locales::Nus;
# This file auto generated from Data\common\main\nus.xml
#	on Fri 13 Oct  9:32:27 am GMT

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
				'ak' => 'Thok aka̱ni',
 				'am' => 'Thok bunyni',
 				'ar' => 'Thok Jalabni',
 				'be' => 'Thok bälärutha',
 				'bg' => 'Thok bälga̱a̱riani',
 				'bn' => 'Thok bängali',
 				'cs' => 'Thok cik',
 				'de' => 'Thok jarmani',
 				'el' => 'Thok girikni',
 				'en' => 'Thok liŋli̱thni',
 				'es' => 'Thok i̱thpaaniani',
 				'fa' => 'Thok perthiani',
 				'fr' => 'Thok pɔrɔthani',
 				'ha' => 'Thok ɣowthani',
 				'hi' => 'Thok ɣändini',
 				'hu' => 'Thok ɣänga̱a̱riɛni',
 				'id' => 'Thok indunithiani',
 				'ig' => 'Thok i̱gboni',
 				'it' => 'Thok i̱taliani',
 				'ja' => 'Thok japanni',
 				'jv' => 'Thok jabanithni',
 				'km' => 'Thok kameeri',
 				'ko' => 'Thok kuriani',
 				'ms' => 'Thok mayɛyni',
 				'my' => 'Thok bormi̱thni',
 				'ne' => 'Thok napalni',
 				'nl' => 'Thok da̱c',
 				'nus' => 'Thok Nath',
 				'pa' => 'Thok puɔnjabani',
 				'pl' => 'Thok pölicni',
 				'pt' => 'Thok puɔtigali',
 				'ro' => 'Thok ji̱ röm',
 				'ru' => 'Thok ra̱ciaani',
 				'rw' => 'Thok ruaandani',
 				'so' => 'Thok thomaaliani',
 				'sv' => 'Thok i̱thwidicni',
 				'ta' => 'Thok tamilni',
 				'th' => 'Thok tayni',
 				'tr' => 'Thok turkicni',
 				'uk' => 'Thok ukeraanini',
 				'ur' => 'Thok udoni',
 				'vi' => 'Thok betnaamni',
 				'yo' => 'Thok yurubani',
 				'zh' => 'Thok cayna',
 				'zu' => 'Thok dhuluni',

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
			'AD' => 'Andora',
 			'AF' => 'Abganithtan',
 			'AG' => 'Antiguaa kɛnɛ Barbuda',
 			'AI' => 'Aŋguɛla',
 			'AL' => 'Albänia',
 			'AM' => 'Aɛrmänia',
 			'AO' => 'Aŋgola',
 			'AR' => 'Aɛrgentin',
 			'AS' => 'Amerika thamow',
 			'AT' => 'Athtɛria',
 			'AU' => 'Athɔra̱lia',
 			'AW' => 'Aruba',
 			'AZ' => 'Adhe̱rbe̱ja̱n',
 			'BA' => 'Bothnia kɛnɛ ɣärgobinia',
 			'BB' => 'Bärbadoth',
 			'BD' => 'Bengeladiec',
 			'BE' => 'Be̱lgim',
 			'BF' => 'Burkinɛ pa̱thu',
 			'BG' => 'Bulga̱a̱ria',
 			'BH' => 'Ba̱reen',
 			'BI' => 'Burundi',
 			'BJ' => 'Be̱ni̱n',
 			'BM' => 'Be̱rmudaa',
 			'BN' => 'Burunɛy',
 			'BO' => 'Bulibia',
 			'BR' => 'Bäraadhiil',
 			'BS' => 'Bämuɔth',
 			'BT' => 'Buta̱n',
 			'BW' => 'Bothiwaana',
 			'BY' => 'Be̱lɛruth',
 			'BZ' => 'Bilidha',
 			'CA' => 'Känɛda',
 			'CF' => 'Cɛntrɔl aprika repuɔblic',
 			'CG' => 'Kɔŋgɔ',
 			'CI' => 'Kodibo̱o̱',
 			'CK' => 'Kuk ɣa̱ylɛn',
 			'CL' => 'Cili̱',
 			'CM' => 'Kɛmɛrun',
 			'CN' => 'Cayna',
 			'CO' => 'Kolombia',
 			'CR' => 'Kothtirika',
 			'CV' => 'Kɛp bedi ɣa̱ylɛn',
 			'DZ' => 'Algeria',
 			'HR' => 'Korwaatia',
 			'IO' => 'Burutic ɣe̱ndian oce̱n',
 			'KH' => 'Kombodia',
 			'KM' => 'Komruth',
 			'KY' => 'Kaymɛn ɣa̱ylɛn',
 			'SD' => 'Sudan',
 			'TD' => 'Ca̱d',
 			'VG' => 'Burutic dhuɔ̱ɔ̱l be̱rgin',

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
			index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'Ɣ', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a ä {a̱} b c d e ë {e̱} ɛ {ɛ̈} {ɛ̱} {ɛ̱̈} f g ɣ h i ï {i̱} j k l m n ŋ o ö {o̱} ɔ {ɔ̈} {ɔ̱} p q r s t u v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'Ɣ', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
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

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ɣää|Ɣ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ëëy|Ë|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
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
				'standard' => {
					'default' => '#,##0.###',
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
		'GBP' => {
			symbol => 'GB£',
		},
		'SSP' => {
			symbol => '£',
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
							'Tiop',
							'Pɛt',
							'Duɔ̱ɔ̱',
							'Guak',
							'Duä',
							'Kor',
							'Pay',
							'Thoo',
							'Tɛɛ',
							'Laa',
							'Kur',
							'Tid'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Tiop thar pɛt',
							'Pɛt',
							'Duɔ̱ɔ̱ŋ',
							'Guak',
							'Duät',
							'Kornyoot',
							'Pay yie̱tni',
							'Tho̱o̱r',
							'Tɛɛr',
							'Laath',
							'Kur',
							'Tio̱p in di̱i̱t'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'T',
							'P',
							'D',
							'G',
							'D',
							'K',
							'P',
							'T',
							'T',
							'L',
							'K',
							'T'
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
						mon => 'Jiec',
						tue => 'Rɛw',
						wed => 'Diɔ̱k',
						thu => 'Ŋuaan',
						fri => 'Dhieec',
						sat => 'Bäkɛl',
						sun => 'Cäŋ'
					},
					wide => {
						mon => 'Jiec la̱t',
						tue => 'Rɛw lätni',
						wed => 'Diɔ̱k lätni',
						thu => 'Ŋuaan lätni',
						fri => 'Dhieec lätni',
						sat => 'Bäkɛl lätni',
						sun => 'Cäŋ kuɔth'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'J',
						tue => 'R',
						wed => 'D',
						thu => 'Ŋ',
						fri => 'D',
						sat => 'B',
						sun => 'C'
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
					abbreviated => {0 => 'P1',
						1 => 'P2',
						2 => 'P3',
						3 => 'P4'
					},
					wide => {0 => 'Päth diɔk tin nhiam',
						1 => 'Päth diɔk tin guurɛ',
						2 => 'Päth diɔk tin wä kɔɔriɛn',
						3 => 'Päth diɔk tin jiɔakdiɛn'
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
					'am' => q{RW},
					'pm' => q{TŊ},
				},
				'wide' => {
					'am' => q{RW},
					'pm' => q{TŊ},
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
				'0' => 'AY',
				'1' => 'ƐY'
			},
			wide => {
				'0' => 'A ka̱n Yecu ni dap',
				'1' => 'Ɛ ca Yecu dap'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/MM/y},
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
			'full' => q{zzzz h:mm:ss a},
			'long' => q{z h:mm:ss a},
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
			MEd => q{E، d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E، d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E، d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E d},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E، d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E، d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E، d MMM y},
			yMMMd => q{d MMM y},
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
