=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sms - Package for language Skolt Sami

=cut

package Locale::CLDR::Locales::Sms;
# This file auto generated from Data\common\main\sms.xml
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
				'ar' => 'arabia',
 				'bn' => 'bengal',
 				'cs' => 'čekk-ǩiõll',
 				'da' => 'danskk-ǩiõll',
 				'de' => 'sakslaǩiõl',
 				'en' => 'eŋgglõsǩiõll',
 				'en_AU' => 'australiaeŋgglõsǩiõll',
 				'en_CA' => 'kanadaeŋgglõsǩiõll',
 				'en_GB' => 'britanneŋgglõsǩiõll',
 				'en_US' => 'aʹmmriikkeŋgglõsǩiõll',
 				'es' => 'espaanǩiõll',
 				'et' => 'eeʹstt',
 				'fi' => 'lääʹddǩiõll',
 				'fr' => 'franskk-kiõll',
 				'fr_CA' => 'kanadafranskk-ǩiõll',
 				'fr_CH' => 'sveiccfranskk-ǩiõll',
 				'hi' => 'hindiǩiõll',
 				'hu' => 'uŋŋar',
 				'id' => 'indonesia',
 				'it' => 'italia',
 				'ja' => 'jaappanǩiõll',
 				'ko' => 'koreaǩiõll',
 				'lv' => 'latviaǩiõll',
 				'nl' => 'hollanttǩiõll',
 				'nl_BE' => 'flaamǩiõll',
 				'pl' => 'puolaǩiõll',
 				'pt' => 'portugalkiõll',
 				'ru' => 'ruõšš',
 				'sms' => 'sääʹmǩiõll',
 				'sv' => 'ruõccǩiõll',
 				'th' => 'thaiǩiõll',
 				'zh' => 'ǩiinaǩiõll',
 				'zh_Hans' => 'pråstjum ǩiinaǩiõll',
 				'zh_Hant' => 'äʹrbbvuõđlaž ǩiinǩiõll',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'001' => 'Skääđsuâl',
 			'002' => 'Afrikk',
 			'003' => 'Taʹvv-Amerikk',
 			'005' => 'Saujj-Amerikk',
 			'009' => 'Oseania',
 			'011' => 'Viõstâr-Afrikk',
 			'013' => 'Kõskk-Amerikk',
 			'014' => 'Nuõrti-Afrikk',
 			'015' => 'Tâʹvv-Afrikk',
 			'017' => 'Kõskk-Afrikk',
 			'019' => 'Amerikk',
 			'029' => 'Karibia',
 			'030' => 'Nuõrti-Aasia',
 			'034' => 'Saujj-Aasia',
 			'035' => 'Ooʹbbdneǩ-Aasia',
 			'039' => 'Saujj-Europp',
 			'054' => 'Melanesia',
 			'061' => 'Polynesia',
 			'142' => 'Aasia',
 			'143' => 'Kõskk-Aasia',
 			'145' => 'Viõstâr-Aasia',
 			'150' => 'Europp',
 			'151' => 'Nuõrti-Europp',
 			'154' => 'Tâʹvv-Europp',
 			'155' => 'Viõstâr-Europp',
 			'AD' => 'Andorra',
 			'AG' => 'Antigua da Bardudasuõllu',
 			'AI' => 'Aŋguillasuõllu',
 			'AL' => 'Albania',
 			'AT' => 'Nuõrtiväʹldd',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandd',
 			'BA' => 'Bosnia da Hertsegovinajânnam',
 			'BB' => 'Barbados',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Fasojânnam',
 			'BG' => 'Bulgaria',
 			'BJ' => 'Beninjânnam',
 			'BL' => 'Saint-Barthélemysuâl',
 			'BM' => 'Bermuda',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karibia Vueʹlljânnam',
 			'BR' => 'Brasilla',
 			'BS' => 'Bahammasuõllu',
 			'BY' => 'Belarus',
 			'BZ' => 'Belizejânnam',
 			'CA' => 'Kanada',
 			'CH' => 'Šveiccjânnam',
 			'CO' => 'Kolumbia',
 			'CU' => 'Kuubajânnam',
 			'CV' => 'Kap Verdesuõllu',
 			'CW' => 'Curacaosuâl',
 			'CZ' => 'Tšekk',
 			'CZ@alt=variant' => 'Tšekk täʹssväʹldd',
 			'DE' => 'Saksslajânnam',
 			'DK' => 'Danskk',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikaallaž tääʹssväʹldd',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta da Melill',
 			'EC' => 'Ecuador',
 			'EE' => 'Viro',
 			'EG' => 'Egyptt',
 			'EH' => 'Viõstâr-Sahara',
 			'ES' => 'Espanja',
 			'EU' => 'Euroopp Union',
 			'FI' => 'Lääʹddjânnam',
 			'FO' => 'Färsuõllu',
 			'FR' => 'Franskkjânnam',
 			'GD' => 'Grenada',
 			'GG' => 'Guernseysuâl',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Ruânnjânnam',
 			'GM' => 'Gambia',
 			'GN' => 'Guineajânnam',
 			'GP' => 'Guadeloupesuõllu',
 			'GR' => 'Greikk',
 			'GT' => 'Guatemala',
 			'GW' => 'Guinea-Bissaujânnam',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatia',
 			'HT' => 'Haitisuâl',
 			'HU' => 'Uŋŋar',
 			'IC' => 'Kanariasuõllu',
 			'IE' => 'Irlantt',
 			'IM' => 'Mansuâl',
 			'IS' => 'Islantt',
 			'IT' => 'Italia',
 			'JE' => 'Jerseysuâl',
 			'JM' => 'Jamaikka',
 			'KN' => 'Saint Kitts da Nevissuõllu',
 			'KY' => 'Caymansuõllu',
 			'LC' => 'Saint Luciasuâl',
 			'LI' => 'Liechtensteinjânnam',
 			'LR' => 'Liberia',
 			'LT' => 'Liettua',
 			'LU' => 'Luxemburg',
 			'LV' => 'Latviajânnam',
 			'LY' => 'Libya',
 			'MA' => 'Marokkojânnam',
 			'MC' => 'Monacojânnam',
 			'MD' => 'Moldova',
 			'MF' => 'Saint-Martiin',
 			'MG' => 'Madagaskaar',
 			'ML' => 'Malijânnam',
 			'MQ' => 'Martiniikk',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserratsuâl',
 			'MU' => 'Mauritiussuâl',
 			'MW' => 'Malaw',
 			'MX' => 'Meksikk',
 			'MZ' => 'Mosambikk',
 			'NE' => 'Nigeeʹr',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Vueʹlljânnam',
 			'NO' => 'Taarr',
 			'PA' => 'Panama',
 			'PE' => 'Perujânnam',
 			'PL' => 'Puola',
 			'PR' => 'Puerto Rico suâl',
 			'RE' => 'Réunionsuâl',
 			'RO' => 'Romania',
 			'RU' => 'Ruõššjânnam',
 			'RW' => 'Ruanda',
 			'SD' => 'Sudaan',
 			'SE' => 'Ruõcc',
 			'SH' => 'Saint Helena suâl',
 			'SJ' => 'Svalbaard da Jan Mayen suõllu',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leoon',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinaam',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'TG' => 'Togojânnam',
 			'TN' => 'Tunisia',
 			'TT' => 'Trinidad da Tobagosuâl',
 			'UA' => 'Ukraina',
 			'UN' => 'Õhttõõvvâm meerkååʹdd',
 			'US' => 'Õhttõsvaldia',
 			'UY' => 'Uruguayjânnam',
 			'VE' => 'Venezuela',
 			'ZM' => 'Sambia',

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
			auxiliary => qr{[ö q w x y]},
			index => ['AÂÅÄ', 'B', 'CČ', 'DĐ', 'E', 'F', 'GǦ', 'Ǥ', 'H', 'I', 'J', 'KǨ', 'L', 'M', 'N', 'Ŋ', 'OÕ', 'P', 'R', 'SŠ', 'T', 'U', 'V', 'ZŽ', 'ƷǮ'],
			main => qr{[aâåä b cč dđ e f gǧ ǥ h i j kǩ l m n ŋ oõ p r sš t u v zž ʒǯ]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – , ; \: ! ? . … ’ ” » ( ) \[ \] § @ * / \\ \& #]},
		};
	},
EOT
: sub {
		return { index => ['AÂÅÄ', 'B', 'CČ', 'DĐ', 'E', 'F', 'GǦ', 'Ǥ', 'H', 'I', 'J', 'KǨ', 'L', 'M', 'N', 'Ŋ', 'OÕ', 'P', 'R', 'SŠ', 'T', 'U', 'V', 'ZŽ', 'ƷǮ'], };
},
);


no Moo;

1;

# vim: tabstop=4
