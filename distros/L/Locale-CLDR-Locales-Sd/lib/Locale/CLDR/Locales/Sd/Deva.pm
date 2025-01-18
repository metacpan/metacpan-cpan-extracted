=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sd::Deva - Package for language Sindhi

=cut

package Locale::CLDR::Locales::Sd::Deva;
# This file auto generated from Data\common\main\sd_Deva.xml
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
				'de' => 'जर्मन',
 				'de_AT' => 'आसट्रियन जर्मन',
 				'de_CH' => 'स्विस हाई जर्मन',
 				'en' => 'अंगरेज़ी',
 				'en_AU' => 'ऑसटेलियन अंगरेज़ी',
 				'en_CA' => 'केनेडियन अंगरेज़ी',
 				'en_GB@alt=short' => 'यूके जी अंगरेज़ी',
 				'en_US@alt=short' => 'यूएस जी अंगरेज़ी',
 				'es' => 'स्पेनिश',
 				'es_419' => 'लैटिन अमेरिकन स्पैनिश',
 				'es_ES' => 'यूरोपी स्पैनिश',
 				'es_MX' => 'मेक्सिकन स्पैनिश',
 				'fr' => 'फ्रेंच',
 				'fr_CA' => 'कैनेडियन फ्रेंच',
 				'fr_CH' => 'स्विस फ्रेंच',
 				'it' => 'इटालियनु',
 				'ja' => 'जापानी',
 				'pt' => 'पुर्तगाली',
 				'pt_BR' => 'ब्राज़ीलियन पुर्तगाली',
 				'pt_PT' => 'यूरोपी पुर्तगाली',
 				'ru' => 'रशियनु',
 				'sd' => 'सिन्धी',
 				'und' => 'अणजा॒तल भाषा',
 				'zh' => 'चीनी (तर्जुमे जो द॒स :खास करे, मैन्डरिन चीनी)',
 				'zh@alt=menu' => 'चीनी, मैन्डरिन',
 				'zh_Hans' => 'सादी थियल चीनी',
 				'zh_Hans@alt=long' => 'सादी थियल मैन्डरिन चीनी',
 				'zh_Hant' => 'रवायती चीनी',
 				'zh_Hant@alt=long' => 'रवायती मैन्डरिन चीनी',

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
 			'Deva' => 'देवनागिरी',
 			'Hans' => 'सादी थियल (तरजुमे जो द॒स : लिखत जे नाले जे हिन बयानु खे चीनीअ लाए भाषा जे नाले सां गद॒ मिलाए करे इस्तेमाल कयो वेंदो आहे)',
 			'Hans@alt=stand-alone' => 'सादी थियल (तरजुमे जो द॒स : लिखत जे नाले जे हिन बयानु खे अलग इस्तेमाल कयो वेंदों आहे, चीनीअ लाए भाषा जे नाले सां गद॒ न कयो वेंदो आहे)',
 			'Hant' => 'रवायती (तरजुमे जो द॒स : लिखत जे नाले जे हिन बयानु खे चीनीअ लाए भाषा जे नाले सां गद॒ मिलाए करे इस्तेमाल कयो वेंदो आहे)',
 			'Hant@alt=stand-alone' => 'रवायती हान (तरजुमे जो द॒स : लिखत जे नाले जे हिन बयानु खे चीनीअ लाए भाषा जे नाले सां गद॒ मिलाए करे इस्तेमाल कयो वेंदो आहे)',
 			'Latn' => 'लैटिन',
 			'Zxxx' => 'अणलिखियल',
 			'Zzzz' => 'अणजा॒तल लिखत',

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
			'BR' => 'ब्राज़ील',
 			'CN' => 'चीन',
 			'DE' => 'जर्मनी',
 			'FR' => 'फ़्रांस',
 			'GB' => 'बरतानी',
 			'IN' => 'भारत',
 			'IT' => 'इटली',
 			'JP' => 'जापान',
 			'PK' => 'पाकिस्तान',
 			'RU' => 'रशिया',
 			'US' => 'अमेरिका',
 			'ZZ' => 'अणजातल इलाइको',

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
 				'gregorian' => q{ग्रेगोरियन कैलेंडरु},
 			},
 			'collation' => {
 				'standard' => q{मअयारी तोर तरतीब},
 			},
 			'numbers' => {
 				'arab' => q{अरबी - इंडिक अंग},
 				'deva' => q{देवनागिरी अंग},
 				'latn' => q{उलहंदा अंग},
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
			'metric' => q{मैट्रिक},
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
			'language' => 'भाषा: {0}',
 			'script' => 'लिखत: {0}',
 			'region' => 'इलाइको : {0}',

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
			auxiliary => qr{[‌‍]},
			main => qr{[़ ं अ आ इ ई उ ऊ ए ऐ ओ औ क ख ग ॻ घ ङ च छ ज ॼ झ ञ ट ठ ड ॾ ढ ण त थ द ध न प फ ब ॿ भ म य र ल व श ष स ह ा ि ी ु ू ृ ॄ ॅ े ै ॉ ो ौ ्]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:हा|हा|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:न|न|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arabext' => {
			'decimal' => q(.),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '0%',
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
				'currency' => q(ब्राज़ीली रियालु),
				'one' => q(ब्राज़ीली रियालु),
				'other' => q(ब्राज़ीली रियाल),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(चीनी युआनु),
				'one' => q(चीनी युआनु),
				'other' => q(चीनी युआन),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(यूरो),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(बरतानवी पाउंडु),
				'one' => q(बरतानवी पाउंडु),
				'other' => q(बरतानवी पाउंड),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(हिंदुस्तानी रुपयो),
				'one' => q(हिंदुस्तानी रुपया),
				'other' => q(हिंदुस्तानी रुपया),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(जापानी येनु),
				'one' => q(जापानी येनु),
				'other' => q(जापानी येन),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(रशियनु रुबलु),
				'one' => q(रशियनु रुबलु),
				'other' => q(रशियनु रुबल),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(यूएस जो डॉलर),
				'one' => q(यूएस जो डॉलर),
				'other' => q(यूएस जा डॉलर),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(अणजा॒तल सिको),
				'one' => q(\(सिके जो अणजा॒तल एको\)),
				'other' => q(अणजा॒तल सिको),
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
							'जन',
							'फर',
							'मार्च',
							'अप्रै',
							'मई',
							'जून',
							'जु',
							'अग',
							'सप्टे',
							'ऑक्टो',
							'नवं',
							'डिसं'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ज',
							'फ़',
							'मा',
							'अ',
							'मा',
							'जू',
							'जु',
							'अग',
							'स',
							'ऑ',
							'न',
							'डि'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'जनवरी',
							'फेबरवरी',
							'मार्चु',
							'अप्रेल',
							'मई',
							'जून',
							'जुलाई',
							'आगस्ट',
							'सप्टेंबर',
							'आक्टोबर',
							'नवंबर',
							'डिसंबर'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'जन',
							'फर',
							'मार्च',
							'अप्रै',
							'मई',
							'जून',
							'जुला',
							'अग',
							'सप्टे',
							'ऑक्टो',
							'नवं',
							'डिसं'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ज',
							'फ़',
							'म',
							'अ',
							'मा',
							'जू',
							'जु',
							'अग',
							'स',
							'ऑ',
							'न',
							'डि'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'जनवरी',
							'फेबरवरी',
							'मार्चु',
							'अप्रेल',
							'मई',
							'जून',
							'जुलाई',
							'आगस्ट',
							'सप्टेंबर',
							'ऑक्टोबर',
							'नवंबर',
							'डिसंबर'
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
						mon => 'सू',
						tue => 'मंग',
						wed => 'बु॒ध',
						thu => 'विस',
						fri => 'जुम',
						sat => 'छंछ',
						sun => 'आर्त'
					},
					wide => {
						mon => 'सूमर',
						tue => 'मंगलु',
						wed => 'ॿुधर',
						thu => 'विस्पत',
						fri => 'जुमो',
						sat => 'छंछर',
						sun => 'आर्तवार'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'सू',
						tue => 'मं',
						wed => 'बुध',
						thu => 'विस',
						fri => 'जु',
						sat => 'छंछ',
						sun => 'आ'
					},
					narrow => {
						mon => 'सू',
						tue => 'मं',
						wed => 'बु॒',
						thu => 'वि',
						fri => 'जु',
						sat => 'छं',
						sun => 'आ'
					},
					wide => {
						mon => 'सू',
						tue => 'मं',
						wed => 'बु॒ध',
						thu => 'विस',
						fri => 'जुम',
						sat => 'छंछ',
						sun => 'आर्त'
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
					wide => {0 => 'पहिंरी टिमाही',
						1 => 'बीं॒ टिमाही',
						2 => 'टीं टिमाही',
						3 => 'चोथीं टिमाही'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'पहिरीं टिमाही',
						1 => 'बीं॒ टिमाही',
						2 => 'टीं टिमाही',
						3 => 'चोथीं टिमाही'
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
					'am' => q{सुबुह जा},
					'pm' => q{शाम जा},
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
				'0' => 'बीसी',
				'1' => 'एडी'
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
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
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
			Ed => q{d E},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			Md => q{M/d},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
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
		gmtFormat => q(जीएमटी{0}),
		gmtZeroFormat => q(जीएमटी),
		regionFormat => q({0} वक़्तु),
		regionFormat => q({0} दीं॒ह जो वक्त),
		regionFormat => q({0} मइयारी वक़्तु),
		'America_Central' => {
			long => {
				'daylight' => q#मरकज़ी दीं॒ह जो वक्त#,
				'generic' => q#मरकज़ी वक्त#,
				'standard' => q#मरकज़ी मअयारी वक्त#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ओभरी दीं॒ह जो वक्त#,
				'generic' => q#ओभरी वक्त#,
				'standard' => q#ओभरी मअयारी वक्त#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#पहाड़ी दीं॒ह जो वक्त#,
				'generic' => q#पहाड़ी वक्त#,
				'standard' => q#पहाड़ी मअयारी वक्त#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#पेसिफिक दीं॒ह जो वक्त#,
				'generic' => q#पेसिफिक वक्त#,
				'standard' => q#पेसिफिक मअयारी वक्त#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#अटलांटिक दीं॒ह जो वक्त#,
				'generic' => q#अटलांटिक वक्त#,
				'standard' => q#अटलांटिक मअयारी वक्त#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#गदि॒यल आलमी वक्तु#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#अणजा॒तल शहरु#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#मरकज़ी यूरोपी उनहारे जो वक्तु#,
				'generic' => q#मरकज़ी यूरोपी वक्त#,
				'standard' => q#मरकज़ी यूरोपी मअयारी वक्तु#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ओभरी यूरोपी उनहारे जो वक्तु#,
				'generic' => q#ओभरी यूरोपी वक्तु#,
				'standard' => q#ओभरी यूरोपी मअयारी वक्तु#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#उलहंदो यूरोपी उनहारे जो वक्तु#,
				'generic' => q#उलहंदो यूरोपी वक्तु#,
				'standard' => q#उलहंदो यूरोपी मअयारी वक्तु#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ग्रीनविच मीन वक़्तु#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
