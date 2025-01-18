=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kxv::Orya - Package for language Kuvi

=cut

package Locale::CLDR::Locales::Kxv::Orya;
# This file auto generated from Data\common\main\kxv_Orya.xml
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
				'af' => 'ଆପ୍ରୀକାନ୍‍ସ',
 				'am' => 'ଆମ୍‍ହେରି',
 				'ar' => 'ଆରବିକ',
 				'ar_001' => 'ପୁନି ଜୁଗ ମାନାଙ୍କ ଆରବିକ୍',
 				'as' => 'ଆସାମିଜ୍',
 				'az' => 'ଆଜେରବେଇଜାନି',
 				'az@alt=short' => 'ଅଜେରି',
 				'be' => 'ବେଲାରୁଷିଆନ୍',
 				'bg' => 'ବୁଲଗାରିଆନ୍',
 				'bn' => 'ବଙ୍ଗାଲି',
 				'bo' => 'ତିବତି',
 				'brx' => 'ବଡ',
 				'bs' => 'ବସନିଆନ୍',
 				'ca' => 'କାଟଲାନ୍',
 				'chr' => 'ଚେରକୀ',
 				'cs' => 'ଚେକ୍',
 				'da' => 'ଡେନିସ୍',
 				'de' => 'ଜର୍ମାନ୍',
 				'de_AT' => 'ଅଷ୍ଟ୍ରିଆ ତି ଜର୍ମାନ',
 				'de_CH' => 'ସ୍ୱିସ୍‌ ହାଇ ତି ଜର୍ମାନ',
 				'doi' => 'ଡଗ୍ରୀ',
 				'el' => 'ଗ୍ରୀକ୍',
 				'en' => 'ଇଂରାଜୀ',
 				'en_AU' => 'ଅଷ୍ଟ୍ରେଲିୟାତି ଇଂରାଜୀ',
 				'en_CA' => 'କାନାଡିୟାତି ଇଂରାଜୀ',
 				'en_GB' => 'ବ୍ରିଟିଶ୍‌ତି ଇଂରାଜୀ',
 				'en_GB@alt=short' => 'ଯୁକ୍ତରାଜ୍ୟତି ଇଂରାଜୀ',
 				'en_US' => 'ଆମେରିକାତି ଇଂରାଜୀ',
 				'en_US@alt=short' => 'ଯୁକ୍ତରାଷ୍ଟ୍ରତି ଇଂରାଜୀ',
 				'es' => 'ସ୍ପାନିସ୍',
 				'es_419' => 'ଲାଟିନ୍‌ ଆମେରିକା ତି ସ୍ପେନିସ୍',
 				'es_ES' => 'ୟୁରପୀୟାତି ସ୍ପେନିସ୍‌',
 				'es_MX' => 'ମେକ୍ସିକତି ସ୍ପେନିସ୍‌',
 				'et' => 'ଏସ୍ଟନିଆ',
 				'eu' => 'ବାସ୍କ',
 				'fa' => 'ପର୍ସିୟାନ୍',
 				'fa_AF' => 'ଡରି',
 				'fi' => 'ପିନିସ୍',
 				'fil' => 'ପିଲିପିନ',
 				'fr' => 'ପ୍ରେଞ୍ଚ‍',
 				'fr_CA' => 'କାନାଡାତି ପ୍ରେଞ୍ଚ‍',
 				'fr_CH' => 'ସ୍ୱିସ୍ ପ୍ରେଞ୍ଚ‍',
 				'gl' => 'ଗଲସିଆତି',
 				'gu' => 'ଗୁଜୁରାଟି',
 				'he' => 'ହିବ୍ରୁ',
 				'hi' => 'ହିନ୍ଦି',
 				'hr' => 'କ୍ରଏସିଆତି',
 				'hu' => 'ହଙ୍ଗେରୀୟାତି',
 				'hy' => 'ଆର୍ମେନିଆତି',
 				'id' => 'ଇଣ୍ଡନେସୀୟା ତି',
 				'is' => 'ଆଇସଲାଣ୍ଡିକ୍',
 				'it' => 'ଇଟାଲି ତି',
 				'ja' => 'ଜାପାନିଜ୍',
 				'ka' => 'ଜର୍ଜିୟାତି',
 				'kk' => 'କାଜାକ୍',
 				'km' => 'କାମେର୍',
 				'kn' => 'କାନ୍ନାଡ଼ା',
 				'ko' => 'କରିଆନ୍ ତି',
 				'kok' => 'କଂଙ୍କଣି',
 				'ks' => 'କାସ୍ମିର',
 				'kxv' => 'କୁୱି',
 				'ky' => 'କୀରଗୀଜ୍',
 				'lo' => 'ଲାଅ',
 				'lt' => 'ଲିଥୁଆନିଆତି',
 				'lv' => 'ଲାଟବିଆତି',
 				'mai' => 'ମଇତିଲୀ',
 				'mk' => 'ମାସେଡୋନିଆ ତି',
 				'ml' => 'ମାଲାୟଲମ୍',
 				'mn' => 'ମଙ୍ଗଲିୟ ତି',
 				'mni' => 'ମଣିପୁରୀ',
 				'mr' => 'ମରାଟୀ',
 				'ms' => 'ମଲୟ',
 				'my' => 'ବର୍ମୀଜ୍',
 				'nb' => 'ନରୱେଜିଆନ୍ ବୋକମଲ୍',
 				'ne' => 'ନେପାଳୀ',
 				'nl' => 'ଡଚ୍',
 				'nl_BE' => 'ପେ୍ଲମିସ୍',
 				'or' => 'ଅଡ଼ିଆ',
 				'pa' => 'ପଞ୍ଜାବୀ',
 				'pl' => 'ପଲିସ୍',
 				'pt' => 'ପର୍ତୁଗୀଜ୍‌',
 				'pt_BR' => 'ବ୍ରାଜିଲିଆନ୍ ପର୍ତୁଗୀଜ୍',
 				'pt_PT' => 'ୟୁରପ୍ ତି ପର୍ତୁଗୀଜ୍',
 				'ro' => 'ରମାନିଆ ତି',
 				'ro_MD' => 'ମଲଡୋଭିଆନ୍ ତି',
 				'ru' => 'ରୁଷିଆ ତି',
 				'sa' => 'ସଂସ୍କୃତ',
 				'sat' => 'ସାନ୍ତାଲି',
 				'sd' => 'ସିନ୍ଦୀ',
 				'si' => 'ସିଂହଲା',
 				'sk' => 'ସ୍ଲବାକ୍',
 				'sl' => 'ସ୍ଲବେନିଆ ତି',
 				'sq' => 'ଆଲବାନିଆନ୍ ତି',
 				'sr' => 'ସର୍ବିୟ ତି',
 				'sv' => 'ସ୍ୱିଡିସ୍',
 				'sw' => 'ସ୍ୱାହିଲି',
 				'sw_CD' => 'କଙ୍ଗ ସ୍ୱାହିଲି',
 				'ta' => 'ତାମିଲ୍',
 				'te' => 'ତେଲୁଗୁ',
 				'th' => 'ତାଇ',
 				'tr' => 'ତୁର୍କିସ୍',
 				'uk' => 'ୟୁକ୍ରାନିଆତି',
 				'ur' => 'ଉର୍ଦୁ',
 				'uz' => 'ଉଜବେକ୍',
 				'vi' => 'ୱିଏତନାମ ତି',
 				'zh' => 'ଚାଇନା ତି',
 				'zh@alt=menu' => 'ଚାଇନା ତି, ମାଣ୍ଡାରିନ୍',
 				'zh_Hans' => 'ସହଜ ଚୀନ',
 				'zh_Hans@alt=long' => 'ସହଜ ମାଣ୍ଡାରିନ୍ ଚାଇନିଜ୍',
 				'zh_Hant' => 'ହିରୁଦଲୁ ଚାଇନିଜ୍‌',
 				'zh_Hant@alt=long' => 'ହିରୁଦଲୁ ମାଣ୍ଡାରିନ୍ ଚାଇନିଜ୍',
 				'zu' => 'ଜୁଲୁ',

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
			'Arab' => 'ଆରବିକ୍',
 			'Beng' => 'ବଙ୍ଗାଲୀ',
 			'Brah' => 'ବ୍ରାହ୍ମି',
 			'Cher' => 'ଚେରକୀ',
 			'Cyrl' => 'ସିରିଲିକ୍',
 			'Deva' => 'ଦେୱନାଗରୀ',
 			'Gujr' => 'ଗୁଜୁରାଟୀ',
 			'Guru' => 'ଗୁରମୁକୀ',
 			'Hans' => 'ସହଜ',
 			'Hans@alt=stand-alone' => 'ସହଜ ହାନ',
 			'Hant' => 'ହିରୁଦଲୁ',
 			'Hant@alt=stand-alone' => 'ହିରୁ ଦଲୁ ହାନ୍‌',
 			'Knda' => 'କନ୍ନଡ଼',
 			'Latn' => 'ଲାଟିନ୍',
 			'Mlym' => 'ମାଲାୟଲମ୍',
 			'Orya' => 'ଅଡ଼ିଆ',
 			'Saur' => 'ସଉରାଷ୍ଟ୍ର',
 			'Taml' => 'ତାମିଲ୍',
 			'Telu' => 'ତେଲୁଗୁ',

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
			'419' => 'ଲାଟିନ୍‌ ଆମେରିକା',
 			'AD' => 'ଆଣ୍ଡୋରା',
 			'AE' => 'ଆଣ୍ଡିତି ଆରବ ଏମିରେଟସ୍',
 			'AF' => 'ଆପଗାନିସ୍ତାନ୍',
 			'AG' => 'ଏଣ୍ଟିଗୁଆ ଅଡ଼େ ବାରବୁଦା',
 			'AI' => 'ଏଙ୍ଗ୍ୱିଲା',
 			'AL' => 'ଆଲବାନିଆ',
 			'AM' => 'ଆର୍ମେନିଆ',
 			'AO' => 'ଅଙ୍ଗଲା',
 			'AQ' => 'ଆଣ୍ଟାର୍କଟିକା',
 			'AR' => 'ଅର୍ଜେଣ୍ଟିନା',
 			'AS' => 'ଅମେରିକା ତି ସମୱା',
 			'AT' => 'ଅଷ୍ଟ୍ରିଆ',
 			'AU' => 'ଅଷ୍ଟ୍ରେଲିଆ',
 			'AW' => 'ଅରୁବା',
 			'AX' => 'ଏଲେଣ୍ଡ',
 			'AZ' => 'ଅଜେର୍‍‍ବାଇଜାନ୍',
 			'BA' => 'ବସ୍ନିଆ ଅଡ଼େ ହର୍ଜଗୱିନା',
 			'BB' => 'ବାର୍‍ବଡସ',
 			'BD' => 'ବାଂଲାଦେଶ',
 			'BE' => 'ବେଲଜିୟମ୍',
 			'BF' => 'ବୁର୍କିନା ପାସ୍ୱ',
 			'BG' => 'ବୁଲ୍‍ଗାରିଆ',
 			'BH' => 'ବହରେନ୍',
 			'BI' => 'ବୁରୁନ୍ଦି',
 			'BJ' => 'ବେନିନ୍',
 			'BL' => 'ସେଣ୍ଟ ବାର୍ତେଲେମି',
 			'BM' => 'ବର୍‍ମୁଣ୍ଡା',
 			'BN' => 'ବ୍ରୂନେଇ',
 			'BO' => 'ବଲିୱିୟା',
 			'BQ' => 'କାରିବିୟନ ନେଦରଲ୍ୟାଣ୍ଡସ୍',
 			'BR' => 'ବ୍ରାଜିଲ୍',
 			'BS' => 'ବାହାମାସ୍',
 			'BT' => 'ବୁଟାନ',
 			'BW' => 'ବସ୍ଟୱାନା',
 			'BY' => 'ବେଲାରୂସ୍',
 			'BZ' => 'ବେଲିଜ୍',
 			'CA' => 'କାନାଡା',
 			'CC' => 'କକସ୍ (କିଲିଂ) ଦିପ',
 			'CD' => 'କଙ୍ଗ-କିଂସାସା',
 			'CD@alt=variant' => 'କଙ୍ଗ(ଡିଆର୍‍ସି)',
 			'CF' => 'ମାଦିନି ଆପ୍ରିକା ରିପବ୍ଲିକ୍',
 			'CG' => 'କଂଙ୍ଗ- ବ୍ରାଜାୱିଲି',
 			'CG@alt=variant' => 'କଂଙ୍ଗ (ରିପବ୍ଲିକ୍)',
 			'CH' => 'ସ୍ୱୀଜଅର୍‍ଲାଣ୍ଡ',
 			'CI' => 'କଟ ଡି ୱା',
 			'CI@alt=variant' => 'ଆଇୱରି କସ୍ଟ',
 			'CK' => 'କୁକ ଦିପ',
 			'CL' => 'ଚିଲି',
 			'CM' => 'କାମେରନ୍',
 			'CN' => 'ଚିନ୍',
 			'CO' => 'କଲମ୍ବିଆ',
 			'CR' => 'କସ୍ଟା ରିକା',
 			'CU' => 'କ୍ୟୁବା',
 			'CV' => 'କେପ୍ ୱଡ଼',
 			'CW' => 'କ୍ୟୁରାସାଅ',
 			'CX' => 'କ୍ରିସ୍ଟମାସ୍ ଦିପ',
 			'CY' => 'ସାଇପ୍ରସ୍',
 			'CZ' => 'ଚେକିଆ',
 			'CZ@alt=variant' => 'ଚେକ୍ ରିପବ୍ଲିକ୍',
 			'DE' => 'ଜର୍ମାନି',
 			'DG' => 'ଡିଏଗ ଗାର୍ସିଆ',
 			'DJ' => 'ଜିବୁତି',
 			'DK' => 'ଡେନମାର୍କ',
 			'DM' => 'ଡମିନିକା',
 			'DO' => 'ଡମିନିକା ତି ରିପବ୍ଲିକ୍',
 			'DZ' => 'ଅଲଜେରିଆ',
 			'EA' => 'ସେଅଟା ଅଡ଼େ ମେଲିଲା',
 			'EC' => 'ଇକ୍ୱାଡର',
 			'EE' => 'ଏସ୍ଟନିଆ',
 			'EG' => 'ଇଜିପ୍ଟ',
 			'EH' => 'ୱେଡ଼ାକୁଣ୍ପୁ ସାହାରା',
 			'ER' => 'ଇରିଟ୍ରିଆ',
 			'ES' => 'ସ୍ପେନ୍',
 			'ET' => 'ଇତିୟପିଆ',
 			'FI' => 'ପିନ୍‍ଲାଣ୍ଡ',
 			'FJ' => 'ପିଜି',
 			'FK' => 'ପାକ୍‍ଲାଣ୍ଡ ଦିପ',
 			'FK@alt=variant' => 'ପାକ୍‍ଲାଣ୍ଡ ଦିପ (ଇଜ୍ଲାସ ମାଲୱିନାସ)',
 			'FM' => 'ମାକ୍ରନେସିଆ',
 			'FO' => 'ପେରୋ ଦୀପ',
 			'FR' => 'ପ୍ରାନ୍ସ',
 			'GA' => 'ଗାବନ',
 			'GB' => 'ଇଉନାଇଟେଡ୍ କିଂଡମ୍',
 			'GB@alt=short' => 'ୟୁକେ',
 			'GD' => 'ଗ୍ରେନାଡା',
 			'GE' => 'ଜର୍ଜିଆ',
 			'GF' => 'ପ୍ରେଞ୍ଚ୍ ଗୁୟାନା',
 			'GG' => 'ଗର୍ନସି',
 			'GH' => 'ଗାନା',
 			'GI' => 'ଜିବ୍ରାଲଟର',
 			'GL' => 'ଗ୍ରୀନ୍ ଲାଣ୍ଡ',
 			'GM' => 'ଗାମ୍ବିଆ',
 			'GN' => 'ଗିନି',
 			'GP' => 'ଗ୍ୱାଡେଲୁପ',
 			'GQ' => 'ଇକ୍ୟୁଏଟେରିୟଲ ଗିନି',
 			'GR' => 'ଗ୍ରିସ୍',
 			'GS' => 'ଦକିନ ଜର୍ଜିଆ ଅଡ଼େ ଦକିନ ସାଣ୍ଡୱିଚ୍ ଦୀପ',
 			'GT' => 'ଗ୍ୱାଟେମାଲା',
 			'GU' => 'ଗୁଆମ୍',
 			'GW' => 'ଗିନି ବିସାଉ',
 			'GY' => 'ଗୁୟାନା',
 			'HK' => 'ହଂଗ କଂଗ (ଏସଏଆର୍ ଚିନା)',
 			'HK@alt=short' => 'ହଂଗ କଂଗ',
 			'HN' => 'ହଣ୍ଡୁରାସ',
 			'HR' => 'କ୍ରସିଆ',
 			'HT' => 'ହାଇତି',
 			'HU' => 'ହଙ୍ଗେରି',
 			'IC' => 'କେନାରି ଦିପ',
 			'ID' => 'ଇଣ୍ଡନେସିୟା',
 			'IE' => 'ଅଇରଲାଣ୍ଡ',
 			'IL' => 'ଇସରାଇଲ',
 			'IM' => 'ମାଣିସି ତା ଦିପ',
 			'IN' => 'ବାରତ',
 			'IO' => 'ବ୍ରିଟିସ୍ ହିନ୍ଦ ସାମୁଦ୍ରି ହାନ୍ଦି',
 			'IQ' => 'ଇରାକ',
 			'IR' => 'ଇରାନ',
 			'IS' => 'ଆଇସଲାଣ୍ଡ',
 			'IT' => 'ଇଟାଲି',
 			'JE' => 'ଜରସି',
 			'JM' => 'ଜାମାଇକା',
 			'JO' => 'ଜର୍ଡାନ',
 			'JP' => 'ଜାପାନ',
 			'KE' => 'କେନ୍ୟା',
 			'KG' => 'କିରଗିସ୍ତାନ',
 			'KH' => 'କମ୍ବଡିଆ',
 			'KI' => 'କିରିବାତି',
 			'KM' => 'କମରସ',
 			'KN' => 'ସେଣ୍ଟ. କିଟ୍ସ ଅଡ଼େ ନେବିସ',
 			'KP' => 'ଉତର କରିୟା',
 			'KR' => 'ଦକିଣ କରିୟା',
 			'KW' => 'କୁୱେତ୍',
 			'KY' => 'କାଇମାନ ଦିପ',
 			'KZ' => 'କାଜାକସ୍ତାନ',
 			'LA' => 'ଲାଅସ୍',
 			'LB' => 'ଲେବନାନ',
 			'LC' => 'ସେଣ୍ଟ. ଲୁସିଆ',
 			'LI' => 'ଲିକ୍‍ଟନ୍‍ସ୍ଟାଇନ୍',
 			'LK' => 'ସ୍ରି ଲଙ୍କା',
 			'LR' => 'ଲାଇବେରିଆ',
 			'LS' => 'ଲେସତ',
 			'LT' => 'ଲିତୁଆନିଆ',
 			'LU' => 'ଲଗ୍ଜମବର୍ଗ',
 			'LV' => 'ଲାତ୍‍ୱିୟା',
 			'LY' => 'ଲିବିୟା',
 			'MA' => 'ମରକ',
 			'MC' => 'ମନାକ',
 			'MD' => 'ମଲ୍‍ଡୱା',
 			'ME' => 'ମଣ୍ଟେନେଗ୍ର',
 			'MF' => 'ସେଣ୍ଟ ମାର୍ଟିନ',
 			'MG' => 'ମାଡ଼ାଗାସ୍କାର',
 			'MH' => 'ମାର୍ସାଲ ଦିପ',
 			'MK' => 'ଉତର ମାସାଡନିୟା',
 			'ML' => 'ମାଲି',
 			'MM' => 'ମିୟାଁମାର (ବର୍ମା)',
 			'MN' => 'ମଙ୍ଗଲିୟା',
 			'MO' => 'ମକାଉ ଏସଏଆର ଚିନା',
 			'MO@alt=short' => 'ମକାଉ',
 			'MP' => 'ଉତର ମାରିୟାନ ଦିପ',
 			'MQ' => 'ମାର୍ଟିନିକ୍',
 			'MR' => 'ମଉରିଟାନିୟା',
 			'MS' => 'ମଣ୍ଟସେରେଟ',
 			'MT' => 'ମାଲ୍ଟା',
 			'MU' => 'ମରିସସ୍',
 			'MV' => 'ମାଲଦୀପି',
 			'MW' => 'ମଲାୱି',
 			'MX' => 'ମେକ୍ସିକ',
 			'MY' => 'ମାଲେସିଆ',
 			'MZ' => 'ମଜାମ୍ବିକ',
 			'NA' => 'ନାମିବିୟା',
 			'NC' => 'ନ୍ୟୁ କେଲେଡନିୟା',
 			'NE' => 'ନାଇଜର',
 			'NF' => 'ନର୍‍ପକ୍ ଦିପ',
 			'NG' => 'ନାଇଜେରିଆ',
 			'NI' => 'ନିକାରଗୁଆ',
 			'NL' => 'ନେଦରଲାଣ୍ଡ',
 			'NO' => 'ନରୱେ',
 			'NP' => 'ନେପାଲ',
 			'NR' => 'ନାଉରୁ',
 			'NU' => 'ନିୟୁ',
 			'NZ' => 'ନିୟୁଜିଲାଣ୍ଡ',
 			'OM' => 'ଅମାନ',
 			'PA' => 'ପନମା',
 			'PE' => 'ପେରୁ',
 			'PF' => 'ପ୍ରେଞ୍ଚ୍ ପଲିନେସିୟା',
 			'PG' => 'ପପୁଆ ନିୟୁ ଗିନି',
 			'PH' => 'ପିଲିପାଇନ୍ସ',
 			'PK' => 'ପାକିସ୍ତାନ',
 			'PL' => 'ପଲାଣ୍ଡ',
 			'PM' => 'ସେଣ୍ଟ ପିଏରେ ଅଡ଼େ ମିକ୍ୱେଲାନ',
 			'PN' => 'ପିଟ୍‍କଇର୍ନ୍ ଦିପ',
 			'PR' => 'ପର୍ଟ ରିକ',
 			'PS' => 'ପାଲେସ୍ଟିଆତି ହାନ୍ଦି',
 			'PS@alt=short' => 'ପାଲେସ୍ଟାଇନ',
 			'PT' => 'ପର୍ତୁଗାଲ',
 			'PW' => 'ପଲାଉ',
 			'PY' => 'ପରଗ୍ୱେ',
 			'QA' => 'କତର',
 			'RE' => 'ରିୟୁନିୟନ',
 			'RO' => 'ରମାନିଆ',
 			'RS' => 'ସର୍ବିୟା',
 			'RU' => 'ରୁସିଆ',
 			'RW' => 'ର୍‍ୱାଣ୍ଡା',
 			'SA' => 'ସାଉଦି ଆରବ',
 			'SB' => 'ସଲମନ ଦିପ',
 			'SC' => 'ସିସେଲ୍ସ',
 			'SD' => 'ସୁଡାନ',
 			'SE' => 'ସ୍ୱିଡେନ',
 			'SG' => 'ସିଙ୍ଗାପୁର',
 			'SH' => 'ସେଣ୍ଟ ହେଲେନ',
 			'SI' => 'ସ୍ଲବେନିଆ',
 			'SJ' => 'ସ୍ୱାଲବାର୍ଡ ଅଡ଼େ ଜାନ ମାୟେନ',
 			'SK' => 'ସ୍ଲବାକିୟା',
 			'SL' => 'ସିଏରା ଲିୟନ',
 			'SM' => 'ସନ ମାରିନ',
 			'SN' => 'ସେନେଗାଲ',
 			'SO' => 'ସମାଲିଆ',
 			'SR' => 'ସୁରିନାମ',
 			'SS' => 'ଦକିଣ ସୁଡାନ',
 			'ST' => 'ସାଅ ଟମ ଅଡ଼େ ପ୍ରିନ୍ସିପେ',
 			'SV' => 'ଅଲ ସଲବାଡର',
 			'SX' => 'ସିଣ୍ଟ ମାର୍ଟିନ',
 			'SY' => 'ସିରିୟା',
 			'SZ' => 'ଏସ୍ୱାଟିନି',
 			'SZ@alt=variant' => 'ସ୍ୱାଜିଲାଣ୍ଡ',
 			'TC' => 'ତୁର୍କ ଅଡ଼େ କାଇକସ ଦିପ',
 			'TD' => 'ଚାଡ',
 			'TF' => 'ପ୍ରେଞ୍ଚ ଦକିନୀୟ ଟେରିଟୋରୀ',
 			'TG' => 'ଟଗ',
 			'TH' => 'ତାଇଲାଣ୍ଡ',
 			'TJ' => 'ତାଜିକିସ୍ତାନ',
 			'TK' => 'ତକେଲାଉ',
 			'TL' => 'ତିମର-ଲେସ୍ତେ',
 			'TL@alt=variant' => 'ଇସ୍ଟ ତିମର',
 			'TM' => 'ତୁର୍କମେନିସ୍ତାନ',
 			'TN' => 'ଟ୍ୟୁନିସିୟା',
 			'TO' => 'ଟଙ୍ଗ',
 			'TR' => 'ତୁର୍କି',
 			'TT' => 'ତ୍ରିନିଡାଡ ଅଡ଼େ ଟବାଗ',
 			'TV' => 'ତୁୱାଲୁ',
 			'TW' => 'ତାଇୱାନ',
 			'TZ' => 'ତାଞ୍ଜାନିୟା',
 			'UA' => 'ୟୁକ୍ରେନ୍',
 			'UG' => 'ଉଗାଣ୍ଡା',
 			'UM' => 'ୟୁ ଏସ୍ ଆଉଟଲାଇଙ୍କ ଦିପ',
 			'US' => 'ଆଣ୍ଡିତି ରାଜ୍ୟ',
 			'US@alt=short' => 'ୟୁ ଏସ୍',
 			'UY' => 'ଉରୁଗ୍ୱେ',
 			'UZ' => 'ଉଜବେକିସ୍ତାନ',
 			'VA' => 'ବାଟିକାନ୍ ସିଟି',
 			'VC' => 'ସେଣ୍ଟ ୱିନସେଣ୍ଟ ଅଡ଼େ ଗ୍ରିନାଡାଇନ୍ସ',
 			'VE' => 'ୱେନେଜୁଏଲ',
 			'VG' => 'ବ୍ରିଟିସ୍ ୱିରଜିନ ଦିପ',
 			'VI' => 'ୟୁ ଏସ ୱିରଜିନ ଦିପ',
 			'VN' => 'ୱିଏତନାମ',
 			'VU' => 'ୱାନୁଆତୁ',
 			'WF' => 'ୱାଲିସ ଅଡ଼େ ପୁଟୁନା',
 			'WS' => 'ସମୱା',
 			'XK' => 'କସୱ',
 			'YE' => 'ୟମନ',
 			'YT' => 'ମାୟତେ',
 			'ZA' => 'ଦକିଣ ଆପ୍ରିକା',
 			'ZM' => 'ଜାମ୍ବିୟା',
 			'ZW' => 'ଜିମ୍ବାୱେ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'କେଲେଣ୍ଡର',
 			'cf' => 'ଟାକାଁ ପରମାଟ',
 			'collation' => 'ମିଲା କ୍ରମ',
 			'currency' => 'ଟାକାଁ',
 			'hc' => 'ୱେଡ଼ାତି ଗିଲା (୧୨ ଅଡ଼େ ୨୪)',
 			'lb' => 'ଦାଡ଼ି ଡିକିହିନ ଆଡା',
 			'ms' => 'ଲାଚିନି ଲେକା',
 			'numbers' => 'ସଂକ୍ୟା',

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
 				'gregorian' => q{ଗ୍ରେଗରିୟାନ କେଲେଣ୍ଡର},
 				'indian' => q{ବାରତ ଜାତିୟ କେଲେଣ୍ଡର},
 			},
 			'cf' => {
 				'standard' => q{ମାନାଙ୍କ ଟାକାଁ ରୁପ},
 			},
 			'collation' => {
 				'ducet' => q{ଡିପଲଟ ୟୁନିକଡ ସର୍ଟ ଲେଁ},
 				'phonebook' => q{ପନ୍‍ବହି ବାଗା ଅର୍ଡର},
 				'search' => q{ସାମାନି-ଉଦେସ୍ୟ ପାରିନ},
 				'standard' => q{ମାନାଙ୍କ ସର୍ଟ ଲେଁ},
 			},
 			'hc' => {
 				'h11' => q{୧୨ ଗଣ୍ଟା ତି ପଦ୍ଦତି (0–୧୧)},
 				'h12' => q{୧୨ ଗଣ୍ଟା ତି ପଦ୍ଦତି (୧–୧୨)},
 				'h23' => q{୨୪ ଗଣ୍ଟା ତି ପଦ୍ଦତି (0–୨୩)},
 				'h24' => q{୨୪ ଗଣ୍ଟା ତି ପଦ୍ଦତି (୧–୨୪)},
 			},
 			'ms' => {
 				'metric' => q{ମେଟ୍ରକି ପଦ୍ଦତି},
 				'uksystem' => q{ସାମ୍ରାଜ୍ୟତି ଆଟିନି ମାପ ପଦ୍ଦତି},
 				'ussystem' => q{ଆମେରିକାତି ମାପ ପଦ୍ଦତି},
 			},
 			'numbers' => {
 				'arab' => q{ଆରବିକ୍-ବାରତୀୟ ନମ୍ବର},
 				'arabext' => q{ନକିଆତି ଆରବିକ୍-ବାରତୀୟ ନମ୍ବର},
 				'beng' => q{ବଙ୍ଗାଲୀ ନମ୍ବର},
 				'deva' => q{ଦେବନାଗରୀ ନମ୍ବର},
 				'gujr' => q{ଗୁଜରାଟି ନମ୍ବର},
 				'guru' => q{ଗୁରୁମୁକି ନମ୍ବର},
 				'knda' => q{କନଡ ନମ୍ବର},
 				'latn' => q{ୱେସ୍ଟେନ୍ ନମ୍ବର},
 				'mlym' => q{ମାଲାୟାଲମ୍ ନମ୍ବର},
 				'orya' => q{ଅଡ଼ିଆ ନମ୍ବର},
 				'roman' => q{ରମାନ ନମ୍ବର},
 				'romanlow' => q{ରମାନ ମିଲା ଅରା ନମ୍ବର},
 				'taml' => q{ହିରୁଦୁଲୁ ତାମିଲ ନମ୍ବର},
 				'tamldec' => q{ତାମିଲ୍ ନମ୍ବର},
 				'telu' => q{ତେଲୁଗୁ ନମ୍ବର},
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
			'metric' => q{ମେଟ୍ରିକ},
 			'UK' => q{ୟୁକେ},
 			'US' => q{ୟୁଏସ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'କାତା: {0}',
 			'script' => 'ଅକର: {0}',
 			'region' => 'ମୁଟ୍ହା: {0}',

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
			main => qr{[଼ ଁଂଃ ଅ {ଅ\:} ଆ {ଆ\:} ଇ ଈ ଉ ଊ ଏ {ଏ\:} କ ଗ ଙ ଚ ଜ ଞ ଟ ଡ ଣ ତ ଦ ନ ପ ବ ମ ୟ ର ଲ ଳ ୱ ସ ହ ା ି ୀ ୁ ୂ େ ୍]},
			numbers => qr{[\- ‑ , . % ‰ + 0 ୧ ୨ ୩ ୪ ୫ ୬ ୭ ୮ ୯]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, ଅଡ଼େ {1}),
				2 => q({0} ଅଡ଼େ {1}),
		} }
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'orya',
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
				'currency' => q(ବ୍ରାଜିଲ୍ ତି ରିଏଲ୍),
				'other' => q(ବ୍ରାଜିଲ୍ ତି ରିଏଲ୍),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(ଚିନି ତି ୟୁଆନ),
				'other' => q(ଚିନି ତି ୟୁଆନ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ୟୁର),
				'other' => q(ୟୁରସ୍),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ବ୍ରିଟିସ୍ ପାଉଣ୍ଡ୍),
				'other' => q(ବ୍ରିଟିସ୍ ପାଉଣ୍ଡ୍),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ବାରତ ତି ଟାକାଁ),
				'other' => q(ବାରତ ତି ଟାକାଁ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ଜାପାନ ତି ୟେନ),
				'other' => q(ଜାପାନ ତି ୟେନ),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ରୁସିଆ ତି ରୁବଲ୍),
				'other' => q(ରୁସିଆ ତି ରୁବଲ୍ସ),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ୟୁ ଏସ ଡଲାର),
				'other' => q(ୟୁ ଏସ ଡଲାର୍‍ସ୍),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ପୁଣ୍‍ଆତି ଲେବୁଁ),
				'other' => q(ପୁଣ୍ଆତି ଲେବୁଁ),
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
							'ପୁସୁ',
							'ମାହା',
							'ପାଗୁ',
							'ହିରେ',
							'ବେସେ',
							'ଜାଟା',
							'ଆସାଡ଼ି',
							'ସ୍ରାବାଁ',
							'ବଦ',
							'ଦାସାରା',
							'ଦିୱି',
							'ପାଣ୍ଡେ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ପୁସୁ ଲେଞ୍ଜୁ',
							'ମାହାକା ଲେଞ୍ଜୁ',
							'ପାଗୁଣି ଲେଞ୍ଜୁ',
							'ହିରେ ଲେଞ୍ଜୁ',
							'ବେସେ ଲେଞ୍ଜୁ',
							'ଜାଟା ଲେଞ୍ଜୁ',
							'ଆସାଡ଼ି ଲେଞ୍ଜୁ',
							'ସ୍ରାବାଁ ଲେଞ୍ଜୁ',
							'ବଦ ଲେଞ୍ଜୁ',
							'ଦାସାରା ଲେଞ୍ଜୁ',
							'ଦିୱିଡ଼ି ଲେଞ୍ଜୁ',
							'ପାଣ୍ଡେ ଲେଞ୍ଜୁ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ପୁ',
							'ମା',
							'ପା',
							'ହି',
							'ବେ',
							'ଜା',
							'ଆ',
							'ସ୍ରା',
							'ବ',
							'ଦା',
							'ଦି',
							'ପା'
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
						mon => 'ସମ୍ବା',
						tue => 'ମାଙ୍ଗା',
						wed => 'ପୁଦା',
						thu => 'ଲାକି',
						fri => 'ସୁକ୍ରୁ',
						sat => 'ସାନି',
						sun => 'ଆଦି'
					},
					short => {
						mon => 'ସ',
						tue => 'ମା',
						wed => 'ପୁ',
						thu => 'ଲା',
						fri => 'ସୁ',
						sat => 'ସାନି',
						sun => 'ଆ'
					},
					wide => {
						mon => 'ସମ୍ବାରା',
						tue => 'ମାଙ୍ଗାଡ଼ା',
						wed => 'ପୁଦାରା',
						thu => 'ଲାକି ୱାରା',
						fri => 'ସୁକ୍ରୁ ୱାରା',
						sat => 'ସାନି ୱାରା',
						sun => 'ଆଦି ୱାରା'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'ସ',
						tue => 'ମା',
						wed => 'ପୁ',
						thu => 'ଲା',
						fri => 'ସୁ',
						sat => 'ସା',
						sun => 'ଆ'
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
					abbreviated => {0 => 'କ ୧',
						1 => 'କ ୨',
						2 => 'କ ୩',
						3 => 'କ ୪'
					},
					wide => {0 => '୧ମ କ୍ୱାଟର',
						1 => '୨ୟ କ୍ୱାଟର',
						2 => '୩ୟ କ୍ୱାଟର',
						3 => '୪ର୍ଥ କ୍ୱାଟର'
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
					'am' => q{ଏ ଏମ},
					'pm' => q{ପି ଏମ},
				},
				'narrow' => {
					'am' => q{ଏ},
					'pm' => q{ପି},
				},
				'wide' => {
					'am' => q{ଏ ଏମ},
					'pm' => q{ପି ଏମ},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ଏ ଏମ},
					'pm' => q{ପି ଏମ},
				},
				'narrow' => {
					'am' => q{ଏ ଏମ},
					'pm' => q{ପି ଏମ},
				},
				'wide' => {
					'am' => q{ଏ ଏମ},
					'pm' => q{ପି ଏମ},
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
				'0' => 'ବିସି',
				'1' => 'ଏଡି'
			},
			wide => {
				'0' => 'ବିଫୋର କ୍ରାଇଷ୍ଟ',
				'1' => 'ଆନ୍ନା ଡୋମିନି'
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
			'full' => q{{1} ଆଁ {0}},
			'long' => q{{1} ଆଁ {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} ଆଁ {0}},
			'long' => q{{1} ଆଁ {0}},
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
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{d E},
			GyMMMEd => q{G E, d MMM y},
			GyMMMd => q{G d MMM y},
			M => q{M},
			MEd => q{E, d/M},
			MMM => q{MMM},
			MMMEd => q{E, d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yyyyM => q{GGGGG M/y},
			yyyyMEd => q{G E, d/M/y},
			yyyyMMM => q{G MMM y},
			yyyyMMMEd => q{G E, d MMM y},
			yyyyMMMd => q{G d MMM y},
			yyyyMd => q{G d/M/y},
			yyyyQQQ => q{QQQ G y},
			yyyyQQQQ => q{QQQQ G y},
		},
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
			MMMMW => q{MMMM ତାଁ ୱାରା W},
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
			yw => q{Y ତାଁ ୱାରା w},
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
			Bh => {
				B => q{B h – B h},
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{B h – B h},
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
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
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
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
		regionFormat => q({0} ବେଲା),
		regionFormat => q({0} ଡେଲାଇଟ ବେଲା),
		regionFormat => q({0} ମାନାଙ୍କ ବେଲା),
		'Afghanistan' => {
			long => {
				'standard' => q#ଆପଗାନିସ୍ତାନ ବେଲା#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#ଆବିଦଜାନ#,
		},
		'Africa/Accra' => {
			exemplarCity => q#ଏକ୍ରା#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#ଆଦିସ୍‌ ଆବାବା#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#ଅଲଜିୟର୍ସ#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#ଅସମରା#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#ବାମାକ#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#ବାଙ୍ଗୁଇ#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#ବାଞ୍ଜୁଲ#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#ବିସାଉ#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#ବ୍ଲାଣ୍ଟାୟାର୍‌#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#ବ୍ରାଜାୱିଲ୍ଲେ#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#ବୁଜୂମ୍ବୁରା#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#କାଇର#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#କାସାବ୍ଲାଙ୍କା#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#ସେଉଟା#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#କନାକ୍ରି#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#ଡକାର#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#ଡର୍‌ ଇସ୍‌ ସାଲାମ#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#ଜିବଟି#,
		},
		'Africa/Douala' => {
			exemplarCity => q#ଡଉଲା#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#ଏଲ୍‌ ଏୟନ୍#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#ପ୍ରିଟାଉନ୍‌#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#ଗାବର୍ଣ୍ଣ#,
		},
		'Africa/Harare' => {
			exemplarCity => q#ହରାରେ#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#ଜହାନ୍ସବର୍ଗ#,
		},
		'Africa/Juba' => {
			exemplarCity => q#ଜୁବା#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#କାମ୍ପାଲା#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#କରଟଉମ୍‌#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#କିଗାଲି#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#କିନସାସ୍‌#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#ଲାଗସ୍‌#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#ଲିବ୍ରେୱିଲ୍ଲେ#,
		},
		'Africa/Lome' => {
			exemplarCity => q#ଲମ୍‌#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#ଲୁଆଣ୍ଡା#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#ଲୁବୁମ୍ବାଶି#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#ଲୁସାକା#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#ମାଲାବ#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#ମାପୁତୋ#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#ମେସେରୁ#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#ମ୍-ବାବାନେ#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#ମୋଗାଡିସୁ#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#ମନରୋବିଆ#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#ନାଇରବି#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#ଜାମେନା#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#ନିଆମି#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#ନୁଆକଚଟ#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#ଅଗାଡଗୁ#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#ପର୍ଟ-ନୱ#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#ସାଅ ଟମେ#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#ତ୍ରିପଲି#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#ଟୁନିସ୍‌#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#ୱିଣ୍ଡହକ୍#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#ମାଦିନି ଆପ୍ରିକା ବେଲା#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#ୱେଡ଼ା ହପୁ ଆପ୍ରିକା ବେଲା#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#ଦକିଣ ଆପ୍ରିକା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଆପ୍ରିକା କାରାଁ ବେଲା#,
				'generic' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଆପ୍ରିକା ବେଲା#,
				'standard' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଆପ୍ରିକା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#ଆଲାସ୍କା ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#ଆଲାସ୍କା ବେଲା#,
				'standard' => q#ଆଲାସ୍କା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#ଆମେଜନ କାରାଁ ବେଲା#,
				'generic' => q#ଆମେଜନ ବେଲା#,
				'standard' => q#ଆମେଜନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#ଆଡାକ୍#,
		},
		'America/Anchorage' => {
			exemplarCity => q#ଆଙ୍କରେଜ୍#,
		},
		'America/Anguilla' => {
			exemplarCity => q#ଆଙ୍ଗୁଇଲା#,
		},
		'America/Antigua' => {
			exemplarCity => q#ଆଣ୍ଟିଗୁଆ#,
		},
		'America/Araguaina' => {
			exemplarCity => q#ଆରାଗୁଆନା#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#ଲା ରି୍ଅଜା#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#ରିୟୋ ଗାଲେଗୋସ#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#ସାଲ୍ଟା#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#ସାୟାନ୍ ୱାନ୍#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#ସୟାନ ଲୁଇସ#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#ଟୋକୁମନ#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#ଉସୁଆଇୟା#,
		},
		'America/Aruba' => {
			exemplarCity => q#ଅରୁବା#,
		},
		'America/Asuncion' => {
			exemplarCity => q#ଆସନସିଅନ୍‌#,
		},
		'America/Bahia' => {
			exemplarCity => q#ବାହିଆ#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#ବାହିଆ ବ୍ୟାଣ୍ଡେରାସ୍#,
		},
		'America/Barbados' => {
			exemplarCity => q#ବାରବାଡସ#,
		},
		'America/Belem' => {
			exemplarCity => q#ବେଲେମ#,
		},
		'America/Belize' => {
			exemplarCity => q#ବେଲିଜେ#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#ବ୍ଲାଙ୍କ-ସାବଲନ୍#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#ବୋଆ ୱିସ୍ଟା#,
		},
		'America/Bogota' => {
			exemplarCity => q#ବଗଟା#,
		},
		'America/Boise' => {
			exemplarCity => q#ବଇସେ#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#ବୁଏନସ୍ ଆଇରେସ୍#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#କେମ୍ଵ୍ରିଜ୍ ବେ#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#କାମ୍ପ ଗ୍ରାଣ୍ଡେ#,
		},
		'America/Cancun' => {
			exemplarCity => q#କାନକୁନ୍#,
		},
		'America/Caracas' => {
			exemplarCity => q#କାରକାସ୍‌#,
		},
		'America/Catamarca' => {
			exemplarCity => q#କା଼ଟାମାକାଁ#,
		},
		'America/Cayenne' => {
			exemplarCity => q#କେୟେନ୍ନି#,
		},
		'America/Cayman' => {
			exemplarCity => q#କାୟମ୍ୟାନ୍#,
		},
		'America/Chicago' => {
			exemplarCity => q#ସିକାଗ#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#ଚିହୁଆହୁଆ#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#ଆଟିକୋକାନ୍#,
		},
		'America/Cordoba' => {
			exemplarCity => q#କୋଡୋବା#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#କଷ୍ଟା ରିକା#,
		},
		'America/Creston' => {
			exemplarCity => q#କ୍ରେସ୍‍ଟନ#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#କୁଇବା#,
		},
		'America/Curacao' => {
			exemplarCity => q#କୁରାକ#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#ଡାନମାର୍କସାଭନ୍#,
		},
		'America/Dawson' => {
			exemplarCity => q#ଡସନ୍‌#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#ଡୱସନ୍ କ୍ରିକ୍#,
		},
		'America/Denver' => {
			exemplarCity => q#ଡେନୱିର୍#,
		},
		'America/Detroit' => {
			exemplarCity => q#ଡେଟ୍ରଇଟ୍#,
		},
		'America/Dominica' => {
			exemplarCity => q#ଡମିନିକା#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ଏଡ୍‍ମନଟନ୍#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#ଇରୁନେପେ#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ଏଲ୍ ସାଲୱାଡୋର୍#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#ପର୍ଟ ନେଲସନ୍#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#ପର୍ଟଲେଜା#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#ଗ୍ଲାସେ ବେ#,
		},
		'America/Godthab' => {
			exemplarCity => q#ନୁଉକ୍#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#ଗୁସ୍ ବେ#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#ଗ୍ରାଣ୍ଡ୍ ଟର୍କ୍#,
		},
		'America/Grenada' => {
			exemplarCity => q#ଗ୍ରେନାଡା#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#ଗୁଆଡେଲଉପେ#,
		},
		'America/Guatemala' => {
			exemplarCity => q#ଗୁଆତେମାଲା#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#ଗୁୟାକ୍ୱିଲ#,
		},
		'America/Guyana' => {
			exemplarCity => q#ଗୁଏନା#,
		},
		'America/Halifax' => {
			exemplarCity => q#ହାଲିଫ୍ୟାକ୍ସ୍#,
		},
		'America/Havana' => {
			exemplarCity => q#ହାୱନା#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#ହେରମସିଲୋ#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#କ୍ନୋକ୍ସ, ଇଣ୍ଡିଆନା#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#ମାରେନଗ, ଇଣ୍ଡିଆନା#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#ପେଟେର୍ସବର୍ଗ୍, ଇଣ୍ଡିଆନା#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#ଟେଲ୍ ସିଟି, ଇଣ୍ଡିଆନା#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#ୱେୱାୟ, ଇଣ୍ଡିଆନା#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#ଭିନସେନ୍ନେସ୍, ଇଣ୍ଡିଆନା#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#ୱିନାମାକ୍, ଇଣ୍ଡିଆନା#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#ଇଣ୍ଡିଆନାପଲିସ୍#,
		},
		'America/Inuvik' => {
			exemplarCity => q#ଇନୁୱିକ୍#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ଇକ୍ଵାଲୁଇଟ୍#,
		},
		'America/Jamaica' => {
			exemplarCity => q#ଜାମାଇକା#,
		},
		'America/Jujuy' => {
			exemplarCity => q#ଜୁଜୋଏ#,
		},
		'America/Juneau' => {
			exemplarCity => q#ଜୁନେଆଉ#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#ମଣ୍ଟିସେଲ, କେଣ୍ଟଉକିକେ#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#କ୍ରାଲେଣ୍ଡିଜିକ#,
		},
		'America/La_Paz' => {
			exemplarCity => q#ଲା ପାଜ#,
		},
		'America/Lima' => {
			exemplarCity => q#ଲିମା#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#ଲସ୍ ଏଞ୍ଜେଲେସ୍#,
		},
		'America/Louisville' => {
			exemplarCity => q#ଲଉଇସୱିଲ୍ଲେ#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#ନିମ୍ନ ପ୍ରିନ୍ସ’ର କ୍ଵାଟର୍#,
		},
		'America/Maceio' => {
			exemplarCity => q#ମାସିଅ#,
		},
		'America/Managua' => {
			exemplarCity => q#ମାନାଗୁଆ#,
		},
		'America/Manaus' => {
			exemplarCity => q#ମାନାଉସ୍‌#,
		},
		'America/Marigot' => {
			exemplarCity => q#ମାରିଗଟ୍#,
		},
		'America/Martinique' => {
			exemplarCity => q#ମାର୍ଟିନିକ୍ୟୁ#,
		},
		'America/Matamoros' => {
			exemplarCity => q#ମାଟାମରସ୍#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#ମାଜାଟଲାନ୍#,
		},
		'America/Mendoza' => {
			exemplarCity => q#ମେଣ୍ଡଜା#,
		},
		'America/Menominee' => {
			exemplarCity => q#ମେନୋମିନି#,
		},
		'America/Merida' => {
			exemplarCity => q#ମେରିଡା#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#ମାଟଲାକାଟଲା#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#ମେକ୍ସିକୋ ସିଟି#,
		},
		'America/Miquelon' => {
			exemplarCity => q#ମିକ୍ଵେଲନ୍#,
		},
		'America/Moncton' => {
			exemplarCity => q#ମାନକଟନ୍#,
		},
		'America/Monterrey' => {
			exemplarCity => q#ମନଟେରିଏ#,
		},
		'America/Montevideo' => {
			exemplarCity => q#ମଣ୍ଟେଭିଡିଅ#,
		},
		'America/Montserrat' => {
			exemplarCity => q#ମନଟସେରରାଟ୍#,
		},
		'America/Nassau' => {
			exemplarCity => q#ନାସାଉ#,
		},
		'America/New_York' => {
			exemplarCity => q#ନ୍ୟୁ ୟର୍କ୍#,
		},
		'America/Nome' => {
			exemplarCity => q#ନୋମେ#,
		},
		'America/Noronha' => {
			exemplarCity => q#ନରହ୍ନ#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#ବେଉଲାହ, ଉତ୍ତର ଡାକଟା#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#କେନ୍ଦ୍ର, ଉତ୍ତର ଡାକଟା#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#ନ୍ୟୁ ସାଲେମ୍, ଉତ୍ତର ଡାକଟା#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ଅଜିନାଗା#,
		},
		'America/Panama' => {
			exemplarCity => q#ପାନାମା#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#ପାରାମାରିବ#,
		},
		'America/Phoenix' => {
			exemplarCity => q#ପଇନିକ୍ସ#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#ପର୍ଟ-ଏୟୁ-ପ୍ରିନ୍‍ସ#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#ପର୍ଟ୍ ଅଫ୍ ସ୍ପେନ୍#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#ପୋର୍ଟୋ ଭେଲୋ#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#ପୁଏର୍ତ ରିକ#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#ପୁଣ୍ଟା ଏରିନାସ୍‌#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#ରାନକିନ୍ ଇନଲେଟ୍#,
		},
		'America/Recife' => {
			exemplarCity => q#ରେସିପି#,
		},
		'America/Regina' => {
			exemplarCity => q#ରେଗିନା#,
		},
		'America/Resolute' => {
			exemplarCity => q#ରିସୋଲୁଟେ#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#ରିୟ ବ୍ରାଙ୍କ#,
		},
		'America/Santarem' => {
			exemplarCity => q#ସାନ୍ତରେମ୍#,
		},
		'America/Santiago' => {
			exemplarCity => q#ସାଣ୍ଟିଆଗ#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#ସାଣ୍ଟ ଡମିଙ୍ଗ#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#ସାଓ ପାଓଲୋ#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#ଇଟ୍ଟକ୍ଵରଟରମିଟ୍#,
		},
		'America/Sitka' => {
			exemplarCity => q#ସିଟକା#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#ସେଣ୍ଟ ବାର୍ତେଲେମି#,
		},
		'America/St_Johns' => {
			exemplarCity => q#ସେଣ୍ଟ୍. ଜନସ୍#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#ସେଣ୍ଟ୍ କିଟ୍‍ସ#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#ସେଣ୍ଟ୍. ଲୁସିଆ#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#ସେଣ୍ଟ୍. ଥମାସ୍#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#ସେଣ୍ଟ୍. ୱିନସେଣ୍ଟ୍#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#ସୁଇଫ୍ଟ୍ କରେଣ୍ଟ୍#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#ଟେଗୁସିଗାଲପା#,
		},
		'America/Thule' => {
			exemplarCity => q#ତୁଲେ#,
		},
		'America/Tijuana' => {
			exemplarCity => q#ତିଜୁଆନା#,
		},
		'America/Toronto' => {
			exemplarCity => q#ଟରଣ୍ଟ#,
		},
		'America/Tortola' => {
			exemplarCity => q#ଟରଟଲା#,
		},
		'America/Vancouver' => {
			exemplarCity => q#ୱାଙ୍କୁୱର୍#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#ହ୍ଵାଇଟହର୍ସ୍#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#ୱିନିପେଗ୍#,
		},
		'America/Yakutat' => {
			exemplarCity => q#ୟାକୁଟାଟ୍#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#ମାଦିନି ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#ମାଦିନି ବେଲା#,
				'standard' => q#ମାଦିନି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ୱେଡ଼ାହପୁ ଜାଗାତି ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#ୱେଡ଼ାହପୁତି ଜାଗା ବେଲା#,
				'standard' => q#ୱେଡ଼ାହପୁ ଜାଗାତି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ହର୍କା ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#ହର୍କା ବେଲା#,
				'standard' => q#ହର୍କା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#ପେସିପିକ୍ ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#ପେସିପିକ୍ ବେଲା#,
				'standard' => q#ପେସିପିକ୍ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#କେସି#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#ଡେୱିସ୍#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#ଡ୍ୟୁମାଣ୍ଟ ଡି ଉରୱିଲେ#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#ମକ୍ୱାରି#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#ମାଁସନ#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#ମ୍ୟାକମୁର୍ଡ#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#ପାଁମର#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#ରୋତେରା#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#ସୋୱା#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ଟୋଲ୍#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#ୱୋସ୍ତକୋ#,
		},
		'Apia' => {
			long => {
				'daylight' => q#ଏପିଆ ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#ଏପିଆ ବେଲା#,
				'standard' => q#ଏପିଆ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#ଆରବିଆତି ମେଦାଣା ବେଲା#,
				'generic' => q#ଆରବିଆତି ବେଲା#,
				'standard' => q#ଆରବିଆତି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#ଳଙ୍ଖୟାରବେନ#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ଆର୍ଜେଣ୍ଟିନା କାରା ବେଲା#,
				'generic' => q#ଆରଜେଣ୍ଟିନା ବେଲା#,
				'standard' => q#ଆରଜେଣ୍ଟିନା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଆର୍ଜେଣ୍ଟିନା କାରାଁ ବେଲା#,
				'generic' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଆର୍ଜେଣ୍ଟିନା ବେଲା#,
				'standard' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଆର୍ଜେଣ୍ଟିନା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ଆରମେନିୟା କାରାଁ ବେଲା#,
				'generic' => q#ଆରମେନିୟା ବେଲା#,
				'standard' => q#ଆରମେନିୟା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#ଏଡେନ୍‌#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#ଅଲମାଟି#,
		},
		'Asia/Amman' => {
			exemplarCity => q#ଅମ୍ମାନ#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#ଆନାଡୟାର୍#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#ଆକଟାଉ#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#ଆକ୍ଟବେ#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#ଆସ୍‍ଗାବଟ୍#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#ଅତିରାଉ#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#ବାଗଦାଦ୍‌#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#ବହାରେନ#,
		},
		'Asia/Baku' => {
			exemplarCity => q#ବାକୁ#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#ବ୍ୟାଙ୍ଗକକ୍‌#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#ବାରନାଉଲ୍#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#ବୀରୁଟ୍‌#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#ବିସକେକ୍‌#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#ବ୍ରୁନେଇ#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#କୋଲକାତା#,
		},
		'Asia/Chita' => {
			exemplarCity => q#ଚିଟା#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#କଲମ୍ବୋ#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#ଡାମାସକସ୍‌#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ଡାକା#,
		},
		'Asia/Dili' => {
			exemplarCity => q#ଦିଲ୍ଲୀ#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#ଦୁବାଇ#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#ଦୁସାନବେ#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#ପାମାଗୁସ୍ଟା#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#ଗାଜା#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#ହେବ୍ରନ୍‌#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#ହଂ କଂ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#ହୋୱଡ୍‌#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#ଇରକୁଟସ୍କ#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#ଜାକର୍ତା#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#ଜୟପୁରା#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#ଜେରୁଜେଲମ#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#କବୁଲ୍#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#କାମଚାଟକା#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#କରାଚି#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#କାଟମାଣ୍ଡୁ#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#କାନଡ୍ୟାଗା#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#କ୍ରାସନୟାରସ୍କ#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#କ୍ୱାଲାଲମ୍ପୁର#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#କୁଚିଂ#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#କୁଏତ#,
		},
		'Asia/Macau' => {
			exemplarCity => q#ମାକାଉ#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#ମାଗାଡାନ୍#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#ମାକାସାର୍‌#,
		},
		'Asia/Manila' => {
			exemplarCity => q#ମାନିଲା#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#ମସ୍କାଟ୍‌#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#ନିକସିଆ#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#ନୱକୁଜନେଟସ୍କ#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#ନୱସିବିରସ୍କ#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#ଓମସ୍କ#,
		},
		'Asia/Oral' => {
			exemplarCity => q#ଅରାଲ୍‌#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#ପନମ୍‌ ପେନହ#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#ପଣ୍ଟିଆନାକ୍‌#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#ପୋୟଙ୍ଗୟାଙ୍ଗ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#କତାର୍#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#କଷ୍ଟନେ#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#କୀଜିଲର୍ଡା#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#ୟାଙ୍ଗୁନ୍‌#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#ରିଆଦ#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#ହ ଚି ମିନ୍‌ ସିଟି#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#ସକାଲିନ୍#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#ସମରକନ୍ଦ#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#ସିଅଲ#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#ସଂଗାଇ#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#ସିଙ୍ଗାପୁର୍‌#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#ସ୍ରେଡନେକଲୟମସ୍କ#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#ତାଇପେଇ#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#ତାସକେଣ୍ଟ#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#ଟିବିଲିସି#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#ତେହେରାନ୍#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#ତିମ୍ପୁ#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#ଟକିଅ#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#ଟମସ୍କ#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#ଉଲାନ୍‌ବାଟର୍‌#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#ଉରୁମକି#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#ୟୁସ୍‍ଟ-ନେରା#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#ୱିଏଣ୍ଟିଏନ୍‌#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#ୱ୍ଲାଡିୱଷ୍ଟୋକ୍#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#ୟାକୁଟସ୍କ#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#ୟେକାଟେରିନବର୍ଗ୍#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#ୟେରେବାନ୍#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ଆଟ୍ଲାଣ୍ଟିକ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ଆଟ୍ଲାଣ୍ଟିକ ବେଲା#,
				'standard' => q#ଆଟ୍ଲାଣ୍ଟିକ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#ଆଜରେସ୍#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#ବରମୁଡା#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#କାନାରେ#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#କେପ୍‌ ୱର୍ଦେ#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#ପରଏ#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#ମାଡେଇରା#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#ରେକ୍ୟାବିକ#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#ଦକ୍ଷିଣ ଜର୍ଜିଆ#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#ସେଣ୍ଟ୍‌ ହେଲିନା#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#ସ୍‍ଟାଲିନ#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#ଏଡିଲେଡ୍#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#ବ୍ରିସବନ୍#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#ବ୍ରୋକନ ହିଲ#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#ଡାର୍ୱିନ୍#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#ୟୁକଲା#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#ହୋବାର୍ଟ#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#ଲିଣ୍ଡେମାନ#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#ଲର୍‍ଡ ହାୱେ#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#ମେଲବୋନଁ#,
		},
		'Australia/Perth' => {
			exemplarCity => q#ପର୍ତ#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#ସିଡନୀ#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#ଅସ୍ଟ୍ରେଲିଆତି ମାଦିନି ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ମାଦିନି ଅସ୍ଟ୍ରେଲିଆ ବେଲା#,
				'standard' => q#ଅସ୍ଟ୍ରେଲିଆତି ମାଦିନି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#ଅସ୍ଟ୍ରେଲିଆତି ମାଦିନି ୱେଡ଼ାକୁଣ୍‍ପୁ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ଅସ୍ଟ୍ରେଲିଆତି ମାଦିନି ୱେଡ଼ାକୁଣ୍‍ପୁ ବେଲା#,
				'standard' => q#ଅସ୍ଟ୍ରେଲିଆତି ମାଦିନି ୱେଡ଼ାକୁଣ୍‍ପୁ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#ଅସ୍ଟ୍ରେଲିଆତି ୱେଡ଼ାହପୁ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ୱେଡ଼ାହପୁ ଅସ୍ଟ୍ରେଲିଆ ବେଲା#,
				'standard' => q#ଅସ୍ଟ୍ରେଲିଆତି ୱେଡ଼ାହପୁ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#ଅସ୍ଟ୍ରେଲିଆତି ୱେଡ଼ାକୁଣ୍‍ପୁ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ୱେଡ଼ାକୁଣ୍‍ପୁ ଅସ୍ଟ୍ରେଲିଆ ବେଲା#,
				'standard' => q#ଅସ୍ଟ୍ରେଲିଆତି ୱେଡ଼ାକୁଣ୍‍ପୁ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#ଅଜେରବାଇଜାନ କାରାଁ ବେଲା#,
				'generic' => q#ଅଜେରବାଇଜାନ ବେଲା#,
				'standard' => q#ଅଜେରବାଇଜାନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#ଅଜରେସ କାରାଁ ବେଲା#,
				'generic' => q#ଅଜରେସ ବେଲା#,
				'standard' => q#ଅଜରେସ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#ବାଙ୍ଗଲାଦେସ୍ କାରାଁ ବେଲା#,
				'generic' => q#ବାଙ୍ଗଲାଦେସ୍ ବେଲା#,
				'standard' => q#ବାଙ୍ଗଲାଦେସ୍ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#ବୁଟାନ ବେଲା#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#ବଲୱିଆ ବେଲା#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#ବ୍ରାଜିଲିୟା କାରାଁ ବେଲା#,
				'generic' => q#ବ୍ରାଜିଲିୟା ବେଲା#,
				'standard' => q#ବ୍ରାଜିଲିୟା ମାନକ ବେଲା#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#ବ୍ରୁନେଇ ଦାରୁସାଲାମ ବେଲା#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#କେପ ବର୍ଡ କାରାଁ ବେଲା#,
				'generic' => q#କେପ ବର୍ଡ ବେଲା#,
				'standard' => q#କେପ ବର୍ଡ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#ଚମର ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#ଚାତାମ ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#ଚାତାମ ବେଲା#,
				'standard' => q#ଚାତାମ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#ଚିଲି କାରାଁ ବେଲା#,
				'generic' => q#ଚିଲି ବେଲା#,
				'standard' => q#ଚିଲି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#ଚିନ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ଚିନ ବେଲା#,
				'standard' => q#ଚିନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#କ୍ରିସମାସ ଦିପ ବେଲା#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#କକସ ଦିପ ବେଲା#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#କଲମ୍ବିୟା କାରାଁ ବେଲା#,
				'generic' => q#କଲମ୍ବିୟା ବେଲା#,
				'standard' => q#କଲମ୍ବିୟା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#କୁକ ଦିପ ଆଦ୍ଦା କାରାଁ ବେଲା#,
				'generic' => q#କୁକ ଦିପ ବେଲା#,
				'standard' => q#କୁକ ଦିପ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#କ୍ୱୁବା ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#କ୍ୱୁବା ବେଲା#,
				'standard' => q#କ୍ୱୁବା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#ଡେବିସ୍ ବେଲା#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ଡ୍ୟୁମାଣ୍ଟ ଡି ଅରୱିଲେ ବେଲା#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#ୱେଡ଼ାହପୁ ତିମର ବେଲା#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ଇସ୍ଟର ଦିପ କାରାଁ ବେଲା#,
				'generic' => q#ଇସ୍ଟର ଦିପ ବେଲା#,
				'standard' => q#ଇସ୍ଟର ଦିପ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ଇକ୍ୱାଡର ବେଲା#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ସମାନି ଜାଗା ପ୍ରୁତି ବେଲା#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ପୁଣ୍ଆଁ ତି ଗାଡ଼ା#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#ଆମଷ୍ଟ୍ରେଡାମ୍#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#ଆଣ୍ଡରା#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#ଆସ୍‍ଟରାକାନ#,
		},
		'Europe/Athens' => {
			exemplarCity => q#ଏତେନ୍ସ#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#ବେଲଗ୍ରେଡେ#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#ବର୍ଲିନ୍#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#ବ୍ରାଟିସଲାୱା#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#ବ୍ରୁସିଲ୍‍ସ#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#ବୁଚାରେସ୍ଟ#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#ବୁଡାପେସ୍ଟ#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#ବୁସିନଗେନ୍#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#ଚିସିନାଉ#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#କପେନହାଗେନ୍#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#ଡବଲିନ୍#,
			long => {
				'daylight' => q#ଆଇରିସ୍ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#ଜିବ୍ରାଲଟର୍‌#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#ଗୁଏରନସେ#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#ହେଲସିନକି#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#ଆଇଲ୍ ଅପ୍ ମ୍ୟାନ୍#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#ଇସ୍ତାନବୁଲ#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#ଜର୍ସି#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#କାଲିନିନଗ୍ରାଡ୍#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#କିଏଭ୍#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#କିରୱ#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#ଲିସବୋନ୍#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#ଲଜୁବ୍ଲଜାନ୍#,
		},
		'Europe/London' => {
			exemplarCity => q#ଲଣ୍ଡନ୍#,
			long => {
				'daylight' => q#ବ୍ରିଟିଶ୍‌ କାରାଁ ବେଲା#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#ଲକ୍ସମବର୍ଗ#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#ମାଡ୍ରିଡ୍#,
		},
		'Europe/Malta' => {
			exemplarCity => q#ମାଲଟା#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#ମାରିୟାହେମ#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#ମିନସ୍କ#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#ମନାକ#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#ମସ୍କ#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#ଅସଲୋ#,
		},
		'Europe/Paris' => {
			exemplarCity => q#ପେରିସ୍#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#ପଡଗରିକା#,
		},
		'Europe/Prague' => {
			exemplarCity => q#ପ୍ରାଗ୍#,
		},
		'Europe/Riga' => {
			exemplarCity => q#ରିଗା#,
		},
		'Europe/Rome' => {
			exemplarCity => q#ରମ୍#,
		},
		'Europe/Samara' => {
			exemplarCity => q#ସାମାରା#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#ସାନ୍ ମାରିନୋ#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#ସାରାଜେବ#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#ସାରାଟୱ୍#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#ସିମଫେରପଲ୍#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#ସ୍କପୟେ#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#ସପିୟା#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#ସ୍ଟକ୍ ହମ୍‌#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#ଟାଲିନ୍ନ#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#ଟାଇରେନ୍#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#ୟୁଲୟାନୱସ୍କ#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#ବାଡୁଜ#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#ୱାଟିକାନ୍#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#ୱିଏନା#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#ୱିଲନିଉସ୍#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#ୱଲଗଗ୍ରାଡ୍#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#ୱାରସୱା#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#ଜାଗ୍ରେବ୍#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#ଜୁରିକ୍#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ମାଦିନା ୟୁରପିଆ ତି କାରାଁ ବେଲା#,
				'generic' => q#ମାଦିନି ୟୁରପିଆ ତି ବେଲା#,
				'standard' => q#ମାଦିନି ୟୁରପିଆ ତି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ୱେଡ଼ାହପୁ ୟୁରପିଆତି କାରାଁ ବେଲା#,
				'generic' => q#ୱେଡ଼ା ହପୁ ୟୁରପତି ବେଲା#,
				'standard' => q#ୱେଡ଼ାହପୁ ୟୁରପିଆତି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ଅର ୱେଡ଼ାହପୁ ୟୁରପତି ବେଲା#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ୱେଡ଼ାକୁଣ୍‍ପୁ ୟୁରପତି କାରାଁ ବେଲା#,
				'generic' => q#ୱେଡ଼ାକୁଣ୍‍ପୁ ୟୁରପତି ବେଲା#,
				'standard' => q#ୱେଡ଼ାକୁଣ୍‍ପୁ ୟୁରପିଆତି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ପାକଲାଣ୍ଡ ଦିପତି କାରାଁ ବେଲା#,
				'generic' => q#ପାକଲାଣ୍ଡ ଦିପ ବେଲା#,
				'standard' => q#ପାକଲାଣ୍ଡ ଦିପତି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#ପିଜି କାରାଁ ବେଲା#,
				'generic' => q#ପିଜି ବେଲା#,
				'standard' => q#ପିଜି ମାନାଙ୍କ ବେଲା#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ପ୍ରେଞ୍ଚ୍ ଗୁୟାନା ବେଲା#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#ପ୍ରେଞ୍ଚ ଦକିଣ ଅଡ଼େ ଆଣ୍ଟାରଟିକ ବେଲା#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ଗ୍ରିନୱିଚ ମିନ ବେଲା#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ଗଲାପଗସ ତି ବେଲା#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#ଗମ୍ବିୟର ବେଲା#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#ଜର୍ଜିୟା କାରା ବେଲା#,
				'generic' => q#ଜର୍ଜିୟା ବେଲା#,
				'standard' => q#ଜର୍ଜିୟା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#ଗିଲ୍‍ବେର୍ଟ ଦିପତି ବେଲା#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#ୱେଡ଼ା ହପୁ ଗ୍ରିନଲାଣ୍ଡ କାରାଁ ବେଲା#,
				'generic' => q#ୱେଡ଼ା ହପୁ ଗ୍ରିନଲାଣ୍ଡ ବେଲା#,
				'standard' => q#ୱେଡ଼ା ହପୁ ଗ୍ରିନଲାଣ୍ଡ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଗ୍ରିନଲାଣ୍ଡ କାରାଁ ବେଲା#,
				'generic' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଗ୍ରିନଲାଣ୍ଡ ବେଲା#,
				'standard' => q#ୱେଡ଼ା କୁଣ୍‍ପୁ ଗ୍ରିନଲାଣ୍ଡ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#ଗଲ୍ପ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#ଗୁୟାନା ବେଲା#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#ହାୱାଇ-ଆଲ୍ୟୁସାନ ଡେ ଲାଇଟ ବେଲା#,
				'generic' => q#ହାୱାଇ-ଆଲ୍ୟୁସାନ ବେଲା#,
				'standard' => q#ହାୱାଇ-ଆଲ୍ୟୁସାନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#ହଙ୍ଗ କଙ୍କ କାରାଁ ବେଲା#,
				'generic' => q#ହଙ୍ଗ କଙ୍ଗ ବେଲା#,
				'standard' => q#ହଙ୍ଗ କଙ୍ଗ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#ହୱଡ କାରାଁ ବେଲା#,
				'generic' => q#ହୱଡ ବେଲା#,
				'standard' => q#ହୱଡ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'India' => {
			long => {
				'standard' => q#ବାରତ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#ଆଣ୍ଟାନାନାରିଭ#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#ଚାଗୋସ୍‌#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#ଖ୍ରୀସ୍‍ଟ ମାସ#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#କକସ୍‌#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#କମର#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#କେରଗୁଲେନ#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#ମାହେ#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#ମାଳଦ୍ୱୀପ#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#ମରିସସ୍#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#ମାୟଟେ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#ରିୟୁନିଅନ୍‌#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#ବାରତ କାଜା ସାମୁଦ୍ରି ବେଲା#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#ଇଣ୍ଡଚିନା ବେଲା#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#ମାଦିନି ଇଣ୍ଡନେସିଆ ବେଲା#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#ୱେଡ଼ାହପୁ ଇଣ୍ଡନେସିଆ ବେଲା#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#ୱେଡ଼ାକୁଣ୍ପୁ ଇଣ୍ଡନେସିଆ ବେଲା#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ଇରାନ ଡେ ଲାଇଟ୍ ବେଲା#,
				'generic' => q#ଇରାନ ବେଲା#,
				'standard' => q#ଇରାନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ଇରକୁସ୍ତକ କାରାଁ ବେଲା#,
				'generic' => q#ଇରକୁସ୍ତକ ବେଲା#,
				'standard' => q#ଇରକୁସ୍ତକ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ଇଜରାଇଲ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ଇଜରାଇଲ ବେଲା#,
				'standard' => q#ଇଜରାଇଲ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#ଜାପାନ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ଜାପାନ ବେଲା#,
				'standard' => q#ଜାପାନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#କଜାକାସ୍ତାନ ବେଲା#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#ୱେଡ଼ାହପୁ କଜାକାସ୍ତାନ ବେଲା#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#ୱେଡ଼ାକୁଣ୍ପୁ କଜାକାସ୍ତାନ ବେଲା#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#କରିୟା ଡେଲାଇଟ ବେଲା#,
				'generic' => q#କରିୟା ବେଲା#,
				'standard' => q#କରିୟା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#କସରାଏ ବେଲା#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#କ୍ରାସ୍ନାର୍ସ୍କ କାରାଁ ବେଲା#,
				'generic' => q#କ୍ରାସ୍ନୟାର୍ସ୍କ ବେଲା#,
				'standard' => q#କ୍ରାସ୍ନୟାର୍ସ୍କ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#କିର୍ଗିସ୍ତାନ ବେଲା#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#ଲାଇନ ଦିପତି ବେଲା#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#ଲର୍ଡ ହୱେ ଡେଲାଇଟ୍ ବେଲା#,
				'generic' => q#ଲର୍ଡ ହୱେ ବେଲା#,
				'standard' => q#ଲର୍ଡ ହୱେ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#ମାଗାଦାନ କାରାଁ ବେଲା#,
				'generic' => q#ମାଗାଦାନ ଦିପ ବେଲା#,
				'standard' => q#ମାଗାଦାନ ମାନଙ୍କ ବେଲା#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#ମାଲେସିୟା ବେଲା#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#ମାଲଡ୍ୱିସ୍ ବେଲା#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#ମାର୍କସସ ବେଲା#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#ମାର୍ସାଲ ଦିପ ବେଲା#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ମରିସସ୍ କାରାଁ ବେଲା#,
				'generic' => q#ମରିସସ୍ ବେଲା#,
				'standard' => q#ମରିସସ୍ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#ମାୱସନ ବେଲା#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#ମେକ୍ସିକତି ପେସିପିକ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ମେକ୍ସିକତି ପେସିପିକ ବେଲା#,
				'standard' => q#ମେକ୍ସିକତି ପେସିପିକ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ଉଲାନ ବଟର କାରାଁ ବେଲା#,
				'generic' => q#ଉଲାନ ବଟର ବେଲା#,
				'standard' => q#ଉଲାନ ବଟର ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ମସ୍କ କାରାଁ ବେଲା#,
				'generic' => q#ମସ୍କ ବେଲା#,
				'standard' => q#ମସ୍କ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#ମ୍ୟାଁମାର ବେଲା#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#ନଉରୁ ବେଲା#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#ନେପାଲ ବେଲା#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#ନ୍ୟୁ କେଲେଡନିୟା କାରାଁ ବେଲା#,
				'generic' => q#ନ୍ୟୁ କେଲେଡନିୟା ବେଲା#,
				'standard' => q#ନ୍ୟୁ କେଲେଡନିୟା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#ନ୍ୟୁଜିଲାଣ୍ଡ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ନ୍ୟୁଜିଲାଣ୍ଡ ବେଲା#,
				'standard' => q#ନ୍ୟୁଜିଲାଣ୍ଡ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#ନ୍ୟୁପାଉଣ୍ଡଲାଣ୍ଡ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ନ୍ୟୁପାଉଣ୍ଡଲାଣ୍ଡ ବେଲା#,
				'standard' => q#ନ୍ୟୁପାଉଣ୍ଡଲାଣ୍ଡ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#ନିୟୁ ବେଲା#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#ନରପାଁକ ଦିପ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ନରପାଁକ ଦିପ ବେଲା#,
				'standard' => q#ନରପାଁକ ଦିପ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ପର୍ନାଡ ଡେ ନରହ୍ନ କାରାଁ ବେଲା#,
				'generic' => q#ପେର୍ନାଡ ଡେ ନରହ୍ନ ବେଲା#,
				'standard' => q#ପର୍ନାଡ ଡେ ନରହ୍ନ ମାନାଙ୍କା ବେଲା#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#ନୱସିବର୍ସ୍କ କାରାଁ ବଲା#,
				'generic' => q#ନୱସିବିର୍ସ୍କ ବେଲା#,
				'standard' => q#ନୱସିବିର୍ସ୍କ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ଅମସ୍କ କାରାଁ ବେଲା#,
				'generic' => q#ଅମସ୍କ ବେଲା#,
				'standard' => q#ଅମସ୍କ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#ଆପିଆ#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#ଅକଲାଣ୍ଡ#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#ବଗେନ୍‌ୱିଲ୍ଲେ#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#ଚାତାମ୍‌#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#ଇଷ୍ଟର୍‌#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#ଇଫେଟ୍‌#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#ପକାଅପ#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#ପିଜି#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#ଫୁନାଫୁଟି#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#ଗାଲାପାଗସ#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#ଗାମ୍ବିୟର୍‌#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#ଗୁଆଡାଲକାନାଲ#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#ଗୁଆମ#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#କେଣ୍ଟନ#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#କିରିତିମାଟି#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#କୋସରେଇ#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#କ୍ୱାଜାଲେଇନ୍#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#ମାଜୁର#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#ମାର୍କ୍ୱେସାସ୍‌#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#ମିଡ୍‌ୱେ#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#ନାଉରୁ#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#ନିୟୂ#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#ନରପକ୍‌#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#ନଉମିୟ#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#ପାଗୋ ପାଗୋ#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#ପାଲାଉ#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#ପିଟକାରିନ୍‌#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#ପହନପେଇ#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#ପର୍ଟ୍‌ ମରେସବି#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#ରାରଟଙ୍ଗା#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#ସାଇପାନ୍#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#ତାହିତି#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#ତାରୱା#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#ଟଙ୍ଗାଟାପୁ#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#ଚୂକ୍‌#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#ୱେକ୍#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#ୱାଲିସ୍‌#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#ପାକିସ୍ତାନ କାରାଁ ବେଲା#,
				'generic' => q#ପାକିସ୍ତାନ ବେଲା#,
				'standard' => q#ପାକିସ୍ତାନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#ପଲାଉ ବେଲା#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#ପାପୁୟା ପୁନି ଗିନି ବେଲା#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#ପେରାଗ୍ୱେ କାରାଁ ବେଲା#,
				'generic' => q#ପେରାଗ୍ୱେ ବେଲା#,
				'standard' => q#ପେରାଗ୍ୱେ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#ପେରୁ କାରାଁ ବେଲା#,
				'generic' => q#ପେରୁ ବେଲା#,
				'standard' => q#ପେରୁ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#ପିଲିପିନ କାରାଁ ବେଲା#,
				'generic' => q#ପିଲିପିନ ବେଲା#,
				'standard' => q#ପିଲିପିନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#ପିନିକ୍ସ ଦିପତି ବେଲା#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#ସେଣ୍ଟ ପିଏରେ ଅଡ଼େ ମିକ୍ୱେଲାନ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ସେଣ୍ଟ ପିଏରେ ଅଡ଼େ ମିକ୍ୱେଲାନ ବେଲା#,
				'standard' => q#ସେଣ୍ଟ ପିଏରେ ଅଡ଼େ ମିକ୍ୱେଲାନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#ପିଟକଇରନ ବେଲା#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ପନାପେ ବେଲା#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#ପ୍ୟଙ୍ଗୟାଙ୍କ ବେଲା#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#ରିୟୁନିୟନ ବେଲା#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#ରତେରା ବେଲା#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#ସକାଲିନ କାରାଁ ବେଲା#,
				'generic' => q#ସକାଲିନ ବେଲା#,
				'standard' => q#ସକାଲିନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#ସାମଆ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ସାମଆ ବେଲା#,
				'standard' => q#ସାମଆ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#ସେସେଲ୍ସ ବେଲା#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#ସାଙ୍ଗାପୁର ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#ସଲମନ ଦିପତି ବେଲା#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#ଦକିଣ ଜର୍ଜିୟା ବେଲା#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#ସୁରିନାମ ବେଲା#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#ସୱା ବେଲା#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#ତାହିତି ବେଲା#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#ତାଇପେ ଡେଲାଇଟ ବେଲା#,
				'generic' => q#ତାଇପେ ବେଲା#,
				'standard' => q#ତାଇପେ ମାନଙ୍କ ବେଲା#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#ତାଜିକିସ୍ତାନ ବେଲା#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#ଟକେଲାଉ ବେଲା#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#ଟଙ୍ଗା କାରାଁ ବେଲା#,
				'generic' => q#ଟଙ୍ଗା ବେଲା#,
				'standard' => q#ଟଙ୍ଗା ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#ଚୁକ ବେଲା#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ତୁର୍କମେନିସ୍ତାନ କାରାଁ ବେଲା#,
				'generic' => q#ତୁର୍କମେନିସ୍ତାନ ବେଲା#,
				'standard' => q#ତୁର୍କମେନିସ୍ତାନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#ତୁୱାଲୁ ବେଲା#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#ଉରୁଗ୍ୱେ କାରାଁ ବେଲା#,
				'generic' => q#ଉରୁଗ୍ୱେ ବେଲା#,
				'standard' => q#ଉରୁଗ୍ୱେ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ଉଜ୍ୱେକିସ୍ତାନ କାରାଁ ବେଲା#,
				'generic' => q#ଉଜ୍ୱେକିସ୍ତାନ ବେଲା#,
				'standard' => q#ଉଜ୍ୱେକିସ୍ତାନ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#ୱନୁଆତୁ କାରାଁ ବେଲା#,
				'generic' => q#ୱନୁଆତୁ ବେଲା#,
				'standard' => q#ୱନୁଆତୁ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#ୱେନେଜୁଏଲା ବେଲା#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ୱ୍ଲାଦିୱସ୍ତକ କାରାଁ ବେଲା#,
				'generic' => q#ୱ୍ଲାଦିୱସ୍ତକ ବେଲା#,
				'standard' => q#ୱ୍ଲାଦିୱସ୍ତକ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#ୱାଲଗଗ୍ରାଡ କାରାଁ ବେଲା#,
				'generic' => q#ୱାଲଗଗ୍ରାଡ ବେଲା#,
				'standard' => q#ୱାଲଗଗ୍ରାଡ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#ୱସ୍ତକ ବେଲା#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ୱେକ ଦିପ ବେଲା#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#ୱାଲିସ ଅଡ଼େ ପୁଟୁନା ବେଲା#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#ୟାକୁତ୍ସକ କାରାଁ ବେଲା#,
				'generic' => q#ୟାକୁତ୍ସକ ବେଲା#,
				'standard' => q#ୟାକୁତ୍ସକ ମାନାଙ୍କ ବେଲା#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#ୟେକାତେରିନବର୍ଗ କାରାଁ ବେଲା#,
				'generic' => q#ୟେକାତେରିନବର୍ଗ ବେଲା#,
				'standard' => q#ୟେକାତେରିନବର୍ଗ ମାନାଙ୍କ ବେଲା#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
