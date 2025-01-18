=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kok::Latn - Package for language Konkani

=cut

package Locale::CLDR::Locales::Kok::Latn;
# This file auto generated from Data\common\main\kok_Latn.xml
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
				'ar' => 'Arbi',
 				'el' => 'Grik',
 				'en' => 'Inglix',
 				'es' => 'Ispanhol',
 				'fr' => 'Fransez',
 				'kn' => 'Kon’nodd',
 				'kok' => 'Konknni',
 				'mr' => 'Moratthi',
 				'zh' => 'Chini',

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
			'Deva' => 'Devanagari',
 			'Latn' => 'Romi',

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
			'CN' => 'Chin',
 			'CY' => 'Siprus',
 			'DE' => 'Jermon',
 			'EG' => 'Ejipt',
 			'ES' => 'Ispania',
 			'FR' => 'Frans',
 			'GR' => 'Gres',
 			'IN' => 'Bharot',
 			'IT' => 'Italia',
 			'LY' => 'Libia',
 			'MK' => 'Ut’tor Masedonia',
 			'RU' => 'Roxya',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Bhas: {0}',
 			'script' => 'Lipi: {0}',
 			'region' => 'Prant: {0}',

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
			auxiliary => qr{[áàăâåäā æ éèĕëē íìĭîïī óòŏöøō œ úùŭûüū ÿ]},
			main => qr{[aã b cç d eêẽ f g h iĩ j k l m nñ oôõ p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
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
					'duration-century' => {
						'name' => q(xekdde),
						'other' => q({0} xekdde),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(xekdde),
						'other' => q({0} xekdde),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dis),
						'other' => q({0} dis),
						'per' => q(dor disa {0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dis),
						'other' => q({0} dis),
						'per' => q(dor disa {0}),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(doskam),
						'other' => q({0} doskam),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(doskam),
						'other' => q({0} doskam),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(voram),
						'other' => q({0} voram),
						'per' => q(dor vora {0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(voram),
						'other' => q({0} voram),
						'per' => q(dor vora {0}),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(maikrosekond),
						'other' => q({0} maikrosekond),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(maikrosekond),
						'other' => q({0} maikrosekond),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekond),
						'other' => q({0} milisekond),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekond),
						'other' => q({0} milisekond),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mintam),
						'other' => q({0} mintam),
						'per' => q(dor minut {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mintam),
						'other' => q({0} mintam),
						'per' => q(dor minut {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mhoine),
						'other' => q({0} mhoine),
						'per' => q(dor mhoino {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mhoine),
						'other' => q({0} mhoine),
						'per' => q(dor mhoino {0}),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekond),
						'other' => q({0} nanosekond),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekond),
						'other' => q({0} nanosekond),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(rati),
						'other' => q({0} rati),
						'per' => q(dor rat {0}),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(rati),
						'other' => q({0} rati),
						'per' => q(dor rat {0}),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(timhoinalle),
						'other' => q({0} timhoinalle),
						'per' => q({0}/timhoinallem),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(timhoinalle),
						'other' => q({0} timhoinalle),
						'per' => q({0}/timhoinallem),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekond),
						'other' => q({0} sekond),
						'per' => q(dor sekond {0}),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekond),
						'other' => q({0} sekond),
						'per' => q(dor sekond {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(suman),
						'other' => q({0} suman),
						'per' => q(dor sumanak {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(suman),
						'other' => q({0} suman),
						'per' => q(dor sumanak {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(vorsam),
						'other' => q({0} vorsam),
						'per' => q(dor voros {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(vorsam),
						'other' => q({0} vorsam),
						'per' => q(dor voros {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(x),
						'other' => q({0}x),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(x),
						'other' => q({0}x),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dos),
						'other' => q({0}dos),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dos),
						'other' => q({0}dos),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(vor),
						'other' => q({0}vor),
						'per' => q({0}/vor),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(vor),
						'other' => q({0}vor),
						'per' => q({0}/vor),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsek),
						'other' => q({0}μsek),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsek),
						'other' => q({0}μsek),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msek),
						'other' => q({0}msek),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msek),
						'other' => q({0}msek),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0}min),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0}min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mho),
						'other' => q({0}mho),
						'per' => q({0}/mho),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mho),
						'other' => q({0}mho),
						'per' => q({0}/mho),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nsek),
						'other' => q({0}nsek),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nsek),
						'other' => q({0}nsek),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(rati),
						'other' => q({0}rati),
						'per' => q({0}/rat),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(rati),
						'other' => q({0}rati),
						'per' => q({0}/rat),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(timho),
						'other' => q({0}timho),
						'per' => q({0}/timho),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(timho),
						'other' => q({0}timho),
						'per' => q({0}/timho),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek),
						'other' => q({0}sek),
						'per' => q({0}/sek),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek),
						'other' => q({0}sek),
						'per' => q({0}/sek),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sum),
						'other' => q({0}sum),
						'per' => q({0}/sum),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sum),
						'other' => q({0}sum),
						'per' => q({0}/sum),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(vorsam),
						'other' => q({0}vorsam),
						'per' => q({0}/voros),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(vorsam),
						'other' => q({0}vorsam),
						'per' => q({0}/voros),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(x),
						'other' => q({0} x),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(x),
						'other' => q({0} x),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dis),
						'other' => q({0} dis),
						'per' => q({0}/dis),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dis),
						'other' => q({0} dis),
						'per' => q({0}/dis),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dos),
						'other' => q({0} dos),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dos),
						'other' => q({0} dos),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(voram),
						'other' => q({0} vor),
						'per' => q({0}/vor),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(voram),
						'other' => q({0} vor),
						'per' => q({0}/vor),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsek),
						'other' => q({0} μsek),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsek),
						'other' => q({0} μsek),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msek),
						'other' => q({0} msek),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msek),
						'other' => q({0} msek),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mho),
						'other' => q({0} mho),
						'per' => q({0}/mho),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mho),
						'other' => q({0} mho),
						'per' => q({0}/mho),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosek),
						'other' => q({0} nsek),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosek),
						'other' => q({0} nsek),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(rati),
						'other' => q({0} rati),
						'per' => q({0}/rat),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(rati),
						'other' => q({0} rati),
						'per' => q({0}/rat),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(timho),
						'other' => q({0} timho),
						'per' => q({0}/timho),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(timho),
						'other' => q({0} timho),
						'per' => q({0}/timho),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(suman),
						'other' => q({0} suman),
						'per' => q({0}/suman),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(suman),
						'other' => q({0} suman),
						'per' => q({0}/suman),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(vorsam),
						'other' => q({0} vorsam),
						'per' => q({0}/voros),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(vorsam),
						'other' => q({0} vorsam),
						'per' => q({0}/voros),
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
			'default' => {
				'1000' => {
					'other' => '0hoz',
				},
				'10000' => {
					'other' => '00hoz',
				},
				'100000' => {
					'other' => '0lak',
				},
				'1000000' => {
					'other' => '00lak',
				},
				'10000000' => {
					'other' => '0ko',
				},
				'100000000' => {
					'other' => '00ko',
				},
				'1000000000' => {
					'other' => '0obz',
				},
				'10000000000' => {
					'other' => '00obz',
				},
				'100000000000' => {
					'other' => '0nikh',
				},
				'1000000000000' => {
					'other' => '00nikh',
				},
				'10000000000000' => {
					'other' => '000nikh',
				},
				'100000000000000' => {
					'other' => '0hoz'.'nikh'.'',
				},
				'standard' => {
					'default' => '#,##,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'other' => '0 hozar',
				},
				'10000' => {
					'other' => '00 hozar',
				},
				'100000' => {
					'other' => '0 lakh',
				},
				'1000000' => {
					'other' => '00 lakh',
				},
				'10000000' => {
					'other' => '0 kotti',
				},
				'100000000' => {
					'other' => '00 kotti',
				},
				'1000000000' => {
					'other' => '0 obz',
				},
				'10000000000' => {
					'other' => '00 obz',
				},
				'100000000000' => {
					'other' => '0 nikhorv',
				},
				'1000000000000' => {
					'other' => '00 nikhorv',
				},
				'10000000000000' => {
					'other' => '000 nikhorv',
				},
				'100000000000000' => {
					'other' => '0 hozar nikhorv',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0hoz',
				},
				'10000' => {
					'other' => '00hoz',
				},
				'100000' => {
					'other' => '0lak',
				},
				'1000000' => {
					'other' => '00lak',
				},
				'10000000' => {
					'other' => '0ko',
				},
				'100000000' => {
					'other' => '00ko',
				},
				'1000000000' => {
					'other' => '0obz',
				},
				'10000000000' => {
					'other' => '00obz',
				},
				'100000000000' => {
					'other' => '0nikh',
				},
				'1000000000000' => {
					'other' => '00nikh',
				},
				'10000000000000' => {
					'other' => '000nikh',
				},
				'100000000000000' => {
					'other' => '0hoz'.'nikh'.'',
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
		'deva' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤#,##,##0.00',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤#,##,##0.00',
					},
				},
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
							'Jan',
							'Feb',
							'Mar',
							'Abr',
							'Mai',
							undef(),
							'Jul',
							'Ago',
							'Set',
							'Otu',
							'Nov',
							'Dez'
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
							'Janer',
							'Febrer',
							'Mars',
							'Abril',
							'Mai',
							'Jun',
							'Julai',
							'Agost',
							'Setembr',
							'Otubr',
							'Novembr',
							'Dezembr'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
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
						mon => 'Som',
						tue => 'Mon',
						wed => 'Bud',
						thu => 'Bre',
						fri => 'Suk',
						sat => 'Son',
						sun => 'Ait'
					},
					narrow => {
						mon => 'S',
						tue => 'M',
						wed => 'B',
						thu => 'B',
						fri => 'S',
						sat => 'S',
						sun => 'A'
					},
					short => {
						mon => 'Sm',
						tue => 'Mg',
						wed => 'Bu',
						thu => 'Br',
						fri => 'Su',
						sat => 'Sn',
						sun => 'Ai'
					},
					wide => {
						mon => 'Somar',
						tue => 'Mongllar',
						wed => 'Budhvar',
						thu => 'Birestar',
						fri => 'Sukrar',
						sat => 'Sonvar',
						sun => 'Aitar'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'S',
						tue => 'M',
						wed => 'B',
						thu => 'B',
						fri => 'S',
						sat => 'S',
						sun => 'A'
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
					abbreviated => {0 => 'Timh1',
						1 => 'Timh2',
						2 => 'Timh3',
						3 => 'Timh4'
					},
					wide => {0 => '1lem timhoinallem',
						1 => '2rem timhoinallem',
						2 => '3rem timhoinallem',
						3 => '4tem timhoinallem'
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
					'am' => q{sokallim},
					'pm' => q{sanje},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{sokallim},
					'pm' => q{sanje},
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
				'0' => 'KA',
				'1' => 'AD'
			},
			narrow => {
				'0' => 'K',
				'1' => 'A'
			},
			wide => {
				'0' => 'Krista Adim',
				'1' => 'Anno Domini'
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
			'full' => q{EEEE, d MMMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{d-M-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{d-M-yy},
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
			'full' => q{a h:mm:ss zzzz},
			'long' => q{a h:mm:ss z},
			'medium' => q{a h:mm:ss},
			'short' => q{a h:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
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
			Ehms => q{E a h:mm:ss},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			GyMd => q{d-M-y GGGGG},
			MEd => q{E, d-M},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			h => q{a h},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E, d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM, y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ehm => q{E a h:mm},
			Ehms => q{E a h:mm:ss},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			GyMd => q{d-M-y G},
			MEd => q{dd-MM, E},
			MMMEd => q{E, d MMM},
			MMMMW => q{MMMM -'acho' 'suman' W},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{a h},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			hmsv => q{a h:mm:ss v},
			hmv => q{a h:mm v},
			yM => q{M-y},
			yMEd => q{E, d-M-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM, y},
			yMd => q{d-M-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{Y -'acho' 'suman' w},
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
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM, y G – E, d MMM, y G},
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				G => q{d MMM, y G – d MMM, y G},
				M => q{d MMM – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{a h – a h},
				h => q{a h – h},
			},
			hm => {
				a => q{a h:mm – a h:mm},
				h => q{a h:mm – h:mm},
				m => q{a h:mm – h:mm},
			},
			hmv => {
				a => q{a h:mm – a h:mm v},
				h => q{a h:mm – h:mm v},
				m => q{a h:mm – h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a h – h v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{B h – B h},
				h => q{B h – h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm – h:mm},
				m => q{B h:mm–h:mm},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E, d/M/y G – E, d/M/y G},
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM, y G – E, d MMM, y G},
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				G => q{d MMM, y G – d MMM, y G},
				M => q{d MMM – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y G – d/M/y G},
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a h:mm – a h:mm},
				h => q{a h:mm–h:mm},
				m => q{a h:mm–h:mm},
			},
			hmv => {
				a => q{a h:mm – a h:mm v},
				h => q{a h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a h–h v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y},
				d => q{E, d MMM – E, d MMM, y},
				y => q{E, d MMM, y – E, d MMM, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y},
				d => q{d – d MMM, y},
				y => q{d MMM, y – d MMM, y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Vell),
		regionFormat => q({0} Dis-uzvadd vachovp Vell),
		regionFormat => q({0} Promann Vell),
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
