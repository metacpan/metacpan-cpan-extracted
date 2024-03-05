=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Gaa - Package for language Ga

=cut

package Locale::CLDR::Locales::Gaa;
# This file auto generated from Data\common\main\gaa.xml
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
				'ab' => 'Abkhazia',
 				'ace' => 'Achinese',
 				'ada' => 'Dangme',
 				'ady' => 'Adyghe',
 				'af' => 'Afrikaans',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aleut',
 				'am' => 'Amharic',
 				'an' => 'Aragonese',
 				'anp' => 'Angika',
 				'ar' => 'Arabik',
 				'ar_001' => 'Ŋmɛnɛŋmɛnɛ Beiaŋ Arabik',
 				'arp' => 'Arapaho',
 				'as' => 'Assamese',
 				'asa' => 'Asu',
 				'ast' => 'Asturian',
 				'atj' => 'Atikamekw',
 				'av' => 'Avaric',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbaijani',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Bashkir',
 				'ban' => 'Balinese',
 				'bas' => 'Basaa',
 				'be' => 'Belarusian',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgarian',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bm' => 'Bambara',
 				'bn' => 'Bangla',
 				'br' => 'Breton',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnian',
 				'bug' => 'Buginese',
 				'byn' => 'Blin',
 				'ca' => 'Katalan',
 				'cay' => 'Kayuga',
 				'ccp' => 'Tsakma',
 				'ceb' => 'Sebuano',
 				'crr' => 'Karolina Algonkian',
 				'de' => 'German',
 				'de_AT' => 'Austria German',
 				'de_CH' => 'Switzerland German Krɔŋŋ',
 				'en' => 'Blɔfo',
 				'en_AU' => 'Australia Blɔfo',
 				'en_CA' => 'Kanada Blɔfo',
 				'en_GB' => 'Britain Blɔfo',
 				'en_GB@alt=short' => 'UK Blɔfo',
 				'en_US' => 'Amerika Blɔfo',
 				'en_US@alt=short' => 'US Blɔfo',
 				'es' => 'Spanish',
 				'es_419' => 'Romanse Amerika Spanish',
 				'es_ES' => 'Yuropa Spanish',
 				'es_MX' => 'Meziko Spanish',
 				'eu' => 'Baske',
 				'fr' => 'Frɛntsi',
 				'fr_CA' => 'Kanada Frɛntsi',
 				'fr_CH' => 'Switzerland Frɛntsi',
 				'frc' => 'Kajun Frɛntsi',
 				'gaa' => 'Gã',
 				'hi' => 'Hindi',
 				'hy' => 'Armenian',
 				'id' => 'Indonesian',
 				'it' => 'Italian',
 				'ja' => 'Japanese',
 				'ko' => 'Korean',
 				'ksf' => 'Bafia',
 				'my' => 'Burmese',
 				'nl' => 'Daatsi',
 				'nl_BE' => 'Flemish',
 				'pl' => 'Polish',
 				'pt' => 'Portuguese',
 				'pt_BR' => 'Brazil Portuguese',
 				'pt_PT' => 'Yuropa Portuguese',
 				'ru' => 'Russian',
 				'rup' => 'Aromanian',
 				'sq' => 'Albanian',
 				'th' => 'Thai',
 				'tr' => 'Turkish',
 				'und' => 'Wiemɔ ko ni gbɛ́i bɛ mli',
 				'yue' => 'Kantonese',
 				'yue@alt=menu' => 'Tsainesi, Kantonese',
 				'zh' => 'Tsainese',
 				'zh@alt=menu' => 'Tsainese, Mandarin',
 				'zh_Hans' => 'Tsainese Ni Waaa',
 				'zh_Hans@alt=long' => 'Mandarin Tsainese Ni Waaa',
 				'zh_Hant' => 'Blema Tsainese',
 				'zh_Hant@alt=long' => 'Blema Mandarin Tsainese',

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
			'Arab' => 'Arabik',
 			'Cyrl' => 'Russiabii Aniŋmaa',
 			'Hans' => 'Nɔ Ni Yɔɔ Mlɛo',
 			'Hans@alt=stand-alone' => 'Nɔ Ni Yɔɔ Mlɛo Kwraa',
 			'Hant' => 'Blema',
 			'Hant@alt=stand-alone' => 'Tsutsu Blema',
 			'Jpan' => 'Japanese',
 			'Kore' => 'Korean',
 			'Latn' => 'Niŋmaa Ni Asharaa Yiteŋ',
 			'Zxxx' => 'Aŋmaaa',
 			'Zzzz' => 'Niŋmaa Ni Aleee',

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
			'001' => 'Jeŋ Fɛɛ',
 			'002' => 'Afrika',
 			'003' => 'Kooyigbɛ Amerika',
 			'005' => 'Wuoyigbɛ Amerika',
 			'009' => 'Ŋshɔkpɔi',
 			'011' => 'Afrika Anaigbɛ',
 			'013' => 'Teŋgbɛ Amerika',
 			'014' => 'Afrika Bokagbɛ',
 			'015' => 'Afrika Kooyigbɛ',
 			'017' => 'Afrika Teŋgbɛ',
 			'018' => 'Afrika Wuoyigbɛ',
 			'019' => 'Amerika Niiaŋ',
 			'021' => 'Kooyigbɛ Shɔŋŋ Amerika',
 			'029' => 'Karibean',
 			'030' => 'Asia Bokagbɛ',
 			'034' => 'Asia Wuoyigbɛ',
 			'035' => 'Asia Wuoyi-Bokagbɛ',
 			'039' => 'Yuropa Wuoyigbɛ',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Ŋshɔkpɔi Bibii',
 			'061' => 'Ŋshɔkpɔi Bibii Pii',
 			'142' => 'Asia',
 			'143' => 'Asia Teŋgbɛ',
 			'145' => 'Asia Anaigbɛ',
 			'150' => 'Yuropa',
 			'151' => 'Yuropa Bokagbɛ',
 			'154' => 'Yuropa Kooyigbɛ',
 			'155' => 'Yuropa Anaigbɛ',
 			'202' => 'Afrika Fã Ni Yɔɔ Sahara Lɛ Shishi',
 			'419' => 'Romanse Amerika',
 			'AG' => 'Antigua Kɛ Barbuda',
 			'AI' => 'Anguilla',
 			'AO' => 'Angola',
 			'AR' => 'Argentina',
 			'AW' => 'Aruba',
 			'BB' => 'Barbados',
 			'BF' => 'Burkina Faso',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BO' => 'Bolivia',
 			'BQ' => 'Netherlands Ni Yɔɔ Karibean',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BV' => 'Bouvet Ŋshɔkpɔ',
 			'BW' => 'Botswana',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Kongo - Kinshasa',
 			'CD@alt=variant' => 'Kongo (DR)',
 			'CF' => 'Teŋgbɛ Afrika Jeŋmaŋ',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Kongo (Jeŋmaŋ)',
 			'CI' => 'Ko Divua',
 			'CL' => 'Tsili',
 			'CM' => 'Kameroon',
 			'CN' => 'Tsaina',
 			'CO' => 'Kolombia',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kape Verde',
 			'CW' => 'Kurasao',
 			'DJ' => 'Djibouti',
 			'DM' => 'Dominika',
 			'DO' => 'Dominika Republik',
 			'DZ' => 'Algeria',
 			'EA' => 'Keuta Kɛ Melilla',
 			'EC' => 'Ekuador',
 			'EG' => 'Ejipt',
 			'EH' => 'Sahara Wuoyigbɛ',
 			'ER' => 'Eritrea',
 			'ET' => 'Etiopia',
 			'EU' => 'Yuropa Maji Ekomefeemɔ',
 			'EZ' => 'Yuropaniiaŋ',
 			'FK' => 'Falkland Ŋshɔkpɔi',
 			'FK@alt=variant' => 'Falkland Ŋshɔkpɔi Lɛ',
 			'GA' => 'Gabon',
 			'GD' => 'Grenada',
 			'GF' => 'Frentsibii Guiana',
 			'GH' => 'Ghana',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekuatorial Guinea',
 			'GS' => 'Georgia Wuoyi Kɛ Sandwitsi Ŋshɔkpɔi Ni Yɔɔ Wuoyi',
 			'GT' => 'Guatemala',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HN' => 'Honduras',
 			'HT' => 'Haiti',
 			'IC' => 'Kanary Ŋshɔkpɔi',
 			'IN' => 'India',
 			'IO' => 'Britain Shikpɔji Ni Yɔɔ Indian Ŋshɔ Lɛ Mli',
 			'JM' => 'Jamaika',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KM' => 'Komoros',
 			'KN' => 'St. Kitts Kɛ Nevis',
 			'KY' => 'Kayman Ŋshɔkpɔi',
 			'LC' => 'St. Lusia',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LY' => 'Libia',
 			'MA' => 'Moroko',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'ML' => 'Mali',
 			'MO' => 'Makao SAR Tsaina',
 			'MO@alt=short' => 'Makao',
 			'MQ' => 'Martinik',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MU' => 'Mauritius',
 			'MW' => 'Malawi',
 			'MX' => 'Meziko',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibia',
 			'NE' => 'Niger',
 			'NG' => 'Anago',
 			'NI' => 'Nikaragua',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PM' => 'St. Pierre Kɛ Mikelon',
 			'PR' => 'Puerto Riko',
 			'PY' => 'Paraguay',
 			'QO' => 'Ŋshɔkpɔi Ni Yɔɔ Shɔŋŋ',
 			'RE' => 'Réunion',
 			'RW' => 'Rwanda',
 			'SC' => 'Seyshelles',
 			'SD' => 'Sudan',
 			'SH' => 'St. Helena',
 			'SL' => 'Sierra Leone',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan Wuoyi',
 			'ST' => 'São Tomé Kɛ Prínsipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TC' => 'Turks Kɛ Kaikos Ŋshɔkpɔi',
 			'TD' => 'Tsad',
 			'TF' => 'Frentsibii Ashikpɔji Ni Yɔɔ Wuoyi',
 			'TG' => 'Togo',
 			'TN' => 'Tunisia',
 			'TT' => 'Trinidad Kɛ Tobago',
 			'TZ' => 'Tanzania',
 			'UG' => 'Uganda',
 			'UN' => 'Jeŋmaji Ekomefeemɔ',
 			'US' => 'United States',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguay',
 			'VC' => 'St. Vinsent Kɛ Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Britain Ŋshɔkpɔi Ni Atarako Amɛhe',
 			'VI' => 'US Ŋshɔkpɔi Ni Atarako Amɛhe',
 			'XA' => 'Eyaa Ŋwɛi Kɛ Shikpɔŋ Fɛɛ',
 			'XB' => 'Eyaa Biɛ Kɛ Biɛ Fɛɛ',
 			'YT' => 'Mayotte',
 			'ZA' => 'South Afrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'He Ko Ni Gbɛ́i Bɛ Mli',

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
 				'gregorian' => q{Gregory Kalanda},
 				'iso8601' => q{ISO-8601 Kalanda},
 			},
 			'collation' => {
 				'standard' => q{Bɔ Ni Atoɔ Naa Daa},
 			},
 			'numbers' => {
 				'latn' => q{Blɔfomɛi Anɔmbai},
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
			'metric' => q{Susumɔnii},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Language: {0}',
 			'script' => 'Script: {0}',
 			'region' => 'Region: {0}',

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
			auxiliary => qr{[áã é íĩ ó ũ]},
			index => ['A', 'B', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a b d e ɛ f g h i j k l m n ŋ o ɔ p q r s t u v w y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
						'name' => q(jeŋ koji ejwɛ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(jeŋ koji ejwɛ),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} bokã),
						'north' => q({0} kooyi),
						'south' => q({0} wuoyi),
						'west' => q({0} anai),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} bokã),
						'north' => q({0} kooyi),
						'south' => q({0} wuoyi),
						'west' => q({0} anai),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(afii ohai),
						'other' => q(afii ohai {0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(afii ohai),
						'other' => q(afii ohai {0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} daa gbi),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} daa gbi),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(afii nyɔŋma),
						'other' => q(afi nyɔŋmai {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(afii nyɔŋma),
						'other' => q(afi nyɔŋmai {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q(ŋmɛlɛtswai {0}),
						'per' => q({0} ŋmɛlɛtswaa fɛɛ ŋmɛlɛtswaa),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q(ŋmɛlɛtswai {0}),
						'per' => q({0} ŋmɛlɛtswaa fɛɛ ŋmɛlɛtswaa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(sɛkɛnsi mlijaa 1000),
						'other' => q(sɛkɛnsi {0} mlijaa 1000),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(sɛkɛnsi mlijaa 1000),
						'other' => q(sɛkɛnsi {0} mlijaa 1000),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(sɛkɛnsi mlijaa 100),
						'other' => q(sɛkɛnsi {0} mlijaa 100),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(sɛkɛnsi mlijaa 100),
						'other' => q(sɛkɛnsi {0} mlijaa 100),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minitii),
						'other' => q(minitii {0}),
						'per' => q({0} miniti fɛɛ miniti),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minitii),
						'other' => q(minitii {0}),
						'per' => q({0} miniti fɛɛ miniti),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} daa nyɔɔŋ),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} daa nyɔɔŋ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(sɛkɛnsi frim),
						'other' => q(sɛkɛnsi frim {0}),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(sɛkɛnsi frim),
						'other' => q(sɛkɛnsi frim {0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sɛkɛnsi),
						'other' => q(sɛkɛnsii {0}),
						'per' => q({0} sɛkɛnsi fɛɛ sɛkɛnsi),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sɛkɛnsi),
						'other' => q(sɛkɛnsii {0}),
						'per' => q({0} sɛkɛnsi fɛɛ sɛkɛnsi),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q(otsii {0}),
						'per' => q({0} daa otsi),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q(otsii {0}),
						'per' => q({0} daa otsi),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q(afii {0}),
						'per' => q({0} daa afi),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q(afii {0}),
						'per' => q({0} daa afi),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sɛntimitai),
						'other' => q(sɛntimitai {0}),
						'per' => q({0} sɛntimita fɛɛ sɛntimita),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sɛntimitai),
						'other' => q(sɛntimitai {0}),
						'per' => q({0} sɛntimita fɛɛ sɛntimita),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dɛsimita),
						'other' => q(dɛsimitai {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dɛsimita),
						'other' => q(dɛsimitai {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomita),
						'other' => q(kilomitai {0}),
						'per' => q({0} kilomita fɛɛ kilomita),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomita),
						'other' => q(kilomitai {0}),
						'per' => q({0} kilomita fɛɛ kilomita),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mitai),
						'other' => q(mitai {0}),
						'per' => q({0} mita fɛɛ mita),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mitai),
						'other' => q(mitai {0}),
						'per' => q({0} mita fɛɛ mita),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimitai),
						'other' => q(milimitai {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimitai),
						'other' => q(milimitai {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}B),
						'north' => q({0}K),
						'south' => q({0}W),
						'west' => q({0}A),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}B),
						'north' => q({0}K),
						'south' => q({0}W),
						'west' => q({0}A),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(gbi),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(gbi),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ŋmɛlɛtswaa),
						'other' => q({0}ŋm),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ŋmɛlɛtswaa),
						'other' => q({0}ŋm),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(sɛkmlij),
						'other' => q({0}sm),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(sɛkmlij),
						'other' => q({0}sm),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(nyɔɔŋ),
						'other' => q({0}n),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(nyɔɔŋ),
						'other' => q({0}n),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(otsi),
						'other' => q({0}o),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(otsi),
						'other' => q({0}o),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(afi),
						'other' => q(a{0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(afi),
						'other' => q(a{0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'other' => q({0}mm),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(koji),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(koji),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} B),
						'north' => q({0} K),
						'south' => q({0} W),
						'west' => q({0} A),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} B),
						'north' => q({0} K),
						'south' => q({0} W),
						'west' => q({0} A),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ao),
						'other' => q({0}ao),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ao),
						'other' => q({0}ao),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(gbii),
						'other' => q(gbii {0}),
						'per' => q({0}/gbi),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(gbii),
						'other' => q(gbii {0}),
						'per' => q({0}/gbi),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(an),
						'other' => q({0}an),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(an),
						'other' => q({0}an),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ŋmɛlɛtswai),
						'other' => q(ŋm {0}),
						'per' => q({0}/ŋm),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ŋmɛlɛtswai),
						'other' => q(ŋm {0}),
						'per' => q({0}/ŋm),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsɛk),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsɛk),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(sɛk mlij),
						'other' => q(sm {0}),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(sɛk mlij),
						'other' => q(sm {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q(min {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q(min {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(nyɔji),
						'other' => q(nyɔji {0}),
						'per' => q({0}/nyɔɔŋ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(nyɔji),
						'other' => q(nyɔji {0}),
						'per' => q({0}/nyɔɔŋ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(sɛkɛnsifrim),
						'other' => q({0}sf),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(sɛkɛnsifrim),
						'other' => q({0}sf),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sɛk),
						'other' => q(sɛk {0}),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sɛk),
						'other' => q(sɛk {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(otsii),
						'other' => q({0} otsii),
						'per' => q({0}/otsi),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(otsii),
						'other' => q({0} otsii),
						'per' => q({0}/otsi),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(afii),
						'other' => q({0} afii),
						'per' => q({0}/afi),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(afii),
						'other' => q({0} afii),
						'per' => q({0}/afi),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sɛm),
						'other' => q({0} sɛm),
						'per' => q({0}/sɛm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sɛm),
						'other' => q({0} sɛm),
						'per' => q({0}/sɛm),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hɛɛ|h|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:dabi|d|no|n)$' }
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
						'negative' => '(¤#,##0.00)',
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
		'ALL' => {
			display_name => {
				'currency' => q(Albania Leki),
				'other' => q(Albania lekii),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Netherlands Antillea Guilda),
				'other' => q(Netherlands Antillea guildai),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angola Kwanza),
				'other' => q(Angola kwanzai),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentina Peso),
				'other' => q(Argentina pesoi),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba Florin),
				'other' => q(Aruba florinii),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnia-Herzegovina Marki Ni Hiɔ Tsakemɔ),
				'other' => q(Bosnia-Herzegovina markii ni hiɔ tsakemɔ),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados Dɔla),
				'other' => q(Barbados dɔlai),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgaria Levi),
				'other' => q(Bulgaria levii),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi Franki),
				'other' => q(Burundi frankii),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda Dɔla),
				'other' => q(Bermuda dɔlai),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivia Boliviano),
				'other' => q(Bolivia bolivianoi),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brazil Real),
				'other' => q(Brazil realii),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamas Dɔla),
				'other' => q(Bahamas dɔlai),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswana Pula),
				'other' => q(Botswana pulai),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Belarus Rubol),
				'other' => q(Belarus rubolii),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize Dɔla),
				'other' => q(Belize dɔlai),
			},
		},
		'CAD' => {
			symbol => 'KA$',
			display_name => {
				'currency' => q(Kanada Dɔla),
				'other' => q(Kanada dɔlai),
			},
		},
		'CDF' => {
			symbol => 'KDF',
			display_name => {
				'currency' => q(Kongo Franki),
				'other' => q(Kongo frankii),
			},
		},
		'CHF' => {
			symbol => 'SZF',
			display_name => {
				'currency' => q(Switzerland Frank),
				'other' => q(Switzerland frankii),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Tsili Peso),
				'other' => q(Tsili pesoi),
			},
		},
		'COP' => {
			symbol => 'KOP',
			display_name => {
				'currency' => q(Kolombia Peso),
				'other' => q(Kolombia pesoi),
			},
		},
		'CRC' => {
			symbol => 'KRK',
			display_name => {
				'currency' => q(Kosta Rika Kolón),
				'other' => q(Kosta Rika kolónii),
			},
		},
		'CUC' => {
			symbol => 'KUK',
			display_name => {
				'currency' => q(Kuba Peso Ni Hiɔ Tsakemɔ),
				'other' => q(Kuba pesoi ni hiɔ tsakemɔ),
			},
		},
		'CUP' => {
			symbol => 'KUP',
			display_name => {
				'currency' => q(Kuba Peso),
				'other' => q(Kuba pesoi),
			},
		},
		'CZK' => {
			symbol => 'TSK',
			display_name => {
				'currency' => q(Tsek Koruna),
				'other' => q(Tsek korunai),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djibouti Franki),
				'other' => q(Djibouti frankii),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Denmark Krone),
				'other' => q(Denmark kronei),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominika Peso),
				'other' => q(Dominika pesoi),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algeria Dinar),
				'other' => q(Algeria dinarii),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ejipt Pound),
				'other' => q(Ejipt pounds),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrea Nakfa),
				'other' => q(Eritrea nakfai),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopia Birr),
				'other' => q(Ethiopia birri),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
				'other' => q(yuro),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland Ŋshɔkpɔi Pound),
				'other' => q(Falkland Ŋshɔkpɔi pounds),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Britain Pound),
				'other' => q(Britain pounds),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sidi),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghana Sidi),
				'other' => q(Ghana sidii),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar Pound),
				'other' => q(Gibraltar pounds),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambia Dalasi),
				'other' => q(Gambia dalasii),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinea Franki),
				'other' => q(Guinea frankii),
			},
		},
		'GTQ' => {
			symbol => 'GTK',
			display_name => {
				'currency' => q(Guatemala Kuetzal),
				'other' => q(Guatemala kuetzalii),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyana Dɔla),
				'other' => q(Guyan dɔlai),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Hondura Lempira),
				'other' => q(Hondura lempirai),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kroatia Kuna),
				'other' => q(Kroatia kunai),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haiti Gourde),
				'other' => q(Haiti gourdei),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Hungary Forinti),
				'other' => q(Hungary forintii),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Aisland Króna),
				'other' => q(Aisland krónai),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaika Dɔla),
				'other' => q(Jamaika dɔlai),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenya Sheleŋ),
				'other' => q(Kenya sheleŋ),
			},
		},
		'KMF' => {
			symbol => 'KF',
			display_name => {
				'currency' => q(Komoros Franki),
				'other' => q(Komoros frankii),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kayman Ŋshɔkpɔi Dɔla),
				'other' => q(Kayman Ŋshɔkpɔi dɔlai),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberia Dɔla),
				'other' => q(Liberia dɔlai),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libia Dinar),
				'other' => q(Libia dinarii),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroko Dirham),
				'other' => q(Moroko dirhamii),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldova Leu),
				'other' => q(Moldova leuii),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaska Ariari),
				'other' => q(Madagaska ariarii),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Makedonia Denari),
				'other' => q(Makedonia denarii),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritania Ouguiya),
				'other' => q(Mauritania ouguiyai),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritius Rupi),
				'other' => q(Mauritius rupii),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi Kwatsa),
				'other' => q(Malawi kwatsai),
			},
		},
		'MXN' => {
			symbol => 'MZ$',
			display_name => {
				'currency' => q(Meziko Peso),
				'other' => q(Meziko pesoi),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambik Metikal),
				'other' => q(Mozambik metikalii),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibia Dɔla),
				'other' => q(Namibia dɔlai),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Anago Naira),
				'other' => q(Anago nairai),
			},
		},
		'NIO' => {
			symbol => 'K$',
			display_name => {
				'currency' => q(Nikaragua Kórdoba),
				'other' => q(Nikaragua kórdobai),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norway Krone),
				'other' => q(Norway kronei),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panama Balboa),
				'other' => q(Panama balboai),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peru Sol),
				'other' => q(Peru solii),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Poland Zloti),
				'other' => q(Poland zlotii),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguay Guarani),
				'other' => q(Paraguay guaranii),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Romania Leu),
				'other' => q(Romania leuii),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbia Dinari),
				'other' => q(Serbia dinarii),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russia Rubol),
				'other' => q(Russia rubolii),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwanda Franki),
				'other' => q(Rwanda frankii),
			},
		},
		'SCR' => {
			symbol => 'SSR',
			display_name => {
				'currency' => q(Seyshɛl Rupi),
				'other' => q(Seyshɛl rupii),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudan Pound),
				'other' => q(Sudan pounds),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Sweden Krona),
				'other' => q(Sweden kronai),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena Pound),
				'other' => q(St. Helena pounds),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leone Leone),
				'other' => q(Sierra Leone leonei),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leone Leone \(1964—2022\)),
				'other' => q(Sierra Leone leonei \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali Sheleŋ),
				'other' => q(Somali sheleŋ),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinam Dɔla),
				'other' => q(Surinam dɔlai),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Sudan Anai Pound),
				'other' => q(Sudan Anai pounds),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazi Lilangeni),
				'other' => q(Swazi lilangenii),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisia Dinar),
				'other' => q(Tunisia dinarii),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad Kɛ Tobago Dɔla),
				'other' => q(Trinidad Kɛ Tobago dɔlai),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzania Sheleŋ),
				'other' => q(Tanzania sheleŋ),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrainia Hryvnia),
				'other' => q(Ukrainia hryvniai),
			},
		},
		'UGX' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(Uganda Sjeleŋ),
				'other' => q(Uganda sheleŋ),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US Dɔla),
				'other' => q(US dɔlai),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguay Peso),
				'other' => q(Uruguay pesoi),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezuela Bolívar),
				'other' => q(Venezuela bolívarii),
			},
		},
		'XCD' => {
			symbol => 'KB$',
			display_name => {
				'currency' => q(Karibbean Bokã Dɔla),
				'other' => q(Karibbean Bokã dɔlai),
			},
		},
		'XOF' => {
			symbol => 'SFA',
			display_name => {
				'currency' => q(Afrika Anai Sefa Franki),
				'other' => q(Afrika Anai Sefa Frankii),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Shika Ko Ni Gbɛ́i Bɛ Mli),
				'other' => q(\(shika ko ni gbɛ́i bɛ mli\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(South Afrika Randi),
				'other' => q(South Afrika randii),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambia Kwatsa),
				'other' => q(Zambia kwatsai),
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
							'Aha',
							'Ofl',
							'Ots',
							'Abe',
							'Agb',
							'Otu',
							'Maa',
							'Man',
							'Gbo',
							'Ant',
							'Ale',
							'Afu'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Aharabata',
							'Oflɔ',
							'Otsokrikri',
							'Abeibe',
							'Agbiɛnaa',
							'Otukwajaŋ',
							'Maawɛ',
							'Manyawale',
							'Gbo',
							'Antɔŋ',
							'Alemle',
							'Afuabe'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'A',
							'O',
							'O',
							'A',
							'A',
							'O',
							'M',
							'M',
							'G',
							'A',
							'A',
							'A'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Aharabata',
							'Oflɔ',
							'Otsokrikri',
							'Abeibe',
							'Agbiɛnaa',
							'Otukwajan',
							'Maawɛ',
							'Manyawale',
							'Gbo',
							'Antɔŋ',
							'Alemle',
							'Afuabe'
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
						mon => 'Ju',
						tue => 'Juf',
						wed => 'Shɔ',
						thu => 'Soo',
						fri => 'Soh',
						sat => 'Hɔɔ',
						sun => 'Hɔg'
					},
					wide => {
						mon => 'Ju',
						tue => 'Jufɔ',
						wed => 'Shɔ',
						thu => 'Soo',
						fri => 'Sohaa',
						sat => 'Hɔɔ',
						sun => 'Hɔgbaa'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'J',
						tue => 'J',
						wed => 'S',
						thu => 'S',
						fri => 'S',
						sat => 'H',
						sun => 'H'
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
					abbreviated => {0 => 'N1',
						1 => 'N2',
						2 => 'N3',
						3 => 'N4'
					},
					wide => {0 => 'nyɔji etɛ 1',
						1 => 'nyɔji etɛ 2',
						2 => 'nyɔji etɛ 3',
						3 => 'nyɔji etɛ 4'
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
					'am' => q{LB},
					'pm' => q{SN},
				},
				'wide' => {
					'am' => q{LEEBI},
					'pm' => q{SHWANE},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{LEEBI},
					'pm' => q{SHWANE},
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
				'0' => 'DY',
				'1' => 'YGS'
			},
			wide => {
				'0' => 'Dani Yesu',
				'1' => 'Yesu Gbele Sɛɛ'
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} 'be' 'ni' 'atswa' {0}},
			'long' => q{{1} 'be' 'ni' 'atswa' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'be' 'ni' 'atswa' {0}},
			'long' => q{{1} 'be' 'ni' 'atswa' {0}},
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
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			Md => q{M/d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMW => q{MMMM 'otsi' W},
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
			yw => q{Y 'otsi' w},
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
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
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
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Be),
		regionFormat => q({0} Be Yɛ Latsa Beiaŋ),
		regionFormat => q({0} Be Yɛ Fɛi Beiaŋ),
		'Africa/Accra' => {
			exemplarCity => q#Ga#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakry#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakshott#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Afrika Teŋgbɛ Be#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Afrika Bokagbɛ Be#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#South Afrika Be#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Afrika Anaigbɛ Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Afrika Anaigbɛ Be#,
				'standard' => q#Afrika Anaigbɛ Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Alaska Be#,
				'standard' => q#Alaska Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankorage#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kambridge Ŋshɔnine Bibioo#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Tsikago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Tsihuahua#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kreston#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasao#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Kpaakpo Bibioo#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Nelson Mɔɔ#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glase Ŋshɔnine Bibioo#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Ŋshɔnine Bibioo#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Turke Wulu#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifas#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knos, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Osheku Maŋ, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vinsennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamak, Indiana#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montisello, Kentuky#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Ablade Shĩa Ni Yɔɔ Jɔɔ Mli#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meziko Maŋ#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monkton#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Maŋteŋ, Dakota Kooyigbɛ#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota Kooyigbɛ#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Abladei Alɛjiadaamɔhe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Spain Lɛjiadaamɔhe#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Riko#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Faa Ni Nɛɔ#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Ŋshɔnine#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittokortoormiit#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthélemy#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lusia#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vinsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Karɛnt#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalpa#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Sarawa Ŋshɔnine Bibioo#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Okpɔŋɔ Yɛŋ#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Kakla Wuɔfɔ#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Amerika Teŋgbɛbii Abe Yɛ Latsa Beiaŋ#,
				'generic' => q#Amerika Teŋgbɛbii Abe#,
				'standard' => q#Amerika Teŋgbɛbii Abe Yɛ Fɛi Beiaŋ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Amerika Bokãgbɛbii Abe Yɛ Latsa Beiaŋ#,
				'generic' => q#Amerika Bokãgbɛbii Abe#,
				'standard' => q#Amerika Bokãgbɛbii Abe Yɛ Fɛi Beiaŋ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Amerika Gɔjianɔbii Abe Yɛ Latsa Beiaŋ#,
				'generic' => q#Amerika Gɔjianɔbii Abe#,
				'standard' => q#Amerika Gɔjianɔbii Abe Yɛ Fɛi Beiaŋ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pasifik Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Pasifik Be#,
				'standard' => q#Pasifik Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kasey#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makwarie#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#MakMurdo#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tsoibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasko#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusalem#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karatsi#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kutsing#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Kata#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Tsi Minh Maŋtiase#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumki#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantik Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Atlantik Be#,
				'standard' => q#Atlantik Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kape Verde#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Ŋmeŋme Ni Ekumɔ#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kurrie#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Yukla#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Nuŋtsɔ Howe#,
		},
		'Azores' => {
			long => {
				'daylight' => q#Azores Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Azores Be#,
				'standard' => q#Azores Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kape Verde Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Kape Verde Be#,
				'standard' => q#Kape Verde Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Kuba Be#,
				'standard' => q#Kuba Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Be Ni Maji Ni Yɔɔ Jeŋ Fɛɛ Kɛtsuɔ Nii#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Maŋtiase Ko Ni Gbɛ́i Bɛ Mli#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Be Ni Irelandbii Kɛtsuɔ Nii#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Be Ni Britainbii Kɛtsuɔ Nii Yɛ Latsa Beiaŋ#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Antarktik Kɛ Wuoyigbɛbii Ni Wieɔ Frɛntsi Be#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Greenland Bokãgbɛ Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Greenland Bokãgbɛ Be#,
				'standard' => q#Greenland Bokãgbɛ Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Greenland Anaigbɛ Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Greenland Anaigbɛ Be#,
				'standard' => q#Greenland Anaigbɛ Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutia Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Hawaii-Aleutia Be#,
				'standard' => q#Hawaii-Aleutia Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Indian/Chagos' => {
			exemplarCity => q#Tsagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Krismas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indian Ŋshɔ Lɛ Be#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Mauritius Be#,
				'standard' => q#Mauritius Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Meziko Kooyi-Anaigbɛ Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Meziko Kooyi-Anaigbɛ Be#,
				'standard' => q#Meziko Kooyi-Anaigbɛ Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meziko Pasifik Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Meziko Pasifik Be#,
				'standard' => q#Meziko Pasifik Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland Be Yɛ Latsa Beiaŋ#,
				'generic' => q#Newfoundland Be#,
				'standard' => q#Newfoundland Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Ɔkland#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Tsatham#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalkanal#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markwesas#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkairn#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Tsuuk#,
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre Kɛ Mikelon Be Yɛ Latsa Beiaŋ#,
				'generic' => q#St. Pierre Kɛ Mikelon Be#,
				'standard' => q#St. Pierre Kɛ Mikelon Be Yɛ Fɛi Beiaŋ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion Be#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seyshelles Be#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
