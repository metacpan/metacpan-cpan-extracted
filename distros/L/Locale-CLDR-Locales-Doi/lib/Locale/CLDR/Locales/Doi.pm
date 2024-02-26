=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Doi - Package for language Dogri

=cut

package Locale::CLDR::Locales::Doi;
# This file auto generated from Data\common\main\doi.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
				'de' => 'जर्मन',
 				'de_AT' => 'आस्ट्रियाई जर्मन',
 				'de_CH' => 'स्विस हाई जर्मन',
 				'doi' => 'डोगरी',
 				'en' => 'अंगरेजी',
 				'en_CA' => 'कैनेडियन अंगरेजी',
 				'en_GB' => 'ब्रिटिश अंगरेजी',
 				'en_GB@alt=short' => 'यूके अंगरेजी',
 				'en_US' => 'अमरीकी अंगरेजी',
 				'en_US@alt=short' => 'यूएस अंगरेजी',
 				'es' => 'स्पैनिश',
 				'es_419' => 'लैटिन अमरीकी स्पैनिश',
 				'es_ES' => 'यूरोपी स्पैनिश',
 				'es_MX' => 'मैक्सिन स्पैनिश',
 				'fr' => 'फ्रेंच',
 				'fr_CA' => 'कैनेडियन फ्रेंच',
 				'fr_CH' => 'स्विस फ्रेंच',
 				'it' => 'इटालियन',
 				'ja' => 'जापानी',
 				'pt' => 'पुर्तगाली',
 				'pt_BR' => 'ब्राजीली पुर्तगाली',
 				'pt_PT' => 'यूरोपी पुर्तगाली',
 				'ru' => 'रूसी',
 				'und' => 'अनजांती भाशा',
 				'zh' => 'चीनी',
 				'zh@alt=menu' => 'चीनी, मंदारिन',
 				'zh_Hans' => 'सरलीकृत चीनी',
 				'zh_Hans@alt=long' => 'सरलीकृत मंदारिन चीनी',
 				'zh_Hant' => 'रवायती चीनी',
 				'zh_Hant@alt=long' => 'रवायती मंदारिन चीनी',

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
			'Arab' => 'अरबी',
 			'Cyrl' => 'सिरिलिक',
 			'Deva' => 'देवनागरी',
 			'Hans' => 'सरलीकृत',
 			'Hans@alt=stand-alone' => 'सरलीकृत हान',
 			'Hant' => 'रवायती',
 			'Hant@alt=stand-alone' => 'रवायती हान',
 			'Latn' => 'लैटिन',
 			'Zxxx' => 'अनलिखत',
 			'Zzzz' => 'अनजांती लिपि',

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
			'BR' => 'ब्राजील',
 			'CN' => 'चीन',
 			'DE' => 'जर्मनी',
 			'FR' => 'फ्रांस',
 			'GB' => 'यूनाइटेड किंगडम',
 			'IN' => 'भारत',
 			'IT' => 'इटली',
 			'JP' => 'जापान',
 			'RU' => 'रूस',
 			'US' => 'यूएस',
 			'ZZ' => 'अनजांता खेत्तर',

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
 				'gregorian' => q{ग्रेगोरी कैलेन्डर},
 			},
 			'collation' => {
 				'standard' => q{मानक ताल तरतीब},
 			},
 			'numbers' => {
 				'arab' => q{अरबी-इंडिक अंक},
 				'deva' => q{देवनागरी अंक},
 				'latn' => q{पच्छमी अंक},
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
			'metric' => q{मीट्रिक},
 			'UK' => q{यूके},
 			'US' => q{यूएस},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'भाशा: {0}',
 			'script' => 'लिपि: {0}',
 			'region' => 'खेत्तर: {0}',

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
			auxiliary => qr{[‌‍ ऍ ऑ ॅ]},
			index => ['अ', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ऋ', 'ॠ', 'ऌ', 'ॡ', 'ए', 'ऐ', 'ओ', 'औ', 'क', 'ख', 'ग', 'घ', 'ङ', 'च', 'छ', 'ज', 'झ', 'ञ', 'ट', 'ठ', 'ड', 'ढ', 'ण', 'त', 'थ', 'द', 'ध', 'न', 'प', 'फ', 'ब', 'भ', 'म', 'य', 'र', 'ल', 'ळ', 'व', 'श', 'ष', 'स', 'ह'],
			main => qr{[॑ ॒ ़ ँ ंः ॐ अ आ इ ई उ ऊ ऋ ॠ ऌ ॡ ए ऐ ओ औ क {क्ष} ख ग घ ङ च छ ज झ ञ ट ठ ड{ड़} ढ{ढ़} ण त थ द ध न प फ ब भ म य र ल ळ व श ष स ह ऽ ा ि ी ु ू ृ ॄ ॢ ॣ े ै ो ौ ्]},
			punctuation => qr{[_ – — , ; \: ! ? . … '‘’ "“” ( ) § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['अ', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ऋ', 'ॠ', 'ऌ', 'ॡ', 'ए', 'ऐ', 'ओ', 'औ', 'क', 'ख', 'ग', 'घ', 'ङ', 'च', 'छ', 'ज', 'झ', 'ञ', 'ट', 'ठ', 'ड', 'ढ', 'ण', 'त', 'थ', 'द', 'ध', 'न', 'प', 'फ', 'ब', 'भ', 'म', 'य', 'र', 'ल', 'ळ', 'व', 'श', 'ष', 'स', 'ह'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ग्राम),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ग्राम),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(किल्लो),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(किल्लो),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}किल्लोवाट/100किमी),
						'other' => q({0} किल्लोवाट/100किमी),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}किल्लोवाट/100किमी),
						'other' => q({0} किल्लोवाट/100किमी),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0}galIm),
						'other' => q({0}galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0}galIm),
						'other' => q({0}galIm),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:हां|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:नेईं|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, ते {1}),
				2 => q({0} ते {1}),
		} }
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'deva',
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
		'BRL' => {
			display_name => {
				'currency' => q(ब्राजीली रियाल),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(चीनी युआन),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(यूरो),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ब्रिटिश पाउंड),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(भारती रपेऽ),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(जापानी येन),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(रूसी रूबल),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(यूएस डालर),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(अनजांती करंसी),
				'one' => q(\(अनजांती करंसी\)),
				'other' => q(\(अनजांती करंसी\)),
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
							'जन.',
							'फर.',
							'मार्च',
							'अप्रैल',
							'मेई',
							'जून',
							'जुलाई',
							'अग.',
							'सित.',
							'अक्तू.',
							'नव.',
							'दिस.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'जनवरी',
							'फरवरी',
							'मार्च',
							'अप्रैल',
							'मेई',
							'जून',
							'जुलाई',
							'अगस्त',
							'सितंबर',
							'अक्तूबर',
							'नवंबर',
							'दिसंबर'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ज',
							'फ',
							'मा',
							'अ',
							'मे',
							'जू',
							'जु',
							'अ',
							'सि',
							'अ',
							'न',
							'दि'
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
						mon => 'सोम',
						tue => 'मंगल',
						wed => 'बुध',
						thu => 'बीर',
						fri => 'शुक्र',
						sat => 'शनि',
						sun => 'ऐत'
					},
					narrow => {
						mon => 'सो.',
						tue => 'म.',
						wed => 'बु.',
						thu => 'बी.',
						fri => 'शु.',
						sat => 'श.',
						sun => 'ऐ.'
					},
					wide => {
						mon => 'सोमबार',
						tue => 'मंगलबार',
						wed => 'बुधबार',
						thu => 'बीरबार',
						fri => 'शुक्रबार',
						sat => 'शनिबार',
						sun => 'ऐतबार'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'सो',
						tue => 'म.',
						wed => 'बु.',
						thu => 'बी.',
						fri => 'शु.',
						sat => 'श.',
						sun => 'ऐ'
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
					abbreviated => {0 => 'त्र.1',
						1 => 'त्र.2',
						2 => 'त्र.3',
						3 => 'त्र.4'
					},
					wide => {0 => 'पैहली त्रमाही',
						1 => 'दूई त्रमाही',
						2 => 'त्री त्रमाही',
						3 => 'चौथी त्रमाही'
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
					'am' => q{सवेर},
					'pm' => q{स’ञ},
				},
				'wide' => {
					'am' => q{सवेर},
					'pm' => q{दपैहर बाद},
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
				'0' => 'ई.पू.',
				'1' => 'ईसवी'
			},
			wide => {
				'1' => 'ई. सन्'
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
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d, MMMM y},
			'long' => q{d, MMMM y},
			'medium' => q{d, MMM y},
			'short' => q{d/M/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
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
		'gregorian' => {
			Ed => q{E d},
			GyMMMEd => q{E, d, MMM G y},
			GyMMMd => q{d, MMM G y},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMW => q{MMMM दा हफ्ता W},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d, MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d, MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{Y दा हफ्ता w},
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
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				h => q{h – h a},
			},
			hm => {
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
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
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
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
		regionFormat => q({0} समां),
		regionFormat => q({0} डेलाइट समां),
		regionFormat => q({0} मानक समां),
		'America_Central' => {
			long => {
				'daylight' => q#उत्तरी अमरीकी डेलाइट केंदरी समां#,
				'generic' => q#उत्तरी अमरीकी केंदरी समां#,
				'standard' => q#उत्तरी अमरीकी मानक केंदरी समां#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#उत्तरी अमरीकी डेलाइट पूर्वी समां#,
				'generic' => q#उत्तरी अमरीकी पूर्वी समां#,
				'standard' => q#उत्तरी अमरीकी मानक पूर्वी समां#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#उत्तरी अमरीकी डेलाइट माउंटेन समां#,
				'generic' => q#उत्तरी अमरीकी माउंटेन समां#,
				'standard' => q#उत्तरी अमरीकी मानक माउंटेन समां#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#उत्तरी अमरीकी डेलाइट प्रशांत समां#,
				'generic' => q#उत्तरी अमरीकी प्रशांत समां#,
				'standard' => q#उत्तरी अमरीकी मानक प्रशांत समां#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#अटलांटिक डेलाइट समां#,
				'generic' => q#अटलांटिक समां#,
				'standard' => q#अटलांटिक मानक समां#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#तालमेली आलमी समां#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#अनजांता शैह्‌र#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#आयरिश मानक समां#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#ब्रिटिश गर्मियें दा समां#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#केंदरी यूरोपी गर्मियें दा समां#,
				'generic' => q#केंदरी यूरोपी समां#,
				'standard' => q#केंदरी यूरोपी मानक समां#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#उत्तरी यूरोपी गर्मियें दा समां#,
				'generic' => q#उत्तरी यूरोपी समां#,
				'standard' => q#उत्तरी यूरोपी मानक समां#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#पच्छमी यूरोपी गर्मियें दा समां#,
				'generic' => q#पच्छमी यूरोपी समां#,
				'standard' => q#पच्छमी यूरोपी मानक समां#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ग्रीनविच मीन टाइम#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
