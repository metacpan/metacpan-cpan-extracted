=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Hi::Latn - Package for language Hindi

=cut

package Locale::CLDR::Locales::Hi::Latn;
# This file auto generated from Data\common\main\hi_Latn.xml
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

extends('Locale::CLDR::Locales::En::Latn::In');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'af' => 'Afreeki',
 				'bgc' => 'Hariyaanvi',
 				'bn' => 'Bangla',
 				'bo' => 'Tibbati',
 				'ckb' => 'Kurdish, Sorani',
 				'crh' => 'Crimean Turkish',
 				'fa' => 'Faarsi',
 				'ff' => 'Fulah',
 				'lah' => 'Lahnda',
 				'mic' => 'Mi\'kmaq',
 				'mus' => 'Muscogee',
 				'nan' => 'Min Nan',
 				'nb' => 'Norwegian Bokmal',
 				'nds_NL' => 'Low Saxon',
 				'ug' => 'Uighur',
 				'wal' => 'walamo',

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
			'Bali' => 'Baali',
 			'Beng' => 'Bangla',
 			'Inds' => 'Sindhu',
 			'Mymr' => 'Burmese',
 			'Orya' => 'Odia',
 			'Talu' => 'Naya Tai Lue',

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
			'AX' => 'Aland Islands',
 			'BL' => 'St. Barthelemy',
 			'CI' => 'Cote d’Ivoire',
 			'CW' => 'Curacao',
 			'IN' => 'Bharat',
 			'KN' => 'St. Kitts & Nevis',
 			'LC' => 'St. Lucia',
 			'MF' => 'St. Martin',
 			'PM' => 'St. Pierre & Miquelon',
 			'RE' => 'Reunion',
 			'SH' => 'St. Helena',
 			'ST' => 'Sao Tome & Principe',
 			'TR' => 'Turkiye',
 			'TR@alt=variant' => 'Turkiye',
 			'UM' => 'U.S. Outlying Islands',
 			'US@alt=short' => 'America',
 			'VC' => 'St. Vincent & Grenadines',
 			'VI' => 'U.S. Virgin Islands',
 			'XB' => 'Pseudo-Bidirectional',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'colalternate' => 'Symbol sorting ignore karein',
 			'colcasefirst' => 'Uppercase/Lowercase ke order mein rakhna',
 			'colcaselevel' => 'Case Sensitive Sorting',
 			'colnormalization' => 'Normalized Sorting',
 			'colstrength' => 'Sorting ki Strength',
 			'fw' => 'Week kaa pahla din',
 			'hc' => 'Hours ki Cycle (12 vs 24)',
 			'lb' => 'Line break ki style',
 			'lw' => 'Words Setting mein Line Breaks',
 			'ms' => 'Measurement kaa system',
 			'rg' => 'Supplemental Data ke liye region',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'colalternate' => {
 				'non-ignorable' => q{Symbols ko sort karein},
 				'shifted' => q{Symbols ko ignore karte hue sort karein},
 			},
 			'colbackwards' => {
 				'no' => q{Accents ko normally sort karein},
 				'yes' => q{Accents ko reverse mein sort karein},
 			},
 			'colcasefirst' => {
 				'lower' => q{Pahle lowercase walon ko sort karein},
 				'no' => q{Normal case order mein sort karein},
 				'upper' => q{Pahle uppercase walon ko sort karein},
 			},
 			'colcaselevel' => {
 				'no' => q{Case insensitive sorting karein},
 				'yes' => q{Case sensitive sorting karein},
 			},
 			'collation' => {
 				'compat' => q{Compatibility ke liye, picchla sort order},
 				'dictionary' => q{Dictionary kaa sort order},
 				'searchjl' => q{Hangul initial consonant se search karein},
 			},
 			'colnormalization' => {
 				'no' => q{Bina normalization ke sort karein},
 				'yes' => q{Sort Unicode Normalized},
 			},
 			'colnumeric' => {
 				'no' => q{Digits ko alag-alag sort karein},
 				'yes' => q{Digits ko numerically sort karein},
 			},
 			'colstrength' => {
 				'identical' => q{Sabhi ko sort karein},
 				'primary' => q{Sirf Base Letters ko sort karein},
 				'quaternary' => q{Accents/Case/Width/Kana ko sort karein},
 				'secondary' => q{Accents ko sort karein},
 				'tertiary' => q{Accents/Case/Width ko sort karein},
 			},
 			'd0' => {
 				'ascii' => q{ASCII},
 				'fwidth' => q{Poori width},
 				'hwidth' => q{Aadhi width},
 				'lower' => q{Lowercase},
 				'npinyin' => q{Numeric tones ke saath pinyin karna},
 				'title' => q{Titlecase},
 				'upper' => q{Uppercase},
 			},
 			'em' => {
 				'default' => q{Emoji Characters ke liye Default Presentation use karein},
 				'emoji' => q{Emoji Characters ke liye Emoji Presentation prefer karein},
 				'text' => q{Emoji Characters ke liye Text Presentation prefer karein},
 			},
 			'fw' => {
 				'fri' => q{Week kaa pahla din Friday},
 				'mon' => q{Week kaa pahla din Monday},
 				'sat' => q{Week kaa pahla din Saturday},
 				'sun' => q{Week kaa pahla din Sunday},
 				'thu' => q{Week kaa pahla din Thursday},
 				'tue' => q{Week kaa pahla din Tuesday},
 				'wed' => q{Week kaa pahla din Wednesday},
 			},
 			'hc' => {
 				'h11' => q{12 Hour System (0–11)},
 				'h12' => q{12 Hour System (1–12)},
 				'h23' => q{24 Hour System (0–23)},
 				'h24' => q{24 Hour System (1–24)},
 			},
 			'lw' => {
 				'breakall' => q{Sabhi Words mein Line Breaks allow karein},
 				'keepall' => q{Sabhi Words mein Line Breaks se bachein},
 				'normal' => q{Words ke liye normal Line Breaks},
 				'phrase' => q{Phrases mein Line Breaks se bachein},
 			},
 			'numbers' => {
 				'beng' => q{Bangla Digits},
 				'hanidec' => q{Chinese Decimal Numbers},
 				'hans' => q{Simplified Chinese Numbers},
 				'hansfin' => q{Simplified Chinese Financial Numbers},
 				'hant' => q{Traditional Chinese Numbers},
 				'hantfin' => q{Traditional Chinese Financial Numbers},
 				'hebr' => q{Hebrew Numbers},
 				'jpan' => q{Japanese Numbers},
 				'jpanfin' => q{Japanese Financial Numbers},
 				'orya' => q{Odia Digits},
 				'roman' => q{Roman Numbers},
 				'romanlow' => q{Roman Lowercase Numbers},
 				'taml' => q{Traditional Tamil Numbers},
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
			'UK' => q{U.K.},
 			'US' => q{U.S.},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Bhasha: {0}',
 			'script' => 'Lipi: {0}',
 			'region' => 'Kshetra: {0}',

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
			auxiliary => qr{[ā ḍ ĕē ḥ ī ḷ{l̥} ṁ{m̐} ñṅṇ ŏō ṛ{r̥}{r̥̄} śṣ ṭ ū]},
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
					'concentr-percent' => {
						'name' => q(percent),
						'one' => q({0} percent),
						'other' => q({0} percent),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(percent),
						'one' => q({0} percent),
						'other' => q({0} percent),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miles per Imp. gallon),
						'one' => q({0} mile per Imp. gallon),
						'other' => q({0} miles per Imp. gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miles per Imp. gallon),
						'one' => q({0} mile per Imp. gallon),
						'other' => q({0} miles per Imp. gallon),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} din),
						'other' => q({0} din),
						'per' => q({0} har din),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} din),
						'other' => q({0} din),
						'per' => q({0} har din),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} ghanta),
						'other' => q({0} ghante),
						'per' => q({0} har ghante),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} ghanta),
						'other' => q({0} ghante),
						'per' => q({0} har ghante),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'per' => q({0} har minute),
					},
					# Core Unit Identifier
					'minute' => {
						'per' => q({0} har minute),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} har month),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} har month),
					},
					# Long Unit Identifier
					'duration-second' => {
						'per' => q({0} har second),
					},
					# Core Unit Identifier
					'second' => {
						'per' => q({0} har second),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0} har week),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0} har week),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} saal),
						'other' => q({0} saal),
						'per' => q({0} har saal),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} saal),
						'other' => q({0} saal),
						'per' => q({0} har saal),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dots per centimeter),
						'one' => q({0} dot per centimeter),
						'other' => q({0} dots per centimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dots per centimeter),
						'one' => q({0} dot per centimeter),
						'other' => q({0} dots per centimeter),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(Scandinavian miles),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(Scandinavian miles),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} tonne),
						'other' => q({0} tons),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} tonne),
						'other' => q({0} tons),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0} metric ton),
						'other' => q({0} tonnes),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0} metric ton),
						'other' => q({0} tonnes),
					},
					# Long Unit Identifier
					'pressure-gasoline-energy-density' => {
						'name' => q(gasoline equivalent),
					},
					# Core Unit Identifier
					'gasoline-energy-density' => {
						'name' => q(gasoline equivalent),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inch mercury),
						'other' => q({0} inches mercury),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inch mercury),
						'other' => q({0} inches mercury),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimetres mercury),
						'one' => q({0} millimetre mercury),
						'other' => q({0} millimetres mercury),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimetres mercury),
						'one' => q({0} millimetre mercury),
						'other' => q({0} millimetres mercury),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(degrees temperature),
						'one' => q({0} degree temperature),
						'other' => q({0} degrees temperature),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(degrees temperature),
						'one' => q({0} degree temperature),
						'other' => q({0} degrees temperature),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dessert spoons),
						'one' => q({0} dessert spoon),
						'other' => q({0} dessert spoons),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dessert spoons),
						'one' => q({0} dessert spoon),
						'other' => q({0} dessert spoons),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. dessert spoons),
						'one' => q({0} Imp. dessert spoon),
						'other' => q({0} Imp. dessert spoons),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. dessert spoons),
						'one' => q({0} Imp. dessert spoon),
						'other' => q({0} Imp. dessert spoons),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp. gallons),
						'one' => q({0} Imp. gallon),
						'other' => q({0} Imp. gallons),
						'per' => q({0} per Imp. gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp. gallons),
						'one' => q({0} Imp. gallon),
						'other' => q({0} Imp. gallons),
						'per' => q({0} per Imp. gallon),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. quarts),
						'one' => q({0} Imp. quart),
						'other' => q({0} Imp. quarts),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. quarts),
						'one' => q({0} Imp. quart),
						'other' => q({0} Imp. quarts),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(μ {0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(μ {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
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
					'digital-byte' => {
						'name' => q(byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GByte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MByte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0}bar),
						'other' => q({0}bars),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0}bar),
						'other' => q({0}bars),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/hr),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/hr),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp dsp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp dsp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
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
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp qt),
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp qt),
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karats),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karats),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimol/litre),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/litre),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miles/gal US),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miles/gal US),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} din),
						'other' => q({0} din),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} din),
						'other' => q({0} din),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} px),
						'other' => q({0} px),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} px),
						'other' => q({0} px),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0} bar),
						'other' => q({0} bars),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0} bar),
						'other' => q({0} bars),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dstspn),
						'one' => q({0} dstspn),
						'other' => q({0} dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dstspn),
						'one' => q({0} dstspn),
						'other' => q({0} dstspn),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp dstspn),
						'one' => q({0} Imp dstspn),
						'other' => q({0} Imp dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp dstspn),
						'one' => q({0} Imp dstspn),
						'other' => q({0} Imp dstspn),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram fluid),
						'one' => q({0} dram fl),
						'other' => q({0} dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fluid),
						'one' => q({0} dram fl),
						'other' => q({0} dram fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q({0} drop),
						'other' => q({0} drop),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q({0} drop),
						'other' => q({0} drop),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
						'one' => q({0} fl oz Imp.),
						'other' => q({0} fl oz Imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
						'one' => q({0} fl oz Imp.),
						'other' => q({0} fl oz Imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q({0} gal US),
						'other' => q({0} gal US),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q({0} gal US),
						'other' => q({0} gal US),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0} gal),
						'other' => q({0} gal Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0} gal),
						'other' => q({0} gal Imp.),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q({0} pinch),
						'other' => q({0} pinch),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0} pinch),
						'other' => q({0} pinch),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. qt),
						'one' => q({0} Imp. qt),
						'other' => q({0} Imp. qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. qt),
						'one' => q({0} Imp. qt),
						'other' => q({0} Imp. qt),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, aur {1}),
				2 => q({0} aur {1}),
		} }
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

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
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
		'ALL' => {
			display_name => {
				'one' => q(Albanian lek),
				'other' => q(Albanian leke),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rican colon),
				'one' => q(Costa Rican colon),
				'other' => q(Costa Rican colons),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Icelandic krona),
				'one' => q(Icelandic krona),
				'other' => q(Icelandic kronur),
			},
		},
		'LSL' => {
			display_name => {
				'one' => q(Lesotho loti),
				'other' => q(Lesotho lotis),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguan cordoba),
				'one' => q(Nicaraguan cordoba),
				'other' => q(Nicaraguan cordobas),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russian ruble),
				'one' => q(Russian ruble),
				'other' => q(Russian rubles),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Sao Tome & Principe Dobra),
				'one' => q(Sao Tome & Principe dobra),
				'other' => q(Sao Tome & Principe dobras),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezuelan bolivar),
				'one' => q(Venezuelan bolivar),
				'other' => q(Venezuelan bolivars),
			},
		},
		'XXX' => {
			display_name => {
				'one' => q(currency ki unknown unit),
				'other' => q(\(unknown currency\)),
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
							'Apr',
							'May',
							'Jun',
							'Jul',
							'Aug',
							'Sep',
							'Oct',
							'Nov',
							'Dec'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Muh',
							'Saf',
							'Rabi 1',
							'Rabi 2',
							'Jum 1',
							'Jum 2',
							'Rajab',
							'Shab',
							'Ram',
							'Shaw',
							'Zu Q',
							'Zu H'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabi al-Awwal',
							'Rabi as-Saani',
							'Jumaada al-Awwal',
							'Jumaada as-Saani',
							'Rajab',
							'Shaabaan',
							'Ramzaan',
							'Shawwaal',
							'Zu’l-Qaada',
							'Zu’l-Hijja'
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
						tue => 'Mangal',
						wed => 'Budh',
						thu => 'Guru',
						fri => 'Shukra',
						sat => 'Shani',
						sun => 'Ravi'
					},
					narrow => {
						mon => 'So',
						tue => 'Ma',
						wed => 'Bu',
						thu => 'Gu',
						fri => 'Sh',
						sat => 'Sha',
						sun => 'Ra'
					},
					short => {
						mon => 'So',
						tue => 'Ma',
						wed => 'Bu',
						thu => 'Gu',
						fri => 'Shu',
						sat => 'Sha',
						sun => 'Ra'
					},
					wide => {
						mon => 'Somwaar',
						tue => 'Mangalwaar',
						wed => 'Budhwaar',
						thu => 'Guruwaar',
						fri => 'Shukrawaar',
						sat => 'Shaniwaar',
						sun => 'Raviwaar'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Som',
						tue => 'Mangal',
						wed => 'Budh',
						thu => 'Guru',
						fri => 'Shukra',
						sat => 'Shani',
						sun => 'Ravi'
					},
					narrow => {
						mon => 'So',
						tue => 'Ma',
						wed => 'Bu',
						thu => 'Gu',
						fri => 'Sh',
						sat => 'Sha',
						sun => 'Ra'
					},
					short => {
						mon => 'So',
						tue => 'Ma',
						wed => 'Bu',
						thu => 'Gu',
						fri => 'Shu',
						sat => 'Sha',
						sun => 'Ra'
					},
					wide => {
						mon => 'Somwaar',
						tue => 'Mangalwaar',
						wed => 'Budhwaar',
						thu => 'Guruwaar',
						fri => 'Shukrawaar',
						sat => 'Shaniwaar',
						sun => 'Raviwaar'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 2000;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2000;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'afternoon1' => q{dopahar},
					'am' => q{AM},
					'evening1' => q{shaam},
					'midnight' => q{midnight},
					'morning1' => q{subah},
					'night1' => q{raat},
					'noon' => q{noon},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{dopahar},
					'evening1' => q{shaam},
					'midnight' => q{mi},
					'morning1' => q{subah},
					'night1' => q{raat},
					'noon' => q{n},
				},
				'wide' => {
					'afternoon1' => q{dopahar},
					'am' => q{AM},
					'evening1' => q{shaam},
					'midnight' => q{aadhi raat},
					'morning1' => q{subah},
					'night1' => q{raat},
					'noon' => q{Madhyanh},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{dopahar},
					'am' => q{AM},
					'evening1' => q{shaam},
					'midnight' => q{aadhi raat},
					'morning1' => q{subah},
					'night1' => q{raat},
					'noon' => q{Madhyanh},
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
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'islamic' => {
			abbreviated => {
				'0' => 'Hijri'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM, y},
			'medium' => q{dd MMM, y},
			'short' => q{dd/MM/y},
		},
		'islamic' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			GyMMM => q{MMM r(U)},
			GyMMMEd => q{E, d MMM r(U)},
			yMd => q{dd/MM/r},
			yyyyMMM => q{MMM r(U)},
			yyyyMMMEd => q{E, d MMM r(U)},
		},
		'generic' => {
			Bhms => q{h:mm.ss B},
			yyyyMd => q{d/M/y GGGGG},
		},
		'gregorian' => {
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEEEEd => q{G y, dd MMMM, E},
			GyMMMEd => q{G y, dd MMM, E},
			GyMMMd => q{G y, d MMM},
			MMMMW => q{MMMM 'kaa' 'week' W},
			yMMMd => q{d MMM, y},
			yw => q{Y 'kaa' 'week' w},
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
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
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
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMd => {
				d => q{d–d MMM, y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{G y –G y},
				y => q{G y – y},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				M => q{G y MMM – MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y d MMM},
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
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y},
				d => q{E, d – E, d MMM, y},
				y => q{E, d MMM, y – E, d MMM, y},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y},
				d => q{d – d MMM, y},
				y => q{d MMM, y – d MMM, y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Africa/Asmera' => {
			exemplarCity => q#Asmera#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc Sablon#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Ciudad Juarez#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Coral Harbour#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curacao#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St Barthelemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#North America Central Daylight Time#,
				'generic' => q#North America Central Time#,
				'standard' => q#North America Central Standard Time#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#North America Eastern Daylight Time#,
				'generic' => q#North America Eastern Time#,
				'standard' => q#North America Eastern Standard Time#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#North America Mountain Daylight Time#,
				'generic' => q#North America Mountain Time#,
				'standard' => q#North America Mountain Standard Time#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#North America Pacific Daylight Time#,
				'generic' => q#North America Pacific Time#,
				'standard' => q#North America Pacific Standard Time#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#DumontDUrville#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Qostanay#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Saigon#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faeroe#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'generic' => q#HST#,
			},
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponape#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Truk#,
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre & Miquelon Daylight Time#,
				'generic' => q#St. Pierre & Miquelon Time#,
				'standard' => q#St. Pierre & Miquelon Standard Time#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunion Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
