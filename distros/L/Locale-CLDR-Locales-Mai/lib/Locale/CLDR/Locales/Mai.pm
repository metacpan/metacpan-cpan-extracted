=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mai - Package for language Maithili

=cut

package Locale::CLDR::Locales::Mai;
# This file auto generated from Data\common\main\mai.xml
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
				'de' => 'जर्मन',
 				'de_AT' => 'ऑस्ट्रियाई जर्मन',
 				'de_CH' => 'स्विस उच्च जर्मन',
 				'en' => 'अंग्रेज़ी',
 				'en_AU' => 'ऑस्ट्रेलियाई अंग्रेज़ी',
 				'en_CA' => 'कनाडाई अंग्रेज़ी',
 				'en_GB' => 'ब्रिटिश अंग्रेज़ी',
 				'en_GB@alt=short' => 'यू॰के॰ अंग्रेज़ी',
 				'en_US' => 'अमेरिकी अंग्रेज़ी',
 				'en_US@alt=short' => 'अमेरिकी अंग्रेज़ी',
 				'es' => 'स्पेनिश',
 				'es_419' => 'लैटिन अमेरिकी स्पेनिश',
 				'es_ES' => 'यूरोपीय स्पेनिश',
 				'es_MX' => 'मैक्सिकन स्पेनिश',
 				'fr' => 'फ़्रेंच',
 				'fr_CA' => 'कनाडाई फ़्रेंच',
 				'fr_CH' => 'स्विस फ़्रेंच',
 				'it' => 'इतालवी',
 				'ja' => 'जापानी',
 				'mai' => 'मैथिली',
 				'pt' => 'पुर्तगाली',
 				'pt_BR' => 'ब्राज़ीली पुर्तगाली',
 				'pt_PT' => 'यूरोपीय पुर्तगाली',
 				'ru' => 'रूसी',
 				'und' => 'अज्ञात भाषा',
 				'zh' => 'चीनी',
 				'zh@alt=menu' => 'चीनी, मैंडेरिन',
 				'zh_Hans' => 'सरलीकृत चीनी',
 				'zh_Hans@alt=long' => 'सरलीकृत मैंडेरिन चीनी',
 				'zh_Hant' => 'पारंपरिक चीनी',
 				'zh_Hant@alt=long' => 'पारंपरिक मैंडेरिन चीनी',

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
 			'Hant' => 'पारंपरिक',
 			'Hant@alt=stand-alone' => 'पारंपरिक हान',
 			'Latn' => 'लैटिन',
 			'Zxxx' => 'अलिखित',
 			'Zzzz' => 'अज्ञात लिपि',

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
 			'GB' => 'यूनाइटेड किंगडम',
 			'IN' => 'भारत',
 			'IT' => 'इटली',
 			'JP' => 'जापान',
 			'RU' => 'रूस',
 			'US' => 'संयुक्त राज्य',
 			'ZZ' => 'अज्ञात क्षेत्र',

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
 				'gregorian' => q{ग्रेगोरियन कैलेंडर},
 			},
 			'collation' => {
 				'standard' => q{मानक सॉर्ट क्रम},
 			},
 			'numbers' => {
 				'deva' => q{देवनागरी अंक},
 				'latn' => q{पश्चिमी अंक},
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
			'language' => 'भाषा: {0}',
 			'script' => 'लिपि: {0}',
 			'region' => 'क्षेत्र: {0}',

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
			auxiliary => qr{[अ {अं} {अः} आ इ ई उ ऊ ऋ ऌ ॡ ए ऐ ओ औ]},
			index => ['\u093C', 'अ', '{अ\u0902}', '{अः}', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ऋ', 'ऌ', 'ॡ', 'ए', 'ऐ', 'ओ', 'औ', 'क', '{क\u094Dष}', 'ख', 'ग', 'घ', 'च', 'छ', 'ज', '{ज\u094Dञ}', 'झ', 'ञ', 'ट', 'ठ', 'ड', '{ड\u0902}', 'ढ', 'ण', 'त', '{त\u094Dर}', 'थ', 'द', 'ध', 'न', 'प', 'फ', 'ब', 'भ', 'म', 'य', 'र', 'ल', 'व', 'श', '{श\u094Dर}', 'ष', 'स', 'ह'],
			main => qr{[़ ं ः क {क्ष} ख ग घ च छ ज {ज्ञ} झ ञ ट ठ ड {डं} ढ ण त {त्र} थ द ध न प फ ब भ म य र ल व श {श्र} ष स ह ा ि ी ु ू े ै ो ौ]},
			punctuation => qr{[_ \- ‑ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] \{ \} § @ * / \\ \& # ′ ″ ` + | ~]},
		};
	},
EOT
: sub {
		return { index => ['\u093C', 'अ', '{अ\u0902}', '{अः}', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ऋ', 'ऌ', 'ॡ', 'ए', 'ऐ', 'ओ', 'औ', 'क', '{क\u094Dष}', 'ख', 'ग', 'घ', 'च', 'छ', 'ज', '{ज\u094Dञ}', 'झ', 'ञ', 'ट', 'ठ', 'ड', '{ड\u0902}', 'ढ', 'ण', 'त', '{त\u094Dर}', 'थ', 'द', 'ध', 'न', 'प', 'फ', 'ब', 'भ', 'म', 'य', 'र', 'ल', 'व', 'श', '{श\u094Dर}', 'ष', 'स', 'ह'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:हं|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:नहि|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, और {1}),
				2 => q({0} और {1}),
		} }
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'deva',
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '[#E0]',
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
				'currency' => q(ब्राज़ीली रियाल),
				'other' => q(ब्राज़ीली रियाल),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(चीनी युआन),
				'other' => q(चीनी युआन),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(यूरो),
				'other' => q(यूरो),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ब्रिटिश पाउंड स्टर्लिंग),
				'other' => q(ब्रिटिश पाउंड स्टर्लिंग),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(भारतीय रुपया),
				'other' => q(भारतीय रुपया),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(जापानी येन),
				'other' => q(जापानी येन),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(रूसी रूबल),
				'other' => q(रूसी रूबल),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(यूएस डॉलर),
				'other' => q(यूएस डॉलर),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(अज्ञात मुद्रा),
				'other' => q(\(अज्ञात मुद्रा\)),
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
							'जन॰',
							'फ़र॰',
							'मार्च',
							'अप्रैल',
							'मई',
							'जून',
							'जुल॰',
							'अग॰',
							'सित॰',
							'अक्तू॰',
							'नव॰',
							'दिस॰'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ज',
							'फ',
							'मा',
							'अ',
							'म',
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
					wide => {
						nonleap => [
							'जनवरी',
							'फरवरी',
							'मार्च',
							'अप्रैल',
							'मई',
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
					abbreviated => {
						nonleap => [
							'जन॰',
							'फर॰',
							'मार्च',
							'अप्रैल',
							'मई',
							'जून',
							'जुल॰',
							'अग॰',
							'सित॰',
							'अक्तू॰',
							'नव॰',
							'दिस॰'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ज',
							'फ',
							'मा',
							'अ',
							'म',
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
					wide => {
						nonleap => [
							'जनवरी',
							'फरवरी',
							'मार्च',
							'अप्रैल',
							'मई',
							'जून',
							'जुलाई',
							'अगस्त',
							'सितंबर',
							'अक्टूबर',
							'नवंबर',
							'दिसंबर'
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
						thu => 'गुरु',
						fri => 'शुक्र',
						sat => 'शनि',
						sun => 'रवि'
					},
					narrow => {
						mon => 'सो',
						tue => 'मं',
						wed => 'बु',
						thu => 'गु',
						fri => 'शु',
						sat => 'श',
						sun => 'र'
					},
					wide => {
						mon => 'सोम दिन',
						tue => 'मंगल दिन',
						wed => 'बुध दिन',
						thu => 'बृहस्पति दिन',
						fri => 'शुक्र दिन',
						sat => 'शनि दिन',
						sun => 'रवि दिन'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'सोम',
						tue => 'मंगल',
						wed => 'बुध',
						thu => 'गुरु',
						fri => 'शुक्र',
						sat => 'शनि',
						sun => 'रवि'
					},
					narrow => {
						mon => 'सो',
						tue => 'मं',
						wed => 'बु',
						thu => 'गु',
						fri => 'शु',
						sat => 'श',
						sun => 'र'
					},
					wide => {
						mon => 'सोम दिन',
						tue => 'मंगल दिन',
						wed => 'बुध दिन',
						thu => 'बृहस्पति दिन',
						fri => 'शुक्र दिन',
						sat => 'शनि दिन',
						sun => 'रवि दिन'
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
					abbreviated => {0 => 'ति1',
						1 => 'ति2',
						2 => 'ति3',
						3 => 'ति4'
					},
					wide => {0 => 'पहिल तिमाही',
						1 => 'दोसर तिमाही',
						2 => 'तेसर तिमाही',
						3 => 'चारिम तिमाही'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'ति1',
						1 => 'ति2',
						2 => 'ति3',
						3 => 'ति4'
					},
					wide => {0 => 'पहिल तिमाही',
						1 => 'दोसर तिमाही',
						2 => 'तेसर तिमाही',
						3 => 'चारिम तिमाही'
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
					'am' => q{भोर},
					'pm' => q{सांझ},
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
				'0' => 'ईसा-पूर्व',
				'1' => 'ईसवी'
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
			'full' => q{G EEEE, d MMMM y},
			'long' => q{G d MMMM y},
			'medium' => q{G d MMM y},
			'short' => q{G d/M/y},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
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
			'full' => q{{1} के {0}},
			'long' => q{{1} के {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} के {0}},
			'long' => q{{1} के {0}},
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
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM G y},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd-MM-y},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} समय),
		regionFormat => q({0} डेलाइट समय),
		regionFormat => q({0} मानक समय),
		'America_Central' => {
			long => {
				'daylight' => q#उत्तरी अमेरिकी केंद्रीय डेलाइट समय#,
				'generic' => q#उत्तरी अमेरिकी केंद्रीय समय#,
				'standard' => q#उत्तरी अमेरिकी केंद्रीय मानक समय#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#उत्तरी अमेरिकी पूर्वी डेलाइट समय#,
				'generic' => q#उत्तरी अमेरिकी पूर्वी समय#,
				'standard' => q#उत्तरी अमेरिकी पूर्वी मानक समय#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#उत्तरी अमेरिकी माउंटेन डेलाइट समय#,
				'generic' => q#उत्तरी अमेरिकी माउंटेन समय#,
				'standard' => q#उत्तरी अमेरिकी माउंटेन मानक समय#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#उत्तरी अमेरिकी प्रशांत डेलाइट समय#,
				'generic' => q#उत्तरी अमेरिकी प्रशांत समय#,
				'standard' => q#उत्तरी अमेरिकी प्रशांत मानक समय#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#अटलांटिक डेलाइट समय#,
				'generic' => q#अटलांटिक समय#,
				'standard' => q#अटलांटिक मानक समय#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#समन्वित वैश्विक समय#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#अज्ञात शहर#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#मध्‍य यूरोपीय ग्रीष्‍मकालीन समय#,
				'generic' => q#मध्य यूरोपीय समय#,
				'standard' => q#मध्य यूरोपीय मानक समय#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#पूर्वी यूरोपीय ग्रीष्मकालीन समय#,
				'generic' => q#पूर्वी यूरोपीय समय#,
				'standard' => q#पूर्वी यूरोपीय मानक समय#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#पश्चिमी यूरोपीय ग्रीष्‍मकालीन समय#,
				'generic' => q#पश्चिमी यूरोपीय समय#,
				'standard' => q#पश्चिमी यूरोपीय मानक समय#,
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
