=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sa - Package for language Sanskrit

=cut

package Locale::CLDR::Locales::Sa;
# This file auto generated from Data\common\main\sa.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
				'aa' => 'अफर',
 				'ab' => 'अब्खासियन्',
 				'ace' => 'अचिनीस्',
 				'ach' => 'अचोलि',
 				'ada' => 'अडङ्गमे',
 				'af' => 'अफ्रिक्कान्स्',
 				'afh' => 'अफ्रिहिलि',
 				'ain' => 'अयिनु',
 				'ak' => 'अकन्',
 				'akk' => 'अक्काटियान्',
 				'ale' => 'अलियुट्',
 				'am' => 'अंहाऱिक्',
 				'anp' => 'अङ्गिक',
 				'ar' => 'अऱबिक्',
 				'de' => 'जर्मनभाषा:',
 				'de_AT' => 'ऑस्ट्रियाई जर्मनभाषा:',
 				'de_CH' => 'स्विस उच्च जर्मनभाषा:',
 				'egy' => 'प्राचीन ईजिप्त्यन्',
 				'en' => 'आङ्ग्लभाषा',
 				'en_AU' => 'ऑस्ट्रेलियादेशः आङ्ग्लभाषा',
 				'en_CA' => 'कनाडादेशः आङ्ग्लभाषा',
 				'en_GB' => 'आङ्ग्लदेशीय आङ्ग्लभाषा:',
 				'en_GB@alt=short' => 'यूके आङ्ग्लभाषा:',
 				'en_US' => 'अमेरिकादेशीय आङ्ग्लभाषा:',
 				'en_US@alt=short' => 'यूएस आङ्ग्लभाषा:',
 				'es' => 'स्पेनीय भाषा:',
 				'es_419' => 'लैटिन अमेरिकादेशीय स्पेनीय भाषा:',
 				'es_ES' => 'फिरङ्गिन् स्पेनीय भाषा:',
 				'es_MX' => 'मैक्सिकन स्पेनीय भाषा:',
 				'fr' => 'फ़्रांसदेशीय भाषा:',
 				'fr_CA' => 'कनाडादेशः फ़्रांसदेशीय भाषा:',
 				'fr_CH' => 'स्विस फ़्रांसदेशीय भाषा:',
 				'grc' => 'पुरातन यवन भाषा',
 				'it' => 'इटलीदेशीय भाषा:',
 				'ja' => 'सूर्यमूलीय भाषा:',
 				'nb' => 'नोर्वीजियन् बॊकामल्',
 				'pt' => 'पुर्तगालदेशीय भाषा:',
 				'pt_BR' => 'ब्राज़ीली पुर्तगालदेशीय भाषा:',
 				'pt_PT' => 'फिरङ्गिन् पुर्तगालदेशीय भाषा:',
 				'ru' => 'रष्यदेशीय भाषा:',
 				'sa' => 'संस्कृत भाषा',
 				'sq' => 'अल्बेनियन्',
 				'und' => 'अज्ञात भाषा:',
 				'zh' => 'चीनी',
 				'zh@alt=menu' => 'चीनी, मैंडेरिन',
 				'zh_Hans' => 'सरलीकृत चीनी',
 				'zh_Hans@alt=long' => 'सरलीकृत मैंडेरिन चीनी',
 				'zh_Hant' => 'परम्परागत चीनी',
 				'zh_Hant@alt=long' => 'परम्परागत मैंडेरिन चीनी',

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
 			'Armi' => 'अर्मि',
 			'Armn' => 'अर्मेनियन्',
 			'Avst' => 'अवेस्थन्',
 			'Bali' => 'बालिनीस्',
 			'Batk' => 'बट्टक्',
 			'Beng' => 'बंगालि',
 			'Cyrl' => 'सिरिलिक:',
 			'Hans' => 'सरलीकृत',
 			'Hans@alt=stand-alone' => 'सरलीकृत हान',
 			'Hant' => 'परम्परागत',
 			'Hant@alt=stand-alone' => 'परम्परागत हान',
 			'Latn' => 'लैटिन:',
 			'Zxxx' => 'अलिखित:',
 			'Zzzz' => 'अज्ञात लिपि:',

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
			'001' => 'लोक',
 			'002' => 'कालद्वीप',
 			'003' => 'उत्तरामेरिका',
 			'005' => 'दक्षिणामेरिका',
 			'009' => 'सामुद्रखण्ड',
 			'013' => 'मध्यामेरिका',
 			'019' => 'अमेरिकाखण्ड',
 			'021' => 'औदीच्यामेरिका',
 			'142' => 'जम्बुद्विप',
 			'150' => 'यूरोपखण्ड',
 			'BR' => 'ब्राजील',
 			'CN' => 'चीन:',
 			'DE' => 'जर्मनीदेश:',
 			'EU' => 'यूरोपसङ्घ',
 			'EZ' => 'यूरोमण्डल',
 			'FR' => 'फ़्रांस:',
 			'GB' => 'संयुक्त राष्ट्र:',
 			'IN' => 'भारतः',
 			'IT' => 'इटली:',
 			'JP' => 'जापन:',
 			'RU' => 'रष्यदेश:',
 			'UN' => 'संयुक्तराष्ट्रसङ्घ',
 			'US' => 'संयुक्त राज्य:',
 			'ZZ' => 'अज्ञात क्षेत्र:',

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
 				'gregorian' => q{ग्रेगोरियन पञ्चाङ्ग},
 			},
 			'collation' => {
 				'standard' => q{मानक न्यूनतम क्रम},
 				'traditional' => q{परम्परागत न्यूनतम क्रम},
 			},
 			'numbers' => {
 				'latn' => q{पाश्चात्य अङ्कः},
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
			'metric' => q{छन्दोमान},
 			'UK' => q{सं.अ.},
 			'US' => q{सं.रा.},

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
			auxiliary => qr{[‌‍ ऍ ऑ ॅ ॉ]},
			index => ['अ', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ऋ', 'ॠ', 'ऌ', 'ॡ', 'ए', 'ऐ', 'ओ', 'औ', 'क', 'ख', 'ग', 'घ', 'ङ', 'च', 'छ', 'ज', 'झ', 'ञ', 'ट', 'ठ', 'ड', 'ढ', 'ण', 'त', 'थ', 'द', 'ध', 'न', 'प', 'फ', 'ब', 'भ', 'म', 'य', 'र', 'ल', 'ळ', 'व', 'श', 'ष', 'स', 'ह'],
			main => qr{[॑ ॒ ़ ँ ंः ॐ अ आ इ ई उ ऊ ऋ ॠ ऌ ॡ ए ऐ ओ औ क ख ग घ ङ च छ ज झ ञ ट ठ ड ढ ण त थ द ध न प फ ब भ म य र ल ळ व श ष स ह ऽ ा ि ी ु ू ृ ॄ ॢ ॣ े ै ो ौ ्]},
			numbers => qr{[\- ‑ , . % ‰ + 0० 1१ 2२ 3३ 4४ 5५ 6६ 7७ 8८ 9९]},
			punctuation => qr{[_ \- ‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] \{ \} § @ * / \\ \& # ′ ″ ` + | ~]},
		};
	},
EOT
: sub {
		return { index => ['अ', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ऋ', 'ॠ', 'ऌ', 'ॡ', 'ए', 'ऐ', 'ओ', 'औ', 'क', 'ख', 'ग', 'घ', 'ङ', 'च', 'छ', 'ज', 'झ', 'ञ', 'ट', 'ठ', 'ड', 'ढ', 'ण', 'त', 'थ', 'द', 'ध', 'न', 'प', 'फ', 'ब', 'भ', 'म', 'य', 'र', 'ल', 'ळ', 'व', 'श', 'ष', 'स', 'ह'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:आम्|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:न|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, तथा {1}),
				2 => q({0} तथा {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'deva',
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
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '[#E0]',
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
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##,##0.00',
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
				'currency' => q(फिरङ्गिन् मुद्रा),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(आङ्ग्लदेशीयः पाउंड),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(भारतीय रूप्यकम्),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(जापानी येन),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(रष्यदेशीय रूबल),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(यूएस डॉलर),
				'other' => q(अमेरिकादेशः डॉलर),
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
							'जनवरी:',
							'फरवरी:',
							'मार्च:',
							'अप्रैल:',
							'मई',
							'जून:',
							'जुलाई:',
							'अगस्त:',
							'सितंबर:',
							'अक्तूबर:',
							'नवंबर:',
							'दिसंबर:'
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
							'जनवरीमासः',
							'फरवरीमासः',
							'मार्चमासः',
							'अप्रैलमासः',
							'मईमासः',
							'जूनमासः',
							'जुलाईमासः',
							'अगस्तमासः',
							'सितंबरमासः',
							'अक्तूबरमासः',
							'नवंबरमासः',
							'दिसंबरमासः'
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
					short => {
						mon => 'Mon',
						tue => 'Tue',
						wed => 'Wed',
						thu => 'Thu',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Sun'
					},
					wide => {
						mon => 'सोमवासरः',
						tue => 'मंगलवासरः',
						wed => 'बुधवासरः',
						thu => 'गुरुवासर:',
						fri => 'शुक्रवासरः',
						sat => 'शनिवासरः',
						sun => 'रविवासरः'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'सो',
						tue => 'मं',
						wed => 'बु',
						thu => 'गु',
						fri => 'शु',
						sat => 'श',
						sun => 'र'
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
					abbreviated => {0 => 'त्रैमासिक1',
						1 => 'त्रैमासिक2',
						2 => 'त्रैमासिक3',
						3 => 'त्रैमासिक4'
					},
					wide => {0 => 'प्रथम त्रैमासिक',
						1 => 'द्वितीय त्रैमासिक',
						2 => 'तृतीय त्रैमासिक',
						3 => 'चतुर्थ त्रैमासिक'
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
					'am' => q{पूर्वाह्न},
					'pm' => q{अपराह्न},
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
			'full' => q{hh:mm:ss a zzzz},
			'long' => q{hh:mm:ss a z},
			'medium' => q{hh:mm:ss a},
			'short' => q{hh:mm a},
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
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM G y},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMW => q{'week' W 'of' MMM},
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
		'generic' => {
			fallback => '{0}-{1}',
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
		gmtFormat => q(जी.एम.टी. {0}),
		gmtZeroFormat => q(जी.एम.टी.),
		regionFormat => q({0} समय:),
		regionFormat => q({0} अयामसमयः),
		regionFormat => q({0} प्रमाणसमयः),
		'America_Central' => {
			long => {
				'daylight' => q#उत्तर अमेरिका: मध्य अयाम समयः#,
				'generic' => q#उत्तर अमेरिका: मध्य समयः#,
				'standard' => q#उत्तर अमेरिका: मध्य आदर्श समयः#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#उत्तर अमेरिका: पौर्व अयाम समय:#,
				'generic' => q#उत्तर अमेरिका: पौर्व समयः#,
				'standard' => q#उत्तर अमेरिका: पौर्व आदर्श समयः#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#उत्तर अमेरिका: शैल अयाम समयः#,
				'generic' => q#उत्तर अमेरिका: शैल समयः#,
				'standard' => q#उत्तर अमेरिका: शैल आदर्श समयः#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#उत्तर अमेरिका: सन्धिप्रिय अयाम समयः#,
				'generic' => q#उत्तर अमेरिका: सन्धिप्रिय समयः#,
				'standard' => q#उत्तर अमेरिका: सन्धिप्रिय आदर्श समयः#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#अटलाण्टिक अयाम समयः#,
				'generic' => q#अटलाण्टिक समयः#,
				'standard' => q#अटलाण्टिक आदर्श समयः#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#समन्वितः वैश्विक समय:#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#अज्ञात नगरी#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#मध्य यूरोपीय ग्रीष्म समयः#,
				'generic' => q#मध्य यूरोपीय समयः#,
				'standard' => q#मध्य यूरोपीय आदर्श समयः#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#पौर्व यूरोपीय ग्रीष्म समयः#,
				'generic' => q#पौर्व यूरोपीय समयः#,
				'standard' => q#पौर्व यूरोपीय आदर्श समयः#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#पाश्चात्य यूरोपीय ग्रीष्म समयः#,
				'generic' => q#पाश्चात्य यूरोपीय समयः#,
				'standard' => q#पाश्चात्य यूरोपीय आदर्श समयः#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ग्रीनविच मीन समयः#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
