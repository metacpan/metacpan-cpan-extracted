=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Syr - Package for language Syriac

=cut

package Locale::CLDR::Locales::Syr;
# This file auto generated from Data\common\main\syr.xml
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
				'ab' => 'ܐܒܟܐܙܝܬ',
 				'am' => 'ܐܡܪܢܝܬ',
 				'an' => 'ܐܪܐܓܘܢܝܬ',
 				'ar' => 'ܥܪܒܝܬ',
 				'ar_001' => 'ܥܪܒܝܬ ܪܘܫܡܝܐ ܚܕܬܐ',
 				'arp' => 'ܐܪܐܦܗܝܬ',
 				'az' => 'ܐܙܪܒܝܓܐܢܝܬ',
 				'az@alt=short' => 'ܐܙܪܝ',
 				'bn' => 'ܒܢܓܐܠܝܐ',
 				'ckb' => 'ܩܪܕܝܬ ܩܢܛܪܘܢܝܐ',
 				'ckb@alt=menu' => 'ܩܘܪܕܝܬ ܡܨܥܝܐ',
 				'ckb@alt=variant' => 'ܩܘܪܕܝܬ ܣܘܪܢܝ',
 				'de' => 'ܐܠܡܢܝܐ',
 				'el' => 'ܝܘܢܐܝܬ',
 				'en' => 'ܐܢܓܠܝܬ',
 				'es' => 'ܣܦܢܝܝܐ',
 				'fa' => 'ܦܪܣܝܬ',
 				'ff' => 'ܦܘܠܐܗܝܬ',
 				'fi' => 'ܦܝܢܠܢܕܝܬ',
 				'fil' => 'ܦܝܠܝܦܝܢܝܬ',
 				'fon' => 'ܦܘܢܝܬ',
 				'fr' => 'ܦܪܢܣܝܬ',
 				'gaa' => 'ܓܐܝܬ',
 				'gl' => 'ܓܠܝܩܝܬ',
 				'gu' => 'ܓܘܓܐܪܝܬ',
 				'he' => 'ܥܒܪܐܝܬ',
 				'hi' => 'ܗܢܕܝܐ',
 				'hy' => 'ܐܪܡܢܝܬ',
 				'id' => 'ܐܢܕܘܢܝܬ',
 				'it' => 'ܐܝܛܠܝܬ',
 				'ja' => 'ܝܦܢܝܐ',
 				'ka' => 'ܓܘܪܓܝܐܝܬ',
 				'ko' => 'ܟܘܪܐܝܬ',
 				'ku' => 'ܩܘܪܕܝܬ',
 				'la' => 'ܠܬܝܢܝܬ',
 				'lg' => 'ܓܢܕܝܬ',
 				'mul' => 'ܠܫ̈ܢܐ ܦܖ̈ܝܫܐ',
 				'nds' => 'ܐܠܡܢܝܐ ܠܐܠܬܚܬ',
 				'nds_NL' => 'ܗܘܠܢܕܐ ܠܐܠܬܚܬ',
 				'nl' => 'ܗܘܠܢܕܝܬ',
 				'nl_BE' => 'ܦܠܡܝܫܝܬ',
 				'no' => 'ܢܘܪܒܝܓܐܝܬ',
 				'om' => 'ܐܘܪܘܡܘܐܝܬ',
 				'pis' => 'ܦܝܓܝܢܝܬ',
 				'pl' => 'ܦܘܠܢܕܐܝܬ',
 				'pt' => 'ܦܘܪܛܘܓܠܐܝܬ',
 				'ro' => 'ܪܘܡܢܐܝܬ',
 				'ru' => 'ܐܘܪܘܣܢܝܬ',
 				'sco' => 'ܣܟܘܬܠܢܕܐܝܬ',
 				'sq' => 'ܐܠܒܢܝܬ',
 				'sv' => 'ܣܘܝܕܐܝܬ',
 				'sw' => 'ܣܘܐܗܝܠܐܝܬ',
 				'syr' => 'ܣܘܪܝܝܐ',
 				'th' => 'ܬܝܠܢܕܐܝܬ',
 				'tr' => 'ܬܘܪܟܝܬ',
 				'uk' => 'ܐܘܟܪܐܝܢܐܝܬ',
 				'und' => 'ܠܫܢܐ ܠܐ ܝܕܝܥܐ',
 				'ur' => 'ܐܘܪܕܘܝܬ',
 				'vi' => 'ܒܝܬܢܐܡܐܝܬ',
 				'yi' => 'ܝܕܝܬܝܬ',
 				'zh' => 'ܨܝܢܝܬ',
 				'zh@alt=menu' => 'ܨܝܢܝܬ (ܡܐܢܕܘܪܝܐ)',
 				'zh_Hans' => 'ܨܝܢܝܬ (ܦܫܝܛܐ)',
 				'zh_Hans@alt=long' => 'ܨܝܢܝܬ (ܡܐܢܕܘܪܝܐ ܦܫܝܛܐ)',
 				'zh_Hant' => 'ܨܝܢܐܝܬ',

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
			'Arab' => 'ܥܪܒܝܬ',
 			'Armi' => 'ܐܪܡܝܐ',
 			'Armn' => 'ܐܪܡܢܝܬ',
 			'Beng' => 'ܒܢܓܠܝܬ',
 			'Bopo' => 'ܒܘܦܘܡܘܦܘܐܝܬ',
 			'Cyrl' => 'ܣܝܪܝܠܝܐ',
 			'Ethi' => 'ܟܘܫܝܬ',
 			'Geor' => 'ܓܘܪܓܝܬ',
 			'Grek' => 'ܝܘܢܝܬ',
 			'Gujr' => 'ܓܘܓܐܪܝܬ',
 			'Hans' => 'ܗܢܙ',
 			'Hant' => 'ܗܢܙ ܦܫܝܛܐ',
 			'Hebr' => 'ܥܒܪܝܬ',
 			'Jpan' => 'ܝܦܢܝܐ',
 			'Knda' => 'ܟܢܕܐܝܬ',
 			'Kore' => 'ܟܘܪܐܝܬ',
 			'Latn' => 'ܠܬܝܢܝܐ',
 			'Syrc' => 'ܣܘܪܝܬ',
 			'Zsye' => 'ܐܝܡܘܓܝ',
 			'Zxxx' => 'ܠܝܬ ܟܬܝܒܘܬܐ',
 			'Zzzz' => 'ܠܝܬ ܛܟܣܐ ܕܟܬܝܒܬܐ',

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
			'001' => 'ܬܐܒܝܠ',
 			'002' => 'ܐܦܪܝܩܐ',
 			'003' => 'ܐܡܪܝܟܐ ܓܪܒܝܝܬܐ',
 			'005' => 'ܐܡܪܝܟܐ ܬܝܡܢܝܬܐ',
 			'009' => 'ܐܘܩܝܢܘܣܝܐ',
 			'011' => 'ܐܦܪܝܩܐ ܡܥܪܒܝܬܐ',
 			'013' => 'ܐܡܪܝܟܐ ܡܨܥܝܬܐ',
 			'014' => 'ܐܦܪܝܩܐ ܡܕܢܚܝܬܐ',
 			'015' => 'ܐܦܪܝܩܐ ܓܪܒܝܝܬܐ',
 			'017' => 'ܐܦܪܝܩܐ ܡܨܥܝܬܐ',
 			'018' => 'ܐܦܪܝܩܐ ܬܝܡܢܝܬܐ',
 			'019' => 'ܐܡܪ̈ܝܟܐ',
 			'021' => 'ܓܪܒܝܐ ܐܡܪܝܟܐ',
 			'029' => 'ܟܐܪܝܒܝܢ',
 			'030' => 'ܐܣܝܐ ܡܕܢܚܝܬܐ',
 			'034' => 'ܐܣܝܐ ܬܝܡܢܝܬܐ',
 			'035' => 'ܬܝܡܢ ܡܕܢܚ ܐܣܝܐ',
 			'039' => 'ܐܘܪܘܦܐ ܬܝܡܢܝܬܐ',
 			'053' => 'ܐܘܣܛܪܐܠܐܣܝܐ',
 			'054' => 'ܡܝܠܐܢܝܣܝܐ',
 			'057' => 'ܡܝܟܪܘܢܝܙܝܐ',
 			'061' => 'ܦܘܠܢܝܣܝܐ',
 			'142' => 'ܐܣܝܐ',
 			'143' => 'ܐܣܝܐ ܡܨܥܝܬܐ',
 			'145' => 'ܐܣܝܐ ܡܥܪܒܝܬܐ',
 			'150' => 'ܐܘܪܘܦܐ',
 			'151' => 'ܐܘܪܘܦܐ ܡܕܢܚܝܬܐ',
 			'154' => 'ܐܘܪܘܦܐ ܓܪܒܝܝܬܐ',
 			'155' => 'ܐܘܪܘܦܐ ܡܥܪܒ݂ܝܬܐ',
 			'202' => 'ܐܦܪܝܩܐ ܨܚܪܐ ܬܝܡܢܝܬܐ',
 			'419' => 'ܐܡܪܝܟܐ ܠܬܝܢܝܬܐ',
 			'AC' => 'ܓܙܪܬܐ ܕܐܣܝܢܫܘܢ',
 			'AD' => 'ܐܢܕܘܪܐ',
 			'AE' => 'ܐܡܝܪ̈ܘܬܐ ܡܚܝܕ̈ܬܐ ܥܪ̈ܒܝܐ',
 			'AF' => 'ܐܦܓܐܢܣܬܐܢ',
 			'AG' => 'ܐܢܬܝܓܘܐ ܘܒܐܪܒܘܕܐ',
 			'AI' => 'ܐܢܓܘܝܠܐ',
 			'AL' => 'ܐܠܒܢܝܐ',
 			'AM' => 'ܐܪܡܢܝܐ',
 			'AO' => 'ܐܢܓܘܠܐ',
 			'AQ' => 'ܐܢܬܪܬܝܟܐ',
 			'AR' => 'ܐܪܓܢܬܝܢܐ',
 			'AS' => 'ܣܡܘܐ ܐܡܝܖ̈ܟܝܐ',
 			'AT' => 'ܐܘܣܛܪܝܐ',
 			'AU' => 'ܐܘܣܬܪܠܝܐ',
 			'AW' => 'ܐܪܘܒܐ',
 			'AX' => 'ܓܙܝܖ̈ܐ ܕܐܠܐܢܕ',
 			'AZ' => 'ܐܙܪܒܝܓܐܢ',
 			'BA' => 'ܒܘܣܢܐ ܘܗܪܬܣܓܘܒܝܢܐ',
 			'BB' => 'ܒܪܒܐܕܘܣ',
 			'BD' => 'ܒܢܓܠܐܕܝܫ',
 			'BE' => 'ܒܠܓܝܩܐ',
 			'BF' => 'ܒܘܪܩܝܢܐ ܦܐܣܘ',
 			'BG' => 'ܒܘܠܓܐܪܝܐ',
 			'BH' => 'ܒܚܪܝܢ',
 			'BI' => 'ܒܘܪܘܢܕܝ',
 			'BJ' => 'ܒܢܝܢ',
 			'BL' => 'ܡܪܬܝ ܒܪ ܬܘܠܡܝ',
 			'BM' => 'ܒܪܡܘܕܐ',
 			'BN' => 'ܒܪܘܢܐܝ',
 			'BO' => 'ܒܘܠܝܒܝܐ',
 			'BQ' => 'ܟܐܪܝܒܝܢ ܕܢܝܬܝܪܠܐܢܕܣ',
 			'BR' => 'ܒܪܐܙܝܠ',
 			'BS' => 'ܒܗܐܡܣ',
 			'BT' => 'ܒܘܬܐܢ',
 			'BV' => 'ܓܙܪܬܐ ܕܒܘܒܝܬ',
 			'BW' => 'ܒܘܛܣܘܐܢܐ',
 			'BY' => 'ܒܠܐܪܘܣ',
 			'BZ' => 'ܒܠܝܙ',
 			'CA' => 'ܟܢܕܐ',
 			'CC' => 'ܓܙܝܖ̈ܐ ܕܟܘܟܘܣ',
 			'CD' => 'ܟܘܢܓܘ - ܟܝܢܫܐܣܐ',
 			'CD@alt=variant' => 'ܩܘܛܢܝܘܬܐ ܕܝܡܘܩܪܛܝܬܐ ܕܟܘܢܓܘ',
 			'CF' => 'ܩܘܛܢܝܘܬܐ ܕܐܦܪܝܩܐ ܡܨܥܝܬܐ',
 			'CG' => 'ܟܘܢܓܘ - ܒܪܐܙܐܒܝܠ',
 			'CG@alt=variant' => 'ܩܘܛܢܝܘܬܐ ܕܟܘܢܓܘ',
 			'CH' => 'ܣܘܝܣܪܐ',
 			'CI' => 'ܩܘܛ ܕܝܒܘܐܪ',
 			'CI@alt=variant' => 'ܣܘܦܐ ܕܓܪܡܦܝܠܐ',
 			'CK' => 'ܓܙܪܬܐ ܟܘܟ',
 			'CL' => 'ܬܫܝܠܝ',
 			'CM' => 'ܟܐܡܪܘܢ',
 			'CN' => 'ܨܝܢ',
 			'CO' => 'ܟܘܠܘܡܒܝܐ',
 			'CP' => 'ܓܙܪܬܐ ܕܟܠܝܦܝܪܬܘܢ',
 			'CR' => 'ܟܘܣܬܐ ܪܝܩܐ',
 			'CU' => 'ܟܘܒܐ',
 			'CV' => 'ܟܐܦ ܒܝܪܕܝ (ܪܝܫܐ ܝܘܪܩܐ)',
 			'CW' => 'ܟܘܪܐܟܘ',
 			'CX' => 'ܓܙܪܬܐ ܕܟܪܝܣܬܡܣ',
 			'CY' => 'ܩܘܦܪܘܣ',
 			'CZ' => 'ܬܫܝܟܝܐ',
 			'CZ@alt=variant' => 'ܬܫܝܟ',
 			'DE' => 'ܐܠܡܢܝܐ',
 			'DG' => 'ܕܐܝܓܘ ܓܪܣܝܐ',
 			'DJ' => 'ܓܝܒܘܛܝ',
 			'DK' => 'ܕܐܢܡܐܪܩ',
 			'DM' => 'ܕܘܡܝܢܝܩܐ',
 			'DO' => 'ܩܘܛܢܝܘܬܐ ܕܘܡܝܢܝܩܐܢܝܬܐ',
 			'DZ' => 'ܓܙܐܪ',
 			'EA' => 'ܟܘܝܛܐ ܘܡܝܠܝܐ',
 			'EC' => 'ܐܩܘܐܕܘܪ',
 			'EE' => 'ܐܣܛܘܢܝܐ',
 			'EG' => 'ܡܨܪܝܢ',
 			'EH' => 'ܨܚܪܐ ܡܥܪܒܝܬܐ',
 			'ER' => 'ܐܪܬܪܝܐ',
 			'ES' => 'ܐܣܦܢܝܐ',
 			'ET' => 'ܟܘܫ',
 			'EU' => 'ܚܘܝܕܐ ܐܘܪܘܦܝܐ',
 			'EZ' => 'ܩܠܝܡܐ ܕܐܘܪܘ',
 			'FI' => 'ܦܝܢܠܢܕ',
 			'FJ' => 'ܦܝܓܝ',
 			'FK' => 'ܓܙܪܬܐ ܕܦܠܟܠܢܕ',
 			'FK@alt=variant' => 'ܓܙܪܬܐ ܕܡܠܒܢܐܣ',
 			'FM' => 'ܐܬܪܘܬܐ ܦܕܪܠܝܐ ܕܡܝܩܪܘܢܝܣܝܐ',
 			'FO' => 'ܓܙܝܖ̈ܐ ܕܦܪܘ',
 			'FR' => 'ܦܪܢܣܐ',
 			'GA' => 'ܓܒܘܢ',
 			'GB' => 'ܡܠܟܘܬܐ ܡܚܝܕܬܐ',
 			'GD' => 'ܓܪܝܢܐܕܐ',
 			'GE' => 'ܓܘܪܓܝܐ',
 			'GF' => 'ܓܘܝܐܢܐ ܦܪܢܣܝܬܐ',
 			'GG' => 'ܓܘܪܢܙܝ',
 			'GH' => 'ܓܐܢܐ',
 			'GI' => 'ܓܒܪܠܛܪ',
 			'GL' => 'ܓܪܝܢܠܢܕ',
 			'GM' => 'ܓܡܒܝܐ',
 			'GN' => 'ܓܝܢܝܐ',
 			'GP' => 'ܓܘܐܕܘܠܘܦܐܝ',
 			'GQ' => 'ܓܝܢܝܐ ܫܘܝܬܐ',
 			'GR' => 'ܝܘܢ',
 			'GS' => 'ܓܙܝܖ̈ܐ ܕܓܘܪܓܝܐ ܘܣܐܢܕܘܝܟ ܬܝܡܢܝ̈ܐ',
 			'GT' => 'ܓܘܐܬܝܡܐܠܐ',
 			'GU' => 'ܓܘܐܡ',
 			'GW' => 'ܓܝܢܝܐ ܒܝܣܐܘ',
 			'GY' => 'ܓܘܝܐܢܐ',
 			'HK' => 'ܗܘܢܓ ܟܘܢܓ',
 			'HM' => 'ܓܙܝܪ̈ܐ ܕܗܪܕ ܘܡܟܕܘܢܠܕ',
 			'HN' => 'ܗܘܢܕܘܪܣ',
 			'HR' => 'ܩܪܘܐܛܝܐ',
 			'HT' => 'ܗܐܝܬܝ',
 			'HU' => 'ܡܓܪ',
 			'IC' => 'ܓܙܝܖ̈ܐ ܕܟܐܢܪܝ',
 			'ID' => 'ܐܝܢܕܘܢܝܣܝܐ',
 			'IE' => 'ܐܝܪܠܢܕ',
 			'IL' => 'ܐܝܣܪܐܝܠ',
 			'IM' => 'ܓܙܪܬܐ ܕܡܐܢ',
 			'IN' => 'ܗܢܕܘ',
 			'IO' => 'ܩܠܝܡܐ ܕܒܪܝܛܢܝܐ ܓܘ ܐܘܩܝܢܘܣ ܗܢܕܘܝܐ',
 			'IQ' => 'ܥܝܪܩ',
 			'IR' => 'ܐܝܪܐܢ',
 			'IS' => 'ܐܝܣܠܢܕ',
 			'IT' => 'ܐܝܛܠܝܐ',
 			'JE' => 'ܓܝܪܙܝ',
 			'JM' => 'ܓܡܝܟܐ',
 			'JO' => 'ܐܘܪܕܘܢ',
 			'JP' => 'ܝܦܢ',
 			'KE' => 'ܩܝܢܝܐ',
 			'KG' => 'ܩܝܪܓܝܙܣܬܐܢ',
 			'KH' => 'ܟܡܒܘܕܝܐ',
 			'KI' => 'ܟܝܪܝܒܬܝ',
 			'KM' => 'ܓܙܪܬܐ ܕܩܡܪ',
 			'KN' => 'ܣܐܢܬ ܟܝܬܣ ܘܢܝܒܝܣ',
 			'KP' => 'ܟܘܪܝܐ ܕܓܪܒܝܐ',
 			'KR' => 'ܟܘܪܝܐ ܕܬܝܡܢܝܐ',
 			'KW' => 'ܟܘܝܬ',
 			'KY' => 'ܓܙܝܖ̈ܐ ܕܟܐܝܡܐܢ',
 			'KZ' => 'ܟܙܩܣܬܐܢ',
 			'LA' => 'ܠܐܘܣ',
 			'LB' => 'ܠܒܢܢ',
 			'LC' => 'ܡܪܬܝ ܠܘܫܐ',
 			'LI' => 'ܠܝܟܛܢܫܛܝܢ',
 			'LK' => 'ܫܪܝ ܠܐܢܟܐ',
 			'LR' => 'ܠܝܒܝܪܝܐ',
 			'LS' => 'ܠܣܘܛܘ',
 			'LT' => 'ܠܬܘܢܝܐ',
 			'LU' => 'ܠܘܟܣܡܒܘܪܓ',
 			'LV' => 'ܠܐܛܒܝܐ',
 			'LY' => 'ܠܘܒܐ',
 			'MA' => 'ܡܓܪܒ',
 			'MC' => 'ܡܘܢܐܩܘ',
 			'MD' => 'ܡܘܠܕܘܒܐ',
 			'ME' => 'ܡܘܢܛܝܢܝܓܪܘ',
 			'MF' => 'ܣܐܢܬ ܡܐܪܬܝܢ',
 			'MG' => 'ܡܕܓܣܩܪ',
 			'MH' => 'ܓܙܪܬܐ ܡܐܪܫܐܠ',
 			'MK' => 'ܓܪܒܝ ܡܩܕܘܢܝܐ',
 			'ML' => 'ܡܐܠܝ',
 			'MM' => 'ܡܝܐܢܡܐܪ (ܒܘܪܡܐ)',
 			'MN' => 'ܡܘܢܓܘܠܝܐ',
 			'MO' => 'ܡܐܟܐܘ',
 			'MP' => 'ܓܙܝܖ̈ܐ ܕܡܪܝܢܐ ܓܪܒܝܐ',
 			'MQ' => 'ܡܐܪܬܝܢܝܩ',
 			'MR' => 'ܡܘܪܝܛܢܝܐ',
 			'MS' => 'ܡܘܢܣܝܪܐܬ',
 			'MT' => 'ܡܝܠܛܐ',
 			'MU' => 'ܡܘܪܝܛܝܘܣ',
 			'MV' => 'ܓܙܪܬܐ ܡܐܠܕܝܒܝܬܐ',
 			'MW' => 'ܡܠܐܘܝ',
 			'MX' => 'ܡܟܣܝܟܘ',
 			'MY' => 'ܡܠܝܙܝܐ',
 			'MZ' => 'ܡܘܙܡܒܝܩ',
 			'NA' => 'ܢܡܝܒܝܐ',
 			'NC' => 'ܢܝܘ ܟܠܝܕܘܢܝܐ',
 			'NE' => 'ܢܝܓܪ',
 			'NF' => 'ܓܙܪܬܐ ܕܢܘܪܦܠܟ',
 			'NG' => 'ܢܝܓܝܪܝܐ',
 			'NI' => 'ܢܝܟܪܐܓܘܐ',
 			'NL' => 'ܗܘܠܢܕܐ',
 			'NO' => 'ܢܘܪܒܝܓ',
 			'NP' => 'ܢܝܦܐܠ',
 			'NR' => 'ܢܐܘܪܘ',
 			'NU' => 'ܢܘܥ',
 			'NZ' => 'ܢܝܘ ܙܝܠܢܕ',
 			'NZ@alt=variant' => 'ܐܬܝܐܐܪܐܘ ܢܝܘ ܙܝܠܢܕ',
 			'OM' => 'ܥܘܡܐܢ',
 			'PA' => 'ܦܢܡܐ',
 			'PE' => 'ܦܝܪܘ',
 			'PF' => 'ܦܘܠܝܢܝܣܝܐ ܦܪܢܣܝܐ',
 			'PG' => 'ܦܐܦܘܐ ܓܝܢܝܐ ܚܕܬܐ',
 			'PH' => 'ܦܝܠܝܦܝܢܝܐ',
 			'PK' => 'ܦܐܟܣܬܐܢ',
 			'PL' => 'ܦܘܠܢܕ',
 			'PM' => 'ܣܐܢܬ ܦܝܥܪ ܘܡܩܘܠܘܢ',
 			'PN' => 'ܓܙܝܪ̈ܐ ܕܦܝܬܟܐܝܪܢ',
 			'PR' => 'ܦܘܐܪܛܘ ܪܝܩܘ',
 			'PS' => 'ܐܬܖ̈ܘܬܐ ܕܦܠܣܛܝܢ',
 			'PS@alt=short' => 'ܦܠܣܛܝܢ',
 			'PT' => 'ܦܘܪܛܘܓܠ',
 			'PW' => 'ܦܠܐܘ',
 			'PY' => 'ܦܪܓܘܐܝ',
 			'QA' => 'ܩܛܪ',
 			'QO' => 'ܐܘܩܝܢܘܣܝܐ ܒܪܝܬܐ',
 			'RE' => 'ܪܝܘܢܝܘܢ',
 			'RO' => 'ܪܘܡܢܝܐ',
 			'RS' => 'ܣܪܒܝܐ',
 			'RU' => 'ܪܘܣܝܐ',
 			'RW' => 'ܪܘܐܢܕܐ',
 			'SA' => 'ܣܥܘܕܝܐ',
 			'SB' => 'ܓܙܪܬܐ ܕܫܠܝܡܘܢ',
 			'SC' => 'ܣܐܝܫܝܠ',
 			'SD' => 'ܣܘܕܐܢ',
 			'SE' => 'ܣܘܝܕ',
 			'SG' => 'ܣܝܢܓܐܦܘܪ',
 			'SH' => 'ܡܪܬܝ ܗܝܠܝܢܐ',
 			'SI' => 'ܣܠܘܒܢܝܐ',
 			'SJ' => 'ܣܒܠܕܒܪܕ ܘܓܐܢ ܡܐܝܝܢ',
 			'SK' => 'ܣܠܘܒܩܝܐ',
 			'SL' => 'ܣܝܝܪܐ ܠܝܐܘܢܝ',
 			'SM' => 'ܣܢ ܡܪܝܢܘ',
 			'SN' => 'ܣܢܓܐܠ',
 			'SO' => 'ܨܘܡܐܠ',
 			'SR' => 'ܣܘܪܝܢܐܡ',
 			'SS' => 'ܬܝܡܢ ܣܘܕܐܢ',
 			'ST' => 'ܣܐܘ ܛܘܡܝ ܘܦܪܝܢܣܝܦܝ',
 			'SV' => 'ܐܠ ܣܠܒܐܕܘܪ',
 			'SX' => 'ܣܢܬ ܡܐܪܬܝܢ',
 			'SY' => 'ܣܘܪܝܐ',
 			'SZ' => 'ܐܣܘܐܛܝܢܝ',
 			'SZ@alt=variant' => 'ܣܘܐܙܝܠܢܕ',
 			'TA' => 'ܬܪܝܣܬܢ ܕܟܘܢܗܐ',
 			'TC' => 'ܓܙܝܖ̈ܐ ܕܬܘܪܟܣ ܘܟܐܝܟܘܣ',
 			'TD' => 'ܬܫܐܕ',
 			'TF' => 'ܩܠܝܡ̈ܐ ܕܦܪܢܣܐ ܬܝܡܢܝܬܐ',
 			'TG' => 'ܬܘܓܘ',
 			'TH' => 'ܬܐܝܠܢܕ',
 			'TJ' => 'ܬܐܓܝܟܣܬܐܢ',
 			'TK' => 'ܬܘܟܝܠܐܘ',
 			'TL' => 'ܬܝܡܘܪ-ܠܣܬܝ',
 			'TL@alt=variant' => 'ܬܝܡܘܪ ܡܕܢܚܐ',
 			'TM' => 'ܬܘܪܟܡܢܣܬܐܢ',
 			'TN' => 'ܬܘܢܣ',
 			'TO' => 'ܬܘܢܓܐ',
 			'TR' => 'ܬܘܪܟܝܐ',
 			'TT' => 'ܬܪܝܢܝܕܐܕ ܘܬܘܒܐܓܘ',
 			'TV' => 'ܬܘܒܐܠܘ',
 			'TW' => 'ܬܐܝܘܐܢ',
 			'TZ' => 'ܛܢܙܢܝܐ',
 			'UA' => 'ܐܘܩܪܐܝܢܐ',
 			'UG' => 'ܐܘܓܢܕܐ',
 			'UM' => 'ܓܙܝܪ̈ܐ ܪ̈ܚܝܩܐ ܕܐܘܚܕ̈ܢܐ ܡܚܝܕ̈ܐ',
 			'UN' => 'ܐܡ̈ܘܬܐ ܡܚܝ̈ܕܬܐ',
 			'US' => 'ܐܘܚܕ̈ܢܐ ܡܚܝܕ̈ܐ',
 			'UY' => 'ܐܘܪܘܓܘܐܝ',
 			'UZ' => 'ܐܘܙܒܟܣܬܐܢ',
 			'VA' => 'ܡܕܝܢܬܐ ܕܘܛܝܩܢ',
 			'VC' => 'ܣܐܢܬ ܒܝܢܣܝܢܬ ܘܓܪܝܢܐܕܝܢܐܣ',
 			'VE' => 'ܒܢܙܘܝܠܐ',
 			'VG' => 'ܓܙܖ̈ܝܐ ܒܬܘ̈ܠܐ ܕܒܪܝܛܢܝܐ',
 			'VI' => 'ܓܙܖ̈ܝܐ ܒܬܘ̈ܠܐ ܕܐܡܝܪܟܐ',
 			'VN' => 'ܒܝܬܢܐܡ',
 			'VU' => 'ܒܐܢܘܐܛܘ',
 			'WF' => 'ܘܝܠܝܣ ܘܦܘܬܘܢܐ',
 			'WS' => 'ܣܡܘܐ',
 			'XK' => 'ܩܘܣܘܒܘ',
 			'YE' => 'ܝܡܢ',
 			'YT' => 'ܡܐܝܘܛ',
 			'ZA' => 'ܬܝܡܢ ܐܦܪܝܩܐ',
 			'ZM' => 'ܙܐܡܒܝܐ',
 			'ZW' => 'ܙܝܡܒܐܒܘܝ',
 			'ZZ' => 'ܩܠܝܡܐ ܠܐ ܝܕܝܥܐ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'ܣܘܪܓܕܐ',
 			'cf' => 'ܛܘܦܣܐ ܕܙܘ̈ܙܐ',
 			'collation' => 'ܛܟܣܐ ܕܦܘܪܫܢܝܐ',
 			'currency' => 'ܙܘ̈ܙܐ',
 			'hc' => 'ܛܟ݂ܣܐ ܥܕܢܘܬܐ (12 ܠܘܩܒܠ 24)',
 			'ms' => 'ܛܟܣܐ ܕܟܝܠܬܐ',
 			'numbers' => 'ܡܢܝ̈ܢܐ',

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
 				'buddhist' => q{ܣܘܪܓܕܐ ܒܘܕܗܝܝܐ},
 				'chinese' => q{ܣܘܪܓܕܐ ܨܝܢܝܐ},
 				'coptic' => q{ܣܘܪܓܕܐ ܐܓܒܛܝܐ},
 				'dangi' => q{ܣܘܪܓܕܐ ܕܢܓܝ},
 				'ethiopic' => q{ܣܘܪܓܕܐ ܟܘܫܝܐ},
 				'gregorian' => q{ܣܘܪܓܕܐ ܓܪܝܓܘܪܝܐ},
 				'hebrew' => q{ܣܘܪܓܕܐ ܝܗܘܕܝܐ},
 				'indian' => q{ܣܘܪܓܕܐ ܐܘܡܬܢܝܐ ܗܢܕܘܝܐ},
 				'islamic' => q{ܣܘܪܓܕܐ ܡܫܠܡܢܝܐ},
 				'islamic-civil' => q{ܣܘܪܓܕܐ ܡܫܠܡܢܝܐ ܡܕܝܢܝܐ},
 				'iso8601' => q{ܣܘܪܓܕܐ ISO-8601},
 				'japanese' => q{ܣܘܪܓܕܐ ܝܦܢܝܐ},
 				'persian' => q{ܣܘܪܓܕܐ ܦܪܣܝܐ},
 				'roc' => q{ܣܘܪܓܕܐ ܡܝܢܓܘ},
 			},
 			'cf' => {
 				'account' => q{ܛܘܦܣܐ ܕܙܘ̈ܙܐ ܡܚܫܒܢܘܬܝܐ},
 				'standard' => q{ܛܘܦܣܐ ܕܙܘ̈ܙܐ ܫܪܫܝܐ},
 			},
 			'collation' => {
 				'dictionary' => q{ܛܟ݂ܣܐ ܦܘܪܫܢܝܐ ܕܠܟܣܝܩܘܢ},
 				'phonebook' => q{ܟܬܒܐ ܕܡܢܝ̈ܢܐ ܕܬܝܠܝܦܘܢ},
 				'standard' => q{ܛܟ݂ܣܐ ܦܘܪܫܢܝܐ ܫܪܫܝܐ},
 				'traditional' => q{ܛܟ݂ܣܐ ܦܘܪܫܢܝܐ ܥܝܕ݂ܝܐ},
 			},
 			'hc' => {
 				'h11' => q{ܛܟ݂ܣܐ 12 ܫܥܬ݂ܐ (0–11)},
 				'h12' => q{ܛܟ݂ܣܐ 12 ܫܥܬ݂ܐ (1–12)},
 				'h23' => q{ܛܟ݂ܣܐ 24 ܫܥܬ݂ܐ (0–23)},
 				'h24' => q{ܛܟ݂ܣܐ 24 ܫܥܬ݂ܐ (0–23)},
 			},
 			'ms' => {
 				'metric' => q{ܛܟܣܐ ܡܝܬܪܝܐ},
 				'uksystem' => q{ܛܟܣܐ ܕܟܝܠܬܐ ܒܪܝܛܢܝܝܐ},
 				'ussystem' => q{ܛܟܣܐ ܕܟܝܠܬܐ ܐܡܪܝܟܝܐ},
 			},
 			'numbers' => {
 				'arab' => q{ܡܢܝ̈ܢܐ ܕܥܖ̈ܒܝܐ ܗܢܕܘܝܐ},
 				'armn' => q{ܡܢܝ̈ܢܐ ܕܐܖ̈ܡܢܝܐ},
 				'ethi' => q{ܡܢܝ̈ܢܐ ܟܘܫܝܐ},
 				'geor' => q{ܡܢܝ̈ܢܐ ܓܘܪܓܝܐ},
 				'grek' => q{ܡܢܝ̈ܢܐ ܕܝܘܢܝ̈ܐ},
 				'hebr' => q{ܡܢܝ̈ܢܐ ܕܝܗܘܕܝ̈ܐ},
 				'jpan' => q{ܡܢܝ̈ܢܐ ܕܝܦܢܝ̈ܐ},
 				'latn' => q{ܡܢܝ̈ܢܐ ܡܥܪܒܝܐ},
 				'mong' => q{ܡܢܝ̈ܢܐ ܕܡܘܢܓܘܠܢܝ̈ܐ},
 				'roman' => q{ܡܢܝ̈ܢܐ ܪܗܘܡܝܐ},
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
			'metric' => q{ܛܟܣܐ ܡܝܬܪܝܐ},
 			'UK' => q{ܛܟܣܐ ܒܪܝܛܢܝܐ},
 			'US' => q{ܛܟܣܐ ܐܡܝܪܟܐ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ܠܫܢܐ:‌ {0}',
 			'script' => 'ܛܟܣܐ ܕܟܬܝܒܬܐ: {0}',
 			'region' => 'ܩܠܝܡܐ: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => '',
			characters => 'right-to-left',
		}}
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
			auxiliary => qr{[܏‌‍ ܭ ܮ ܯ ݍ ݎ ݏ]},
			index => ['ܐ', 'ܒ', 'ܓ', 'ܖ', 'ܕ', 'ܗ', 'ܘ', 'ܙ', 'ܚ', 'ܛ', 'ܝ', 'ܟ', 'ܠ', 'ܡ', 'ܢ', 'ܣ', 'ܥ', 'ܦ', 'ܨ', 'ܩ', 'ܪ', 'ܫ', 'ܬ'],
			main => qr{[݀ ݃ ݄ ݇ ݈ ݉ ݊ ݁ ݅ ݂ ݆ ܑ ܰ ܱ ܲ ܳ ܴ ܵ ܶ ܷ ܸ ܹ ܺ ܻ ܼ ܽ ܾ ܿ ܃ ܄ ܅ ܆ ܇ ܈ ܉ ܁ ܂ ܀ ܊ ܋ ܌ ܍ ܐ ܒ ܓܔ ܖ ܕ ܗ ܘ ܙ ܚ ܛܜ ܝ ܞ ܟ ܠ ܡ ܢ ܣܤ ܥ ܦܧ ܨ ܩ ܪ ܫ ܬ]},
			numbers => qr{[؜‎ \- ‑ , ٫ ٬ . % ٪ ‰ ؉ + 0٠ 1١ 2٢ 3٣ 4٤ 5٥ 6٦ 7٧ 8٨ 9٩]},
			punctuation => qr{[\- ‐‑ – — ، ؛ \: ܃ ܄ ܅ ܆ ܇ ܈ ! ؟ ܉ . … ܁ ܂ ܀ '‘’ "“” « » ( ) \[ \] ܊ ܋ ܌ ܍]},
		};
	},
EOT
: sub {
		return { index => ['ܐ', 'ܒ', 'ܓ', 'ܖ', 'ܕ', 'ܗ', 'ܘ', 'ܙ', 'ܚ', 'ܛ', 'ܝ', 'ܟ', 'ܠ', 'ܡ', 'ܢ', 'ܣ', 'ܥ', 'ܦ', 'ܨ', 'ܩ', 'ܪ', 'ܫ', 'ܬ'], };
},
);


has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{؟},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(ܦܝܟܘ{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(ܦܝܟܘ{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(ܦ̮ܝܡܬܘ{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(ܦ̮ܝܡܬܘ{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(ܐܬܘ{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ܐܬܘ{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(ܙܝܦܬܘ{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(ܙܝܦܬܘ{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(ܝܟܬܘ{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(ܝܟܬܘ{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(ܡܝܠܝ{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(ܡܝܠܝ{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(ܡܝܟܪܘ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(ܡܝܟܪܘ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(ܢܐܢܘ{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(ܢܐܢܘ{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ܕܝܟܐ{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ܕܝܟܐ{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ܬܝܪܐ{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ܬܝܪܐ{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(ܦܝܬܐ{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(ܦܝܬܐ{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(ܐܟܣܐ{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ܐܟܣܐ{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ܗܟܬܘ{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ܗܟܬܘ{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(ܙܝܬܐ{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(ܙܝܬܐ{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(ܝܘܬܐ{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(ܝܘܬܐ{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ܪܘܢܐ{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ܪܘܢܐ{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(ܟܝܠܘ{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(ܟܝܠܘ{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(ܟܒܝܬܐ{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(ܟܒܝܬܐ{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(ܡܝܓܐ{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(ܡܝܓܐ{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(ܓܝܓܐ{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(ܓܝܓܐ{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ܚܝܠܐ ܢܬܘܦܘܬܐ),
						'one' => q({0} ܚܝܠܐ ܢܬܘܦܘܬܐ),
						'other' => q({0} ܚܝܠܐ ܢܬܘܦܘܬܐ),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ܚܝܠܐ ܢܬܘܦܘܬܐ),
						'one' => q({0} ܚܝܠܐ ܢܬܘܦܘܬܐ),
						'other' => q({0} ܚܝܠܐ ܢܬܘܦܘܬܐ),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(ܡܝܬܪ̈ܐ ܒܪܦܦܐ ܡܪܒܥܐ),
						'one' => q({0} ܡܝܬܪܐ ܒܪܦܦܐ ܡܪܒܥܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ ܒܪܦܦܐ ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(ܡܝܬܪ̈ܐ ܒܪܦܦܐ ܡܪܒܥܐ),
						'one' => q({0} ܡܝܬܪܐ ܒܪܦܦܐ ܡܪܒܥܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ ܒܪܦܦܐ ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(ܩܛܝ̈ܢܬܐ ܩܫܬܢܝܬܐ),
						'one' => q(ܩܛܝܢܐ ܩܫܬܢܝܐ),
						'other' => q({0} ܩܛܝ̈ܢܬܐ ܩܫܬܢܝܬܐ),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(ܩܛܝ̈ܢܬܐ ܩܫܬܢܝܬܐ),
						'one' => q(ܩܛܝܢܐ ܩܫܬܢܝܐ),
						'other' => q({0} ܩܛܝ̈ܢܬܐ ܩܫܬܢܝܬܐ),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(ܪ̈ܦܦܐ ܩܫܬܢܝܐ),
						'one' => q({0} ܪ̈ܦܦܐ ܩܫܬܢܝܐ),
						'other' => q({0} ܪ̈ܦܦܐ ܩܫܬܢ̈ܝܐ),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(ܪ̈ܦܦܐ ܩܫܬܢܝܐ),
						'one' => q({0} ܪ̈ܦܦܐ ܩܫܬܢܝܐ),
						'other' => q({0} ܪ̈ܦܦܐ ܩܫܬܢ̈ܝܐ),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(ܕܪ̈ܓܐ),
						'one' => q(ܕܪܓܐ),
						'other' => q({0} ܕܖ̈ܓܐ),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(ܕܪ̈ܓܐ),
						'one' => q(ܕܪܓܐ),
						'other' => q({0} ܕܖ̈ܓܐ),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(ܪܐܕܝܐܢ),
						'one' => q({0} ܪܐܕܝܐܢ),
						'other' => q({0} ܪܐܕܝܐܢ),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(ܪܐܕܝܐܢ),
						'one' => q({0} ܪܐܕܝܐܢ),
						'other' => q({0} ܪܐܕܝܐܢ),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ܚܘܕܖ̈ܢܐ),
						'one' => q({0} ܚܘܕܪܐ),
						'other' => q({0} ܚܘܕܖ̈ܢܐ),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ܚܘܕܖ̈ܢܐ),
						'one' => q({0} ܚܘܕܪܐ),
						'other' => q({0} ܚܘܕܖ̈ܢܐ),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ܗܟܬܪ),
						'other' => q({0} ܗܟܬܖ̈ܐ),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} ܗܟܬܪ),
						'other' => q({0} ܗܟܬܖ̈ܐ),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(ܣܢܬܝܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܣܢܬܝܡܝܬܪܐ ܡܪܒܥܐ),
						'other' => q({0} ܣܢܬܝܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܣܢܬܝܡܝܬܪܐ ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(ܣܢܬܝܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܣܢܬܝܡܝܬܪܐ ܡܪܒܥܐ),
						'other' => q({0} ܣܢܬܝܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܣܢܬܝܡܝܬܪܐ ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ܐܩܠ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܐܩܠܐ ܡܪܒܥܐ),
						'other' => q({0} ܐܩܠ̈ܐ ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ܐܩܠ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܐܩܠܐ ܡܪܒܥܐ),
						'other' => q({0} ܐܩܠ̈ܐ ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(ܐܢܟ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܐܢܟ ܡܪܒܥܐ),
						'other' => q({0} ܐܢܟ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܐܢܟ ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(ܐܢܟ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܐܢܟ ܡܪܒܥܐ),
						'other' => q({0} ܐܢܟ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܐܢܟ ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(ܟܝܠܘܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܟܝܠܘܡܝܬܪܐ ܡܪܒܥܐ),
						'other' => q({0} ܟܝܠܘܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܟܝܠܘܡܝܬܪܐ ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(ܟܝܠܘܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܟܝܠܘܡܝܬܪܐ ܡܪܒܥܐ),
						'other' => q({0} ܟܝܠܘܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܟܝܠܘܡܝܬܪܐ ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܡܝܬܪܐ ܡܪܒܥܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܡܝܬܪܐ ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܡܝܬܪܐ ܡܪܒܥܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܡܝܬܪܐ ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(ܡܝܠ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܡܝܠܐ ܡܪܒܥܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܡܝܠ̈ܐ ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(ܡܝܠ̈ܐ ܡܪܒܥܐ),
						'one' => q({0} ܡܝܠܐ ܡܪܒܥܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܡܪܒܥܐ),
						'per' => q({0} ܒܡܝܠ̈ܐ ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ܝܪ̈ܕܐ ܡܪܒܥܐ),
						'one' => q({0} ܝܪܕܐ ܡܪܒܥܐ),
						'other' => q({0} ܝܪ̈ܕܐ ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ܝܪ̈ܕܐ ܡܪܒܥܐ),
						'one' => q({0} ܝܪܕܐ ܡܪܒܥܐ),
						'other' => q({0} ܝܪ̈ܕܐ ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ܡܠܘܐ̈ܐ),
						'one' => q(ܚܕ ܡܠܘܐܐ),
						'other' => q({0} ܡܠܘܐ̈ܐ),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ܡܠܘܐ̈ܐ),
						'one' => q(ܚܕ ܡܠܘܐܐ),
						'other' => q({0} ܡܠܘܐ̈ܐ),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ܩܪ̈ܛܐ),
						'one' => q(ܩܪܛܐ),
						'other' => q({0} ܩܪ̈ܛܐ),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ܩܪ̈ܛܐ),
						'one' => q(ܩܪܛܐ),
						'other' => q({0} ܩܪ̈ܛܐ),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(ܡܝܠܝܓܪ̈ܡܐ ܒܕܝܣܝܠܝܬܪܐ),
						'one' => q({0} ܡܝܠܝܓܪܡܐ ܒܕܝܣܝܠܝܬܪ),
						'other' => q({0} ܡܝܠܝܓܪ̈ܡܐ ܒܕܝܣܝܠܝܬܪܐ),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(ܡܝܠܝܓܪ̈ܡܐ ܒܕܝܣܝܠܝܬܪܐ),
						'one' => q({0} ܡܝܠܝܓܪܡܐ ܒܕܝܣܝܠܝܬܪ),
						'other' => q({0} ܡܝܠܝܓܪ̈ܡܐ ܒܕܝܣܝܠܝܬܪܐ),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ܡܝܠܝܡܘܠ ܒܠܝܬܪܐ),
						'one' => q({0} ܡܝܠܝܡܘܠ ܒܠܝܬܪܐ),
						'other' => q({0} ܡܝܠܝܡܘܠ ܒܠܝܬܪܐ),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ܡܝܠܝܡܘܠ ܒܠܝܬܪܐ),
						'one' => q({0} ܡܝܠܝܡܘܠ ܒܠܝܬܪܐ),
						'other' => q({0} ܡܝܠܝܡܘܠ ܒܠܝܬܪܐ),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(ܡܘܠ),
						'one' => q({0} ܡܘܠ),
						'other' => q({0} ܡܘܠ),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(ܡܘܠ),
						'one' => q({0} ܡܘܠ),
						'other' => q({0} ܡܘܠ),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ܒܡܐܐ),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ܒܡܐܐ),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(ܒܐܠܦܐ),
						'one' => q({0} ܒܐܠܦܐ),
						'other' => q({0} ܒܐܠܦܐ),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(ܒܐܠܦܐ),
						'one' => q({0} ܒܐܠܦܐ),
						'other' => q({0} ܒܐܠܦܐ),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ܡܢܘ̈ܬܐ ܒܡܠܝܘܢ),
						'one' => q({0} ܡܢܬܐ ܒܡܠܝܘܢ),
						'other' => q({0} ܡܢܘ̈ܬܐ ܒܡܠܝܘܢ),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ܡܢܘ̈ܬܐ ܒܡܠܝܘܢ),
						'one' => q({0} ܡܢܬܐ ܒܡܠܝܘܢ),
						'other' => q({0} ܡܢܘ̈ܬܐ ܒܡܠܝܘܢ),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ܠܝܬܪ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܠܝܬܪ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪܐ),
						'other' => q({0} ܠܝܬܪ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ܠܝܬܪ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܠܝܬܪ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪܐ),
						'other' => q({0} ܠܝܬܪ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ܠܝܬܪ̈ܐ ܒܟܝܠܘܡܝܬܪܐ),
						'one' => q({0} ܠܝܬܪܐ ܒܟܝܠܘܡܝܬܪܐ),
						'other' => q({0} ܠܝܬܪ̈ܐ ܒܟܝܠܘܡܝܬܪܐ),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ܠܝܬܪ̈ܐ ܒܟܝܠܘܡܝܬܪܐ),
						'one' => q({0} ܠܝܬܪܐ ܒܟܝܠܘܡܝܬܪܐ),
						'other' => q({0} ܠܝܬܪ̈ܐ ܒܟܝܠܘܡܝܬܪܐ),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(ܡܝܠ̈ܐ ܒܓܠܘܢܐ),
						'one' => q({0} ܡܝܠܐ ܒܓܠܘܢܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܒܓܠܘܢܐ),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(ܡܝܠ̈ܐ ܒܓܠܘܢܐ),
						'one' => q({0} ܡܝܠܐ ܒܓܠܘܢܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܒܓܠܘܢܐ),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(ܡܝܠ̈ܐ ܒܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܡܝܠܐ ܒܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܒܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(ܡܝܠ̈ܐ ܒܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܡܝܠܐ ܒܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܒܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ܡܕܢܚܐ),
						'north' => q({0} ܓܪܒܝܐ),
						'south' => q({0} ܬܝܡܢܐ),
						'west' => q({0} ܡܥܪܒ݂ܐ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ܡܕܢܚܐ),
						'north' => q({0} ܓܪܒܝܐ),
						'south' => q({0} ܬܝܡܢܐ),
						'west' => q({0} ܡܥܪܒ݂ܐ),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(ܒܬ),
						'one' => q({0} ܒܬ),
						'other' => q({0} ܒܬ),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(ܒܬ),
						'one' => q({0} ܒܬ),
						'other' => q({0} ܒܬ),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(ܒܐܝܬ),
						'one' => q({0} ܒܐܝܬ),
						'other' => q({0} ܒܐܝܬ),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(ܒܐܝܬ),
						'one' => q({0} ܒܐܝܬ),
						'other' => q({0} ܒܐܝܬ),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(ܓܝܓܐܒܬ),
						'one' => q({0} ܓܝܓܐܒܬ),
						'other' => q({0} ܓܝܓܐܒܬ),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(ܓܝܓܐܒܬ),
						'one' => q({0} ܓܝܓܐܒܬ),
						'other' => q({0} ܓܝܓܐܒܬ),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(ܓܝܓܐܒܐܝܬ),
						'one' => q({0} ܓܝܓܐܒܐܝܬ),
						'other' => q({0} ܓܝܓܐܒܐܝܬ),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(ܓܝܓܐܒܐܝܬ),
						'one' => q({0} ܓܝܓܐܒܐܝܬ),
						'other' => q({0} ܓܝܓܐܒܐܝܬ),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(ܟܝܠܘܒܬ),
						'one' => q({0} ܟܝܠܘܒܬ),
						'other' => q({0} ܟܝܠܘܒܬ),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(ܟܝܠܘܒܬ),
						'one' => q({0} ܟܝܠܘܒܬ),
						'other' => q({0} ܟܝܠܘܒܬ),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ܟܝܠܘܒܐܝܬ),
						'one' => q({0} ܟܝܠܘܒܐܝܬ),
						'other' => q({0} ܟܝܠܘܒܐܝܬ),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ܟܝܠܘܒܐܝܬ),
						'one' => q({0} ܟܝܠܘܒܐܝܬ),
						'other' => q({0} ܟܝܠܘܒܐܝܬ),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(ܡܝܓܐܒܬ),
						'one' => q({0} ܡܝܓܐܒܬ),
						'other' => q({0} ܡܝܓܐܒܬ),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(ܡܝܓܐܒܬ),
						'one' => q({0} ܡܝܓܐܒܬ),
						'other' => q({0} ܡܝܓܐܒܬ),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(ܡܝܓܐܒܐܝܬ),
						'one' => q({0} ܡܝܓܐܒܐܝܬ),
						'other' => q({0} ܡܝܓܐܒܐܝܬ),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(ܡܝܓܐܒܐܝܬ),
						'one' => q({0} ܡܝܓܐܒܐܝܬ),
						'other' => q({0} ܡܝܓܐܒܐܝܬ),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(ܦܝܬܐܒܐܝܬ),
						'one' => q({0} ܦܝܬܐܒܐܝܬ),
						'other' => q({0} ܦܝܬܐܒܐܝܬ),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(ܦܝܬܐܒܐܝܬ),
						'one' => q({0} ܦܝܬܐܒܐܝܬ),
						'other' => q({0} ܦܝܬܐܒܐܝܬ),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(ܬܝܪܐܒܬ),
						'one' => q({0} ܬܝܪܐܒܬ),
						'other' => q({0} ܬܝܪܐܒܬ),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(ܬܝܪܐܒܬ),
						'one' => q({0} ܬܝܪܐܒܬ),
						'other' => q({0} ܬܝܪܐܒܬ),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ܬܝܪܐܒܐܝܬ),
						'one' => q({0} ܬܝܪܐܒܐܝܬ),
						'other' => q({0} ܬܝܪܐܒܐܝܬ),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ܬܝܪܐܒܐܝܬ),
						'one' => q({0} ܬܝܪܐܒܐܝܬ),
						'other' => q({0} ܬܝܪܐܒܐܝܬ),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ܕܪ̈ܐ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ܕܪ̈ܐ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} ܒܝܘܡܐ),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} ܒܝܘܡܐ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ܥܣܝܪ̈ܘܬܐ),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ܥܣܝܪ̈ܘܬܐ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} ܒܫܥܬܐ),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} ܒܫܥܬܐ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(ܡܝܟܪܘܪ̈ܦܦܐ),
						'one' => q({0} ܡܝܟܪܘܪܦܦܐ),
						'other' => q({0} ܡܝܟܪܘܪ̈ܦܦܐ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(ܡܝܟܪܘܪ̈ܦܦܐ),
						'one' => q({0} ܡܝܟܪܘܪܦܦܐ),
						'other' => q({0} ܡܝܟܪܘܪ̈ܦܦܐ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q(ܩܛܝܢܐ),
						'other' => q({0} ܩܛܝܢ̈ܐ),
						'per' => q({0} ܒܩܛܝܢܐ),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q(ܩܛܝܢܐ),
						'other' => q({0} ܩܛܝܢ̈ܐ),
						'per' => q({0} ܒܩܛܝܢܐ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} ܒܝܪܚܐ),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} ܒܝܪܚܐ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0} ܢܐܢܘܪܦܦܐ),
						'other' => q({0} ܢܐܢܘܪ̈ܦܦܐ),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0} ܢܐܢܘܪܦܦܐ),
						'other' => q({0} ܢܐܢܘܪ̈ܦܦܐ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ܪ̈ܘܒܥܐ),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ܪ̈ܘܒܥܐ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} ܪܦܦܐ),
						'other' => q({0} ܪ̈ܦܦܐ),
						'per' => q({0} ܒܪܦܦܐ),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} ܪܦܦܐ),
						'other' => q({0} ܪ̈ܦܦܐ),
						'per' => q({0} ܒܪܦܦܐ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0} ܒܫܒܘܥܐ),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0} ܒܫܒܘܥܐ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} ܒܫܢܬܐ),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} ܒܫܢܬܐ),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ܐܡܦܝܪ),
						'one' => q({0} ܐܡܦܝܪ),
						'other' => q({0} ܐܡܦܝܪ),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ܐܡܦܝܪ),
						'one' => q({0} ܐܡܦܝܪ),
						'other' => q({0} ܐܡܦܝܪ),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(ܡܝܠܝܐܡܦܝܪ),
						'one' => q({0} ܡ ܐܡܦܝܪ),
						'other' => q({0} ܡ ܐܡܦܝܪ),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(ܡܝܠܝܐܡܦܝܪ),
						'one' => q({0} ܡ ܐܡܦܝܪ),
						'other' => q({0} ܡ ܐܡܦܝܪ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(ܟܝܠܘܘܐܬ-ܫܥ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܟܝܠܘܘܐܬ-ܫܥܬܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪܐ),
						'other' => q({0} ܟܝܠܘܘܐܬ-ܫܥ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(ܟܝܠܘܘܐܬ-ܫܥ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܟܝܠܘܘܐܬ-ܫܥܬܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪܐ),
						'other' => q({0} ܟܝܠܘܘܐܬ-ܫܥ̈ܐ ܒܡܐܐ ܟܝܠܘܡܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(ܢܝܘܬܢ),
						'one' => q({0} ܢܝܘܬܢ),
						'other' => q({0} ܢܝܘܬܢ),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(ܢܝܘܬܢ),
						'one' => q({0} ܢܝܘܬܢ),
						'other' => q({0} ܢܝܘܬܢ),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(ܡܝܓܐܦܝ̈ܟܣܠܐ),
						'one' => q({0} ܡܝܓܐܦܝܟܣܠܐ),
						'other' => q({0} ܡܝܓܐܦܝ̈ܟܣܠܐ),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(ܡܝܓܐܦܝ̈ܟܣܠܐ),
						'one' => q({0} ܡܝܓܐܦܝܟܣܠܐ),
						'other' => q({0} ܡܝܓܐܦܝ̈ܟܣܠܐ),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(ܦܝ̈ܟܣܠܐ),
						'one' => q({0} ܦܝܟܣܠܐ),
						'other' => q({0} ܦܝ̈ܟܣܠܐ),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(ܦܝ̈ܟܣܠܐ),
						'one' => q({0} ܦܝܟܣܠܐ),
						'other' => q({0} ܦܝ̈ܟܣܠܐ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ܦܝ̈ܟܣܠܐ ܒܣܢܬܝܡܝܬܪܐ),
						'one' => q({0} ܦܝܟܣܠܐ ܒܣܢܬܝܡܝܬܪܐ),
						'other' => q({0} ܦܝ̈ܟܣܠܐ ܒܣܢܬܝܡܝܬܪܐ),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ܦܝ̈ܟܣܠܐ ܒܣܢܬܝܡܝܬܪܐ),
						'one' => q({0} ܦܝܟܣܠܐ ܒܣܢܬܝܡܝܬܪܐ),
						'other' => q({0} ܦܝ̈ܟܣܠܐ ܒܣܢܬܝܡܝܬܪܐ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(ܦܝ̈ܟܣܠܐ ܒܐܢܟ),
						'one' => q({0} ܦܝܟܣܠܐ ܒܐܢܟ),
						'other' => q({0} ܦܝ̈ܟܣܠܐ ܒܐܢܟ),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ܦܝ̈ܟܣܠܐ ܒܐܢܟ),
						'one' => q({0} ܦܝܟܣܠܐ ܒܐܢܟ),
						'other' => q({0} ܦܝ̈ܟܣܠܐ ܒܐܢܟ),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ܡܫܘܚ̈ܐ ܪܩܝܥܝ̈ܐ),
						'one' => q({0} ܡܫܘܚܬܐ ܪܩܝܥܝܬܐ),
						'other' => q({0} ܡܫܘܚܬܐ ܪܩܝܥܝܬܐ),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ܡܫܘܚ̈ܐ ܪܩܝܥܝ̈ܐ),
						'one' => q({0} ܡܫܘܚܬܐ ܪܩܝܥܝܬܐ),
						'other' => q({0} ܡܫܘܚܬܐ ܪܩܝܥܝܬܐ),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(ܣܢܬܝܡܝܬܪ̈ܐ),
						'one' => q({0} ܣܢܬܝܡܝܬܪܐ),
						'other' => q({0} ܣܢܬܝܡܝܬܪ̈ܐ),
						'per' => q({0} ܒܣܢܬܝܡܝܬܪܐ),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(ܣܢܬܝܡܝܬܪ̈ܐ),
						'one' => q({0} ܣܢܬܝܡܝܬܪܐ),
						'other' => q({0} ܣܢܬܝܡܝܬܪ̈ܐ),
						'per' => q({0} ܒܣܢܬܝܡܝܬܪܐ),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(ܕܝܣܝܡܝܬܪ̈ܐ),
						'one' => q({0} ܕܝܣܝܡܝܬܪܐ),
						'other' => q({0} ܕܝܣܝܡܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(ܕܝܣܝܡܝܬܪ̈ܐ),
						'one' => q({0} ܕܝܣܝܡܝܬܪܐ),
						'other' => q({0} ܕܝܣܝܡܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(ܥܘܒܐ ܦܫܝܛܐ ܐܪܥܝܐ),
						'one' => q(ܚܕ ܥܘܒܐ ܦܫܝܛܐ ܐܪܥܝܐ),
						'other' => q({0} ܥܘܒ̈ܐ ܦܫܝ̈ܛܐ ܐܖ̈ܥܝܐ),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(ܥܘܒܐ ܦܫܝܛܐ ܐܪܥܝܐ),
						'one' => q(ܚܕ ܥܘܒܐ ܦܫܝܛܐ ܐܪܥܝܐ),
						'other' => q({0} ܥܘܒ̈ܐ ܦܫܝ̈ܛܐ ܐܖ̈ܥܝܐ),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} ܐܩܠܐ),
						'other' => q({0} ܐܩܠ̈ܐ),
						'per' => q({0} ܒܐܩܠܐ),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} ܐܩܠܐ),
						'other' => q({0} ܐܩܠ̈ܐ),
						'per' => q({0} ܒܐܩܠܐ),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(ܦܘܪ̈ܠܢܓܐ),
						'one' => q({0} ܦܘܪܠܢܓ),
						'other' => q({0} ܦܘܪ̈ܠܢܓܐ),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(ܦܘܪ̈ܠܢܓܐ),
						'one' => q({0} ܦܘܪܠܢܓ),
						'other' => q({0} ܦܘܪ̈ܠܢܓܐ),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(ܐܢܟ̈ܐ),
						'one' => q({0} ܐܢܟ),
						'other' => q({0} ܐܢܟ̈ܐ),
						'per' => q({0} ܒܐܢܟ),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(ܐܢܟ̈ܐ),
						'one' => q({0} ܐܢܟ),
						'other' => q({0} ܐܢܟ̈ܐ),
						'per' => q({0} ܒܐܢܟ),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(ܟܝܠܘܡܝܬܪ̈ܐ),
						'one' => q(ܚܕ ܟܝܠܘܡܝܬܪܐ),
						'other' => q({0} ܟܝܠܘܡܝܬܪ̈ܐ),
						'per' => q({0} ܒܟܝܠܘܡܝܬܪܐ),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(ܟܝܠܘܡܝܬܪ̈ܐ),
						'one' => q(ܚܕ ܟܝܠܘܡܝܬܪܐ),
						'other' => q({0} ܟܝܠܘܡܝܬܪ̈ܐ),
						'per' => q({0} ܒܟܝܠܘܡܝܬܪܐ),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ܫ̈ܢܐ ܕܢܘܗܪܐ),
						'one' => q({0} ܫܢܬܐ ܕܢܘܗܪܐ),
						'other' => q({0} ܫ̈ܢܐ ܕܢܘܗܪܐ),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ܫ̈ܢܐ ܕܢܘܗܪܐ),
						'one' => q({0} ܫܢܬܐ ܕܢܘܗܪܐ),
						'other' => q({0} ܫ̈ܢܐ ܕܢܘܗܪܐ),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(ܡܝܬܪ̈ܐ),
						'one' => q(ܡܝܬܪܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ),
						'per' => q({0} ܒܡܝܬܪܐ),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(ܡܝܬܪ̈ܐ),
						'one' => q(ܡܝܬܪܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ),
						'per' => q({0} ܒܡܝܬܪܐ),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(ܡܝܟܪܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܡܝܟܪܘܡܝܬܪܐ),
						'other' => q({0} ܡܝܟܪܘܡܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(ܡܝܟܪܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܡܝܟܪܘܡܝܬܪܐ),
						'other' => q({0} ܡܝܟܪܘܡܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(ܡܝܠ̈ܐ),
						'one' => q({0} ܡܝܠܐ),
						'other' => q({0} ܡܝܠ̈ܐ),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(ܡܝܠ̈ܐ),
						'one' => q({0} ܡܝܠܐ),
						'other' => q({0} ܡܝܠ̈ܐ),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(ܡܝܠ̈ܐ ܐܣܟܢܕܝܢܒܝܝܢ),
						'one' => q({0} ܡܝܠܐ ܐܣܟܢܕܝܢܒܝܝܢ),
						'other' => q({0} ܡܝܠ̈ܐ ܐܣܟܢܕܝܢܒܝܝܢ),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(ܡܝܠ̈ܐ ܐܣܟܢܕܝܢܒܝܝܢ),
						'one' => q({0} ܡܝܠܐ ܐܣܟܢܕܝܢܒܝܝܢ),
						'other' => q({0} ܡܝܠ̈ܐ ܐܣܟܢܕܝܢܒܝܝܢ),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(ܡܝܠܝܡܝܬܪ̈ܐ),
						'one' => q({0} ܡܝܠܝܡܝܬܪܐ),
						'other' => q({0} ܡܝܠܝܡܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(ܡܝܠܝܡܝܬܪ̈ܐ),
						'one' => q({0} ܡܝܠܝܡܝܬܪܐ),
						'other' => q({0} ܡܝܠܝܡܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(ܢܐܢܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܢܐܢܘܡܝܬܪܐ),
						'other' => q({0} ܢܐܢܘܡܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(ܢܐܢܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܢܐܢܘܡܝܬܪܐ),
						'other' => q({0} ܢܐܢܘܡܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(ܡܝܠ̈ܐ ܝܡܝ̈ܐ),
						'one' => q({0} ܡܝܠܐ ܝܡܝܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܝܡܝ̈ܐ),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(ܡܝܠ̈ܐ ܝܡܝ̈ܐ),
						'one' => q({0} ܡܝܠܐ ܝܡܝܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܝܡܝ̈ܐ),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(ܦܪ̈ܣܚܐ),
						'one' => q({0} ܦܪܣܚܐ),
						'other' => q({0} ܦܪ̈ܣܚܐ),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(ܦܪ̈ܣܚܐ),
						'one' => q({0} ܦܪܣܚܐ),
						'other' => q({0} ܦܪ̈ܣܚܐ),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(ܦܝܟܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܦܝܟܘܡܝܬܪܐ),
						'other' => q({0} ܦܝܟܘܡܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(ܦܝܟܘܡܝܬܪ̈ܐ),
						'one' => q({0} ܦܝܟܘܡܝܬܪܐ),
						'other' => q({0} ܦܝܟܘܡܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(ܢܘܩܙ̈ܐ),
						'one' => q({0} ܢܘܩܙܐ),
						'other' => q({0} ܢܘܩܙ̈ܐ),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(ܢܘܩܙ̈ܐ),
						'one' => q({0} ܢܘܩܙܐ),
						'other' => q({0} ܢܘܩܙ̈ܐ),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(ܥܘܒܐ ܦܫܝܛܐ ܫܡܫܝܐ),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(ܥܘܒܐ ܦܫܝܛܐ ܫܡܫܝܐ),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ܝܪܕ̈ܐ),
						'one' => q({0} ܝܪܕ̈ܐ),
						'other' => q({0} ܝܪܕ̈ܐ),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ܝܪܕ̈ܐ),
						'one' => q({0} ܝܪܕ̈ܐ),
						'other' => q({0} ܝܪܕ̈ܐ),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(ܢܗܝܪܐ),
						'one' => q({0} ܢܗܝܪܐ),
						'other' => q({0} ܢܗܝܪܐ),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(ܢܗܝܪܐ),
						'one' => q({0} ܢܗܝܪܐ),
						'other' => q({0} ܢܗܝܪܐ),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(ܠܘܡܝܢ),
						'one' => q({0} ܠܘܡܝܢ),
						'other' => q({0} ܠܘܡܝܢ),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(ܠܘܡܝܢ),
						'one' => q({0} ܠܘܡܝܢ),
						'other' => q({0} ܠܘܡܝܢ),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ܩܪ̈ܛܐ),
						'one' => q({0} ܩܪܛܐ),
						'other' => q({0} ܩܪ̈ܛܐ),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ܩܪ̈ܛܐ),
						'one' => q({0} ܩܪܛܐ),
						'other' => q({0} ܩܪ̈ܛܐ),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(ܕܐܠܬܘܢ),
						'one' => q({0} ܕܐܠܬܘܢ),
						'other' => q({0} ܕܐܠܬܘܢ),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(ܕܐܠܬܘܢ),
						'one' => q({0} ܕܐܠܬܘܢ),
						'other' => q({0} ܕܐܠܬܘܢ),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(ܥܘܫܢܐ ܐܪܥܝܐ),
						'one' => q({0} ܥܘܫܢܐ ܐܪܥܝܐ),
						'other' => q({0} ܥܘܫܢܐ ܐܪܥܝܐ),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(ܥܘܫܢܐ ܐܪܥܝܐ),
						'one' => q({0} ܥܘܫܢܐ ܐܪܥܝܐ),
						'other' => q({0} ܥܘܫܢܐ ܐܪܥܝܐ),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ܓܪ̈ܡܐ),
						'one' => q(ܓܪܡܐ),
						'other' => q({0} ܓܪ̈ܡܐ),
						'per' => q({0} ܒܓܪܡܐ),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ܓܪ̈ܡܐ),
						'one' => q(ܓܪܡܐ),
						'other' => q({0} ܓܪ̈ܡܐ),
						'per' => q({0} ܒܓܪܡܐ),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(ܟܝܠܘܓܪ̈ܡܐ),
						'one' => q({0} ܟܝܠܘܓܪܡܐ),
						'other' => q({0} ܟܝܠܘܓܪ̈ܡܐ),
						'per' => q({0} ܒܟܝܠܘܓܪܡܐ),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(ܟܝܠܘܓܪ̈ܡܐ),
						'one' => q({0} ܟܝܠܘܓܪܡܐ),
						'other' => q({0} ܟܝܠܘܓܪ̈ܡܐ),
						'per' => q({0} ܒܟܝܠܘܓܪܡܐ),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(ܡܝܟܪܘܓܪ̈ܡܐ),
						'one' => q({0} ܡܝܟܪܘܓܪܡܐ),
						'other' => q({0} ܡܝܟܪܘܓܪ̈ܡܐ),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(ܡܝܟܪܘܓܪ̈ܡܐ),
						'one' => q({0} ܡܝܟܪܘܓܪܡܐ),
						'other' => q({0} ܡܝܟܪܘܓܪ̈ܡܐ),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(ܡܝܠܝܓܪ̈ܡܐ),
						'one' => q({0} ܡܝܠܝܓܪܡܐ),
						'other' => q({0} ܡܝܠܝܓܪ̈ܡܐ),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(ܡܝܠܝܓܪ̈ܡܐ),
						'one' => q({0} ܡܝܠܝܓܪܡܐ),
						'other' => q({0} ܡܝܠܝܓܪ̈ܡܐ),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ܐܘܢܩ̈ܝܐ),
						'one' => q({0} ܐܘܢܩܝܐ),
						'other' => q({0} ܐܘܢܩ̈ܝܐ),
						'per' => q({0} ܒܐܘܢܩܝܐ),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ܐܘܢܩ̈ܝܐ),
						'one' => q({0} ܐܘܢܩܝܐ),
						'other' => q({0} ܐܘܢܩ̈ܝܐ),
						'per' => q({0} ܒܐܘܢܩܝܐ),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(ܡܢܝ̈ܐ),
						'one' => q({0} ܡܢܝܐ),
						'other' => q({0} ܡܢܝ̈ܐ),
						'per' => q({0} ܒܡܢܝܐ),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(ܡܢܝ̈ܐ),
						'one' => q({0} ܡܢܝܐ),
						'other' => q({0} ܡܢܝ̈ܐ),
						'per' => q({0} ܒܡܢܝܐ),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(ܥܘܫܢܐ ܫܡܫܝܐ),
						'one' => q({0} ܥܘܫܢܐ ܫܡܫܝܐ),
						'other' => q({0} ܥܘܫܢܐ ܫܡܫܝܐ),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(ܥܘܫܢܐ ܫܡܫܝܐ),
						'one' => q({0} ܥܘܫܢܐ ܫܡܫܝܐ),
						'other' => q({0} ܥܘܫܢܐ ܫܡܫܝܐ),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(ܣܛܘܢ),
						'one' => q({0} ܣܛܘܢ),
						'other' => q({0} ܣܛܘܢ),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(ܣܛܘܢ),
						'one' => q({0} ܣܛܘܢ),
						'other' => q({0} ܣܛܘܢ),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ܬܘܢ̈ܐ),
						'one' => q({0} ܬܘܢܐ),
						'other' => q({0} ܬܘܢ̈ܐ),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ܬܘܢ̈ܐ),
						'one' => q({0} ܬܘܢܐ),
						'other' => q({0} ܬܘܢ̈ܐ),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(ܬܘܢ ܡܝܬܪܝܐ),
						'one' => q({0} ܬܘܢ ܡܝܬܪܝܐ),
						'other' => q({0} ܬܘܢ̈ ܡܝܬܪ̈ܝܐ),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(ܬܘܢ ܡܝܬܪܝܐ),
						'one' => q({0} ܬܘܢ ܡܝܬܪܝܐ),
						'other' => q({0} ܬܘܢ̈ ܡܝܬܪ̈ܝܐ),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(ܓܝܓܐܘܐܬ),
						'one' => q({0} ܓܝܓܐܘܐܬ),
						'other' => q({0} ܓܝܓܐܘܐܬ),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(ܓܝܓܐܘܐܬ),
						'one' => q({0} ܓܝܓܐܘܐܬ),
						'other' => q({0} ܓܝܓܐܘܐܬ),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ܚܝܠܐ ܕܣܘܣܝܐ),
						'one' => q({0} ܣܘܣܝܐ),
						'other' => q({0} ܣܘܣܝܐ),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ܚܝܠܐ ܕܣܘܣܝܐ),
						'one' => q({0} ܣܘܣܝܐ),
						'other' => q({0} ܣܘܣܝܐ),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(ܟܝܠܘܘܐܬ),
						'one' => q({0} ܟܝܠܘܘܐܬ),
						'other' => q({0} ܟܝܠܘܘܐܬ),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(ܟܝܠܘܘܐܬ),
						'one' => q({0} ܟܝܠܘܘܐܬ),
						'other' => q({0} ܟܝܠܘܘܐܬ),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(ܡܝܓܐܘܐܬ),
						'one' => q({0} ܡܝܓܐܘܐܬ),
						'other' => q({0} ܡܝܓܐܘܐܬ),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(ܡܝܓܐܘܐܬ),
						'one' => q({0} ܡܝܓܐܘܐܬ),
						'other' => q({0} ܡܝܓܐܘܐܬ),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(ܡܝܠܝܘܐܬ),
						'one' => q({0} ܡܝܠܝܘܐܬ),
						'other' => q({0} ܡܝܠܝܘܐܬ),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(ܡܝܠܝܘܐܬ),
						'one' => q({0} ܡܝܠܝܘܐܬ),
						'other' => q({0} ܡܝܠܝܘܐܬ),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(ܘܐܬ),
						'one' => q({0} ܘܐܬ),
						'other' => q({0} ܘܐܬ),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(ܘܐܬ),
						'one' => q({0} ܘܐܬ),
						'other' => q({0} ܘܐܬ),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q({0} ܡܪܒܥܐ),
						'other' => q({0} ܡܪܒܥܐ),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q({0} ܡܪܒܥܐ),
						'other' => q({0} ܡܪܒܥܐ),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q({0} ܡܩܦܣܐ),
						'other' => q({0} ܡܩܦܣܐ),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q({0} ܡܩܦܣܐ),
						'other' => q({0} ܡܩܦܣܐ),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(ܡܫܘܚܬܐ ܟܒܘܫܝܬܐ ܪܩܝܥܝܬܐ),
						'one' => q({0} ܟܒܘܫܐ ܪܩܝܥܐ),
						'other' => q({0} ܟܒܘܫ̈ܐ ܪ̈ܩܝܥܐ),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(ܡܫܘܚܬܐ ܟܒܘܫܝܬܐ ܪܩܝܥܝܬܐ),
						'one' => q({0} ܟܒܘܫܐ ܪܩܝܥܐ),
						'other' => q({0} ܟܒܘܫ̈ܐ ܪ̈ܩܝܥܐ),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(ܒܐܪ),
						'one' => q({0} ܒܐܪ),
						'other' => q({0} ܒܐܪ),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(ܒܐܪ),
						'one' => q({0} ܒܐܪ),
						'other' => q({0} ܒܐܪ),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ܗܟܬܘܦܣܟ̈ܠܐ),
						'one' => q({0} ܗܟܬܘܦܣܟ̈ܠܐ),
						'other' => q({0} ܗܟܬܘܦܣܟ̈ܠܐ),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ܗܟܬܘܦܣܟ̈ܠܐ),
						'one' => q({0} ܗܟܬܘܦܣܟ̈ܠܐ),
						'other' => q({0} ܗܟܬܘܦܣܟ̈ܠܐ),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(ܟܝܠܘܦܣܟܠ),
						'one' => q({0} ܟܝܠܘܦܣܟܠ),
						'other' => q({0} ܟܝܠܘܦܣܟܠ),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(ܟܝܠܘܦܣܟܠ),
						'one' => q({0} ܟܝܠܘܦܣܟܠ),
						'other' => q({0} ܟܝܠܘܦܣܟܠ),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(ܡܝܓܐܦܣܟܠ),
						'one' => q({0} ܡܝܓܐܦܣܟܠ),
						'other' => q({0} ܡܝܓܐܦܣܟܠ),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(ܡܝܓܐܦܣܟܠ),
						'one' => q({0} ܡܝܓܐܦܣܟܠ),
						'other' => q({0} ܡܝܓܐܦܣܟܠ),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(ܡܝܠܝܒܐܪ),
						'one' => q({0} ܡܝܠܝܒܐܪ),
						'other' => q({0} ܡܝܠܝܒܐܪ),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(ܡܝܠܝܒܐܪ),
						'one' => q({0} ܡܝܠܝܒܐܪ),
						'other' => q({0} ܡܝܠܝܒܐܪ),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(ܡܝܠܝܡܝܬܪ̈ܐ ܕܙܝܘܓܐ),
						'one' => q({0} ܡܝܠܝܡܝܬܪܐ ܕܙܝܘܓܐ),
						'other' => q({0} ܡܝܠܝܡܝܬܪ̈ܐ ܕܙܝܘܓܐ),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(ܡܝܠܝܡܝܬܪ̈ܐ ܕܙܝܘܓܐ),
						'one' => q({0} ܡܝܠܝܡܝܬܪܐ ܕܙܝܘܓܐ),
						'other' => q({0} ܡܝܠܝܡܝܬܪ̈ܐ ܕܙܝܘܓܐ),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(ܦܣܟ̈ܠܐ),
						'one' => q({0} ܦܣܟ̈ܠܐ),
						'other' => q({0} ܦܣܟ̈ܠܐ),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(ܦܣܟ̈ܠܐ),
						'one' => q({0} ܦܣܟ̈ܠܐ),
						'other' => q({0} ܦܣܟ̈ܠܐ),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(ܟܝܠܘܡܝܬܪ̈ܐ ܒܫܥܬܐ),
						'one' => q({0} ܟܝܠܘܡܝܬܪܐ ܒܫܥܬܐ),
						'other' => q({0} ܟܝܠܘܡܝܬܪ̈ܐ ܒܫܥܬܐ),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(ܟܝܠܘܡܝܬܪ̈ܐ ܒܫܥܬܐ),
						'one' => q({0} ܟܝܠܘܡܝܬܪܐ ܒܫܥܬܐ),
						'other' => q({0} ܟܝܠܘܡܝܬܪ̈ܐ ܒܫܥܬܐ),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(ܩܛܪ̈ܐ),
						'one' => q({0} ܩܛܪܐ),
						'other' => q({0} ܩܛܪ̈ܐ),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(ܩܛܪ̈ܐ),
						'one' => q({0} ܩܛܪܐ),
						'other' => q({0} ܩܛܪ̈ܐ),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(ܡܝܬܪ̈ܐ ܒܪܦܦܐ),
						'one' => q({0} ܡܝܬܪܐ ܒܪܦܦܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ ܒܪܦܦܐ),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(ܡܝܬܪ̈ܐ ܒܪܦܦܐ),
						'one' => q({0} ܡܝܬܪܐ ܒܪܦܦܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ ܒܪܦܦܐ),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(ܡܝܠ̈ܐ ܒܫܥܬܐ),
						'one' => q({0} ܡܝܠܐ ܒܫܥܬܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܒܫܥܬܐ),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(ܡܝܠ̈ܐ ܒܫܥܬܐ),
						'one' => q({0} ܡܝܠܐ ܒܫܥܬܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܒܫܥܬܐ),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(ܕܪ̈ܓܐ ܡܐܢܝܐ),
						'one' => q({0} ܕܪܓܐ ܡܐܢܝܐ),
						'other' => q({0} ܕܪ̈ܓܐ ܡܐܢܝܐ),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(ܕܪ̈ܓܐ ܡܐܢܝܐ),
						'one' => q({0} ܕܪܓܐ ܡܐܢܝܐ),
						'other' => q({0} ܕܪ̈ܓܐ ܡܐܢܝܐ),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(ܕܪ̈ܓܐ ܦܐܗܪܢܗܥܝܬ),
						'one' => q({0} ܕܪܓܐ ܦܐܗܪܢܗܥܝܬ),
						'other' => q({0} ܕܪ̈ܓܐ ܦܐܗܪܢܗܥܝܬ),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(ܕܪ̈ܓܐ ܦܐܗܪܢܗܥܝܬ),
						'one' => q({0} ܕܪܓܐ ܦܐܗܪܢܗܥܝܬ),
						'other' => q({0} ܕܪ̈ܓܐ ܦܐܗܪܢܗܥܝܬ),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(ܕܪ̈ܓܐ ܟܠܒܝܢ),
						'one' => q({0} ܕܪܓܐ ܟܠܒܝܢ),
						'other' => q({0} ܕܪ̈ܓܐ ܟܠܒܝܢ),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(ܕܪ̈ܓܐ ܟܠܒܝܢ),
						'one' => q({0} ܕܪܓܐ ܟܠܒܝܢ),
						'other' => q({0} ܕܪ̈ܓܐ ܟܠܒܝܢ),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(ܢܝܘܬܢ-ܡܝܬܪ̈ܐ),
						'one' => q({0} ܢܝܘܬܢ-ܡܝܬܪܐ),
						'other' => q({0} ܢܝܘܬܢ-ܡܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(ܢܝܘܬܢ-ܡܝܬܪ̈ܐ),
						'one' => q({0} ܢܝܘܬܢ-ܡܝܬܪܐ),
						'other' => q({0} ܢܝܘܬܢ-ܡܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ܐܩܠ̈ܐ-ܦܕܢܐ),
						'one' => q({0} ܐܩܠܐ-ܦܕܢܐ),
						'other' => q({0} ܐܩܠ̈ܐ-ܦܕܢܐ),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ܐܩܠ̈ܐ-ܦܕܢܐ),
						'one' => q({0} ܐܩܠܐ-ܦܕܢܐ),
						'other' => q({0} ܐܩܠ̈ܐ-ܦܕܢܐ),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(ܣܢܬܝܠܝܬܪ̈ܐ),
						'one' => q({0} ܣܢܬܝܠܝܬܪܐ),
						'other' => q({0} ܣܢܬܝܠܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(ܣܢܬܝܠܝܬܪ̈ܐ),
						'one' => q({0} ܣܢܬܝܠܝܬܪܐ),
						'other' => q({0} ܣܢܬܝܠܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(ܣܢܬܝܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܣܢܬܝܡܝܬܪܐ ܡܩܦܣܐ),
						'other' => q({0} ܣܢܬܝܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'per' => q({0}/ܣܢܬܝܡܝܬܪܐ ܡܩܦܣܐ),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(ܣܢܬܝܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܣܢܬܝܡܝܬܪܐ ܡܩܦܣܐ),
						'other' => q({0} ܣܢܬܝܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'per' => q({0}/ܣܢܬܝܡܝܬܪܐ ܡܩܦܣܐ),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ܐܩܠ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܐܩܠܐ ܡܩܦܣܐ),
						'other' => q({0} ܐܩܠ̈ܐ ܡܩܦܣܐ),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ܐܩܠ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܐܩܠܐ ܡܩܦܣܐ),
						'other' => q({0} ܐܩܠ̈ܐ ܡܩܦܣܐ),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(ܐܢܟ̈ܐ ܡܩܦܣܐ),
						'one' => q(ܚܕܐ ܐܢܟ ܡܩܦܣܐ),
						'other' => q({0} ܐܢܟ̈ܐ ܡܩܦܣܐ),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(ܐܢܟ̈ܐ ܡܩܦܣܐ),
						'one' => q(ܚܕܐ ܐܢܟ ܡܩܦܣܐ),
						'other' => q({0} ܐܢܟ̈ܐ ܡܩܦܣܐ),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(ܟܝܠܘܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܟܝܠܘܡܝܬܪܐ ܡܩܦܣܐ),
						'other' => q({0} ܟܝܠܘܡܝܬܪ̈ܐ ܡܩܦܣܐ),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(ܟܝܠܘܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܟܝܠܘܡܝܬܪܐ ܡܩܦܣܐ),
						'other' => q({0} ܟܝܠܘܡܝܬܪ̈ܐ ܡܩܦܣܐ),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(ܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܡܝܬܪܐ ܡܩܦܣܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'per' => q({0}/ܡܝܬܪܐ ܡܩܦܣܐ),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(ܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܡܝܬܪܐ ܡܩܦܣܐ),
						'other' => q({0} ܡܝܬܪ̈ܐ ܡܩܦܣܐ),
						'per' => q({0}/ܡܝܬܪܐ ܡܩܦܣܐ),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(ܡܝܠ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܡܝܠܐ ܡܩܦܣܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܡܩܦܣܐ),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(ܡܝܠ̈ܐ ܡܩܦܣܐ),
						'one' => q({0} ܡܝܠܐ ܡܩܦܣܐ),
						'other' => q({0} ܡܝܠ̈ܐ ܡܩܦܣܐ),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(ܝܪ̈ܕܐ ܡܩܦܣܐ),
						'one' => q({0} ܝܪܕܐ ܡܩܦܣܐ),
						'other' => q({0} ܝܪ̈ܕܐ ܡܩܦܣܐ),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(ܝܪ̈ܕܐ ܡܩܦܣܐ),
						'one' => q({0} ܝܪܕܐ ܡܩܦܣܐ),
						'other' => q({0} ܝܪ̈ܕܐ ܡܩܦܣܐ),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(ܕܝܣܝܠܝܬܪ̈ܐ),
						'one' => q({0} ܕܝܣܝܠܝܬܪܐ),
						'other' => q({0} ܕܝܣܝܠܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(ܕܝܣܝܠܝܬܪ̈ܐ),
						'one' => q({0} ܕܝܣܝܠܝܬܪܐ),
						'other' => q({0} ܕܝܣܝܠܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ܬܪ̈ܘܕܐ ܚܠܝ̈ܐ),
						'one' => q({0} ܬܪܘܕܐ ܚܠܝܐ),
						'other' => q({0} ܬܪ̈ܘܕܐ ܚܠܝ̈ܐ),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ܬܪ̈ܘܕܐ ܚܠܝ̈ܐ),
						'one' => q({0} ܬܪܘܕܐ ܚܠܝܐ),
						'other' => q({0} ܬܪ̈ܘܕܐ ܚܠܝ̈ܐ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(ܬܪ̈ܘܕܐ ܚܠܝ̈ܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܬܪܘܕܐ ܚܠܝܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܬܪ̈ܘܕܐ ܚܠܝ̈ܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(ܬܪ̈ܘܕܐ ܚܠܝ̈ܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܬܪܘܕܐ ܚܠܝܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܬܪ̈ܘܕܐ ܚܠܝ̈ܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ܕܪ̈ܟܡܐ ܪ̈ܕܘܝܐ),
						'one' => q({0} ܕܪܟܡܐ ܪܕܘܝܐ),
						'other' => q({0} ܕܪ̈ܟܡܐ ܪ̈ܕܘܝܐ),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ܕܪ̈ܟܡܐ ܪ̈ܕܘܝܐ),
						'one' => q({0} ܕܪܟܡܐ ܪܕܘܝܐ),
						'other' => q({0} ܕܪ̈ܟܡܐ ܪ̈ܕܘܝܐ),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ܛܘܦ̈ܢܐ),
						'one' => q({0} ܛܘܦܬܐ),
						'other' => q({0} ܛܘܦ̈ܢܐ),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ܛܘܦ̈ܢܐ),
						'one' => q({0} ܛܘܦܬܐ),
						'other' => q({0} ܛܘܦ̈ܢܐ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ܐܘܢܩ̈ܝܐ ܪ̈ܕܘܝܐ),
						'one' => q({0} ܐܘܢܩܝܐ ܪܕܘܝܐ),
						'other' => q({0} ܐܘܢܩ̈ܝܐ ܪ̈ܕܘܝܐ),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ܐܘܢܩ̈ܝܐ ܪ̈ܕܘܝܐ),
						'one' => q({0} ܐܘܢܩܝܐ ܪܕܘܝܐ),
						'other' => q({0} ܐܘܢܩ̈ܝܐ ܪ̈ܕܘܝܐ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(ܐܘܢܩ̈ܝܐ ܪ̈ܕܘܝܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܐܘܢܩܝܐ ܪܕܘܝܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܐܘܢܩ̈ܝܐ ܪ̈ܕܘܝܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(ܐܘܢܩ̈ܝܐ ܪ̈ܕܘܝܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܐܘܢܩܝܐ ܪܕܘܝܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܐܘܢܩ̈ܝܐ ܪ̈ܕܘܝܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(ܓܠܘܢ̈ܐ),
						'one' => q({0} ܓܠܘܢܐ),
						'other' => q({0} ܓܠܘܢ̈ܐ),
						'per' => q({0}/ܓܠܘܢܐ),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(ܓܠܘܢ̈ܐ),
						'one' => q({0} ܓܠܘܢܐ),
						'other' => q({0} ܓܠܘܢ̈ܐ),
						'per' => q({0}/ܓܠܘܢܐ),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(ܓܠܘܢ̈ܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܓܠܘܢ̈ܐ ܐܡܦܪܬܘܪܝܐ),
						'per' => q({0}/ܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(ܓܠܘܢ̈ܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܓܠܘܢ̈ܐ ܐܡܦܪܬܘܪܝܐ),
						'per' => q({0}/ܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ܗܟܬܘܠܝܬܪ̈ܐ),
						'one' => q({0} ܗܟܬܘܠܝܬܪܐ),
						'other' => q({0} ܗܟܬܘܠܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ܗܟܬܘܠܝܬܪ̈ܐ),
						'one' => q({0} ܗܟܬܘܠܝܬܪܐ),
						'other' => q({0} ܗܟܬܘܠܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ܠܝܬܪ̈ܐ),
						'one' => q({0} ܠܝܬܪܐ),
						'other' => q({0} ܠܝܬܪ̈ܐ),
						'per' => q({0}/ܠܝܬܪܐ),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ܠܝܬܪ̈ܐ),
						'one' => q({0} ܠܝܬܪܐ),
						'other' => q({0} ܠܝܬܪ̈ܐ),
						'per' => q({0}/ܠܝܬܪܐ),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ܡܝܓܐܠܝܬܪ̈ܐ),
						'one' => q({0} ܡܝܓܐܠܝܬܪܐ),
						'other' => q({0} ܡܝܓܐܠܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ܡܝܓܐܠܝܬܪ̈ܐ),
						'one' => q({0} ܡܝܓܐܠܝܬܪܐ),
						'other' => q({0} ܡܝܓܐܠܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ܡܝܠܝܠܝܬܪ̈ܐ),
						'one' => q({0} ܡܝܠܝܠܝܬܪܐ),
						'other' => q({0} ܡܝܠܝܠܝܬܪ̈ܐ),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ܡܝܠܝܠܝܬܪ̈ܐ),
						'one' => q({0} ܡܝܠܝܠܝܬܪܐ),
						'other' => q({0} ܡܝܠܝܠܝܬܪ̈ܐ),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ܪ̈ܘܒܥܐ ܓܠܘܢ̈ܐ),
						'one' => q({0} ܪܘܒܥܐ ܓܠܘܢܐ),
						'other' => q({0} ܪ̈ܘܒܥܐ ܓܠܘܢ̈ܐ),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ܪ̈ܘܒܥܐ ܓܠܘܢ̈ܐ),
						'one' => q({0} ܪܘܒܥܐ ܓܠܘܢܐ),
						'other' => q({0} ܪ̈ܘܒܥܐ ܓܠܘܢ̈ܐ),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(ܪ̈ܘܒܥܐ ܓܠܘܢ̈ܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܪܘܒܥܐ ܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܪ̈ܘܒܥܐ ܓܠܘܢ̈ܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(ܪ̈ܘܒܥܐ ܓܠܘܢ̈ܐ ܐܡܦܪܬܘܪܝܐ),
						'one' => q({0} ܪܘܒܥܐ ܓܠܘܢܐ ܐܡܦܪܬܘܪܝܐ),
						'other' => q({0} ܪ̈ܘܒܥܐ ܓܠܘܢ̈ܐ ܐܡܦܪܬܘܪܝܐ),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ܬܪ̈ܘܕܐ ܪ̈ܒܐ),
						'one' => q({0} ܬܪܘܕܐ ܪܒܐ),
						'other' => q({0} ܬܪ̈ܘܕܐ ܪ̈ܒܐ),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ܬܪ̈ܘܕܐ ܪ̈ܒܐ),
						'one' => q({0} ܬܪܘܕܐ ܪܒܐ),
						'other' => q({0} ܬܪ̈ܘܕܐ ܪ̈ܒܐ),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ܬܪ̈ܘܕܐ ܙܥܘܪ̈ܐ),
						'one' => q({0} ܬܪܘܕܐ ܙܥܘܪܐ),
						'other' => q({0} ܬܪ̈ܘܕܐ ܙܥܘܪ̈ܐ),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ܬܪ̈ܘܕܐ ܙܥܘܪ̈ܐ),
						'one' => q({0} ܬܪܘܕܐ ܙܥܘܪܐ),
						'other' => q({0} ܬܪ̈ܘܕܐ ܙܥܘܪ̈ܐ),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ܦܕܢܐ),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ܦܕܢܐ),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ܒܡܐܐ),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ܒܡܐܐ),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ܡܕܢܚܐ),
						'north' => q({0} ܓܪܒܝܐ),
						'south' => q({0} ܬܝܡܢܐ),
						'west' => q({0} ܡܥܪܒ݂ܐ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ܡܕܢܚܐ),
						'north' => q({0} ܓܪܒܝܐ),
						'south' => q({0} ܬܝܡܢܐ),
						'west' => q({0} ܡܥܪܒ݂ܐ),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0} ܕܪܐ),
						'other' => q({0} ܕܪ̈ܐ),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0} ܕܪܐ),
						'other' => q({0} ܕܪ̈ܐ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ܝܘܡܐ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ܝܘܡܐ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0} ܥܣܝܪܘܬܐ),
						'other' => q({0} ܥܣܝܪ̈ܘܬܐ),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0} ܥܣܝܪܘܬܐ),
						'other' => q({0} ܥܣܝܪ̈ܘܬܐ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ܫܥܬܐ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ܫܥܬܐ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(ܡܝܟܪܘܪܦܦܐ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(ܡܝܟܪܘܪܦܦܐ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ܡܝܠܝܪܦܦܐ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ܡܝܠܝܪܦܦܐ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ܩܛܝܢܐ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ܩܛܝܢܐ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ܝܪܚܐ),
						'one' => q({0} ܝܪܚܐ),
						'other' => q({0} ܝܪ̈ܚܐ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ܝܪܚܐ),
						'one' => q({0} ܝܪܚܐ),
						'other' => q({0} ܝܪ̈ܚܐ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ܢܐܢܘܪܦܦܐ),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ܢܐܢܘܪܦܦܐ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q({0} ܪܘܒܥܐ),
						'other' => q({0} ܪ̈ܘܒܥܐ),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0} ܪܘܒܥܐ),
						'other' => q({0} ܪ̈ܘܒܥܐ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ܪܦܦܐ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ܪܦܦܐ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ܫܒܘܥܐ),
						'per' => q({0}/ܫܒܘܥܐ),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ܫܒܘܥܐ),
						'per' => q({0}/ܫܒܘܥܐ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ܫܢܬܐ),
						'one' => q({0} ܫܢܬܐ),
						'other' => q({0} ܫ̈ܢܐ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ܫܢܬܐ),
						'one' => q({0} ܫܢܬܐ),
						'other' => q({0} ܫ̈ܢܐ),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pts),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pts),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(☉R),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(☉R),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ܦܢܝܬܐ ܫܪܫܢܝܬܐ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ܦܢܝܬܐ ܫܪܫܢܝܬܐ),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(ܟܝܒܝ{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(ܟܝܒܝ{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(ܡܝܒܝ{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(ܡܝܒܝ{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(ܓܝܒܝ{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(ܓܝܒܝ{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(ܬܝܒܝ{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(ܬܝܒܝ{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(ܦܝܒܝ{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(ܦܝܒܝ{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ܐܟܣܒܝ{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ܐܟܣܒܝ{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(ܙܝܒܝ{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(ܙܝܒܝ{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(ܝܘܒܝ{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(ܝܘܒܝ{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(ܕܝܣܝ{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ܕܝܣܝ{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(ܦ{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(ܦ{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(ܦ̮{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(ܦ̮{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(ܐ{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ܐ{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(ܣܢܬܝ{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(ܣܢܬܝ{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(ܙܝܦ{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(ܙܝܦ{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(ܝܟ{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(ܝܟ{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q({0}ܪܘܢܬܘ),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q({0}ܪܘܢܬܘ),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(ܡ{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(ܡ{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(ܡܟ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(ܡܟ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(ܢ{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(ܢ{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ܕܐ{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ܕܐ{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ܬ{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ܬ{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(ܦܝܬ{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(ܦܝܬ{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(ܐܟ{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ܐܟ{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ܗ{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ܗ{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(ܙܬ{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(ܙܬ{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(ܝܘ{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(ܝܘ{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ܪ{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ܪ{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(ܟ{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(ܟ{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(ܟܒ{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(ܟܒ{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(ܡܝܓ{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(ܡܝܓ{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(ܓܝ{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(ܓܝ{0}),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ܦ̈ܕܢܐ),
						'one' => q({0} ܦܕܢܐ),
						'other' => q({0} ܦ̈ܕܢܐ),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ܦ̈ܕܢܐ),
						'one' => q({0} ܦܕܢܐ),
						'other' => q({0} ܦ̈ܕܢܐ),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ܡܠܘܐܐ),
						'one' => q(ܡܠܘܐܐ),
						'other' => q({0} ܡܠܘܐ̈ܐ),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ܡܠܘܐܐ),
						'one' => q(ܡܠܘܐܐ),
						'other' => q({0} ܡܠܘܐ̈ܐ),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ܕܪܐ),
						'one' => q(ܕܪܐ),
						'other' => q({0} ܕܪ̈ܐ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ܕܪܐ),
						'one' => q(ܕܪܐ),
						'other' => q({0} ܕܪ̈ܐ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ܝܘܡܢ̈ܐ),
						'one' => q(ܚܕ ܝܘܡܐ),
						'other' => q({0} ܝܘܡܢ̈ܐ),
						'per' => q({0}/ܝܘܡܐ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ܝܘܡܢ̈ܐ),
						'one' => q(ܚܕ ܝܘܡܐ),
						'other' => q({0} ܝܘܡܢ̈ܐ),
						'per' => q({0}/ܝܘܡܐ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ܥܣܝܪܘܬܐ),
						'one' => q(ܥܣܝܪܘܬܐ),
						'other' => q({0} ܥܣܝܪ̈ܘܬܐ),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ܥܣܝܪܘܬܐ),
						'one' => q(ܥܣܝܪܘܬܐ),
						'other' => q({0} ܥܣܝܪ̈ܘܬܐ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ܫ̈ܥܐ),
						'one' => q({0} ܫܥܬܐ),
						'other' => q({0} ܫ̈ܥܐ),
						'per' => q({0}/ܫܥܬܐ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ܫ̈ܥܐ),
						'one' => q({0} ܫܥܬܐ),
						'other' => q({0} ܫ̈ܥܐ),
						'per' => q({0}/ܫܥܬܐ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(ܡܝܟܪܘܖ̈ܦܦܐ),
						'one' => q({0} ܡܝܟܪܘܪܦܦܐ),
						'other' => q({0} ܡܝܟܪܘܖ̈ܦܦܐ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(ܡܝܟܪܘܖ̈ܦܦܐ),
						'one' => q({0} ܡܝܟܪܘܪܦܦܐ),
						'other' => q({0} ܡܝܟܪܘܖ̈ܦܦܐ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ܡܝܠܝܪ̈ܦܦܐ),
						'one' => q({0} ܡܝܠܝܪܦܦܐ),
						'other' => q({0} ܡܝܠܝܪ̈ܦܦܐ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ܡܝܠܝܪ̈ܦܦܐ),
						'one' => q({0} ܡܝܠܝܪܦܦܐ),
						'other' => q({0} ܡܝܠܝܪ̈ܦܦܐ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ܩܛܝܢ̈ܐ),
						'one' => q({0} ܩܛܝܢܐ),
						'other' => q({0} ܩܛܝܢ̈ܐ),
						'per' => q({0}/ܩܛܝܢܐ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ܩܛܝܢ̈ܐ),
						'one' => q({0} ܩܛܝܢܐ),
						'other' => q({0} ܩܛܝܢ̈ܐ),
						'per' => q({0}/ܩܛܝܢܐ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ܝܪ̈ܚܐ),
						'one' => q(ܝܪܚܐ),
						'other' => q({0} ܝܪ̈ܚܐ),
						'per' => q({0}/ܝܪܚܐ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ܝܪ̈ܚܐ),
						'one' => q(ܝܪܚܐ),
						'other' => q({0} ܝܪ̈ܚܐ),
						'per' => q({0}/ܝܪܚܐ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ܢܐܢܘܪ̈ܦܦܐ),
						'one' => q({0} ܢܐܢܘܪܦܦܐ),
						'other' => q({0} ܢܐܢܘܖ̈ܦܦܐ),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ܢܐܢܘܪ̈ܦܦܐ),
						'one' => q({0} ܢܐܢܘܪܦܦܐ),
						'other' => q({0} ܢܐܢܘܖ̈ܦܦܐ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ܪܘܒܥܐ),
						'one' => q(ܪܘܒܥܐ),
						'other' => q({0} ܪ̈ܘܒܥܐ),
						'per' => q({0}/ܪܘܒܥܐ),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ܪܘܒܥܐ),
						'one' => q(ܪܘܒܥܐ),
						'other' => q({0} ܪ̈ܘܒܥܐ),
						'per' => q({0}/ܪܘܒܥܐ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ܪ̈ܦܦܐ),
						'one' => q({0} ܪܦܦܐ),
						'other' => q({0} ܖ̈ܦܦܐ),
						'per' => q({0}/ܪܦܦܐ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ܪ̈ܦܦܐ),
						'one' => q({0} ܪܦܦܐ),
						'other' => q({0} ܖ̈ܦܦܐ),
						'per' => q({0}/ܪܦܦܐ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ܫܒ̈ܘܥܐ),
						'one' => q({0} ܫܒܘܥܐ),
						'other' => q({0} ܫܒ̈ܘܥܐ),
						'per' => q({0}/ܫܒ̈ܘܥܐ),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ܫܒ̈ܘܥܐ),
						'one' => q({0} ܫܒܘܥܐ),
						'other' => q({0} ܫܒ̈ܘܥܐ),
						'per' => q({0}/ܫܒ̈ܘܥܐ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ܫ̈ܢܐ),
						'one' => q(ܫܢܬܐ),
						'other' => q({0} ܫ̈ܢܐ),
						'per' => q({0}/ܫܢܬܐ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ܫ̈ܢܐ),
						'one' => q(ܫܢܬܐ),
						'other' => q({0} ܫ̈ܢܐ),
						'per' => q({0}/ܫܢܬܐ),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ܐܩܠ̈ܐ),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ܐܩܠ̈ܐ),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} ☉R),
						'other' => q({0} ☉R),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} ☉R),
						'other' => q({0} ☉R),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ܗܐ|ܗ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ܠܐ|ܠ|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0} ܘ{1}),
				middle => q({0} ܘ{1}),
				end => q({0} ܘ{1}),
				2 => q({0} ܘ{1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'nan' => q(ܠܝܬ ܡܢܝܢܐ),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0.###;#,##0.###-',
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
		'SYP' => {
			symbol => 'ل.س.‏',
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
							'ܟܢܘܢ ܒ',
							'ܫܒܛ',
							'ܐܕܪ',
							'ܢܝܣܢ',
							'ܐܝܪ',
							'ܚܙܝܪܢ',
							'ܬܡܘܙ',
							'ܐܒ',
							'ܐܝܠܘܠ',
							'ܬܫܪܝܢ ܐ',
							'ܬܫܪܝܢ ܒ',
							'ܟܢܘܢ ܐ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ܟ',
							'ܫ',
							'ܐ',
							'ܢ',
							'ܐ',
							'ܚ',
							'ܬ',
							'ܐ',
							'ܐ',
							'ܬ',
							'ܬ',
							'ܟ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ܟܢܘܢ ܐܚܪܝܐ',
							'ܫܒܛ',
							'ܐܕܪ',
							'ܢܝܣܢ',
							'ܐܝܪ',
							'ܚܙܝܪܢ',
							'ܬܡܘܙ',
							'ܐܒ',
							'ܐܝܠܘܠ',
							'ܬܫܪܝܢ ܩܕܡܝܐ',
							'ܬܫܪܝܢ ܐܚܪܝܐ',
							'ܟܢܘܢ ܩܕܡܝܐ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ܟ',
							'ܫ',
							'ܐ',
							'ܢ',
							'ܐ',
							'ܬ',
							'ܚ',
							'ܐ',
							'ܐ',
							'ܬ',
							'ܬ',
							'ܟ'
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
						mon => 'ܬܪܝܢ',
						tue => 'ܬܠܬ',
						wed => 'ܐܪܒܥ',
						thu => 'ܚܡܫ',
						fri => 'ܥܪܘ',
						sat => 'ܫܒܬܐ',
						sun => 'ܚܕ'
					},
					wide => {
						mon => 'ܬܪܝܢܒܫܒܐ',
						tue => 'ܬܠܬܒܫܒܐ',
						wed => 'ܐܪܒܥܒܫܒܐ',
						thu => 'ܚܡܫܒܫܒܐ',
						fri => 'ܥܪܘܒܬܐ',
						sat => 'ܫܒܬܐ',
						sun => 'ܚܕܒܫܒܐ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'ܬ',
						tue => 'ܬ',
						wed => 'ܐ',
						thu => 'ܚ',
						fri => 'ܥ',
						sat => 'ܫ',
						sun => 'ܚ'
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
					wide => {0 => 'ܪܘܒܥܐ ܩܕܡܝܐ',
						1 => 'ܪܘܒܥܐ ܬܪܝܢܐ',
						2 => 'ܪܘܒܥܐ ܬܠܝܬܝܐ',
						3 => 'ܪܘܒܥܐ ܪܒܝܥܝܐ'
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
					'am' => q{܏ܩܛ‌},
					'pm' => q{܏ܒܛ‌},
				},
				'narrow' => {
					'am' => q{܏ܩ‌},
					'pm' => q{܏ܒ‌},
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
				'0' => '܏ܩܡ‌',
				'1' => '܏ܫܡ‌'
			},
			wide => {
				'0' => 'ܩܕܡ ܡܫܝܚܐ',
				'1' => 'ܫܢܬܐ ܡܪܢܝܬܐ'
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
			'full' => q{EEEE، d ܒMMMM y G},
			'long' => q{d ܒMMMM y G},
			'medium' => q{d ܒMMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE، d ܒMMMM y},
			'long' => q{d ܒMMMM y},
			'medium' => q{d ܒMMM y},
			'short' => q{d-MM-y},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			'full' => q{{1}، {0}},
			'long' => q{{1}، {0}},
			'medium' => q{{1}، {0}},
			'short' => q{{1}، {0}},
		},
		'gregorian' => {
			'full' => q{{1}، {0}},
			'long' => q{{1}، {0}},
			'medium' => q{{1}، {0}},
			'short' => q{{1}، {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E، d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{EEEE، d ܒMMM y G},
			GyMMMd => q{d ܒMMM y G},
			GyMd => q{dd/MM/y G},
			MEd => q{EEEE، dd/MM},
			MMMEd => q{E، d ܒMMM},
			MMMMd => q{d ܒMMMM},
			MMMd => q{d ܒMMM},
			Md => q{dd/MM},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E، d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E، d ܒMMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d ܒMMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E، d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{EEEE، d ܒMMM y G},
			GyMMMd => q{d ܒMMM y G},
			GyMd => q{dd/MM/y G},
			MEd => q{EEEE، dd/MM},
			MMMEd => q{E، d ܒMMM},
			MMMMW => q{ܫܒܘܥܐ W ܒMMMM},
			MMMMd => q{d ܒMMMM},
			MMMd => q{d ܒMMM},
			Md => q{dd/MM},
			yM => q{MM/y},
			yMEd => q{E، d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E، d ܒMMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d ܒMMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{ܫܒܘܥܐ w ܕܫܢܬܐ Y},
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
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM/y GGGG – MM/y GGGG},
				M => q{MM/y – MM/y GGGG},
				y => q{MM/y – MM/y GGGG},
			},
			GyMEd => {
				G => q{E، d/M/y GGGG – E، d/M/y GGGG},
				M => q{E، d/M/y – E، d/M/y GGGG},
				d => q{E، d/M/y – E، d/M/y GGGG},
				y => q{E، d/M/y – E، d/M/y GGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E، d ܒMMM y G – E، d ܒMMM y G},
				M => q{E، d ܒMMM – E، d ܒMMM y G},
				d => q{E، d ܒMMM – E، d ܒMMM y G},
				y => q{E، d ܒMMM y – E، d ܒMMM y G},
			},
			GyMMMd => {
				G => q{d ܒMMM y G – d ܒMMM y G},
				M => q{d ܒMMM – d ܒMMM y G},
				d => q{d–d ܒMMM y G},
				y => q{d ܒMMM y – d ܒMMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGG – d/M/y GGGG},
				M => q{d/M/y – d/M/y GGGG},
				d => q{d/M/y – d/M/y GGGG},
				y => q{d/M/y – d/M/y GGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E، d/M – E، M/d},
				d => q{E، d/M – E، M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E، d ܒMMM – E، d ܒMMM},
				d => q{E، d ܒMMM – E، d ܒMMM},
			},
			MMMd => {
				M => q{d ܒMMM – d ܒMMM},
				d => q{d–d ܒMMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			fallback => '{0} - {1}',
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E، d/M/y – E، d/M/y GGGGG},
				d => q{E، d/M/y – E، d/M/y GGGGG},
				y => q{E، d/M/y – E، d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E، d ܒMMM – E، d ܒMMM y G},
				d => q{E، d ܒMMM – E، d ܒMMM y G},
				y => q{E، d ܒMMM y – E، d ܒMMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d ܒMMM – d ܒMMM y G},
				d => q{d–d ܒMMM y G},
				y => q{d ܒMMM y – d ܒMMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y G – MM/y G},
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			GyMEd => {
				G => q{E، d/M/y G – E، d/M/y G},
				M => q{E، d/M/y – E، d/M/y G},
				d => q{E، d/M/y – E، d/M/y G},
				y => q{E، d/M/y – E، d/M/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E، d ܒMMM y G – E، d ܒMMM y G},
				M => q{E، d ܒMMM – E، d ܒMMM y G},
				d => q{E، d ܒMMM – E، d ܒMMM y G},
				y => q{E، d ܒMMM y – E، d ܒMMM y G},
			},
			GyMMMd => {
				G => q{d ܒMMM y G – d ܒMMM y G},
				M => q{d ܒMMM – dܒMMM y G},
				d => q{d–d ܒMMM y G},
				y => q{d ܒMMM y – d ܒMMM y G},
			},
			GyMd => {
				G => q{d/M/y G – d/M/y G},
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E، d/‏M – E، d/‏M},
				d => q{E، d/‏M –‏ E، d/‏M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E، d ܒMMM – E، d ܒMMM},
				d => q{E، d – E، d ܒMMM},
			},
			MMMd => {
				M => q{d ܒMMM – d ܒMMM},
				d => q{d–d ܒMMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E، d/M/y – E، d/M/y},
				d => q{E، d/M/y – E، d/M/y},
				y => q{E، d/M/y – E، d/M/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E، d ܒMMM – E، d ܒMMM y},
				d => q{E، d ܒMMM – E، d ܒMMM y},
				y => q{E، d ܒMMM y – E، d ܒMMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d ܒMMM – d ܒMMM y},
				d => q{d–d ܒMMM y},
				y => q{d ܒMMM y – d ܒMMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(ܥܕܢܐ {0}),
		regionFormat => q(ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ {0}),
		regionFormat => q(ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ {0}),
		'Acre' => {
			long => {
				'daylight' => q#ܥܕܢܘܬܐ ܩܝܬܝܬܐ ܕܐܝܟܝܪ#,
				'generic' => q#ܥܕܢܘܬܐ ܕܐܝܟܝܪ#,
				'standard' => q#ܥܕܢܘܬܐ ܫܪܫܝܬܐ ܥܕܢܘܬܐ ܫܪܫܝܬܐ ܕܐܝܟܝܪ#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܐܦܓܐܢܣܬܐܢ#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#ܐܒܕܓܢ#,
		},
		'Africa/Accra' => {
			exemplarCity => q#ܐܟܪܐ#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#ܐܕܝܣ ܐܒܒܐ#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#ܓܙܐܐܪ#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#ܐܣܡܐܪܐ#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#ܒܐܡܐܟܘ#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#ܒܐܢܓܐܘܝ#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#ܒܐܢܓܘܠ#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#ܒܝܣܐܘ#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#ܒܠܢܬܝܪ#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#ܒܪܐܙܐܒܝܠ#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#ܒܘܓܘܡܒܘܪܐ#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#ܩܐܗܖ̈ܗ#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#ܟܐܣܐܒܠܢܟܐ#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#ܣܒܬܐ#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#ܟܘܢܐܟܪܝ#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#ܕܐܟܐܪ#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#ܕܐܪ ܫܠܡܐ#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#ܓܝܒܘܬܝ#,
		},
		'Africa/Douala' => {
			exemplarCity => q#ܕܘܐܠܐ#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#ܐܠ ܥܝܘܢ#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#ܦܪܝܬܐܘܢ#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#ܓܒܘܪܘܢ#,
		},
		'Africa/Harare' => {
			exemplarCity => q#ܗܪܐܪܝ#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#ܝܘܗܢܝܣܒܘܪܓ#,
		},
		'Africa/Juba' => {
			exemplarCity => q#ܓܘܒܐ#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#ܟܐܡܦܐܠܐ#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#ܚܪܛܘܡ#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#ܟܝܓܐܠܝ#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#ܟܝܢܫܐܣܐ#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#ܠܐܓܘܣ#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#ܠܝܒܪܝܒܝܠ#,
		},
		'Africa/Lome' => {
			exemplarCity => q#ܠܘܡܝ#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#ܠܘܐܢܕܐ#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#ܠܘܒܘܡܒܫܝ#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#ܠܘܣܐܟܐ#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#ܡܐܠܐܒܘ#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#ܡܐܦܘܬܘ#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#ܡܐܣܝܪܘ#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#ܡܒܐܒܐܢܝ#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#ܡܘܩܕܝܫܘ#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#ܡܘܢܪܘܒܝܐ#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#ܢܝܪܘܒܝ#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#ܢܓܡܝܢܐ#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#ܢܝܐܡܝ#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#ܢܘܐܟܫܘܬ#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#ܐܘܐܓܐܕܐܘܓܐܘ#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#ܦܘܪܬܘ-ܢܘܒܘ#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#ܣܐܘ ܬܘܡܝ#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#ܛܪܝܦܘܠܝܣ#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#ܬܘܢܣ#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#ܘܝܢܕܗܘܟ#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܨܥܝܬܐ ܐܦܪܝܩܐ#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܕܢܚ ܐܦܪܝܩܐ#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܬܝܡܢ ܐܦܪܝܩܐ#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܩܝܬܝܬܐ ܕܡܥܪܒ ܐܦܪܝܩܐ#,
				'generic' => q#ܥܕܢܐ ܕܡܥܪܒ ܐܦܪܝܩܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܡܥܪܒ ܐܦܪܝܩܐ#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܠܐܣܟܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܠܐܣܟܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܠܐܣܟܐ#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܠܡܐܬܝ#,
				'generic' => q#ܥܕܢܐ ܕܐܠܡܐܬܝ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܠܡܐܬܝ#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܡܙܢ#,
				'generic' => q#ܥܕܢܐ ܕܐܡܙܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܡܙܢ#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#ܐܕܐܟ#,
		},
		'America/Anchorage' => {
			exemplarCity => q#ܐܢܟܘܪܓ#,
		},
		'America/Anguilla' => {
			exemplarCity => q#ܐܢܓܘܝܐ#,
		},
		'America/Antigua' => {
			exemplarCity => q#ܐܢܬܝܓܘܐ#,
		},
		'America/Araguaina' => {
			exemplarCity => q#ܐܪܐܓܐܘܝܢܐ#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#ܠܐ ܪܝܘܗܐ#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#ܪܝܘ ܓܝܓܘܣ#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#ܣܠܬܐ#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#ܣܐܢ ܘܐܢ#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#ܣܐܢ ܠܘܝܣ#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#ܬܘܟܘܡܐܢ#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#ܐܘܫܘܐܝܐ#,
		},
		'America/Aruba' => {
			exemplarCity => q#ܐܪܘܒܐ#,
		},
		'America/Asuncion' => {
			exemplarCity => q#ܐܣܘܢܟܣܝܘܢ#,
		},
		'America/Bahia' => {
			exemplarCity => q#ܒܐܗܝܐ#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#ܒܐܗܝܐ ܒܐܢܝܪܣ#,
		},
		'America/Barbados' => {
			exemplarCity => q#ܒܐܪܒܕܘܣ#,
		},
		'America/Belem' => {
			exemplarCity => q#ܒܝܠܝܡ#,
		},
		'America/Belize' => {
			exemplarCity => q#ܒܝܠܝܙ#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#ܒܠܐܢܟ-ܣܐܒܠܘܢ#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#ܒܘܥ ܒܝܣܬܐ#,
		},
		'America/Bogota' => {
			exemplarCity => q#ܒܘܓܘܬܐ#,
		},
		'America/Boise' => {
			exemplarCity => q#ܒܘܝܙܝ#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#ܒܘܐܝܢܘܣ ܥܝܪܣ#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#ܟܡܒܪܓ ܒܐܝ#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#ܟܐܡܦܘ ܓܪܢܕܝ#,
		},
		'America/Cancun' => {
			exemplarCity => q#ܟܐܢܟܘܢ#,
		},
		'America/Caracas' => {
			exemplarCity => q#ܟܐܪܐܟܣ#,
		},
		'America/Catamarca' => {
			exemplarCity => q#ܟܐܬܐܡܪܟܐ#,
		},
		'America/Cayenne' => {
			exemplarCity => q#ܟܐܝܐܢ#,
		},
		'America/Cayman' => {
			exemplarCity => q#ܟܐܝܡܝܢ#,
		},
		'America/Chicago' => {
			exemplarCity => q#ܫܟܓܘ#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#ܟܝܘܐܘܐ#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#ܣܝܘܕܐܕ ܐܘܪܝܙ#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#ܐܬܝܟܘܟܐܢ#,
		},
		'America/Cordoba' => {
			exemplarCity => q#ܟܘܪܕܘܒܐ#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#ܟܘܣܬܐ ܪܝܟܐ#,
		},
		'America/Creston' => {
			exemplarCity => q#ܟܪܝܣܬܘܢ#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#ܟܘܝܐܒܐ#,
		},
		'America/Curacao' => {
			exemplarCity => q#ܟܘܪܐܟܐܘ#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#ܕܐܢܡܪܟܫܒܝܢ#,
		},
		'America/Dawson' => {
			exemplarCity => q#ܕܐܣܘܢ#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#ܕܐܣܘܢ ܟܪܝܟ#,
		},
		'America/Denver' => {
			exemplarCity => q#ܕܢܒܪ#,
		},
		'America/Detroit' => {
			exemplarCity => q#ܕܝܬܪܘܝܬ#,
		},
		'America/Dominica' => {
			exemplarCity => q#ܕܘܡܝܢܝܟܐ#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ܐܕܡܘܢܬܘܢ#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#ܐܝܪܘܢܝܦܝ#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ܐܠ ܣܠܒܐܕܘܪ#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#ܦܘܪܬ ܢܝܠܣܘܢ#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#ܦܘܪܬܐܠܝܙܐ#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#ܓܠܝܣ ܒܐܝ#,
		},
		'America/Godthab' => {
			exemplarCity => q#ܢܘܟ#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#ܓܘܣ ܒܐܝ#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#ܓܪܐܢܕ ܬܘܪܟ#,
		},
		'America/Grenada' => {
			exemplarCity => q#ܓܪܝܢܕܐ#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#ܓܘܐܕܐܠܘܦܝ#,
		},
		'America/Guatemala' => {
			exemplarCity => q#ܓܘܐܬܡܐܠܐ#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#ܓܘܐܝܐܩܘܝܠ#,
		},
		'America/Guyana' => {
			exemplarCity => q#ܓܘܝܐܢܐ#,
		},
		'America/Halifax' => {
			exemplarCity => q#ܗܠܝܦܐܟܣ#,
		},
		'America/Havana' => {
			exemplarCity => q#ܗܐܒܐܢܐ#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#ܗܝܪܡܘܣܝܐ#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#ܢܘܟܣ، ܐܢܕܝܐܢܐ#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#ܡܪܝܢܓܘ، ܐܢܕܝܐܢܐ#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#ܦܝܬܝܪܣܒܝܪܓ، ܐܢܕܝܐܢܐ#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#ܡܢܕܝܬܐ ܕܬܝܠ، ܐܢܕܝܐܢܐ#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#ܒܝܒܐܝ، ܐܢܕܝܐܢܐ#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#ܒܝܢܣܝܢܝܣ، ܐܢܕܝܐܢܐ#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#ܘܝܢܐܡܐܟ، ܐܢܕܝܐܢܐ#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#ܐܢܕܝܐܢܐܦܘܠܝܣ#,
		},
		'America/Inuvik' => {
			exemplarCity => q#ܐܢܘܒܝܟ#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ܐܝܩܠܘܝܬ#,
		},
		'America/Jamaica' => {
			exemplarCity => q#ܓܡܐܝܟܐ#,
		},
		'America/Jujuy' => {
			exemplarCity => q#ܓܘܓܘܝ#,
		},
		'America/Juneau' => {
			exemplarCity => q#ܓܘܢܘ#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#ܡܘܢܬܐܟܝܠܘ، ܟܝܢܬܐܟܝ#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#ܟܪܠܝܢܓܩ#,
		},
		'America/La_Paz' => {
			exemplarCity => q#ܠܐ ܦܐܙ#,
		},
		'America/Lima' => {
			exemplarCity => q#ܠܝܡܐ#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#ܠܘܣ ܐܢܓܠܘܣ#,
		},
		'America/Louisville' => {
			exemplarCity => q#ܠܘܝܣܒܝܠ#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#ܪܘܒ݂ܥܐ ܕܫܠܝܛܐ ܬܚܬܝܐ#,
		},
		'America/Maceio' => {
			exemplarCity => q#ܡܐܣܝܐܘ#,
		},
		'America/Managua' => {
			exemplarCity => q#ܡܐܢܐܓܘܐ#,
		},
		'America/Manaus' => {
			exemplarCity => q#ܡܐܢܐܘܣ#,
		},
		'America/Marigot' => {
			exemplarCity => q#ܡܪܝܓܘܬ#,
		},
		'America/Martinique' => {
			exemplarCity => q#ܡܐܪܬܝܢܝܩ#,
		},
		'America/Matamoros' => {
			exemplarCity => q#ܡܐܬܐܡܘܪܘܣ#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#ܡܙܛܠܐܢ#,
		},
		'America/Mendoza' => {
			exemplarCity => q#ܡܢܕܘܙܐ#,
		},
		'America/Menominee' => {
			exemplarCity => q#ܡܢܘܡܝܢܝ#,
		},
		'America/Merida' => {
			exemplarCity => q#ܡܪܝܕܐ#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#ܡܛܠܟܐܬܠܐ#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#ܡܕܝܢܬܐ ܕܡܟܣܝܟܘ#,
		},
		'America/Miquelon' => {
			exemplarCity => q#ܡܩܘܠܘܢ#,
		},
		'America/Moncton' => {
			exemplarCity => q#ܡܘܢܟܬܘܢ#,
		},
		'America/Monterrey' => {
			exemplarCity => q#ܡܘܢܛܪܐܝ#,
		},
		'America/Montevideo' => {
			exemplarCity => q#ܡܘܢܬܝܒܝܕܝܘ#,
		},
		'America/Montserrat' => {
			exemplarCity => q#ܡܘܢܬܣܝܪܐܬ#,
		},
		'America/Nassau' => {
			exemplarCity => q#ܢܐܣܐܘ#,
		},
		'America/New_York' => {
			exemplarCity => q#ܢܝܘ ܝܘܪܟ#,
		},
		'America/Nome' => {
			exemplarCity => q#ܢܘܡ#,
		},
		'America/Noronha' => {
			exemplarCity => q#ܢܘܪܘܢܗܐ#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#ܒܝܘܠܐ، ܕܐܟܘܬܐ ܓܪܒܝܝܬܐ#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#ܣܝܢܬܪ، ܕܐܟܘܬܐ ܓܪܒܝܝܬܐ#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#ܢܝܘ ܣܐܠܝܡ،‌ ܕܐܟܘܬܐ ܓܪܒܝܝܬܐ#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ܘܓܝܢܐܓܐ#,
		},
		'America/Panama' => {
			exemplarCity => q#ܦܢܡܐ#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#ܦܐܪܐܡܐܪܝܒܘ#,
		},
		'America/Phoenix' => {
			exemplarCity => q#ܦܝܢܝܟܣ#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#ܦܘܪܬ ܐܘ ܦܪܝܢܣ#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#ܦܘܪܬ ܕܐܣܦܢܝܐ#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#ܦܘܪܬܘ ܒܝܠܗܘ#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#ܦܘܪܬܘ ܪܝܟܘ#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#ܦܘܢܬܐ ܥܪܝܢܣ#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#ܪܐܢܟܢ ܐܢܠܝܬ#,
		},
		'America/Recife' => {
			exemplarCity => q#ܪܝܣܝܦܝ#,
		},
		'America/Regina' => {
			exemplarCity => q#ܪܝܓܝܢܐ#,
		},
		'America/Resolute' => {
			exemplarCity => q#ܪܝܣܘܠܘܬ#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#ܪܝܘ ܒܪܢܟܘ#,
		},
		'America/Santarem' => {
			exemplarCity => q#ܣܐܢܬܐܪܡ#,
		},
		'America/Santiago' => {
			exemplarCity => q#ܣܐܢܬܝܐܓܘ#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#ܣܢܬܘ ܕܘܡܝܢܓܘ#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#ܣܐܘ ܦܐܘܠܘ#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#ܐܝܛܘܩܘܪܡܝܬ#,
		},
		'America/Sitka' => {
			exemplarCity => q#ܣܝܛܟܐ#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#ܡܪ ܒܪ ܬܘܠܡܝ#,
		},
		'America/St_Johns' => {
			exemplarCity => q#ܡܪ ܝܘܚܢܢ#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#ܣܐܢܬ ܟܬܣ#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#ܡܪܬܝ ܠܘܫܐ#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#ܡܪ ܬܐܘܡܐ#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#ܡܪ ܒܢܣܢܬ#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#ܢܕܘܪܬܐ#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#ܬܝܓܘܣܝܓܐܠܦܐ#,
		},
		'America/Thule' => {
			exemplarCity => q#ܬܘܠ#,
		},
		'America/Tijuana' => {
			exemplarCity => q#ܬܝܐܘܐܢܐ#,
		},
		'America/Toronto' => {
			exemplarCity => q#ܬܘܪܘܢܬܘ#,
		},
		'America/Tortola' => {
			exemplarCity => q#ܬܘܪܬܘܠܐ#,
		},
		'America/Vancouver' => {
			exemplarCity => q#ܒܢܟܘܒܝܪ#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#ܣܘܣܬܐ ܚܘܪܬܐ#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#ܘܝܢܝܦܓ#,
		},
		'America/Yakutat' => {
			exemplarCity => q#ܝܩܘܬܐܬ#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܡܨܥܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܡܨܥܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܡܨܥܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܡܕܢܚܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܡܕܢܚܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܡܕܢܚܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܛܘܪܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܛܘܪܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܛܘܪܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܫܝܢܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܫܝܢܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܫܝܢܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܢܐܕܝܪ#,
				'generic' => q#ܥܕܢܐ ܕܐܢܐܕܝܪ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܢܐܕܝܪ#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#ܟܐܝܣܝ#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#ܕܒܝܣ#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#ܕܘܡܘܢܬ ܕܐܘܪܒܝܠ#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#ܡܐܟܐܘܪܝ#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#ܡܐܘܣܘܢ#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#ܡܟܡܘܪܕܘ#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#ܦܐܠܡܝܪ#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#ܪܘܬܝܪܐ#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#ܣܝܘܐ#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ܬܪܘܠ#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#ܒܘܣܬܘܟ#,
		},
		'Apia' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܦܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܦܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܦܝܐ#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܟܬܐܘ#,
				'generic' => q#ܥܕܢܐ ܐܟܬܐܘ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܟܬܐܘ#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܟܬܘܒ#,
				'generic' => q#ܥܕܢܐ ܕܐܟܬܘܒ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܟܬܘܒ#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܪܒܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܪܒܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܪܒܝܐ#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#ܠܘܢܓܝܥܪܒܝܝܢ#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܪܓܢܬܝܢܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܪܓܢܬܝܢܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܪܓܢܬܝܢܐ#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܪܓܢܬܝܢܐ ܡܥܪܒܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܪܓܢܬܝܢܐ ܡܥܪܒܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܪܓܢܬܝܢܐ ܡܥܪܒܝܬܐ#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܪܡܢܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܪܡܢܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܪܡܢܝܐ#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#ܥܕܢ#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#ܐܠܡܐܬܝ#,
		},
		'Asia/Amman' => {
			exemplarCity => q#ܥܡܐܢ#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#ܐܢܐܕܝܪ#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#ܐܟܬܐܘ#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#ܐܟܬܘܒ#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#ܥܫܩܐܒܐܕ#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#ܐܬܝܪܘ#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#ܒܓܕܕ#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#ܒܚܪܝܢ#,
		},
		'Asia/Baku' => {
			exemplarCity => q#ܒܐܟܘ#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#ܒܐܢܟܘܟ#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#ܒܐܪܢܐܘܠ#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#ܒܝܪܘܬ#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#ܒܝܫܟܝܟ#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#ܒܪܘܢܐܝ#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#ܟܘܠܟܬܐ#,
		},
		'Asia/Chita' => {
			exemplarCity => q#ܬܫܝܬܐ#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#ܟܘܠܘܡܒܘ#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#ܕܪܡܣܘܩ#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ܕܟܐ#,
		},
		'Asia/Dili' => {
			exemplarCity => q#ܕܝܠܝ#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#ܕܘܒܐܝ#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#ܕܘܫܐܢܒܝ#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#ܦܐܡܐܓܘܣܬܐ#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#ܥܙܐ#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#ܚܒܪܘܢ#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#ܗܘܢܓ ܟܘܢܓ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#ܗܘܒܕ#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#ܐܝܪܟܘܬܣܟ#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#ܓܐܟܐܪܬܐ#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#ܓܐܝܦܘܪܐ#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#ܐܘܪܫܠܡ#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#ܟܐܒܘܠ#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#ܟܐܡܬܫܐܬܟܐ#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#ܟܪܐܟܝ#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#ܟܐܬܡܐܢܕܘ#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#ܚܐܢܕܝܓܐ#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#ܟܪܐܣܢܘܝܪܣܟ#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#ܟܘܐܠܐ ܠܘܡܦܘܪ#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#ܟܘܫܝܢܓ#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#ܟܘܝܬ#,
		},
		'Asia/Macau' => {
			exemplarCity => q#ܡܐܟܐܘ#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#ܡܐܓܐܕܐܢ#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#ܡܐܟܐܣܐܪ#,
		},
		'Asia/Manila' => {
			exemplarCity => q#ܡܐܢܝܠܐ#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#ܡܣܩܛ#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#ܢܝܩܘܣܝܐ#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#ܢܘܒܘܟܘܙܢܝܬܣܟ#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#ܢܘܒܘܣܝܒܪܣܟ#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#ܐܘܡܣܟ#,
		},
		'Asia/Oral' => {
			exemplarCity => q#ܐܘܪܐܠ#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#ܦܢܘܡ ܦܢ#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#ܦܘܢܬܝܐܢܐܟ#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#ܦܝܘܢܓܝܢܓ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#ܩܛܪ#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#ܟܘܣܬܐܢܐܝ#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#ܟܝܙܝܠܘܪܕܐ#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#ܝܢܓܘܢ#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#ܪܝܐܕ#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#ܡܕܝܢܬܐ ܕܗܘ ܟܝ ܡܝܢ#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#ܣܐܚܐܠܝܢ#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#ܣܡܪܟܢܕ#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#ܣܐܘܠ#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#ܫܢܓܗܐܝܝ#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#ܣܝܢܓܐܦܘܪ#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#ܣܪܝܕܢܝܟܘܠܝܡܣܟ#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#ܬܐܝܦܐܝ#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#ܬܫܟܝܢܬ#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#ܬܦܠܝܣ#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#ܬܗܪܢ#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#ܬܝܡܦܘ#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#ܛܘܟܝܘ#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#ܬܘܡܣܟ#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#ܐܘܠܐܢܒܐܬܘܪ#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#ܐܘܪܘܡܟܝ#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#ܐܘܣܬ-ܢܝܪܐ#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#ܒܝܐܢܬܝܐܢ#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#ܒܠܐܕܝܒܘܣܬܘܟ#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#ܝܐܟܘܬܣܟ#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#ܝܟܐܬܝܪܢܒܝܪܓ#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#ܝܪܒܐܢ#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܐܛܠܢܛܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܐܛܠܢܛܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܐܛܠܢܛܝܬܐ ܕܐܡܪܝܟܐ ܓܪܒܝܝܬܐ#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#ܓܙܪܬܐ ܕܐܙܘܪ#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#ܒܝܪܡܝܘܕܐ#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#ܟܐܢܪܝ#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#ܟܐܦ ܒܝܪܕܝ#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#ܦܐܪܘ#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#ܡܕܐܝܪܐ#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#ܪܐܝܟܒܝܟ#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#ܬܡܝܢ ܓܘܪܓܝܐ#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#ܡܪܬܝ ܗܝܠܝܢܐ#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#ܣܬܐܢܠܝ#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#ܐܕܝܠܝܕ#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#ܒܪܝܣܒܐܢ#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#ܒܪܘܟܝܢ ܗܝܠ#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#ܕܪܘܝܢ#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#ܐܘܟܠܐ#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#ܗܘܒܪܬ#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#ܠܝܢܕܡܐܢ#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#ܠܘܪܕ ܗܐܘ#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#ܡܝܠܒܘܪܢ#,
		},
		'Australia/Perth' => {
			exemplarCity => q#ܦܝܪܬ#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#ܣܝܕܢܝ#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܣܬܪܠܝܐ ܡܨܥܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܣܬܪܠܝܐ ܡܨܥܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܣܬܪܠܝܐ ܡܨܥܝܬܐ#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܡܥܪܒܝܬܐ ܡܨܥܝܬܐ ܕܐܘܣܬܪܠܝܐ#,
				'generic' => q#ܥܕܢܐ ܡܥܪܒܝܬܐ ܡܨܥܝܬܐ ܕܐܘܣܬܪܠܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܡܥܪܒܝܬܐ ܡܨܥܝܬܐ ܕܐܘܣܬܪܠܝܐ#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܣܬܪܠܝܐ ܡܕܢܚܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܣܬܪܠܝܐ ܡܕܢܚܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܣܬܪܠܝܐ ܡܕܢܚܝܬܐ#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܣܬܪܠܝܐ ܡܥܪܒܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܣܬܪܠܝܐ ܡܥܪܒܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܣܬܪܠܝܐ ܡܥܪܒܝܬܐ#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܙܪܒܝܓܐܢ#,
				'generic' => q#ܥܕܢܐ ܕܐܙܪܒܝܓܐܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܙܪܒܝܓܐܢ#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܙܘܪ#,
				'generic' => q#ܥܕܢܐ ܕܐܙܘܪ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܙܘܪ#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܒܢܓܠܐܕܝܫ#,
				'generic' => q#ܥܕܢܐ ܕܒܢܓܠܐܕܝܫ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܒܢܓܠܐܕܝܫ#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܒܘܬܐܢ#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܒܘܠܝܒܝܐ#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܒܪܐܣܝܠܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܒܪܐܣܝܠܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܒܪܐܣܝܠܝܐ#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܒܪܘܢܐܝ ܕܐܪܘܣܐܠܡ#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܟܐܦ ܒܝܪܕܝ#,
				'generic' => q#ܥܕܢܐ ܕܟܐܦ ܒܝܪܕܝ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܟܐܦ ܒܝܪܕܝ#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܟܐܝܣܝ#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܬܫܐܡܘܪܘ#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܬܫܐܬܡ#,
				'generic' => q#ܥܕܢܐ ܕܬܫܐܬܡ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܬܫܐܬܡ#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܬܫܝܠܝ#,
				'generic' => q#ܥܕܢܐ ܕܬܫܝܠܝ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܬܫܝܠܝ#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܨܝܢ#,
				'generic' => q#ܥܕܢܐ ܕܨܝܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܨܝܢ#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܪܬܐ ܕܟܪܝܣܬܡܣ#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܝܖ̈ܐ ܕܟܘܟܘܣ#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܟܘܠܘܡܒܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܟܘܠܘܡܒܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܟܘܠܘܡܒܝܐ#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܓܙܝܪ̈ܐ ܕܟܘܟ#,
				'generic' => q#ܥܕܢܐ ܓܙܝܪ̈ܐ ܕܟܘܟ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܓܙܝܪ̈ܐ ܕܟܘܟ#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܟܘܒܐ#,
				'generic' => q#ܥܕܢܐ ܕܟܘܒܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܟܘܒܐ#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܕܒܝܣ#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܕܘܡܘܢܬ ܕܐܘܪܒܝܠ#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܕܢܚ ܬܝܡܘܪ#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܓܙܪܬܐ ܦܨܚܐ#,
				'generic' => q#ܥܕܢܐ ܕܓܙܪܬܐ ܦܨܚܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܓܙܪܬܐ ܦܨܚܐ#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܐܩܘܐܕܘܪ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ܥܕܢܘܬܐ ܬܒܠܝܬܐ ܡܛܟܘܣܬܐ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ܡܕܝܢܬܐ ܠܐ ܝܕܥܝܬܐ#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#ܐܡܣܬܪܕܡ#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#ܐܢܕܘܪܐ#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#ܐܣܬܪܐܚܢ#,
		},
		'Europe/Athens' => {
			exemplarCity => q#ܐܬܢܘܣ#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#ܒܠܓܪܕ#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#ܒܪܠܝܢ#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#ܒܪܬܝܣܠܒܐ‏#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#ܒܪܘܟܣܠ#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#ܒܘܩܘܪܫܛ#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#ܒܘܕܦܫܛ#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#ܒܘܣܝܢܓܢ#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#ܟܝܣܝܢܐܘ#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#ܟܘܦܢܗܐܓܢ#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#ܕܒܠܢ#,
			long => {
				'daylight' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܝܪܠܢܕ#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#ܓܒܪܠܛܪ#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#ܓܘܪܢܙܝ#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#ܗܠܣܢܟܝ#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#ܓܙܪܬܐ ܕܡܐܢ#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#ܐܣܛܢܒܘܠ#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#ܓܝܪܙܝ#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#ܟܐܠܝܢܝܢܓܪܐܕ#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#ܟܝܝܒ#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#ܟܝܪܘܒ#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#ܠܫܒܘܢܐ#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#ܠܝܘܒܠܝܐܢܐ#,
		},
		'Europe/London' => {
			exemplarCity => q#ܠܘܢܕܘܢ#,
			long => {
				'daylight' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܒܪܝܛܢܝܐ#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#ܠܘܟܣܡܒܘܪܓ#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#ܡܕܪܝܕ#,
		},
		'Europe/Malta' => {
			exemplarCity => q#ܡܝܠܛܐ#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#ܡܐܪܝܗܐܡ#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#ܡܝܢܣܟ#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#ܡܘܢܐܟܘ#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#ܡܘܣܟܘ#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#ܐܘܣܠܘ#,
		},
		'Europe/Paris' => {
			exemplarCity => q#ܦܐܪܝܣ#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#ܦܘܕܓܘܪܝܟܐ#,
		},
		'Europe/Prague' => {
			exemplarCity => q#ܦܪܐܓ#,
		},
		'Europe/Riga' => {
			exemplarCity => q#ܪܝܓܐ#,
		},
		'Europe/Rome' => {
			exemplarCity => q#ܪܘܡܝ#,
		},
		'Europe/Samara' => {
			exemplarCity => q#ܣܡܐܪܐ#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#ܣܢ ܡܪܝܢܘ#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#ܣܪܐܝܝܒܘ#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#ܣܪܐܬܘܒ#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#ܣܡܦܪܘܦܠ#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#ܣܩܘܦܝܐ#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#ܣܘܦܝܐ#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#ܣܬܘܟܗܘܠܡ#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#ܬܐܠܝܢ#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#ܬܝܪܐܢ#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#ܐܘܠܝܢܘܒܣܟ#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#ܒܕܘܙ#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#ܘܐܬܝܩܐܢ#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#ܒܝܝܢܐ#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#ܒܠܢܘܣ#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#ܒܘܠܓܘܓܪܐܕ#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#ܘܐܪܣܘ#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#ܙܐܓܪܒ#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#ܙܝܘܪܚ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܪܘܦܐ ܡܨܥܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܪܘܦܐ ܡܨܥܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܪܘܦܐ ܡܨܥܝܬܐ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܪܘܦܐ ܡܕܢܚܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܪܘܦܐ ܡܕܢܚܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܪܘܦܐ ܡܕܢܚܝܬܐ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܐܘܪܘܦܐ (ܗܡ ܡܕܢܚܐ)#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܪܘܦܐ ܡܥܪܒܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܪܘܦܐ ܡܥܪܒܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܪܘܦܐ ܡܥܪܒܝܬܐ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܓܙܝܪ̈ܐ ܕܦܠܟܠܢܕ#,
				'generic' => q#ܥܕܢܐ ܕܓܙܝܪ̈ܐ ܕܦܠܟܠܢܕ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܓܙܝܪ̈ܐ ܕܦܠܟܠܢܕ#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܦܝܓܝ#,
				'generic' => q#ܥܕܢܐ ܕܦܝܓܝ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܦܝܓܝ#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܘܝܐܢܐ ܦܪܢܣܝܬܐ#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܦܪܢܣܐ ܬܝܡܢܝܬܐ ܘܐܢܬܪܬܝܟܐ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܪܝܢܟ#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܐܠܦܐܓܘܣ#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܡܒܝܪ#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܓܘܪܓܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܓܘܪܓܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܓܘܪܓܝܐ#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܝܪ̈ܐ ܕܓܝܠܒܪܬ#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܓܪܝܢܠܢܕ ܡܕܢܚܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܓܪܝܢܠܢܕ ܡܕܢܚܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܓܪܝܢܠܢܕ ܡܕܢܚܝܬܐ#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܓܪܝܢܠܢܕ ܕܡܥܪܒܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܓܪܝܢܠܢܕ ܕܡܥܪܒܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܓܪܝܢܠܢܕ ܕܡܥܪܒܝܬܐ#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܓܘܐܡ#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܡܥܠܢܐ#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܘܝܐܢܐ#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܗܐܘܐܝܝ ܐܠܘܫܝܢ#,
				'generic' => q#ܥܕܢܐ ܕܗܐܘܐܝܝ ܐܠܘܫܝܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܗܐܘܐܝܝ ܐܠܘܫܝܢ#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܗܘܢܓ ܟܘܢܓ#,
				'generic' => q#ܥܕܢܐ ܕܗܘܢܓ ܟܘܢܓ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܗܘܢܓ ܟܘܢܓ#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܗܘܒܕ#,
				'generic' => q#ܕܗܘܒܕ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܗܘܒܕ#,
			},
		},
		'India' => {
			long => {
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܗܢܕܘ#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#ܐܢܬܐܢܐܢܪܝܒܘ#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#ܬܫܓܘܣ#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#ܟܪܝܣܬܡܣ#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#ܟܘܟܘܣ#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#ܟܘܡܘܪܘ#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#ܟܝܪܓܘܠܝܢ#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#ܡܐܗܝ#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#ܓܙܪܬܐ ܡܐܠܕܝܒܝܬܐ#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#ܡܘܪܝܫܘܣ#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#ܡܐܝܘܬ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#ܪܝܘܢܝܘܢ#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܐܘܩܝܢܘܣ ܗܢܕܘܝܐ#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܗܢܕܘܨܝܢ#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܗܢܕܘܨܝܢ ܡܨܥܝܬܐ#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܗܢܕܘܨܝܢ ܡܕܢܚܝܬܐ#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܗܢܕܘܨܝܢ ܡܥܪܒܝܬܐ#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܝܪܐܢ#,
				'generic' => q#ܥܕܢܐ ܕܐܝܪܐܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܝܪܐܢ#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܝܪܟܘܬܣܟ#,
				'generic' => q#ܥܕܢܐ ܕܐܝܪܟܘܬܣܟ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܝܪܟܘܬܣܟ#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܝܣܪܐܝܠ#,
				'generic' => q#ܥܕܢܐ ܕܐܝܣܪܐܝܠ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܝܣܪܐܝܠ#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܝܦܢ#,
				'generic' => q#ܥܕܢܐ ܕܝܦܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܝܦܢ#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܦܝܬܪܘܦܒܠܒܣܟܝ-ܟܐܡܟܬܣܟܝ#,
				'generic' => q#ܥܕܢܐ ܕܦܝܬܪܘܦܒܠܒܣܟܝ-ܟܐܡܟܬܣܟܝ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܦܝܬܪܘܦܒܠܒܣܟܝ-ܟܐܡܟܬܣܟܝ#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܕܢܚ ܟܙܩܣܬܐܢ#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܥܪܒ ܟܙܩܣܬܐܢ#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܟܘܪܝܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܟܘܪܝܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܟܘܪܝܝܐ#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#ܥܕܢܐ ܟܘܣܪܐܝ#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܟܪܐܣܢܘܝܪܣܟ#,
				'generic' => q#ܥܕܢܐ ܕܟܪܐܣܢܘܝܪܣܟ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܟܪܐܣܢܘܝܪܣܟ#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܩܝܪܓܝܙܣܬܐܢ#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܠܐܢܟܐ#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܝܪ̈ܐ ܕܠܐܝܢ#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܠܘܪܕ ܗܐܘ#,
				'generic' => q#ܥܕܢܐ ܕܠܘܪܕ ܗܐܘ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܠܘܪܕ ܗܐܘ#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܡܐܟܐܘ#,
				'generic' => q#ܥܕܢܐ ܕܡܐܟܐܘ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܡܐܟܐܘ#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܡܐܓܕܐܢ#,
				'generic' => q#ܥܕܢܐ ܕܡܐܓܐܕܐܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܡܐܓܕܐܢ#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܠܝܙܝܐ#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܪܬܐ ܡܐܠܕܝܒܝܬܐ#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܐܪܟܐܘܣܐܣ#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܝܪ̈ܐ ܕܡܐܪܫܐܠ#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܡܘܪܝܛܝܘܣ#,
				'generic' => q#ܥܕܢܐ ܕܡܘܪܝܛܝܘܣ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܡܘܪܝܛܝܘܣ#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܐܘܣܘܢ#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܡܟܣܝܩܘ ܫܝܢܝܬܐ#,
				'generic' => q#ܥܕܢܐ ܕܡܟܣܝܩܘ ܫܝܢܝܬܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܡܟܣܝܩܘ ܫܝܢܝܬܐ#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܠܐܢܒܐܬܘܪ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܠܐܢܒܐܬܘܪ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܠܐܢܒܐܬܘܪ#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܡܘܣܟܘ#,
				'generic' => q#ܥܕܢܐ ܕܡܘܣܟܘ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܡܘܣܟܘ#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܡܝܐܢܡܐܪ#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܢܐܘܪܘ#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܢܝܦܐܠ#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܢܝܘ ܟܠܝܕܘܢܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܢܝܘ ܟܠܝܕܘܢܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܢܝܘ ܟܠܝܕܘܢܝܐ#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܢܝܘ ܙܝܠܢܕ#,
				'generic' => q#ܥܕܢܐ ܕܢܝܘ ܙܝܠܢܕ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܢܝܘ ܙܝܠܢܕ#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܢܝܘܦܐܘܢܠܢܕ#,
				'generic' => q#ܥܕܢܐ ܕܢܝܘܦܐܘܢܠܢܕ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܢܝܘܦܐܘܢܠܢܕ#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܢܝܘܝ#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܓܙܪܬܐ ܕܢܘܪܦܠܟ#,
				'generic' => q#ܥܕܢܐ ܕܓܙܪܬܐ ܕܢܘܪܦܠܟ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܓܙܪܬܐ ܕܢܘܪܦܠܟ#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܦܪܢܢܕܘ ܕܢܘܪܘܢܗܐ#,
				'generic' => q#ܥܕܢܐ ܕܦܪܢܢܕܘ ܕܢܘܪܘܢܗܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܦܪܢܢܕܘ ܕܢܘܪܘܢܗܐ#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܝܖ̈ܐ ܕܡܪܝܐܢܐ ܓܪܒܝܝܬܐ#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܢܘܒܘܣܝܒܪܣܟ#,
				'generic' => q#ܥܕܢܐ ܕܢܘܒܘܣܝܒܪܣܟ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܢܘܒܘܣܝܒܪܣܟ#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܘܡܣܟ#,
				'generic' => q#ܥܕܢܐ ܕܘܡܣܟ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܘܡܣܟ#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#ܐܦܝܐ#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#ܐܟܠܐܢܕ#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#ܒܘܓܐܝܢܒܝܠ#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#ܬܫܐܬܡ#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#ܦܨܚܐ#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#ܝܦܐܬ#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#ܦܐܟܐܘܦܘ#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#ܦܝܓܝ#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#ܦܘܢܐܦܘܬܝ#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#ܓܐܠܐܦܓܘܣ#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#ܓܡܒܝܪ#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#ܓܘܐܕܐܠܟܐܢܐܠ#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#ܓܘܐܡ#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#ܟܐܢܬܘܢ#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#ܟܝܪܝܡܐܬܝ#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#ܟܘܣܪܐܝ#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#ܟܘܐܓܐܠܝܢ#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#ܡܐܓܘܪܘ#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#ܡܐܪܟܐܘܣܐܣ#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#ܡܝܕܘܐܝ#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#ܢܐܘܪܘ#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#ܢܝܘܝ#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#ܢܘܪܦܠܟ#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#ܢܘܡܝܐ#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#ܦܐܓܘ ܦܐܓܘ#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#ܦܠܐܘ#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#ܦܝܬܟܐܝܪܢ#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#ܦܘܗܢܦܐܝ#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#ܦܘܪܬ ܡܘܪܝܣܒܐܝ#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#ܪܐܪܘܬܘܢܓܐ#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#ܣܐܝܦܐܢ#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#ܬܐܗܝܬܝ#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#ܬܐܪܐܘܐ#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#ܬܘܢܓܐܬܐܦܘ#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#ܬܫܘܟ#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#ܘܐܝܟ#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#ܘܝܠܝܣ#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܦܐܟܣܬܐܢ#,
				'generic' => q#ܥܕܢܐ ܕܦܐܟܣܬܐܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܦܐܟܣܬܐܢ#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܦܠܐܘ#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܦܐܦܘܐ ܓܝܢܝܐ ܚܕܬܐ#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܦܪܓܘܐܝ#,
				'generic' => q#ܥܕܢܐ ܕܦܪܓܘܐܝ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܦܪܓܘܐܝ#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܦܝܪܘ#,
				'generic' => q#ܥܕܢܐ ܕܦܝܪܘ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܦܝܪܘ#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܦܝܠܝܦܝܢܝܐ#,
				'generic' => q#ܥܕܢܐ ܕܦܝܠܝܦܝܢܝܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܦܝܠܝܦܝܢܝܐ#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܝܪ̈ܐ ܕܦܝܢܝܟܣ#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܣܐܢܬ ܦܝܥܪ ܘܡܩܘܠܘܢ#,
				'generic' => q#ܥܕܢܐ ܕܣܐܢܬ ܦܝܥܪ ܘܡܩܘܠܘܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܣܐܢܬ ܦܝܥܪ ܘܡܩܘܠܘܢ#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܦܝܬܟܐܝܪܢ#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܦܘܢܐܦܝ#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܦܝܘܢܓܝܢܓ#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܟܝܙܝܠܘܪܕܐ#,
				'generic' => q#ܥܕܢܐ ܕܟܝܙܝܠܘܪܕܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܟܝܙܝܠܘܪܕܐ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܪܝܘܢܝܘܢ#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܪܘܬܝܪܐ#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܣܐܚܐܠܝܢ#,
				'generic' => q#ܥܕܢܐ ܕܣܐܚܐܠܝܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܣܐܚܐܠܝܢ#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܣܡܐܪܐ#,
				'generic' => q#ܥܕܢܐ ܕܣܡܐܪܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܣܡܐܪܐ#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܣܡܘܐ#,
				'generic' => q#ܥܕܢܐ ܕܣܡܘܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܣܡܘܐ#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܣܐܝܫܝܠ#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܣܝܢܓܐܦܘܪ#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܝܪ̈ܐ ܕܫܠܝܡܘܢ#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܝܘܪܓܝܐ ܬܝܡܢܝܬܐ#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܣܘܪܝܢܐܡ#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܣܝܘܐ#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܬܗܝܬܝ#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܬܐܝܦܐܝ#,
				'generic' => q#ܥܕܢܐ ܕܬܐܝܦܐܝ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܬܐܝܦܐܝ#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܬܐܓܝܟܣܬܐܢ#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܬܘܟܝܠܐܘ#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܬܘܢܓܐ#,
				'generic' => q#ܥܕܢܐ ܬܘܢܓܐ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܬܘܢܓܐ#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܬܫܘܟ#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܬܘܪܟܡܢܣܬܐܢ#,
				'generic' => q#ܥܕܢܐ ܕܬܘܪܟܡܢܣܬܐܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܬܘܪܟܡܢܣܬܐܢ#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܬܘܒܐܠܘ#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܪܘܓܘܐܝ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܪܘܓܘܐܝ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܪܘܓܘܐܝ#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܐܘܙܒܟܣܬܐܢ#,
				'generic' => q#ܥܕܢܐ ܕܐܘܙܒܟܣܬܐܢ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܐܘܙܒܟܣܬܐܢ#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܒܐܢܘܐܛܘ#,
				'generic' => q#ܥܕܢܐ ܕܒܐܢܘܐܛܘ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܒܐܢܘܐܛܘ#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܒܢܙܘܝܠܐ#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܒܠܐܕܝܒܘܣܬܘܟ#,
				'generic' => q#ܥܕܢܐ ܕܒܠܐܕܝܒܘܣܬܘܟ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܒܠܐܕܝܒܘܣܬܘܟ#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܒܘܠܓܘܓܪܐܕ#,
				'generic' => q#ܥܕܢܐ ܕܒܘܠܓܘܓܪܐܕ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܒܘܠܓܘܓܪܐܕ#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܒܘܣܬܘܟ#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܓܙܝܪ̈ܐ ܕܘܐܝܟ#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܘܝܠܝܣ ܘܦܘܬܘܢܐ#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܝܐܟܘܬܣܟ#,
				'generic' => q#ܥܕܢܐ ܕܝܐܟܘܬܣܟ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܝܐܟܘܬܣܟ#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#ܥܕܢܐ ܕܒܗܪ ܝܘܡܐ ܕܝܟܐܬܝܪܢܒܝܪܓ#,
				'generic' => q#ܥܕܢܐ ܕܝܟܐܬܝܪܢܒܝܪܓ#,
				'standard' => q#ܥܕܢܐ ܡܫܘܚܬܢܝܬܐ ܕܝܟܐܬܝܪܢܒܝܪܓ#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#ܥܕܢܐ ܕܝܘܩܘܢ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
