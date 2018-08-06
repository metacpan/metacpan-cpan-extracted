=head1

Locale::CLDR::Locales::Mgo - Package for language Metaʼ

=cut

package Locale::CLDR::Locales::Mgo;
# This file auto generated from Data\common\main\mgo.xml
#	on Sun  5 Aug  6:11:11 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
				'mgo' => 'metaʼ',
 				'und' => 'ngam tisɔʼ',

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
			'Latn' => 'ngam ŋwaʼri',
 			'Zxxx' => 'ngam choʼ',
 			'Zzzz' => 'abo ŋwaʼri tisɔʼ',

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
			'CM' => 'Kamalun',
 			'ZZ' => 'aba aben tisɔ̀',

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
 				'gregorian' => q{ngàb mə̀kala},
 			},
 			'numbers' => {
 				'latn' => q{inu},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

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
			auxiliary => qr{[c h l q v x]},
			index => ['A', 'B', '{CH}', 'D', 'E', 'Ə', 'F', 'G', '{GH}', 'I', 'J', 'K', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'W', 'Y', 'Z', 'ʼ'],
			main => qr{[a à b {ch} d e è ə {ə̀} f g {gh} i ì j k m n ŋ o ò ɔ {ɔ̀} p r s t u ù w y z ʼ]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[, ; \: ! ? . ' ‘ ’ " “ ”]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', '{CH}', 'D', 'E', 'Ə', 'F', 'G', '{GH}', 'I', 'J', 'K', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'W', 'Y', 'Z', 'ʼ'], };
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
	default		=> qq{?},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
				},
				'short' => {
					'day' => {
						'name' => q(d),
					},
					'hour' => {
						'name' => q(h),
					},
					'minute' => {
						'name' => q(min),
					},
					'month' => {
						'name' => q(m),
					},
					'second' => {
						'name' => q(s),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:èè|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ideg.|no|n)$' }
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

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
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
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(shirè),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(iku ikap mɔʼɔ),
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
							'mbegtug',
							'imeg àbùbì',
							'imeg mbəŋchubi',
							'iməg ngwə̀t',
							'iməg fog',
							'iməg ichiibɔd',
							'iməg àdùmbə̀ŋ',
							'iməg ichika',
							'iməg kud',
							'iməg tèsiʼe',
							'iməg zò',
							'iməg krizmed'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'M1',
							'A2',
							'M3',
							'N4',
							'F5',
							'I6',
							'A7',
							'I8',
							'K9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'iməg mbegtug',
							'imeg àbùbì',
							'imeg mbəŋchubi',
							'iməg ngwə̀t',
							'iməg fog',
							'iməg ichiibɔd',
							'iməg àdùmbə̀ŋ',
							'iməg ichika',
							'iməg kud',
							'iməg tèsiʼe',
							'iməg zò',
							'iməg krizmed'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'mbegtug',
							'imeg àbùbì',
							'imeg mbəŋchubi',
							'iməg ngwə̀t',
							'iməg fog',
							'iməg ichiibɔd',
							'iməg àdùmbə̀ŋ',
							'iməg ichika',
							'iməg kud',
							'iməg tèsiʼe',
							'iməg zò',
							'iməg krizmed'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'M1',
							'A2',
							'M3',
							'N4',
							'F5',
							'I6',
							'A7',
							'I8',
							'K9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'iməg mbegtug',
							'imeg àbùbì',
							'imeg mbəŋchubi',
							'iməg ngwə̀t',
							'iməg fog',
							'iməg ichiibɔd',
							'iməg àdùmbə̀ŋ',
							'iməg ichika',
							'iməg kud',
							'iməg tèsiʼe',
							'iməg zò',
							'iməg krizmed'
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
						mon => 'Aneg 2',
						tue => 'Aneg 3',
						wed => 'Aneg 4',
						thu => 'Aneg 5',
						fri => 'Aneg 6',
						sat => 'Aneg 7',
						sun => 'Aneg 1'
					},
					narrow => {
						mon => 'A2',
						tue => 'A3',
						wed => 'A4',
						thu => 'A5',
						fri => 'A6',
						sat => 'A7',
						sun => 'A1'
					},
					short => {
						mon => '2',
						tue => '3',
						wed => '4',
						thu => '5',
						fri => '6',
						sat => '7',
						sun => '1'
					},
					wide => {
						mon => 'Aneg 2',
						tue => 'Aneg 3',
						wed => 'Aneg 4',
						thu => 'Aneg 5',
						fri => 'Aneg 6',
						sat => 'Aneg 7',
						sun => 'Aneg 1'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Aneg 2',
						tue => 'Aneg 3',
						wed => 'Aneg 4',
						thu => 'Aneg 5',
						fri => 'Aneg 6',
						sat => 'Aneg 7',
						sun => 'Aneg 1'
					},
					narrow => {
						mon => 'A2',
						tue => 'A3',
						wed => 'A4',
						thu => 'A5',
						fri => 'A6',
						sat => 'A7',
						sun => 'A1'
					},
					short => {
						mon => '2',
						tue => '3',
						wed => '4',
						thu => '5',
						fri => '6',
						sat => '7',
						sun => '1'
					},
					wide => {
						mon => 'Aneg 2',
						tue => 'Aneg 3',
						wed => 'Aneg 4',
						thu => 'Aneg 5',
						fri => 'Aneg 6',
						sat => 'Aneg 7',
						sun => 'Aneg 1'
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
					'pm' => q{PM},
					'am' => q{AM},
				},
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
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
				'0' => 'BCE',
				'1' => 'CE'
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
			'full' => q{EEEE, G y MMMM dd},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, y MMMM dd},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
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
		'generic' => {
			d => q{d},
		},
		'gregorian' => {
			d => q{d},
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
			fallback => '{0} – {1}',
		},
		'gregorian' => {
			fallback => '{0} – {1}',
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
		fallbackFormat => q({1} ({0})),
	 } }
);
no Moo;

1;

# vim: tabstop=4
