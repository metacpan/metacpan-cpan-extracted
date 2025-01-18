=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Doi - Package for language Dogri

=cut

package Locale::CLDR::Locales::Doi;
# This file auto generated from Data\common\main\doi.xml
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
					'' => {
						'name' => q(प्रधान दिशा),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(प्रधान दिशा),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ग्रै-फोर्स),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ग्रै-फोर्स),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(मीटर फी सकिंट²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(मीटर फी सकिंट²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(आर्क मिंट),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(आर्क मिंट),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(आर्क सकिंट),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(आर्क सकिंट),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(डिग्रियां),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(डिग्रियां),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(रेडियन),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(रेडियन),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(घमघेरे),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(घमघेरे),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(किल्ले),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(किल्ले),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(डोनम),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(डोनम),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(हैक्टर),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(हैक्टर),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(वर्ग सैंटीमीटर),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(वर्ग सैंटीमीटर),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(वर्ग फुट),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(वर्ग फुट),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(वर्ग इंच),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(वर्ग इंच),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(वर्ग किलोमीटर),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(वर्ग किलोमीटर),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(वर्ग मीटर),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(वर्ग मीटर),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(वर्ग मील),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(वर्ग मील),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(वर्ग गज),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(वर्ग गज),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(कैरट),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(कैरट),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(मिलिग्राम फी डैसीलीटर),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(मिलिग्राम फी डैसीलीटर),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(मिलीमोल फी लीटर),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(मिलीमोल फी लीटर),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(मोल),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(मोल),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(प्रतिशत/फीसदी),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(प्रतिशत/फीसदी),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(फी ज्हार),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(फी ज्हार),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(हिस्से फी दस लक्ख),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(हिस्से फी दस लक्ख),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(फी दस ज्हार),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(फी दस ज्हार),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(लीटर प्रति 100 किलोमीटर),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(लीटर प्रति 100 किलोमीटर),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(लीटर प्रति किलोमीटर),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(लीटर प्रति किलोमीटर),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(मील प्रति गैलन),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(मील प्रति गैलन),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(मील प्रति इंपीरियल गैलन),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(मील प्रति इंपीरियल गैलन),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(बिट),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(बिट),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(बाइट),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(बाइट),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(गीगाबिट),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(गीगाबिट),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(गीगाबाइट),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(गीगाबाइट),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(किलोबिट),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(किलोबिट),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(किलोबाइट),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(किलोबाइट),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(मैगाबिट),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(मैगाबिट),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(मैगाबाइट),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(मैगाबाइट),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(पेटाबाइट),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(पेटाबाइट),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(टैराबिट),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(टैराबिट),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(टैराबाइट),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(टैराबाइट),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(सदियां),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(सदियां),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(दिन),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(दिन),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(द्हाके),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(द्हाके),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(घैंटे),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(घैंटे),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(माइक्रोसकिंट),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(माइक्रोसकिंट),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(मिलीसकिंट),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(मिलीसकिंट),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(मिंट),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(मिंट),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(म्हीने),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(म्हीने),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(नैनो सकिंट),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(नैनो सकिंट),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(त्रमाहियां),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(त्रमाहियां),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(सकिंट),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(सकिंट),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(हफ्ते),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(हफ्ते),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ब’रे/साल),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ब’रे/साल),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(एंपीयर),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(एंपीयर),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(मिलीएंपीयर),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(मिलीएंपीयर),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ओम),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ओम),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(वोल्ट),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(वोल्ट),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(ब्रिटिश थर्मल यूनटां),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(ब्रिटिश थर्मल यूनटां),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(कैलोरियां),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(कैलोरियां),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(इलैक्ट्रॉनवोल्ट),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(इलैक्ट्रॉनवोल्ट),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(जूल),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(जूल),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(किलो कैलोरी),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(किलो कैलोरी),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(किलो जूल),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(किलो जूल),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(किलोवॉट-घैंटे),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(किलोवॉट-घैंटे),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(यूऐस्स थर्म),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(यूऐस्स थर्म),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(किलोवॉट-घैंटे फी 100किलोमीटर),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(किलोवॉट-घैंटे फी 100किलोमीटर),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(न्यूटन),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(न्यूटन),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(पौंड-बल),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(पौंड-बल),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(गीगाहर्ट्ज़),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(गीगाहर्ट्ज़),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(हर्ट्ज़),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(हर्ट्ज़),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(किलोहर्ट्ज़),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(किलोहर्ट्ज़),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(मैगाहर्ट्ज़),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(मैगाहर्ट्ज़),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(टाइपोग्राफ़िक ऐम्म),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(टाइपोग्राफ़िक ऐम्म),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(मैगापिक्सल),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(मैगापिक्सल),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(पिक्सल),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(पिक्सल),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(पिक्सल फी सैंटीमीटर),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(पिक्सल फी सैंटीमीटर),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(पिक्सल फी इंच),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(पिक्सल फी इंच),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(खगोली यूनटां),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(खगोली यूनटां),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(सैंटीमीटर),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(सैंटीमीटर),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(डैसीमीटर),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(डैसीमीटर),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(धरती दा घेरा),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(धरती दा घेरा),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(मसातरां),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(मसातरां),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(फुट),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(फुट),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(फरलांग),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(फरलांग),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(इंच),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(इंच),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(किलोमीटर),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(किलोमीटर),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(रुशनाई ब’रे),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(रुशनाई ब’रे),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(मीटर),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(मीटर),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(माइक्रोमीटर),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(माइक्रोमीटर),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(मील),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(मील),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(मील-स्कैण्डिनेवियन),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(मील-स्कैण्डिनेवियन),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(मिलीमीटर),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(मिलीमीटर),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(नैनोमीटर),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(नैनोमीटर),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(नॉटिकल मील),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(नॉटिकल मील),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(पारसेक),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(पारसेक),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(पिकोमीटर),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(पिकोमीटर),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(सौर अद्धाव्यास),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(सौर अद्धाव्यास),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(गज),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(गज),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(कैंडेला),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(कैंडेला),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(लुमेन),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(लुमेन),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(लक्स),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(लक्स),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(सौर चानन),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(सौर चानन),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(कैरट),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(कैरट),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(डाल्टन),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(डाल्टन),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(धरती पिंड),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(धरती पिंड),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(डेढ रत्ती),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(डेढ रत्ती),
					},
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
						'name' => q(किलोग्राम),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(किलोग्राम),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(माइक्रोग्राम),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(माइक्रोग्राम),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(मिलीग्राम),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(मिलीग्राम),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(औंस),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(औंस),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ट्राय औंस),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ट्राय औंस),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(पौंड),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(पौंड),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(सौर पिंड),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(सौर पिंड),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(स्टोन),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(स्टोन),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(मीट्रिक टन),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(मीट्रिक टन),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(गीगावॉट),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(गीगावॉट),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(हार्सपावर),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(हार्सपावर),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(किलोवॉट),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(किलोवॉट),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(मिलीवॉट),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(मिलीवॉट),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(वॉट),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(वॉट),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(वायुमंडली दबाऽ),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(वायुमंडली दबाऽ),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(बार),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(बार),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(हैक्टोपास्कल),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(हैक्टोपास्कल),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(पाराई इंच),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(पाराई इंच),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(किलोपास्कल),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(किलोपास्कल),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(मैगापास्कल),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(मैगापास्कल),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(मिलीबार),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(मिलीबार),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(पाराई मिलीमीटर),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(पाराई मिलीमीटर),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(पास्कल),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(पास्कल),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(पौंड-फोर्स फी वर्ग इंच),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(पौंड-फोर्स फी वर्ग इंच),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(किलोमीटर फी घैंटा),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(किलोमीटर फी घैंटा),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(नॉट),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(नॉट),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(मीटर प्रति सकिंट),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(मीटर प्रति सकिंट),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(मील प्रति घैंटा),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(मील प्रति घैंटा),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(डिग्री सेल्सियस),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(डिग्री सेल्सियस),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(डिग्री फारेनहाइट),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(डिग्री फारेनहाइट),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(केल्विन),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(केल्विन),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(न्यूटन-मीटर),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(न्यूटन-मीटर),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(पौंड-फोर्स-फुट),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(पौंड-फोर्स-फुट),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(किल्ला-फुट),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(किल्ला-फुट),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(बैरल),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(बैरल),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(बुशल),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(बुशल),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(सैंटीलीटर),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(सैंटीलीटर),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(क्यूबिक सेंटीमीटर),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(क्यूबिक सेंटीमीटर),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(क्यूबिक फुट),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(क्यूबिक फुट),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(क्यूबिक इंच),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(क्यूबिक इंच),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(क्यूबिक किलोमीटर),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(क्यूबिक किलोमीटर),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(क्यूबिक मीटर),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(क्यूबिक मीटर),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(क्यूबिक मील),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(क्यूबिक मील),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(क्यूबिक गज),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(क्यूबिक गज),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(कप),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(कप),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(मीट्रिक कप),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(मीट्रिक कप),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(डैसीलीटर),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(डैसीलीटर),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(डेज़र्ट स्पून),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(डेज़र्ट स्पून),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(इंपी. डेज़र्टस्पून),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(इंपी. डेज़र्टस्पून),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ड्रैम फ्लूइड),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ड्रैम फ्लूइड),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(बूंद),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(बूंद),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(फ्लूइड औंस),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(फ्लूइड औंस),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(गैलनां),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(गैलनां),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(इंपीरियल गैलनां),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(इंपीरियल गैलनां),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(हैक्टोलीटर),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(हैक्टोलीटर),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(जिगर),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(जिगर),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(लीटर),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(लीटर),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(मैगालीटर),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(मैगालीटर),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(मिलीलीटर),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(मिलीलीटर),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(चूंडियां),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(चूंडियां),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(पिंट),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(पिंट),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(मीट्रिक पिंट),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(मीट्रिक पिंट),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(कुआर्ट),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(कुआर्ट),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(इंपी. कुआर्ट),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(इंपी. कुआर्ट),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(टेबलस्पून),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(टेबलस्पून),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(टी स्पून),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(टी स्पून),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(दिशा),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(दिशा),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ग्रै-फोर्स),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ग्रै-फोर्स),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(मीटर/स²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(मीटर/स²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(आर्क मिंट),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(आर्क मिंट),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(आर्कसकिं),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(आर्कसकिं),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(डिग.),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(डिग.),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(रेडि),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(रेडि),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(घमघेरा),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(घमघेरा),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(किल्ला),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(किल्ला),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(डोनम),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(डोनम),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(हैक्टर),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(हैक्टर),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(व.सैंमी),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(व.सैंमी),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(वफु),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(वफु),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(वइं),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(वइं),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(व. किमी),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(व. किमी),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(व. मीटर),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(व. मीटर),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(व.मील),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(व.मील),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(वग),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(वग),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(कैरट),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(कैरट),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(मि॰ग्रा॰/डैली),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(मि॰ग्रा॰/डैली),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(मिलीमोल/ली),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(मिलीमोल/ली),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(मोल),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(मोल),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(हिफीदल),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(हिफीदल),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ली/100 किमी),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ली/100 किमी),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(लीटर/किमी),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(लीटर/किमी),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(मील/गै),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(मील/गै),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(मी/गै यूके),
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(मी/गै यूके),
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(बिट),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(बिट),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(बा),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(बा),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(गीबि),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(गीबि),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(गीबा),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(गीबा),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(किबी),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(किबी),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(किबा),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(किबा),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(मैबि),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(मैबि),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(मैबा),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(मैबा),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(पेबा),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(पेबा),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(टैबा),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(टैबा),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(टैबा),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(टैबा),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(स.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(स.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(दिन),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(दिन),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(द्हा.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(द्हा.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(घैंटा),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(घैंटा),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(मासकिं),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(मासकिं),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(मि.सकिं),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(मि.सकिं),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(मिं),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(मिं),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(म्हीना),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(म्हीना),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(नैसकिं),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(नैसकिं),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(त्रमा.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(त्रमा.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(सकिं),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(सकिं),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(हफ्),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(हफ्),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ब’रा/साल),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ब’रा/साल),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(एंपी),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(एंपी),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(मिएं),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(मिएं),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ओम),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ओम),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(वोल्ट),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(वोल्ट),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(ब्रिथयू),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(ब्रिथयू),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(कैल),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(कैल),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(इवो),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(इवो),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(जूल),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(जूल),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(किकैल),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(किकैल),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(किजू),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(किजू),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(किवॉघैं),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(किवॉघैं),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(यूऐस्स थर्म),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(यूऐस्स थर्म),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(किवॉघैं/100किमी),
						'one' => q({0}किल्लोवाट/100किमी),
						'other' => q({0} किल्लोवाट/100किमी),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(किवॉघैं/100किमी),
						'one' => q({0}किल्लोवाट/100किमी),
						'other' => q({0} किल्लोवाट/100किमी),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(न्यू.),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(न्यू.),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(खगोयू),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(खगोयू),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(सैंमी),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(सैंमी),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(डैमी),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(डैमी),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(मसातर),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(मसातर),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(फु.),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(फु.),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(फरलांग),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(फरलांग),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(इं.),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(इं.),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(किमी),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(किमी),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(रुब),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(रुब),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(मी),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(मी),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(मील),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(मील),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(मिमी),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(मिमी),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(पारसेक),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(पारसेक),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ग.),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ग.),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(लक्स),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(लक्स),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(कैरट),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(कैरट),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(डा),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(डा),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(डे. रत्ती),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(डे. रत्ती),
					},
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
						'name' => q(किग्रा),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(किग्रा),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(माग्रा),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(माग्रा),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(मिग्रा),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(मिग्रा),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(औं),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(औं),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(औं.ट्रा),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(औं.ट्रा),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(पौंड),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(पौंड),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(स्टोन),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(स्टोन),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(टन),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(टन),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(मैवॉ),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(मैवॉ),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(हापा),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(हापा),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(किवॉ),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(किवॉ),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(मिवॉ),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(मिवॉ),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(वॉट),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(वॉट),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(बार),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(बार),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(किपा),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(किपा),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(मेपा),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(मेपा),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(पा),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(पा),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(किमी/घैं),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(किमी/घैं),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(नॉट),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(नॉट),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(मीटर/स),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(मीटर/स),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(मील/घैं),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(मील/घैं),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°से॰),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°से॰),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(डिग्री फारेनहाइट),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(डिग्री फारेनहाइट),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(न्यू.मी.),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(न्यू.मी.),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(किल्ला फु),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(किल्ला फु),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(बैर.),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(बैर.),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(बुशल),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(बुशल),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(सैली),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(सैली),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(क्यू सैंमी),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(क्यू सैंमी),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(क्यूफु),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(क्यूफु),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(क्यूइं),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(क्यूइं),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(क्यू.किमी),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(क्यू.किमी),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(क्यू मी),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(क्यू मी),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(क्यू मील),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(क्यू मील),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(क्यूग),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(क्यूग),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(कप),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(कप),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(मीक),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(मीक),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(डैली),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(डैली),
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
					'volume-dram' => {
						'name' => q(ड्रै.फ्लू.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ड्रै.फ्लू.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(बूंद),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(बूंद),
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
					'volume-gallon' => {
						'name' => q(गैल),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(गैल),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(इंपी गैल),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(इंपी गैल),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(हैली),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(हैली),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(जिगर),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(जिगर),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(लीटर),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(लीटर),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(मैली),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(मैली),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(मिली),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(मिली),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(चूं),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(चूं),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(पिं.),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(पिं.),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(मीपिं),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(मीपिं),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(कुआर्ट),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(कुआर्ट),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(कु इंपी),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(कु इंपी),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(दिशा),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(दिशा),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ग्रै-फोर्स),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ग्रै-फोर्स),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(मीटर/सकिं²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(मीटर/सकिं²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(आर्क मिंट),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(आर्क मिंट),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(आर्क सकिं),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(आर्क सकिं),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(डिग्रियां),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(डिग्रियां),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(रेडियन),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(रेडियन),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(घमघेरे),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(घमघेरे),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(किल्ले),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(किल्ले),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(डोनम),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(डोनम),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(हैक्टर),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(हैक्टर),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(व. सैं.मी.),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(व. सैं.मी.),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(व.फु.),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(व.फु.),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(व.इं॰),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(व.इं॰),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(व. कि.मी.),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(व. कि.मी.),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(व. मीटर),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(व. मीटर),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(व.मील),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(व.मील),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(व.गज),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(व.गज),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(कैरट),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(कैरट),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(मि॰ग्रा॰/डै.ली.),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(मि॰ग्रा॰/डै.ली.),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(मिलीमोल/लीटर),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(मिलीमोल/लीटर),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(मोल),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(मोल),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(प्रतिशत/फीसदी),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(प्रतिशत/फीसदी),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(फी ज्हार),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(फी ज्हार),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(हिस्से/दस लक्ख),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(हिस्से/दस लक्ख),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ली./100 कि.मी.),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ली./100 कि.मी.),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(लीटर/किमी),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(लीटर/किमी),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(मील/गैल),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(मील/गैल),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(मील/गैल इंपी.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(मील/गैल इंपी.),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(बिट),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(बिट),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(बाइट),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(बाइट),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(गीबिट),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(गीबिट),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(गीबाइट),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(गीबाइट),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(किबिट),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(किबिट),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(किबाइट),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(किबाइट),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(मैबिट),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(मैबिट),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(मैबाइट),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(मैबाइट),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(पेबाइट),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(पेबाइट),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(टैबाइट),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(टैबाइट),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(स.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(स.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(दिन),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(दिन),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(द्हा.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(द्हा.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(घैंटे),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(घैंटे),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(माइक्रोसकिं),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(माइक्रोसकिं),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(मिलीसकिं.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(मिलीसकिं.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(मिं.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(मिं.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(म्हीने),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(म्हीने),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(नैनो सकिं),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(नैनो सकिं),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(त्रमा.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(त्रमा.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(सकिं.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(सकिं.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(हफ्ते),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(हफ्ते),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ब’रे/साल),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ब’रे/साल),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(एंपी),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(एंपी),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(मिलीएंप),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(मिलीएंप),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ओम),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ओम),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(वोल्ट),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(वोल्ट),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(ब्रिथयू),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(ब्रिथयू),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(कैल),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(कैल),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(इलैक्ट्रॉनवोल्ट),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(इलैक्ट्रॉनवोल्ट),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(जूल),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(जूल),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(किकैल),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(किकैल),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(किलो जूल),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(किलो जूल),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(किवॉघैं),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(किवॉघैं),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(यूऐस्स थर्म),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(यूऐस्स थर्म),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(न्यूटन),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(न्यूटन),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(मैगापिक्सल),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(मैगापिक्सल),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(पिक्सल),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(पिक्सल),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(खगो.यू.),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(खगो.यू.),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(सैं.मी.),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(सैं.मी.),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(डै.मी.),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(डै.मी.),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(मसातरां),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(मसातरां),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(फुट),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(फुट),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(फरलांग),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(फरलांग),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(इंच),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(इंच),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(कि.मी.),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(कि.मी.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(रुशनाई ब’रे),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(रुशनाई ब’रे),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(मी.),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(मी.),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(मामी),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(मामी),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(मील),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(मील),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(मि.मी.),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(मि.मी.),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(नैमी),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(नैमी),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(नॉमी),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(नॉमी),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(पारसेक),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(पारसेक),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(पिमी),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(पिमी),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(गज),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(गज),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(लक्स),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(लक्स),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(कैरट),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(कैरट),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(डाल्टन),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(डाल्टन),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(डेढ रत्ती),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(डेढ रत्ती),
					},
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
						'name' => q(कि.ग्रा.),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(कि.ग्रा.),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(मा.ग्रा.),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(मा.ग्रा.),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(मि.ग्रा.),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(मि.ग्रा.),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(औं.),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(औं.),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(औं. ट्राय),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(औं. ट्राय),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(पौंड),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(पौंड),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(स्टोन),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(स्टोन),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(टन),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(टन),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(मैवॉ),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(मैवॉ),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(हापा),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(हापा),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(किवॉ),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(किवॉ),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(मिवॉ),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(मिवॉ),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(वॉट),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(वॉट),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(बार),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(बार),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(किपा.),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(किपा.),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(मेपा.),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(मेपा.),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(पा.),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(पा.),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(कि.मी./घैंटा),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(कि.मी./घैंटा),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(नॉट),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(नॉट),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(मीटर/सकिं),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(मीटर/सकिं),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(मील/घैंटा),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(मील/घैंटा),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(डिग्री सेल्सियस),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(डिग्री सेल्सियस),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(डिग्री फारेनहाइट),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(डिग्री फारेनहाइट),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(न्यू.मी.),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(न्यू.मी.),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(किल्ला फु.),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(किल्ला फु.),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(बैरल),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(बैरल),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(बुशल),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(बुशल),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(सैं.ली.),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(सैं.ली.),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(क्यू.सैं.मी.),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(क्यू.सैं.मी.),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(क्यू. फुट),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(क्यू. फुट),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(क्यू. इंच),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(क्यू. इंच),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(क्यू. कि.मी.),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(क्यू. कि.मी.),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(क्यू.मी.),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(क्यू.मी.),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(क्यू. मील),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(क्यू. मील),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(क्यू.ग.),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(क्यू.ग.),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(कप),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(कप),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(मी.क.),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(मी.क.),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(डै.ली.),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(डै.ली.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(डेस्पून),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(डेस्पून),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(इंपी डेस्पून),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(इंपी डेस्पून),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ड्रैम फ्लूइड),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ड्रैम फ्लूइड),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(बूंद),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(बूंद),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(फ्लू. औं.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(फ्लू. औं.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(गैल.),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(गैल.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(इंपी. गैल.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(इंपी. गैल.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(है.ली.),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(है.ली.),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(जिगर),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(जिगर),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(लीटर),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(लीटर),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(मै.ली.),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(मै.ली.),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(मि.ली.),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(मि.ली.),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(चूंडी),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(चूंडी),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(पिंट),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(पिंट),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(मी.पिं.),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(मी.पिं.),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(कुआर्ट),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(कुआर्ट),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(कु इंपी),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(कु इंपी),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(टेस्पून),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(टेस्पून),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(टीस्पून),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(टीस्पून),
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
			'indian' => {
				'format' => {
					wide => {
						nonleap => [
							'चेत्तर',
							'बसाख',
							'जेठ',
							'हाड़',
							'सौन',
							'भाद्रो',
							'अस्सू',
							'कत्ता',
							'मग्घर',
							'पोह्',
							'माघ',
							'फग्गन'
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
		'indian' => {
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
		'indian' => {
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
		'indian' => {
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
		'indian' => {
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
