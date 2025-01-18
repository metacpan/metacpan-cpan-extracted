=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Shi - Package for language Tachelhit

=cut

package Locale::CLDR::Locales::Shi;
# This file auto generated from Data\common\main\shi.xml
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
				'ak' => 'ⵜⴰⴽⴰⵏⵜ',
 				'am' => 'ⵜⴰⵎⵀⴰⵔⵉⵜ',
 				'ar' => 'ⵜⴰⵄⵔⴰⴱⵜ',
 				'be' => 'ⵜⴰⴱⵉⵍⴰⵔⵓⵙⵜ',
 				'bg' => 'ⵜⴰⴱⵍⵖⴰⵔⵉⵜ',
 				'bn' => 'ⵜⴰⴱⵏⵖⴰⵍⵉⵜ',
 				'cs' => 'ⵜⴰⵜⵛⵉⴽⵉⵜ',
 				'de' => 'ⵜⴰⵍⵉⵎⴰⵏⵜ',
 				'el' => 'ⵜⴰⴳⵔⵉⴳⵉⵜ',
 				'en' => 'ⵜⴰⵏⴳⵍⵉⵣⵜ',
 				'es' => 'ⵜⴰⵙⴱⵏⵢⵓⵍⵉⵜ',
 				'fa' => 'ⵜⴰⴼⵓⵔⵙⵉⵜ',
 				'fr' => 'ⵜⴰⴼⵔⴰⵏⵙⵉⵙⵜ',
 				'ha' => 'ⵜⴰⵀⴰⵡⵙⴰⵜ',
 				'hi' => 'ⵜⴰⵀⵉⵏⴷⵉⵜ',
 				'hu' => 'ⵜⴰⵀⵏⵖⴰⵔⵉⵜ',
 				'id' => 'ⵜⴰⵏⴷⵓⵏⵉⵙⵉⵜ',
 				'ig' => 'ⵜⵉⴳⴱⵓⵜ',
 				'it' => 'ⵜⴰⵟⴰⵍⵢⴰⵏⵜ',
 				'ja' => 'ⵜⴰⵊⴰⴱⴱⵓⵏⵉⵜ',
 				'jv' => 'ⵜⴰⵊⴰⴼⴰⵏⵉⵜ',
 				'km' => 'ⵜⴰⵅⵎⵉⵔⵜ',
 				'ko' => 'ⵜⴰⴽⵓⵔⵉⵜ',
 				'ms' => 'ⵜⴰⵎⴰⵍⴰⵡⵉⵜ',
 				'my' => 'ⵜⴰⴱⵉⵔⵎⴰⵏⵉⵜ',
 				'ne' => 'ⵜⴰⵏⵉⴱⴰⵍⵉⵜ',
 				'nl' => 'ⵜⴰⵀⵓⵍⴰⵏⴷⵉⵜ',
 				'pa' => 'ⵜⴰⴱⵏⵊⴰⴱⵉⵜ',
 				'pl' => 'ⵜⴰⴱⵓⵍⵓⵏⵉⵜ',
 				'pt' => 'ⵜⴰⴱⵕⵟⵇⵉⵣⵜ',
 				'ro' => 'ⵜⴰⵔⵓⵎⴰⵏⵉⵜ',
 				'ru' => 'ⵜⴰⵔⵓⵙⵉⵜ',
 				'rw' => 'ⵜⴰⵔⵓⵡⴰⵏⴷⵉⵜ',
 				'shi' => 'ⵜⴰⵛⵍⵃⵉⵜ',
 				'so' => 'ⵜⴰⵙⵓⵎⴰⵍⵉⵜ',
 				'sv' => 'ⵜⴰⵙⵡⵉⴷⵉⵜ',
 				'ta' => 'ⵜⴰⵜⴰⵎⵉⵍⵜ',
 				'th' => 'ⵜⴰⵜⴰⵢⵍⴰⵏⴷⵉⵜ',
 				'tr' => 'ⵜⴰⵜⵓⵔⴽⵉⵜ',
 				'uk' => 'ⵜⵓⴽⵔⴰⵏⵉⵜ',
 				'ur' => 'ⵜⵓⵔⴷⵓⵜ',
 				'vi' => 'ⵜⴰⴼⵉⵜⵏⴰⵎⵉⵜ',
 				'yo' => 'ⵜⴰⵢⵔⵓⴱⴰⵜ',
 				'zh' => 'ⵜⴰⵛⵉⵏⵡⵉⵜ',
 				'zu' => 'ⵜⴰⵣⵓⵍⵓⵜ',

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
			'AD' => 'ⴰⵏⴷⵓⵔⴰ',
 			'AE' => 'ⵍⵉⵎⴰⵔⴰⵜ',
 			'AF' => 'ⴰⴼⵖⴰⵏⵉⵙⵜⴰⵏ',
 			'AG' => 'ⴰⵏⵜⵉⴳⴰ ⴷ ⴱⵔⴱⵓⴷⴰ',
 			'AI' => 'ⴰⵏⴳⵉⵍⴰ',
 			'AL' => 'ⴰⵍⴱⴰⵏⵢⴰ',
 			'AM' => 'ⴰⵔⵎⵉⵏⵢⴰ',
 			'AO' => 'ⴰⵏⴳⵓⵍⴰ',
 			'AR' => 'ⴰⵔⵊⴰⵏⵜⵉⵏ',
 			'AS' => 'ⵙⴰⵎⵡⴰ ⵜⴰⵎⵉⵔⵉⴽⴰⵏⵉⵜ',
 			'AT' => 'ⵏⵏⵎⵙⴰ',
 			'AU' => 'ⵓⵙⵜⵔⴰⵍⵢⴰ',
 			'AW' => 'ⴰⵔⵓⴱⴰ',
 			'AZ' => 'ⴰⴷⵔⴰⴱⵉⵊⴰⵏ',
 			'BA' => 'ⴱⵓⵙⵏⴰ ⴷ ⵀⵉⵔⵙⵉⴽ',
 			'BB' => 'ⴱⴰⵔⴱⴰⴷ',
 			'BD' => 'ⴱⴰⵏⴳⵍⴰⴷⵉⵛ',
 			'BE' => 'ⴱⵍⵊⵉⴽⴰ',
 			'BF' => 'ⴱⵓⵔⴽⵉⵏⴰ ⴼⴰⵙⵓ',
 			'BG' => 'ⴱⵍⵖⴰⵔⵢⴰ',
 			'BH' => 'ⴱⵃⵔⴰⵢⵏ',
 			'BI' => 'ⴱⵓⵔⵓⵏⴷⵉ',
 			'BJ' => 'ⴱⵉⵏⵉⵏ',
 			'BM' => 'ⴱⵔⵎⵓⴷⴰ',
 			'BN' => 'ⴱⵔⵓⵏⵉ',
 			'BO' => 'ⴱⵓⵍⵉⴼⵢⴰ',
 			'BR' => 'ⴱⵔⴰⵣⵉⵍ',
 			'BS' => 'ⴱⴰⵀⴰⵎⴰⵙ',
 			'BT' => 'ⴱⵀⵓⵜⴰⵏ',
 			'BW' => 'ⴱⵓⵜⵙⵡⴰⵏⴰ',
 			'BY' => 'ⴱⵉⵍⴰⵔⵓⵙⵢⴰ',
 			'BZ' => 'ⴱⵉⵍⵉⵣ',
 			'CA' => 'ⴽⴰⵏⴰⴷⴰ',
 			'CD' => 'ⵜⴰⴳⴷⵓⴷⴰⵏⵜ ⵜⴰⴷⵉⵎⵓⵇⵔⴰⵜⵉⵜ ⵏ ⴽⵓⵏⴳⵓ',
 			'CF' => 'ⵜⴰⴳⴷⵓⴷⴰⵏⵜ ⵜⴰⵏⴰⵎⵎⴰⵙⵜ ⵏ ⵉⴼⵔⵉⵇⵢⴰ',
 			'CG' => 'ⴽⵓⵏⴳⵓ',
 			'CH' => 'ⵙⵡⵉⵙⵔⴰ',
 			'CI' => 'ⴽⵓⵜ ⴷⵉⴼⵡⴰⵔ',
 			'CK' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⴽⵓⴽ',
 			'CL' => 'ⵛⵛⵉⵍⵉ',
 			'CM' => 'ⴽⴰⵎⵉⵔⵓⵏ',
 			'CN' => 'ⵛⵛⵉⵏⵡⴰ',
 			'CO' => 'ⴽⵓⵍⵓⵎⴱⵢⴰ',
 			'CR' => 'ⴽⵓⵙⵜⴰ ⵔⵉⴽⴰ',
 			'CU' => 'ⴽⵓⴱⴰ',
 			'CV' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⴽⴰⴱⴱⵉⵔⴷⵉ',
 			'CY' => 'ⵇⵓⴱⵔⵓⵙ',
 			'CZ' => 'ⵜⴰⴳⴷⵓⴷⴰⵏⵜ ⵜⴰⵜⵛⵉⴽⵉⵜ',
 			'DE' => 'ⴰⵍⵎⴰⵏⵢⴰ',
 			'DJ' => 'ⴷⵊⵉⴱⵓⵜⵉ',
 			'DK' => 'ⴷⴰⵏⵎⴰⵔⴽ',
 			'DM' => 'ⴷⵓⵎⵉⵏⵉⴽ',
 			'DO' => 'ⵜⴰⴳⴷⵓⴷⴰⵏⵜ ⵜⴰⴷⵓⵎⵉⵏⵉⴽⵜ',
 			'DZ' => 'ⴷⵣⴰⵢⵔ',
 			'EC' => 'ⵉⴽⵡⴰⴷⵓⵔ',
 			'EE' => 'ⵉⵙⵜⵓⵏⵢⴰ',
 			'EG' => 'ⵎⵉⵚⵕ',
 			'ER' => 'ⵉⵔⵉⵜⵉⵔⵢⴰ',
 			'ES' => 'ⵙⴱⴰⵏⵢⴰ',
 			'ET' => 'ⵉⵜⵢⵓⴱⵢⴰ',
 			'FI' => 'ⴼⵉⵍⵍⴰⵏⴷⴰ',
 			'FJ' => 'ⴼⵉⴷⵊⵉ',
 			'FK' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⵎⴰⵍⴰⵡⵉ',
 			'FM' => 'ⵎⵉⴽⵔⵓⵏⵉⵣⵢⴰ',
 			'FR' => 'ⴼⵔⴰⵏⵙⴰ',
 			'GA' => 'ⴳⴰⴱⵓⵏ',
 			'GB' => 'ⵜⴰⴳⵍⴷⵉⵜ ⵉⵎⵓⵏⵏ',
 			'GD' => 'ⵖⵔⵏⴰⵟⴰ',
 			'GE' => 'ⵊⵓⵔⵊⵢⴰ',
 			'GF' => 'ⴳⵡⵉⵢⴰⵏ ⵜⴰⴼⵔⴰⵏⵙⵉⵙⵜ',
 			'GH' => 'ⵖⴰⵏⴰ',
 			'GI' => 'ⴰⴷⵔⴰⵔ ⵏ ⵟⴰⵕⵉⵇ',
 			'GL' => 'ⴳⵔⵉⵍⴰⵏⴷ',
 			'GM' => 'ⴳⴰⵎⴱⵢⴰ',
 			'GN' => 'ⵖⵉⵏⵢⴰ',
 			'GP' => 'ⴳⵡⴰⴷⴰⵍⵓⴱ',
 			'GQ' => 'ⵖⵉⵏⵢⴰ ⵏ ⵉⴽⵡⴰⴷⵓⵔ',
 			'GR' => 'ⵍⵢⵓⵏⴰⵏ',
 			'GT' => 'ⴳⵡⴰⵜⵉⵎⴰⵍⴰ',
 			'GU' => 'ⴳⵡⴰⵎ',
 			'GW' => 'ⵖⵉⵏⵢⴰ ⴱⵉⵙⴰⵡ',
 			'GY' => 'ⴳⵡⵉⵢⴰⵏⴰ',
 			'HN' => 'ⵀⵓⵏⴷⵓⵔⴰⵙ',
 			'HR' => 'ⴽⵔⵡⴰⵜⵢⴰ',
 			'HT' => 'ⵀⴰⵢⵜⵉ',
 			'HU' => 'ⵀⵏⵖⴰⵔⵢⴰ',
 			'ID' => 'ⴰⵏⴷⵓⵏⵉⵙⵢⴰ',
 			'IE' => 'ⵉⵔⵍⴰⵏⴷⴰ',
 			'IL' => 'ⵉⵙⵔⴰⵢⵉⵍ',
 			'IN' => 'ⵍⵀⵉⵏⴷ',
 			'IO' => 'ⵜⴰⵎⵏⴰⴹⵜ ⵜⴰⵏⴳⵍⵉⵣⵉⵜ ⵏ ⵓⴳⴰⵔⵓ ⴰⵀⵉⵏⴷⵉ',
 			'IQ' => 'ⵍⵄⵉⵔⴰⵇ',
 			'IR' => 'ⵉⵔⴰⵏ',
 			'IS' => 'ⵉⵙⵍⴰⵏⴷ',
 			'IT' => 'ⵉⵟⴰⵍⵢⴰ',
 			'JM' => 'ⵊⴰⵎⴰⵢⴽⴰ',
 			'JO' => 'ⵍⵓⵔⴷⵓⵏ',
 			'JP' => 'ⵍⵢⴰⴱⴰⵏ',
 			'KE' => 'ⴽⵉⵏⵢⴰ',
 			'KG' => 'ⴽⵉⵔⵖⵉⵣⵉⵙⵜⴰⵏ',
 			'KH' => 'ⴽⴰⵎⴱⵓⴷⵢⴰ',
 			'KI' => 'ⴽⵉⵔⵉⴱⴰⵜⵉ',
 			'KM' => 'ⵇⵓⵎⵓⵔ',
 			'KN' => 'ⵙⴰⵏⴽⵔⵉⵙ ⴷ ⵏⵉⴼⵉⵙ',
 			'KP' => 'ⴽⵓⵔⵢⴰ ⵏ ⵉⵥⵥⵍⵎⴹ',
 			'KR' => 'ⴽⵓⵔⵢⴰ ⵏ ⵉⴼⴼⵓⵙ',
 			'KW' => 'ⵍⴽⵡⵉⵜ',
 			'KY' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⴽⴰⵢⵎⴰⵏ',
 			'KZ' => 'ⴽⴰⵣⴰⵅⵙⵜⴰⵏ',
 			'LA' => 'ⵍⴰⵡⵙ',
 			'LB' => 'ⵍⵓⴱⵏⴰⵏ',
 			'LC' => 'ⵙⴰⵏⵜⵍⵓⵙⵉ',
 			'LI' => 'ⵍⵉⴽⵉⵏⵛⵜⴰⵢⵏ',
 			'LK' => 'ⵙⵔⵉⵍⴰⵏⴽⴰ',
 			'LR' => 'ⵍⵉⴱⵉⵔⵢⴰ',
 			'LS' => 'ⵍⵉⵚⵓⵟⵓ',
 			'LT' => 'ⵍⵉⵜⵡⴰⵏⵢⴰ',
 			'LU' => 'ⵍⵓⴽⵙⴰⵏⴱⵓⵔⴳ',
 			'LV' => 'ⵍⴰⵜⴼⵢⴰ',
 			'LY' => 'ⵍⵉⴱⵢⴰ',
 			'MA' => 'ⵍⵎⵖⵔⵉⴱ',
 			'MC' => 'ⵎⵓⵏⴰⴽⵓ',
 			'MD' => 'ⵎⵓⵍⴷⵓⴼⵢⴰ',
 			'MG' => 'ⵎⴰⴷⴰⵖⴰⵛⵇⴰⵔ',
 			'MH' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⵎⴰⵔⵛⴰⵍ',
 			'ML' => 'ⵎⴰⵍⵉ',
 			'MM' => 'ⵎⵢⴰⵏⵎⴰⵔ',
 			'MN' => 'ⵎⵏⵖⵓⵍⵢⴰ',
 			'MP' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⵎⴰⵔⵢⴰⵏ ⵏ ⵉⵥⵥⵍⵎⴹ',
 			'MQ' => 'ⵎⴰⵔⵜⵉⵏⵉⴽ',
 			'MR' => 'ⵎⵓⵕⵉⵟⴰⵏⵢⴰ',
 			'MS' => 'ⵎⵓⵏⵙⵉⵔⴰⵜ',
 			'MT' => 'ⵎⴰⵍⵟⴰ',
 			'MU' => 'ⵎⵓⵔⵉⵙ',
 			'MV' => 'ⵎⴰⵍⴷⵉⴼ',
 			'MW' => 'ⵎⴰⵍⴰⵡⵉ',
 			'MX' => 'ⵎⵉⴽⵙⵉⴽ',
 			'MY' => 'ⵎⴰⵍⵉⵣⵢⴰ',
 			'MZ' => 'ⵎⵓⵣⵏⴱⵉⵇ',
 			'NA' => 'ⵏⴰⵎⵉⴱⵢⴰ',
 			'NC' => 'ⴽⴰⵍⵉⴷⵓⵏⵢⴰ ⵜⴰⵎⴰⵢⵏⵓⵜ',
 			'NE' => 'ⵏⵏⵉⵊⵉⵔ',
 			'NF' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⵏⵓⵔⴼⵓⵍⴽ',
 			'NG' => 'ⵏⵉⵊⵉⵔⵢⴰ',
 			'NI' => 'ⵏⵉⴽⴰⵔⴰⴳⵡⴰ',
 			'NL' => 'ⵀⵓⵍⴰⵏⴷⴰ',
 			'NO' => 'ⵏⵏⵔⵡⵉⵊ',
 			'NP' => 'ⵏⵉⴱⴰⵍ',
 			'NR' => 'ⵏⴰⵡⵔⵓ',
 			'NU' => 'ⵏⵉⵡⵉ',
 			'NZ' => 'ⵏⵢⵓⵣⵉⵍⴰⵏⴷⴰ',
 			'OM' => 'ⵄⵓⵎⴰⵏ',
 			'PA' => 'ⴱⴰⵏⴰⵎⴰ',
 			'PE' => 'ⴱⵉⵔⵓ',
 			'PF' => 'ⴱⵓⵍⵉⵏⵉⵣⵢⴰ ⵜⴰⴼⵔⴰⵏⵙⵉⵙⵜ',
 			'PG' => 'ⴱⴰⴱⵡⴰ ⵖⵉⵏⵢⴰ ⵜⴰⵎⴰⵢⵏⵓⵜ',
 			'PH' => 'ⴼⵉⵍⵉⴱⴱⵉⵏ',
 			'PK' => 'ⴱⴰⴽⵉⵙⵜⴰⵏ',
 			'PL' => 'ⴱⵓⵍⵓⵏⵢⴰ',
 			'PM' => 'ⵙⴰⵏⴱⵢⵉⵔ ⴷ ⵎⵉⴽⵍⵓⵏ',
 			'PN' => 'ⴱⵉⵜⴽⴰⵢⵔⵏ',
 			'PR' => 'ⴱⵓⵔⵜⵓ ⵔⵉⴽⵓ',
 			'PS' => 'ⴰⴳⵎⵎⴰⴹ ⵏ ⵜⴰⴳⵓⵜ ⴷ ⵖⵣⵣⴰ',
 			'PT' => 'ⴱⵕⵟⵇⵉⵣ',
 			'PW' => 'ⴱⴰⵍⴰⵡ',
 			'PY' => 'ⴱⴰⵔⴰⴳⵡⴰⵢ',
 			'QA' => 'ⵇⴰⵜⴰⵔ',
 			'RE' => 'ⵔⵉⵢⵓⵏⵢⵓⵏ',
 			'RO' => 'ⵔⵓⵎⴰⵏⵢⴰ',
 			'RU' => 'ⵔⵓⵙⵢⴰ',
 			'RW' => 'ⵔⵡⴰⵏⴷⴰ',
 			'SA' => 'ⵙⵙⴰⵄⵓⴷⵉⵢⴰ',
 			'SB' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⵙⴰⵍⵓⵎⴰⵏ',
 			'SC' => 'ⵙⵙⵉⵛⵉⵍ',
 			'SD' => 'ⵙⵙⵓⴷⴰⵏ',
 			'SE' => 'ⵙⵙⵡⵉⴷ',
 			'SG' => 'ⵙⵏⵖⴰⴼⵓⵔⴰ',
 			'SH' => 'ⵙⴰⵏⵜⵉⵍⵉⵏ',
 			'SI' => 'ⵙⵍⵓⴼⵉⵏⵢⴰ',
 			'SK' => 'ⵙⵍⵓⴼⴰⴽⵢⴰ',
 			'SL' => 'ⵙⵙⵉⵔⴰⵍⵢⵓⵏ',
 			'SM' => 'ⵙⴰⵏⵎⴰⵔⵉⵏⵓ',
 			'SN' => 'ⵙⵙⵉⵏⵉⴳⴰⵍ',
 			'SO' => 'ⵚⵚⵓⵎⴰⵍ',
 			'SR' => 'ⵙⵓⵔⵉⵏⴰⵎ',
 			'ST' => 'ⵙⴰⵡⵟⵓⵎⵉ ⴷ ⴱⵔⴰⵏⵙⵉⴱ',
 			'SV' => 'ⵙⴰⵍⴼⴰⴷⵓⵔ',
 			'SY' => 'ⵙⵓⵔⵢⴰ',
 			'SZ' => 'ⵙⵡⴰⵣⵉⵍⴰⵏⴷⴰ',
 			'TC' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵏ ⵜⵓⵔⴽⵢⴰ ⴷ ⴽⴰⵢⴽ',
 			'TD' => 'ⵜⵛⴰⴷ',
 			'TG' => 'ⵟⵓⴳⵓ',
 			'TH' => 'ⵟⴰⵢⵍⴰⵏⴷ',
 			'TJ' => 'ⵜⴰⴷⵊⴰⴽⵉⵙⵜⴰⵏ',
 			'TK' => 'ⵟⵓⴽⵍⴰⵡ',
 			'TL' => 'ⵜⵉⵎⵓⵔ ⵏ ⵍⵇⴱⵍⵜ',
 			'TM' => 'ⵜⵓⵔⴽⵎⴰⵏⵙⵜⴰⵏ',
 			'TN' => 'ⵜⵓⵏⵙ',
 			'TO' => 'ⵟⵓⵏⴳⴰ',
 			'TR' => 'ⵜⵓⵔⴽⵢⴰ',
 			'TT' => 'ⵜⵔⵉⵏⵉⴷⴰⴷ ⴷ ⵟⵓⴱⴰⴳⵓ',
 			'TV' => 'ⵜⵓⴼⴰⵍⵓ',
 			'TW' => 'ⵟⴰⵢⵡⴰⵏ',
 			'TZ' => 'ⵟⴰⵏⵥⴰⵏⵢⴰ',
 			'UA' => 'ⵓⴽⵔⴰⵏⵢⴰ',
 			'UG' => 'ⵓⵖⴰⵏⴷⴰ',
 			'US' => 'ⵉⵡⵓⵏⴰⴽ ⵎⵓⵏⵏⵉⵏ ⵏ ⵎⵉⵔⵉⴽⴰⵏ',
 			'UY' => 'ⵓⵔⵓⴳⵡⴰⵢ',
 			'UZ' => 'ⵓⵣⴱⴰⴽⵉⵙⵜⴰⵏ',
 			'VA' => 'ⴰⵡⴰⵏⴽ ⵏ ⴼⴰⵜⵉⴽⴰⵏ',
 			'VC' => 'ⵙⴰⵏⴼⴰⵏⵙⴰⵏ ⴷ ⴳⵔⵉⵏⴰⴷⵉⵏ',
 			'VE' => 'ⴼⵉⵏⵣⵡⵉⵍⴰ',
 			'VG' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵜⵉⵎⴳⴰⴷ ⵏ ⵏⵏⴳⵍⵉⵣ',
 			'VI' => 'ⵜⵉⴳⵣⵉⵔⵉⵏ ⵜⵉⵎⴳⴰⴷ ⵏ ⵉⵡⵓⵏⴰⴽ ⵎⵓⵏⵏⵉⵏ',
 			'VN' => 'ⴼⵉⵜⵏⴰⵎ',
 			'VU' => 'ⴼⴰⵏⵡⴰⵟⵓ',
 			'WF' => 'ⵡⴰⵍⵉⵙ ⴷ ⴼⵓⵜⵓⵏⴰ',
 			'WS' => 'ⵙⴰⵎⵡⴰ',
 			'YE' => 'ⵢⴰⵎⴰⵏ',
 			'YT' => 'ⵎⴰⵢⵓⵟ',
 			'ZA' => 'ⴰⴼⵔⵉⵇⵢⴰ ⵏ ⵉⴼⴼⵓⵙ',
 			'ZM' => 'ⵣⴰⵎⴱⵢⴰ',
 			'ZW' => 'ⵣⵉⵎⴱⴰⴱⵡⵉ',

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
			index => ['ⴰ', 'ⴱ', 'ⴳ', 'ⴷ', 'ⴹ', 'ⴻ', 'ⴼ', 'ⴽ', 'ⵀ', 'ⵃ', 'ⵄ', 'ⵅ', 'ⵇ', 'ⵉ', 'ⵊ', 'ⵍ', 'ⵎ', 'ⵏ', 'ⵓ', 'ⵔ', 'ⵕ', 'ⵖ', 'ⵙ', 'ⵚ', 'ⵛ', 'ⵜ', 'ⵟ', 'ⵡ', 'ⵢ', 'ⵣ', 'ⵥ'],
			main => qr{[ⴰ ⴱ ⴳ {ⴳⵯ} ⴷ ⴹ ⴻ ⴼ ⴽ {ⴽⵯ} ⵀ ⵃ ⵄ ⵅ ⵇ ⵉ ⵊ ⵍ ⵎ ⵏ ⵓ ⵔ ⵕ ⵖ ⵙ ⵚ ⵛ ⵜ ⵟ ⵡ ⵢ ⵣ ⵥ]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['ⴰ', 'ⴱ', 'ⴳ', 'ⴷ', 'ⴹ', 'ⴻ', 'ⴼ', 'ⴽ', 'ⵀ', 'ⵃ', 'ⵄ', 'ⵅ', 'ⵇ', 'ⵉ', 'ⵊ', 'ⵍ', 'ⵎ', 'ⵏ', 'ⵓ', 'ⵔ', 'ⵕ', 'ⵖ', 'ⵙ', 'ⵚ', 'ⵛ', 'ⵜ', 'ⵟ', 'ⵡ', 'ⵢ', 'ⵣ', 'ⵥ'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ⵢⵢⵉⵀ|ⵢ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ⵓⵀⵓ|ⵓ|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
		},
	} }
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
						'positive' => '#,##0.00¤',
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
		'AED' => {
			display_name => {
				'currency' => q(ⴰⴷⵔⵉⵎ ⵏ ⵍⵉⵎⴰⵔⴰⵜ),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(ⴽⵡⴰⵏⵣⴰ ⵏ ⴰⵏⴳⵓⵍⴰ),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(ⴰⴷⵓⵍⴰⵔ ⵏ ⵓⵙⵜⵔⴰⵍⵢⴰ),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(ⴰⴷⵉⵏⴰⵔ ⵏ ⴱⵃⵔⴰⵢⵏ),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(ⴼⵔⴰⵏⴽ ⵏ ⴱⵓⵔⵓⵏⴷⵉ),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(ⴰⴱⵓⵍⴰ ⵏ ⴱⵓⵜⵙⵡⴰⵏⴰ),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(ⴰⴷⵓⵍⴰⵔ ⵏ ⴽⴰⵏⴰⴷⴰ),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(ⴼⵔⴰⵏⴽ ⵏ ⴽⵓⵏⴳⵓ),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(ⴰⴼⵔⴰⵏⴽ ⵏ ⵙⵡⵉⵙⵔⴰ),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(ⴰⵢⴰⵏ ⵏ ⵛⵛⵉⵏⵡⴰ),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(ⵉⵙⴽⵓⴷⵓ ⵏ ⴽⴰⴱⴱⵉⵔⴷⵉ),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(ⴼⵔⴰⵏⴽ ⵏ ⴷⵊⵉⴱⵓⵜⵉ),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(ⴰⴷⵉⵏⴰⵔ ⵏ ⴷⵣⴰⵢⵔ),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(ⴰⵊⵏⵉⵀ ⵏ ⵎⵉⵚⵕ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(ⵏⴰⴼⴽⴰ ⵏ ⵉⵔⵉⵜⵉⵔⵢⴰ),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(ⴱⵉⵔ ⵏ ⵉⵜⵢⵓⴱⵢⴰ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ⵓⵔⵓ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ⴰⵊⵏⵉⵀ ⴰⵙⵜⵔⵍⵉⵏⵉ ⵏ ⵏⵏⴳⵍⵉⵣ),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ⵙⵉⴷⵉ ⵏ ⵖⴰⵏⴰ),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(ⴷⴰⵍⴰⵙⵉ ⵏ ⴳⴰⵎⴱⵢⴰ),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(ⴼⵔⴰⵏⴽ ⵏ ⵖⵉⵏⵢⴰ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ⴰⵔⵓⴱⵉ ⵏ ⵍⵀⵉⵏⴷ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ⴰⵢⴰⵏ ⵏ ⵍⵢⴰⴱⴰⵏ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(ⴰⵛⵉⵍⵉⵏ ⵏ ⴽⵉⵏⵢⴰ),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(ⴼⵔⴰⵏⴽ ⵏ ⵇⵓⵎⵓⵕ),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(ⴰⴷⵓⵍⴰⵔ ⵏ ⵍⵉⴱⵉⵔⵢⴰ),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(ⵍⵓⵜⵉ ⵏ ⵍⵉⵚⵓⵟⵓ),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(ⴰⴷⵉⵏⴰⵔ ⵏ ⵍⵉⴱⵢⴰ),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(ⴰⴷⵔⵉⵎ ⵏ ⵍⵎⵖⵔⵉⴱ),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ⴼⵔⴰⵏⴽ ⵏ ⵎⴰⴷⴰⵖⴰⵛⵇⴰⵔ),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ⵓⵇⵉⵢⵢⴰ ⵏ ⵎⵓⵕⵉⵟⴰⵏⵢⴰ \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ⵓⵇⵉⵢⵢⴰ ⵏ ⵎⵓⵕⵉⵟⴰⵏⵢⴰ),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(ⴰⵔⵓⴱⵉ ⵏ ⵎⵓⵔⵉⵙ),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(ⴽⵡⴰⵛⴰ ⵏ ⵎⴰⵍⴰⵡⵉ),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(ⴰⵎⵉⵜⵉⴽⵍ ⵏ ⵎⵓⵣⵏⴱⵉⵇ),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(ⴰⴷⵓⵍⴰⵔ ⵏ ⵏⴰⵎⵉⴱⵢⴰ),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(ⵏⴰⵢⵔⴰ ⵏ ⵏⵉⵊⵉⵔⵢⴰ),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ⴰⴼⵔⴰⵏⴽ ⵏ ⵔⵡⴰⵏⴷⴰ),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(ⴰⵔⵢⴰⵍ ⵏ ⵙⵙⴰⵄⵓⴷⵉⵢⴰ),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(ⴰⵔⵓⴱⵉ ⵏ ⵙⵙⵉⵛⵉⵍ),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(ⴰⴷⵉⵏⴰⵔ ⵏ ⵙⵙⵓⴷⴰⵏ),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(ⴰⵊⵏⵉⵀ ⵏ ⵙⵙⵓⴷⴰⵏ),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(ⴰⵊⵏⵉⵀ ⵏ ⵙⴰⵏⵜⵉⵍⵉⵏ),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(ⵍⵉⵢⵓⵏ),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(ⵍⵉⵢⵓⵏ \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(ⴰⵛⵉⵍⵉⵏ ⵏ ⵚⵚⵓⵎⴰⵍ),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(ⴰⴷⵓⴱⵔⴰ ⵏ ⵙⴰⵏⵟⵓⵎⵉ \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(ⴰⴷⵓⴱⵔⴰ ⵏ ⵙⴰⵏⵟⵓⵎⵉ),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(ⵍⵉⵍⴰⵏⵊⵉⵏⵉ),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(ⴰⴷⵉⵏⴰⵔ ⵏ ⵜⵓⵏⵙ),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(ⴰⵛⵉⵍⵉⵏ ⵏ ⵟⴰⵏⵥⴰⵏⵢⴰ),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ⴰⵛⵉⵍⵉⵏ ⵏ ⵓⵖⴰⵏⴷⴰ),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ⴰⴷⵓⵍⴰⵔ ⵏ ⵉⵡⵓⵏⴰⴽ ⵉⵎⵓⵏⵏ),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(ⴼⵔⴰⵏⴽ ⵚⵉⴼⴰ),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(ⴼⵔⴰⵏⴽ ⵚⵉⴼⴰ ⴱⵉⵙⴰⵡ),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(ⴰⵔⴰⵏⴷ ⵏ ⴰⴼⵔⵉⵇⵢⴰ ⵏ ⵉⴼⴼⵓⵙ),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(ⴰⴽⵡⴰⵛⴰ ⵏ ⵣⴰⵎⴱⵢⴰ \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(ⴰⴽⵡⴰⵛⴰ ⵏ ⵣⴰⵎⴱⵢⴰ),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(ⴰⴷⵓⵍⴰⵔ ⵏ ⵣⵉⵎⴱⴰⴱⵡⵉ),
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
							'ⵉⵏⵏ',
							'ⴱⵕⴰ',
							'ⵎⴰⵕ',
							'ⵉⴱⵔ',
							'ⵎⴰⵢ',
							'ⵢⵓⵏ',
							'ⵢⵓⵍ',
							'ⵖⵓⵛ',
							'ⵛⵓⵜ',
							'ⴽⵜⵓ',
							'ⵏⵓⵡ',
							'ⴷⵓⵊ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ⵉⵏⵏⴰⵢⵔ',
							'ⴱⵕⴰⵢⵕ',
							'ⵎⴰⵕⵚ',
							'ⵉⴱⵔⵉⵔ',
							'ⵎⴰⵢⵢⵓ',
							'ⵢⵓⵏⵢⵓ',
							'ⵢⵓⵍⵢⵓⵣ',
							'ⵖⵓⵛⵜ',
							'ⵛⵓⵜⴰⵏⴱⵉⵔ',
							'ⴽⵜⵓⴱⵔ',
							'ⵏⵓⵡⴰⵏⴱⵉⵔ',
							'ⴷⵓⵊⴰⵏⴱⵉⵔ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ⵉ',
							'ⴱ',
							'ⵎ',
							'ⵉ',
							'ⵎ',
							'ⵢ',
							'ⵢ',
							'ⵖ',
							'ⵛ',
							'ⴽ',
							'ⵏ',
							'ⴷ'
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
						mon => 'ⴰⵢⵏ',
						tue => 'ⴰⵙⵉ',
						wed => 'ⴰⴽⵕ',
						thu => 'ⴰⴽⵡ',
						fri => 'ⴰⵙⵉⵎ',
						sat => 'ⴰⵙⵉⴹ',
						sun => 'ⴰⵙⴰ'
					},
					wide => {
						mon => 'ⴰⵢⵏⴰⵙ',
						tue => 'ⴰⵙⵉⵏⴰⵙ',
						wed => 'ⴰⴽⵕⴰⵙ',
						thu => 'ⴰⴽⵡⴰⵙ',
						fri => 'ⵙⵉⵎⵡⴰⵙ',
						sat => 'ⴰⵙⵉⴹⵢⴰⵙ',
						sun => 'ⴰⵙⴰⵎⴰⵙ'
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
					abbreviated => {0 => 'ⴰⴽ 1',
						1 => 'ⴰⴽ 2',
						2 => 'ⴰⴽ 3',
						3 => 'ⴰⴽ 4'
					},
					wide => {0 => 'ⴰⴽⵕⴰⴹⵢⵓⵔ 1',
						1 => 'ⴰⴽⵕⴰⴹⵢⵓⵔ 2',
						2 => 'ⴰⴽⵕⴰⴹⵢⵓⵔ 3',
						3 => 'ⴰⴽⵕⴰⴹⵢⵓⵔ 4'
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
					'am' => q{ⵜⵉⴼⴰⵡⵜ},
					'pm' => q{ⵜⴰⴷⴳⴳⵯⴰⵜ},
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
				'0' => 'ⴷⴰⵄ',
				'1' => 'ⴷⴼⵄ'
			},
			wide => {
				'0' => 'ⴷⴰⵜ ⵏ ⵄⵉⵙⴰ',
				'1' => 'ⴷⴼⴼⵉⵔ ⵏ ⵄⵉⵙⴰ'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/y},
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
		},
	} },
);

has 'datetime_formats' => (
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

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
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

no Moo;

1;

# vim: tabstop=4
