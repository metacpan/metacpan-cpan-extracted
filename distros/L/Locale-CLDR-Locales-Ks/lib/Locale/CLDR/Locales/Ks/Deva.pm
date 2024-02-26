=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ks::Deva - Package for language Kashmiri

=cut

package Locale::CLDR::Locales::Ks::Deva;
# This file auto generated from Data\common\main\ks_Deva.xml
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
 				'de_AT' => 'आस्ट्रियन जर्मन',
 				'de_CH' => 'स्विस हाई जर्मन',
 				'en' => 'अंगरिज़ी',
 				'en_AU' => 'आसट्रेलवी अंगरिज़ी',
 				'en_CA' => 'कनाडियन अंगरिज़ी',
 				'en_GB' => 'बरतानवी अंगरिज़ी',
 				'en_GB@alt=short' => 'UK अंगरिज़ी',
 				'en_US' => 'अमरीकी अंगरिज़ी',
 				'en_US@alt=short' => 'US अंगरिज़ी',
 				'es' => 'हसपानवी',
 				'es_419' => 'लातिनी अमरीकी हसपानवी',
 				'es_ES' => 'यूरपी हसपानवी',
 				'es_MX' => 'मेकसिकी हसपानवी',
 				'fr' => 'फ्रांसीसी',
 				'fr_CA' => 'कनाडियन फ्रांसीसी',
 				'fr_CH' => 'स्विस फ्रांसीसी',
 				'it' => 'इतालवी',
 				'ja' => 'जापानी',
 				'ks' => 'कॉशुर',
 				'pt' => 'पुरतउगाली',
 				'pt_BR' => 'ब्राज़िली पुरतउगाली',
 				'pt_PT' => 'यूरपी पुरतउगाली',
 				'ru' => 'रूसी',
 				'und' => 'नामोलुम ज़बान',
 				'zh' => 'चीनी (तरजुम इशार: खास तोर, मैन्डरिन चीनी।)',
 				'zh@alt=menu' => 'चीनी, मैन्डरिन',
 				'zh_Hans' => 'आसान चीनी',
 				'zh_Hans@alt=long' => 'आसान मैन्डरिन चीनी',
 				'zh_Hant' => 'रिवायाती चीनी',
 				'zh_Hant@alt=long' => 'रिवायाती मैन्डरिन चीनी',

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
 			'Hans' => 'आसान (तरजुम इशार: स्क्रिप्ट नवुक यि वर्ज़न छु चीनी बापथ ज़बान नाव किस मुरकब कि इस्तिमल करान।)',
 			'Hans@alt=stand-alone' => 'आसान हान (तरजुम इशार: स्क्रिप्ट नवुक यि वर्ज़न छु अलग इस्तिमाल सपदन, यि छु नि चीनी ज़बान बापथ ज़बान नवास सीथ मुरकब।)',
 			'Hant' => 'रिवायाती (तरजुम इशार: स्क्रिप्ट नवुक यि वर्ज़न छु चीनी बापथ ज़बान नाव किस मुरकब कि इस्तिमल करान।)',
 			'Hant@alt=stand-alone' => 'रिवायाती हान (तरजुम इशार: स्क्रिप्ट नवुक यि वर्ज़न छु अलग इस्तिमाल सपदन, यि छु नि चीनी ज़बान बापथ ज़बान नवास सीथ मुरकब।)',
 			'Latn' => 'लातिनी',
 			'Zxxx' => 'गेर तहरीर',
 			'Zzzz' => 'गेर तहरीर स्क्रिप्ट',

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
 			'DE' => 'जर्मन',
 			'FR' => 'फ्रांस',
 			'GB' => 'मुतहीद बादशाहत',
 			'IN' => 'हिंदोस्तान',
 			'IT' => 'इटली',
 			'JP' => 'जापान',
 			'RU' => 'रूस',
 			'US' => 'मूतहीद रियासत',
 			'ZZ' => 'नामोलुम अलाक़',

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
 				'gregorian' => q{ग्रिगोरियन कैलंडर},
 			},
 			'collation' => {
 				'standard' => q{मियारी तरतीब ऑर्डर},
 			},
 			'numbers' => {
 				'arab' => q{अरबी-इंडिक हिंदसी},
 				'arabext' => q{तोसी शुद अरबी-इंडिक हिंदसी},
 				'deva' => q{देवनागरी हिंदसि},
 				'latn' => q{यूरपी हिंदसी},
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
			'metric' => q{मेट्रिक},
 			'UK' => q{यू के},
 			'US' => q{यू एस},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ज़बान: {0}',
 			'script' => 'स्क्रिप्ट: {0}',
 			'region' => 'अलाक़: {0}',

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
			main => qr{[़ ँ ं अ आ इ ई उ ऊ ए ऑ ओ क ख ग च{च़} छ{छ़} ज ट ठ ड त थ द न प फ ब म य र ल व श स ह ा ि ी ु ू ृ ॄ ॅ े ै ॉ ो ौ ्]},
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
					'mass-gram' => {
						'name' => q(ग्राम),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ग्राम),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(किलो ग्राम),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(किलो ग्राम),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:आ|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:न|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, ति {1}),
				2 => q({0} ति {1}),
		} }
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arabext' => {
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
				'currency' => q(ब्राज़िली रील),
				'one' => q(ब्राज़िली रील),
				'other' => q(ब्राज़िली रीलज़),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(चीनी युवान),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(यूरो),
				'one' => q(यूरो),
				'other' => q(यूरोज़),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(बरतानवी पूनड),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(इंडियन रूपी),
				'one' => q(इंडियन रूपी),
				'other' => q(इंडियन रुपीज़),
			},
		},
		'JPY' => {
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
				'currency' => q(US डॉलर),
				'one' => q(US डॉलर),
				'other' => q(US डॉलर्ज़),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(नामोलुम करन्सी),
				'one' => q(\(करन्सी हुंद नामोलुम यूनिट\)),
				'other' => q(\(नामोलुम करन्सी\)),
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
							'जनवरी',
							'फ़रवरी',
							'मार्च',
							'अप्रैल',
							'मे',
							'जून',
							'जुलाई',
							'अगस्त',
							'सतुंबर',
							'अक्तूबर',
							'नवूमबर',
							'दसूमबर'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'जनवरी',
							'फ़रवरी',
							'मार्च',
							'अप्रैल',
							'मे',
							'जून',
							'जुलाई',
							'अगस्त',
							'सतमबर',
							'अक्तूबर',
							'नवमबर',
							'दसमबर'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'जनवरी',
							'फ़रवरी',
							'मार्च',
							'अप्रैल',
							'मे',
							'जून',
							'जुलाई',
							'अगस्त',
							'सतुंबर',
							'अकतुम्बर',
							'नवूमबर',
							'दसूमबर'
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
							'म',
							'ज',
							'ज',
							'अ',
							'स',
							'ओ',
							'न',
							'द'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'जनवरी',
							'फ़रवरी',
							'मार्च',
							'अप्रैल',
							'मे',
							'जून',
							'जुलाई',
							'अगस्त',
							'सतुंबर',
							'अकतुम्बर',
							'नवूमबर',
							'दसूमबर'
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
						mon => 'चंदिरवार',
						tue => 'बुवार',
						wed => 'बोदवार',
						thu => 'ब्रेसवार',
						fri => 'जुमा',
						sat => 'बटवार',
						sun => 'आथवार'
					},
					wide => {
						mon => 'च़ंदिरवार',
						tue => 'बोमवार',
						wed => 'बोदवार',
						thu => 'ब्रेसवार',
						fri => 'जुमा',
						sat => 'बटवार',
						sun => 'आथवार'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'चंदिरवार',
						tue => 'बुवार',
						wed => 'बोदवार',
						thu => 'ब्रेसवार',
						fri => 'जुम्मा',
						sat => 'बटवार',
						sun => 'आथवार'
					},
					narrow => {
						mon => 'च',
						tue => 'ब',
						wed => 'ब',
						thu => 'ब',
						fri => 'ज',
						sat => 'ब',
						sun => 'अ'
					},
					wide => {
						mon => 'चंदिरवार',
						tue => 'बुवार',
						wed => 'बोदवार',
						thu => 'ब्रेसवार',
						fri => 'जुम्मा',
						sat => 'बटवार',
						sun => 'आथवार'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => '1st सह माह',
						1 => '2nd सह माह',
						2 => '3rd सह माह',
						3 => '4th सह माह'
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
					'am' => q{ये एम},
					'pm' => q{पी एम},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{दुपहर ब्रोंठ},
					'pm' => q{दुपहरपतॖ},
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'ईसा ब्रोंठ',
				'1' => 'ईस्वी'
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
			'full' => q{G y MMMM d, EEEE},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
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
			'full' => q{a h:mm:ss zzzz},
			'long' => q{a h:mm:ss z},
			'medium' => q{a h:mm:ss},
			'short' => q{a h:mm},
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
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
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
		gmtFormat => q(जी एम टी {0}),
		gmtZeroFormat => q(जी एम टी),
		regionFormat => q({0} वख),
		regionFormat => q({0} डे लाइट वख),
		regionFormat => q({0} मयॉरी वख),
		'America_Central' => {
			long => {
				'daylight' => q#सेंट्रल डे लाइट वख#,
				'generic' => q#सेंट्रल वख#,
				'standard' => q#सेंट्रल स्टैन्डर्ड वख#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#मशरिकी डे लाइट वख#,
				'generic' => q#मशरिकी वख#,
				'standard' => q#मशरिकी स्टैन्डर्ड वख#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#माउंटेन डे लाइट वख#,
				'generic' => q#माउंटेन वख#,
				'standard' => q#माउंटेन स्टैन्डर्ड वख#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#पेसिफिक डे लाइट वख#,
				'generic' => q#पेसिफिक वख#,
				'standard' => q#पेसिफिक स्टैन्डर्ड वख#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#अटलांटिक डे लाइट वख#,
				'generic' => q#अटलांटिक वख#,
				'standard' => q#अटलांटिक स्टैन्डर्ड वख#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#कोऑर्डनैटिड यूनवर्सल वख#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#नमोलुम शहर#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#मरकज़ी यूरपी समर वख#,
				'generic' => q#मरकज़ी यूरपी वख#,
				'standard' => q#मरकज़ी यूरपी स्टैन्डर्ड वख#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#मशरिकी यूरपी समर वख#,
				'generic' => q#मशरिकी यूरपी वख#,
				'standard' => q#मशरिकी यूरपी स्टैन्डर्ड वख#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#मगरीबी यूरपी समर वख#,
				'generic' => q#मगरीबी यूरपी वख#,
				'standard' => q#मगरीबी यूरपी स्टैन्डर्ड वख#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ग्रीनविच ओसत वख#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
