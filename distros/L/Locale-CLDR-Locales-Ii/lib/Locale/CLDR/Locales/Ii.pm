=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ii - Package for language Sichuan Yi

=cut

package Locale::CLDR::Locales::Ii;
# This file auto generated from Data\common\main\ii.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'de' => 'ꄓꇩꉙ',
 				'en' => 'ꑱꇩꉙ',
 				'es' => 'ꑭꀠꑸꉙ',
 				'fr' => 'ꃔꇩꉙ',
 				'ii' => 'ꆈꌠꉙ',
 				'it' => 'ꑴꄊꆺꉙ',
 				'ja' => 'ꏝꀪꉙ',
 				'pt' => 'ꁍꄨꑸꉙ',
 				'pt_BR' => 'ꀠꑟꁍꄨꑸꉙ',
 				'ru' => 'ꊉꇩꉙ',
 				'und' => 'ꅉꀋꌠꅇꂷ',
 				'zh' => 'ꍏꇩꉙ',
 				'zh_Hans' => 'ꈝꐯꍏꇩꉙ',
 				'zh_Hant' => 'ꀎꋏꍏꇩꉙ',

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
			'Arab' => 'ꀊꇁꀨꁱꂷ',
 			'Cyrl' => 'ꀊꆨꌦꇁꃚꁱꂷ',
 			'Hans' => 'ꈝꐯꉌꈲꁱꂷ',
 			'Hant' => 'ꀎꋏꉌꈲꁱꂷ',
 			'Latn' => 'ꇁꄀꁱꂷ',
 			'Yiii' => 'ꆈꌠꁱꂷ',
 			'Zxxx' => 'ꁱꀋꉆꌠ',
 			'Zzzz' => 'ꅉꀋꐚꌠꁱꂷ',

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
			'BR' => 'ꀠꑭ',
 			'CN' => 'ꍏꇩ',
 			'DE' => 'ꄓꇩ',
 			'FR' => 'ꃔꇩ',
 			'GB' => 'ꑱꇩ',
 			'IN' => 'ꑴꄗ',
 			'IT' => 'ꑴꄊꆺ',
 			'JP' => 'ꏝꀪ',
 			'RU' => 'ꊉꇆꌦ',
 			'US' => 'ꂰꇩ',
 			'ZZ' => 'ꃅꄷꅉꀋꐚꌠ',

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
 				'gregorian' => q{ꄉꉻꃅꑍ},
 				'islamic' => q{ꑳꌦꇂꑍꉖ},
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
			'metric' => q{ꂰꌬꌠ},
 			'US' => q{ꂰꇩ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ꅇꉙ: {0}',
 			'script' => 'ꇇꁱ: {0}',
 			'region' => 'ꃅꄷ: {0}',

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
			index => ['ꀀ', 'ꀋ', 'ꀗ', 'ꀣ', 'ꀯ', 'ꀺ', 'ꁆ', 'ꁒ', 'ꁞ', 'ꁩ', 'ꁵ', 'ꂁ', 'ꂍ', 'ꂘ', 'ꂤ', 'ꂰ', 'ꂼ', 'ꃇ', 'ꃓ', 'ꃟ', 'ꃫ', 'ꃶ', 'ꄂ', 'ꄎ', 'ꄚ', 'ꄥ', 'ꄱ', 'ꄽ', 'ꅉ', 'ꅔ', 'ꅠ', 'ꅬ', 'ꅸ', 'ꆃ', 'ꆏ', 'ꆛ', 'ꆧ', 'ꆳ', 'ꆾ', 'ꇊ', 'ꇖ', 'ꇢ', 'ꇭ', 'ꇹ', 'ꈅ', 'ꈑ', 'ꈜ', 'ꈨ', 'ꈴ', 'ꉀ', 'ꉋ', 'ꉗ', 'ꉣ', 'ꉯ', 'ꉺ', 'ꊆ', 'ꊒ', 'ꊞ', 'ꊩ', 'ꊵ', 'ꋁ', 'ꋍ', 'ꋘ', 'ꋤ', 'ꋰ', 'ꋼ', 'ꌇ', 'ꌓ', 'ꌟ', 'ꌫ', 'ꌷ', 'ꍂ', 'ꍎ', 'ꍚ', 'ꍦ', 'ꍱ', 'ꍽ', 'ꎉ', 'ꎕ', 'ꎠ', 'ꎬ', 'ꎸ', 'ꏄ', 'ꏏ', 'ꏛ', 'ꏧ', 'ꏳ', 'ꏾ', 'ꐊ', 'ꐖ', 'ꐢ', 'ꐭ', 'ꐹ', 'ꑅ', 'ꑑ', 'ꑜ', 'ꑨ', 'ꑴ', 'ꒀ', 'ꒋ'],
			main => qr{[ꀀ-ꒌ]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['ꀀ', 'ꀋ', 'ꀗ', 'ꀣ', 'ꀯ', 'ꀺ', 'ꁆ', 'ꁒ', 'ꁞ', 'ꁩ', 'ꁵ', 'ꂁ', 'ꂍ', 'ꂘ', 'ꂤ', 'ꂰ', 'ꂼ', 'ꃇ', 'ꃓ', 'ꃟ', 'ꃫ', 'ꃶ', 'ꄂ', 'ꄎ', 'ꄚ', 'ꄥ', 'ꄱ', 'ꄽ', 'ꅉ', 'ꅔ', 'ꅠ', 'ꅬ', 'ꅸ', 'ꆃ', 'ꆏ', 'ꆛ', 'ꆧ', 'ꆳ', 'ꆾ', 'ꇊ', 'ꇖ', 'ꇢ', 'ꇭ', 'ꇹ', 'ꈅ', 'ꈑ', 'ꈜ', 'ꈨ', 'ꈴ', 'ꉀ', 'ꉋ', 'ꉗ', 'ꉣ', 'ꉯ', 'ꉺ', 'ꊆ', 'ꊒ', 'ꊞ', 'ꊩ', 'ꊵ', 'ꋁ', 'ꋍ', 'ꋘ', 'ꋤ', 'ꋰ', 'ꋼ', 'ꌇ', 'ꌓ', 'ꌟ', 'ꌫ', 'ꌷ', 'ꍂ', 'ꍎ', 'ꍚ', 'ꍦ', 'ꍱ', 'ꍽ', 'ꎉ', 'ꎕ', 'ꎠ', 'ꎬ', 'ꎸ', 'ꏄ', 'ꏏ', 'ꏛ', 'ꏧ', 'ꏳ', 'ꏾ', 'ꐊ', 'ꐖ', 'ꐢ', 'ꐭ', 'ꐹ', 'ꑅ', 'ꑑ', 'ꑜ', 'ꑨ', 'ꑴ', 'ꒀ', 'ꒋ'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ꉬ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ꀋꉬ|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
			'minusSign' => q(-),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
					'standard' => {
						'positive' => '¤ #,##0.00',
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
		'CNY' => {
			symbol => '¥',
		},
		'XXX' => {
			display_name => {
				'currency' => q(ꅉꀋꐚꌠꌋꆀꎆꃀꀋꈁꀐꌠ),
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
							'ꋍꆪ',
							'ꑍꆪ',
							'ꌕꆪ',
							'ꇖꆪ',
							'ꉬꆪ',
							'ꃘꆪ',
							'ꏃꆪ',
							'ꉆꆪ',
							'ꈬꆪ',
							'ꊰꆪ',
							'ꊰꊪꆪ',
							'ꊰꑋꆪ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ꋍꆪ',
							'ꑍꆪ',
							'ꌕꆪ',
							'ꇖꆪ',
							'ꉬꆪ',
							'ꃘꆪ',
							'ꏃꆪ',
							'ꉆꆪ',
							'ꈬꆪ',
							'ꊰꆪ',
							'ꊰꊪꆪ',
							'ꊰꑋꆪ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'ꋍꆪ',
							'ꑍꆪ',
							'ꌕꆪ',
							'ꇖꆪ',
							'ꉬꆪ',
							'ꃘꆪ',
							'ꏃꆪ',
							'ꉆꆪ',
							'ꈬꆪ',
							'ꊰꆪ',
							'ꊰꊪꆪ',
							'ꊰꑋꆪ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ꋍꆪ',
							'ꑍꆪ',
							'ꌕꆪ',
							'ꇖꆪ',
							'ꉬꆪ',
							'ꃘꆪ',
							'ꏃꆪ',
							'ꉆꆪ',
							'ꈬꆪ',
							'ꊰꆪ',
							'ꊰꊪꆪ',
							'ꊰꑋꆪ'
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
						mon => 'ꆏꋍ',
						tue => 'ꆏꑍ',
						wed => 'ꆏꌕ',
						thu => 'ꆏꇖ',
						fri => 'ꆏꉬ',
						sat => 'ꆏꃘ',
						sun => 'ꑭꆏ'
					},
					narrow => {
						mon => 'ꋍ',
						tue => 'ꑍ',
						wed => 'ꌕ',
						thu => 'ꇖ',
						fri => 'ꉬ',
						sat => 'ꃘ',
						sun => 'ꆏ'
					},
					wide => {
						mon => 'ꆏꊂꋍ',
						tue => 'ꆏꊂꑍ',
						wed => 'ꆏꊂꌕ',
						thu => 'ꆏꊂꇖ',
						fri => 'ꆏꊂꉬ',
						sat => 'ꆏꊂꃘ',
						sun => 'ꑭꆏꑍ'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'ꆏꋍ',
						tue => 'ꆏꑍ',
						wed => 'ꆏꌕ',
						thu => 'ꆏꇖ',
						fri => 'ꆏꉬ',
						sat => 'ꆏꃘ',
						sun => 'ꑭꆏ'
					},
					narrow => {
						mon => 'ꋍ',
						tue => 'ꑍ',
						wed => 'ꌕ',
						thu => 'ꇖ',
						fri => 'ꉬ',
						sat => 'ꃘ',
						sun => 'ꆏ'
					},
					wide => {
						mon => 'ꆏꊂꋍ',
						tue => 'ꆏꊂꑍ',
						wed => 'ꆏꊂꌕ',
						thu => 'ꆏꊂꇖ',
						fri => 'ꆏꊂꉬ',
						sat => 'ꆏꊂꃘ',
						sun => 'ꑭꆏꑍ'
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
					abbreviated => {0 => 'ꃅꑌ',
						1 => 'ꃅꎸ',
						2 => 'ꃅꍵ',
						3 => 'ꃅꋆ'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'ꃅꑌ',
						1 => 'ꃅꎸ',
						2 => 'ꃅꍵ',
						3 => 'ꃅꋆ'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'ꃅꑌ',
						1 => 'ꃅꎸ',
						2 => 'ꃅꍵ',
						3 => 'ꃅꋆ'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'ꃅꑌ',
						1 => 'ꃅꎸ',
						2 => 'ꃅꍵ',
						3 => 'ꃅꋆ'
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
					'am' => q{ꎸꄑ},
					'pm' => q{ꁯꋒ},
				},
				'wide' => {
					'am' => q{ꎸꄑ},
					'pm' => q{ꁯꋒ},
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
			abbreviated => {
				'0' => 'ꃅꋊꂿ',
				'1' => 'ꃅꋊꊂ'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{y MMMM d, EEEE},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{y-MM-dd, E},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{y MMMM},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
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
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Etc/Unknown' => {
			exemplarCity => q#ꅉꀋꐚꌠ#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
