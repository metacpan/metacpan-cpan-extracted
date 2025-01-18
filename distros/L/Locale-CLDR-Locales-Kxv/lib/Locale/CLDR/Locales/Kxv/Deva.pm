=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kxv::Deva - Package for language Kuvi

=cut

package Locale::CLDR::Locales::Kxv::Deva;
# This file auto generated from Data\common\main\kxv_Deva.xml
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
				'af' => 'आप्रिकान्स',
 				'am' => 'अम्हेरी',
 				'ar' => 'आरॉबिक',
 				'ar_001' => 'पुनिजुगो मानांकॉ आरॉबिक',
 				'as' => 'आसामीस्',
 				'az' => 'अज़रबेजानी',
 				'az@alt=short' => 'अज़ेरी',
 				'be' => 'बेलारूसी',
 				'bg' => 'बुल्गारियाति',
 				'bn' => 'बंगाली',
 				'bo' => 'तिब्बती',
 				'brx' => 'बोडो',
 				'bs' => 'बाॅस्नियाती',
 				'ca' => 'कातालान',
 				'chr' => 'चेरोकी',
 				'cs' => 'चेक',
 				'da' => 'डेनिस',
 				'de' => 'जर्मन',
 				'de_AT' => 'ऑस्ट्रियाति जर्मन',
 				'de_CH' => 'स्विस हाइ ति जर्मन',
 				'doi' => 'डोगरी',
 				'el' => 'ग्रीक',
 				'en' => 'इंराजी',
 				'en_AU' => 'ऑस्ट्रेलियाति इंराजी',
 				'en_CA' => 'कनाडाति इंराजी',
 				'en_GB' => 'ब्रिटिस इंराजी',
 				'en_GB@alt=short' => 'यू॰के॰ राज्यॉ ति इंराजी',
 				'en_US' => 'अमेरिकी इंराजी',
 				'es' => 'स्पानिस',
 				'es_419' => 'लातिन आमेरिका ति स्पेनिस',
 				'es_ES' => 'यूरोपीय ति स्पेनिस',
 				'es_MX' => 'मेक्सिको ति स्पेनिस',
 				'et' => 'एस्टोनियाति',
 				'eu' => 'बास्क',
 				'fa' => 'पर्सियन',
 				'fa_AF' => 'डॉरि',
 				'fi' => 'प़िनिस',
 				'fil' => 'प़िलिपीनो',
 				'fr' => 'प़्रेंच',
 				'fr_CA' => 'कनाडाति प़्रेंच',
 				'fr_CH' => 'स्विस प़्रेंच',
 				'gl' => 'ग्यालिसियन',
 				'gu' => 'गुजराटी',
 				'he' => 'हिब्रू',
 				'hi' => 'हिन्दी',
 				'hi_Latn' => 'हिन्दी (लातिन)',
 				'hr' => 'क्रोएसियाति',
 				'hu' => 'हंगेरियाति',
 				'hy' => 'आर्मेनियाति',
 				'id' => 'इंडोनेसियाति',
 				'is' => 'आइसलेंड िक',
 				'it' => 'इताली ती',
 				'ja' => 'जापानीज',
 				'ka' => 'जॉर्जियाति',
 				'kk' => 'कज़ाक़',
 				'km' => 'कमेर',
 				'kn' => 'कन्नड़',
 				'ko' => 'कोरियाति',
 				'kok' => 'कोंकणी',
 				'ks' => 'कस्मीरी',
 				'kxv' => 'कुवि',
 				'ky' => 'किर्गीज़',
 				'lo' => 'लाओ',
 				'lt' => 'लितुआनियाति',
 				'lv' => 'लातवियाति',
 				'mai' => 'मेतिली',
 				'mk' => 'मकदूनियाति',
 				'ml' => 'मलयालम',
 				'mn' => 'मंगोलियाति',
 				'mni' => 'मणिपुरी',
 				'mr' => 'मराठी',
 				'ms' => 'मलय',
 				'my' => 'बर्मीज़',
 				'nb' => 'नॉर्वेजियाति बोकमाल',
 				'ne' => 'नेपाली',
 				'nl' => 'डच',
 				'nl_BE' => 'प़्लेमिस',
 				'or' => 'उड़िया',
 				'pa' => 'पंजाबी',
 				'pl' => 'पोलिस',
 				'pt' => 'पुर्तगाली',
 				'pt_BR' => 'ब्राज़ीली पुर्तगाली',
 				'pt_PT' => 'यूरोपीय पुर्तगाली',
 				'ro' => 'रोमानियाति',
 				'ro_MD' => 'मोलडावियन',
 				'ru' => 'रुसिया ति',
 				'sa' => 'संस्कृत',
 				'sat' => 'संताली',
 				'sd' => 'सिंधी',
 				'si' => 'सिंहली',
 				'sk' => 'स्लोवाक',
 				'sl' => 'स्लोवेनियाति',
 				'sq' => 'अल्बानियाति',
 				'sr' => 'सर्बियाति',
 				'sv' => 'स्वीडिस',
 				'sw' => 'स्वाहिली',
 				'sw_CD' => 'कांगो स्वाहिली',
 				'ta' => 'तमिल',
 				'te' => 'तेलुगू',
 				'th' => 'ताई',
 				'tr' => 'तुर्की',
 				'uk' => 'यूक्रेनियाति',
 				'ur' => 'उर्दू',
 				'uz' => 'उज़्बेक',
 				'vi' => 'वियतनामी',
 				'zh' => 'चीनी',
 				'zh@alt=menu' => 'चीनी, मेंडेरिन',
 				'zh_Hans' => 'साॅहाॅजाॅ चीनी',
 				'zh_Hans@alt=long' => 'साॅहाॅजाॅ मेंडेरिन चीनी',
 				'zh_Hant' => 'हिरूदोल्लु चीनी',
 				'zh_Hant@alt=long' => 'हिरूदोल्लु मेंडेरिन चीनी',
 				'zu' => 'ज़ुलू',

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
 			'Beng' => 'बंगाली',
 			'Brah' => 'ब्राह्मि',
 			'Cher' => 'चेरोकी',
 			'Cyrl' => 'सिरिलिक',
 			'Deva' => 'देवनागरी',
 			'Gujr' => 'गुजराती',
 			'Guru' => 'गुरमुकी',
 			'Hans' => 'साॅहाॅजाॅ',
 			'Hans@alt=stand-alone' => 'साॅहाॅजाॅ हान',
 			'Hant' => 'हिरूदोल्लु',
 			'Hant@alt=stand-alone' => 'हिरूदोल्लु हान',
 			'Knda' => 'कन्नड़',
 			'Latn' => 'लातिन',
 			'Mlym' => 'मलयालम',
 			'Orya' => 'ऑड़िया',
 			'Saur' => 'सॉउराष्ट्र',
 			'Taml' => 'तमिल',
 			'Telu' => 'तेलुगू',
 			'Zxxx' => 'राचा-आ-आत्ति',
 			'Zzzz' => 'पुण्-आँऽति ऑकाॅराॅ',

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
			'001' => 'राजि, पृती',
 			'419' => 'लातिन आमेरिका ति',
 			'AD' => 'अंडोरा',
 			'AE' => 'आण्डी ति अरब एमिरेट्स',
 			'AF' => 'अप़गानिस्तान',
 			'AG' => 'एंटिगुआ ऑड़े बरबुडा',
 			'AI' => 'एंग्विला',
 			'AL' => 'अल्बानिया',
 			'AM' => 'आर्मेनिया',
 			'AO' => 'अंगोला',
 			'AQ' => 'अंटार्कटिका',
 			'AR' => 'अर्जेंटीना',
 			'AS' => 'आमेरिका-ति समोआ',
 			'AT' => 'ऑस्ट्रिया',
 			'AU' => 'ऑस्ट्रेलिया',
 			'AW' => 'अरूबा',
 			'AX' => 'एलेंड द्वीप',
 			'AZ' => 'अज़रबेजान',
 			'BA' => 'बोस्निया ऑड़े हर्ज़ेगोविना',
 			'BB' => 'बारबाडोस',
 			'BD' => 'बांग्लादेस',
 			'BE' => 'बेल्जियम',
 			'BF' => 'बुर्किना प़ासो',
 			'BG' => 'बुल्गारिया',
 			'BH' => 'बहरीन',
 			'BI' => 'बुरुंडी',
 			'BJ' => 'बेनिन',
 			'BL' => 'सेंट बार्तेलेमी',
 			'BM' => 'बरमूडा',
 			'BN' => 'ब्रूनेई',
 			'BO' => 'बोलीविया',
 			'BQ' => 'केरिबियन नीदरलेंड',
 			'BR' => 'ब्राज़ील',
 			'BS' => 'बहामास',
 			'BT' => 'बुटान',
 			'BW' => 'बोत्स्वाना',
 			'BY' => 'बेलारूस',
 			'BZ' => 'बेलीज़',
 			'CA' => 'कानाडा',
 			'CC' => 'कोकोस (कीलिंग) द्वीप',
 			'CD' => 'कांगो - किंसासा',
 			'CD@alt=variant' => 'कांगो (डीआरसी)',
 			'CF' => 'मध्य अप़्रीकी गणराज्य',
 			'CG' => 'कांगो – ब्राज़ाविल',
 			'CG@alt=variant' => 'कांगो (गणराज्य)',
 			'CH' => 'स्विट्ज़रलेंड',
 			'CI' => 'कोट डी वोआ',
 			'CI@alt=variant' => 'आइवरी कोस्ट',
 			'CK' => 'कुक द्वीप',
 			'CL' => 'चिली',
 			'CM' => 'केमरून',
 			'CN' => 'चीन',
 			'CO' => 'कोलंबिया',
 			'CR' => 'कोस्टारिका',
 			'CU' => 'क्यूबा',
 			'CV' => 'केप वर्ड',
 			'CW' => 'क्यूरासाओ',
 			'CX' => 'क्रिसमस द्वीप',
 			'CY' => 'साइप्रस',
 			'CZ' => 'चेकिया',
 			'CZ@alt=variant' => 'चेक गणराज्य',
 			'DE' => 'जर्मनी',
 			'DG' => 'डिएगो गार्सिया',
 			'DJ' => 'जिबूती',
 			'DK' => 'डेनमार्क',
 			'DM' => 'डोमिनिका',
 			'DO' => 'डोमिनिकन गणराज्य',
 			'DZ' => 'अल्जीरिया',
 			'EA' => 'सेउटा ऑड़े मेलिला',
 			'EC' => 'इक्वाडोर',
 			'EE' => 'एस्टोनिया',
 			'EG' => 'मिस्र',
 			'EH' => 'वेड़ा कुण्पु सहारा',
 			'ER' => 'इरिट्रिया',
 			'ES' => 'स्पेन',
 			'ET' => 'इतियोपिया',
 			'FI' => 'प़िनलेंड',
 			'FJ' => 'प़िजी',
 			'FK' => 'प़ॉकलेंड द्वीप',
 			'FK@alt=variant' => 'प़ॉकलेंड द्वीप (इज़्लास माल्विनास)',
 			'FM' => 'माइक्रोनेसिया',
 			'FO' => 'पेरो दीप',
 			'FR' => 'प़्रांस',
 			'GA' => 'ग्याबॉन',
 			'GB' => 'यूनाइटेड किंगडम',
 			'GB@alt=short' => 'यू॰के॰',
 			'GD' => 'ग्रेनाडा',
 			'GE' => 'जॉर्जिया',
 			'GF' => 'प़्रेंच गुयाना',
 			'GG' => 'गर्नसी',
 			'GH' => 'गाना',
 			'GI' => 'जिब्राल्टर',
 			'GL' => 'ग्रीनलेंड',
 			'GM' => 'गाम्बिया',
 			'GN' => 'गिनी',
 			'GP' => 'ग्वाडेलूप',
 			'GQ' => 'इक्वेटोरियल गिनी',
 			'GR' => 'यूनान',
 			'GS' => 'दकिण जॉर्जिया अड़े दकिण सैंडविच दीप',
 			'GT' => 'ग्वाटेमाला',
 			'GU' => 'गुआम',
 			'GW' => 'गिनी-बिसाउ',
 			'GY' => 'गुयाना',
 			'HK' => 'हाँग काँग (एस ए आर चीन)',
 			'HK@alt=short' => 'हाँग काँग',
 			'HN' => 'होंडूरास',
 			'HR' => 'क्रोएसिया',
 			'HT' => 'हाइती',
 			'HU' => 'हंगरी',
 			'IC' => 'केनेरी द्वीप',
 			'ID' => 'इंडोनेसिया',
 			'IE' => 'आयरलेंड',
 			'IL' => 'इज़राइल',
 			'IM' => 'आइल ऑप़ मेन',
 			'IN' => 'बारत',
 			'IO' => 'ब्रिटिस हिंद सामुद्रि हांडि',
 			'IQ' => 'इराक',
 			'IR' => 'ईरान',
 			'IS' => 'आइसलेंड',
 			'IT' => 'इटली',
 			'JE' => 'जर्सी',
 			'JM' => 'जमेका',
 			'JO' => 'जॉर्डन',
 			'JP' => 'जापान',
 			'KE' => 'केन्या',
 			'KG' => 'किर्गिज़स्तान',
 			'KH' => 'कंबोडिया',
 			'KI' => 'किरिबाती',
 			'KM' => 'कोमोरोस',
 			'KN' => 'सेंट किट्स ऑड़े नेविस',
 			'KP' => 'उतर कोरिया',
 			'KR' => 'दॉकिण कोरिया',
 			'KW' => 'कुवेत',
 			'KY' => 'केमेन द्वीप',
 			'KZ' => 'कज़ाकस्तान',
 			'LA' => 'लाओस',
 			'LB' => 'लेबनान',
 			'LC' => 'सेंट लूसिया',
 			'LI' => 'लिक्टेन्स्टीन',
 			'LK' => 'स्रीलंका',
 			'LR' => 'लाइबेरिया',
 			'LS' => 'लेसोतो',
 			'LT' => 'लितुआनिया',
 			'LU' => 'लग्ज़मबर्ग',
 			'LV' => 'लातविया',
 			'LY' => 'लीबिया',
 			'MA' => 'मोरक्को',
 			'MC' => 'मोनाको',
 			'MD' => 'मॉल्डोवा',
 			'ME' => 'मोंटेनेग्रो',
 			'MF' => 'सेंट मार्टिन',
 			'MG' => 'मेडागास्कर',
 			'MH' => 'मार्सल द्वीप',
 			'MK' => 'उतॉरॉ मकदूनिया',
 			'ML' => 'माली',
 			'MM' => 'म्यांमार (बर्मा)',
 			'MN' => 'मंगोलिया',
 			'MO' => 'मकाऊ (एस ए आर चीन)',
 			'MO@alt=short' => 'मकाऊ',
 			'MP' => 'उतॉरॉ मारियाना द्वीप',
 			'MQ' => 'मार्टीनिक',
 			'MR' => 'मॉरिटानिया',
 			'MS' => 'मोंटसेरात',
 			'MT' => 'माल्टा',
 			'MU' => 'मॉरीसस',
 			'MV' => 'मालदीप',
 			'MW' => 'मलावी',
 			'MX' => 'मेक्सिको',
 			'MY' => 'मलेसिया',
 			'MZ' => 'मोज़ांबिक',
 			'NA' => 'नामीबिया',
 			'NC' => 'न्यू केलेडोनिया',
 			'NE' => 'नाइजर',
 			'NF' => 'नॉरप़ॉक द्वीप',
 			'NG' => 'नाइजीरिया',
 			'NI' => 'निकारागुआ',
 			'NL' => 'नीदरलेंड',
 			'NO' => 'नॉर्वे',
 			'NP' => 'नेपाल',
 			'NR' => 'नाउरु',
 			'NU' => 'नीयू',
 			'NZ' => 'न्यूज़ीलेंड',
 			'OM' => 'ओमान',
 			'PA' => 'पनामा',
 			'PE' => 'पेरू',
 			'PF' => 'प़्रेंच पोलिनेसिया',
 			'PG' => 'पापुआ न्यू गिनी',
 			'PH' => 'प़िलिपींस',
 			'PK' => 'पाकिस्तान',
 			'PL' => 'पोलेंड',
 			'PM' => 'सेंट पिएरे ऑड़े मिक्वेलान',
 			'PN' => 'पिटकेर्न द्वीप',
 			'PR' => 'पोर्टो रिको',
 			'PS' => 'प़िलिस्तीनी क्षेत्र',
 			'PS@alt=short' => 'प़िलिस्तीन',
 			'PT' => 'पुर्तगाल',
 			'PW' => 'पलाऊ',
 			'PY' => 'पराग्वे',
 			'QA' => 'क़तर',
 			'RE' => 'रियूनियन',
 			'RO' => 'रोमानिया',
 			'RS' => 'सर्बिया',
 			'RU' => 'रूस',
 			'RW' => 'र्-वांडा',
 			'SA' => 'सऊदी अरब',
 			'SB' => 'सोलोमन द्वीप',
 			'SC' => 'सेसेल्स',
 			'SD' => 'सूडान',
 			'SE' => 'स्वीडन',
 			'SG' => 'सिंगापुर',
 			'SH' => 'सेंट हेलेना',
 			'SI' => 'स्लोवेनिया',
 			'SJ' => 'स्वालबार्ड ऑड़े जान मायेन',
 			'SK' => 'स्लोवाकिया',
 			'SL' => 'सिएरा लियोन',
 			'SM' => 'सेन मेरीनो',
 			'SN' => 'सेनेगल',
 			'SO' => 'सोमालिया',
 			'SR' => 'सूरीनाम',
 			'SS' => 'दॉकिण सूडान',
 			'ST' => 'साओ टोम ऑड़े प्रिंसिपे',
 			'SV' => 'अल सल्वाडोर',
 			'SX' => 'सिंट माऽरतेन',
 			'SY' => 'सीरिया',
 			'SZ' => 'एस्वाटिनी',
 			'SZ@alt=variant' => 'स्वाज़ीलेंड',
 			'TC' => 'तुर्क ऑड़े केकोज़ द्वीप',
 			'TD' => 'चाड',
 			'TF' => 'प्रेंच दकिनी टेरिटोरी',
 			'TG' => 'टोगो',
 			'TH' => 'ताईलेंड',
 			'TJ' => 'तजाकिस्तान',
 			'TK' => 'तोकेलाउ',
 			'TL' => 'तिमोर-लेस्त',
 			'TL@alt=variant' => 'वेड़ा हॉपु तिमोर',
 			'TM' => 'तुर्कमेनिस्तान',
 			'TN' => 'ट्यूनीसिया',
 			'TO' => 'टोंगा',
 			'TR' => 'तुर्की',
 			'TT' => 'त्रिनिदाद ऑड़े टोबेगो',
 			'TV' => 'तुवालू',
 			'TW' => 'ताइवान',
 			'TZ' => 'तंज़ानिया',
 			'UA' => 'यूक्रेन',
 			'UG' => 'युगांडा',
 			'UM' => 'यू॰एस॰ आउटलाइंग द्वीप',
 			'US' => 'आण्डि ति राज्यॉ',
 			'US@alt=short' => 'यू॰एस॰',
 			'UY' => 'उरूग्वे',
 			'UZ' => 'उज़्बेकिस्तान',
 			'VA' => 'बाटिकान सिटी',
 			'VC' => 'सेंट विंसेंट ऑड़े ग्रेनाडाइंस',
 			'VE' => 'वेनेज़ुएला',
 			'VG' => 'ब्रिटिस वर्जिन द्वीप',
 			'VI' => 'यू॰एस॰ वर्जिन द्वीप',
 			'VN' => 'वियतनाम',
 			'VU' => 'वनुआतू',
 			'WF' => 'वालिस ऑड़े प़्यूचूना',
 			'WS' => 'समोआ',
 			'XK' => 'कोसोवो',
 			'YE' => 'यमन',
 			'YT' => 'मायोते',
 			'ZA' => 'दॉकिण आप़्रीका',
 			'ZM' => 'ज़ाम्बिया',
 			'ZW' => 'ज़िम्बाब्वे',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'केलेंडर',
 			'cf' => 'टाकाँ पॉरॉमाटो',
 			'collation' => 'मिला क्रॉमॉ',
 			'currency' => 'टाकाँ',
 			'hc' => 'वेड़ाति गिला (१२ ऑड़े २४)',
 			'lb' => 'धाड़ी लिनी आड़ा',
 			'ms' => 'लाटिनि लेका',
 			'numbers' => 'सॉङ्क्या',

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
 				'gregorian' => q{ग्रेगोरियन केलेंडर},
 				'indian' => q{बारॉतॉ जातियॉ केलेंडर},
 			},
 			'cf' => {
 				'standard' => q{मानांकॉ टाकाँ रुपॉ},
 			},
 			'collation' => {
 				'ducet' => q{डिप़ॉल्ट यूनिकोड सॉर्ट लेँ},
 				'phonebook' => q{फॉन्-वॉहि सॉर्ट लेँ},
 				'search' => q{सामानि-उद्देस्य पारिनॉ},
 				'standard' => q{मानांकॉ सॉर्ट लेँ},
 			},
 			'hc' => {
 				'h11' => q{१२ गॉन्ता ति पॉद्दॉति (0–११)},
 				'h12' => q{१२ गॉन्ता ति पॉद्दॉति (१–१२)},
 				'h23' => q{२४ गॉन्ता ति पॉद्दॉति (0–२३)},
 				'h24' => q{२४ गॉन्ता ति पॉद्दॉति (१–२४)},
 			},
 			'ms' => {
 				'metric' => q{मेट्रिक पॉद्दॉति},
 				'uksystem' => q{सामराज्यॉ ति आटिनि मापॉ पॉद्दॉति},
 				'ussystem' => q{आमेरिका ति मापॉ पॉद्दॉति},
 			},
 			'numbers' => {
 				'arab' => q{आरॉबिक-बारतीय नॉम्बर},
 				'arabext' => q{नॉकि-आति आरॉबिक-बारतीय नॉम्बर},
 				'beng' => q{बंगाली नॉम्बर},
 				'deva' => q{देवनागरी नॉम्बर},
 				'gujr' => q{गुजराती नॉम्बर},
 				'guru' => q{गुरमुकी नॉम्बर},
 				'knda' => q{कन्नड़ नॉम्बर},
 				'latn' => q{वेड़ा कुण्पु नॉम्बर},
 				'mlym' => q{मलयालम नॉम्बर},
 				'orya' => q{ऑड़िया नॉम्बर},
 				'roman' => q{रोमन नॉम्बर},
 				'romanlow' => q{रोमन मिला गिरा नॉम्बर},
 				'taml' => q{हिरूदोल्लु तामिल नॉम्बर},
 				'tamldec' => q{तामिल नॉम्बर},
 				'telu' => q{तेलुगू नॉम्बर},
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
			'language' => 'काता: {0}',
 			'script' => 'ऑकॉरॉ : {0}',
 			'region' => 'मुट्-हा: {0}',

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
			main => qr{[ँ ंः अ {अऽ} आ {आऽ} इ ई उ ऊ ए {एऽ} ओ {ओऽ} क ग ङ च ज ञ ट ड{ड़} ण त द न प ब म य र ल ळ व स ह ऽ ा ि ी ु ू े ो ्]},
			numbers => qr{[\- ‑ , . % ‰ + 0 १ २ ३ ४ ५ ६ ७ ८ ९]},
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
				end => q({0}, ऑड़े {1}),
				2 => q({0} ऑड़े {1}),
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
		'CNY' => {
			display_name => {
				'currency' => q(चीन ति युआन),
				'other' => q(चीन ति युआन),
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
				'currency' => q(ब्रिटिस पाउंड स्टर्लिंग),
				'other' => q(ब्रिटिस पाउंड स्टर्लिंग),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(बारत ति टाकाँ),
				'other' => q(बारत ति टाकाँ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(जापान ति येन),
				'other' => q(जापान ति येन),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(रूस ति रूबल),
				'other' => q(रूस ति रूबल),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(यूएस डॉलर),
				'other' => q(यूएस डॉलर),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(पुण्-आँऽति लेबुँ),
				'other' => q(पुण्-आँऽति लेबुँ),
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
							'पुसु',
							'माहा',
							'पागु',
							'हिर्रे',
							'बेसे',
							'जाट्टा',
							'आसाड़ी',
							'स्राबाँ',
							'बाॅदो',
							'दासारा',
							'दिवी',
							'पान्डे'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'पुसु लेञ्जु',
							'माहाका लेञ्जु',
							'पागुणी लेञ्जु',
							'हिरे लेञ्जु',
							'बेसे लेञ्जु',
							'जाटा लेञ्जु',
							'आसाड़ी लेञ्जु',
							'स्राबाँ लेञ्जु',
							'बोदो लेञ्जु',
							'दसारा लेञ्जु',
							'दिवी लेञ्जु',
							'पान्डे लेञ्जु'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'पु',
							'मा',
							'पा',
							'हि',
							'बे',
							'जा',
							'आ',
							'स्रा',
							'बाॅ',
							'दा',
							'दि',
							'पा'
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
						mon => 'साॅम्मा',
						tue => 'मान्गा',
						wed => 'पूदा',
						thu => 'लाक्की',
						fri => 'सुकुरु',
						sat => 'सान्नि',
						sun => 'आदि'
					},
					narrow => {
						mon => 'साॅ',
						tue => 'मा',
						wed => 'पू',
						thu => 'ला',
						fri => 'सु',
						sat => 'सा',
						sun => 'आ'
					},
					short => {
						mon => 'साॅ',
						tue => 'मा',
						wed => 'पू',
						thu => 'ला',
						fri => 'सु',
						sat => 'सा',
						sun => 'आ'
					},
					wide => {
						mon => 'साॅम्वारा',
						tue => 'मंगाड़ा',
						wed => 'पुद्दारा',
						thu => 'लाक्कि वारा',
						fri => 'सुकुरु वारा',
						sat => 'सान्नि वारा',
						sun => 'आदि वारा'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'साॅ',
						tue => 'मा',
						wed => 'पू',
						thu => 'ला',
						fri => 'सु',
						sat => 'सा',
						sun => 'आ'
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
					abbreviated => {0 => 'क १',
						1 => 'क २',
						2 => 'क ३',
						3 => 'क ४'
					},
					wide => {0 => '१स्ट क्वाटर',
						1 => '२ क्वाटर',
						2 => '३र्ड क्वाटर',
						3 => '४थ क्वाटर'
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
					'am' => q{ए एम},
					'pm' => q{पी एम},
				},
				'narrow' => {
					'am' => q{ए एम},
					'pm' => q{पी एम},
				},
				'wide' => {
					'am' => q{ए एम},
					'pm' => q{पी एम},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ए एम},
					'pm' => q{पी एम},
				},
				'wide' => {
					'am' => q{ए एम},
					'pm' => q{पी एम},
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
				'0' => 'बिसि',
				'1' => 'ए-डि'
			},
			wide => {
				'0' => 'बिफोर क्राइस्ट',
				'1' => 'अन्नो डोमिनी'
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
			'full' => q{{1} आँ {0}},
			'long' => q{{1} आँ {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} आँ {0}},
			'long' => q{{1} आँ {0}},
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
			MMMMW => q{MMMM ताँ वारा W},
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
			yw => q{Y ताँ वारा w},
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
		regionFormat => q({0} बेला),
		regionFormat => q({0} मानांकॉ बेला),
		regionFormat => q({0} डेलाइट बेला),
		'Afghanistan' => {
			long => {
				'standard' => q#आपगानिस्तान बेला#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#अबिदजान#,
		},
		'Africa/Accra' => {
			exemplarCity => q#एक्रा#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#अदीस अबाबा#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#अल्जीयर्स#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#अस्मारा#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#बामाको#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#बांगुइ#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#ब्यान्जुल#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#बिसाऊ#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#ब्लांटायर#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#ब्राज़ाविले#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#बुजुंबूरा#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#कायरो#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#कासाब्लांका#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#सेउटा#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#कोनाक्री#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#डकार#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#दार अस सलाम#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#जिबूती#,
		},
		'Africa/Douala' => {
			exemplarCity => q#डूआला#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#अल आइयून#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#प़्रीटाउन#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#गाबोरोन#,
		},
		'Africa/Harare' => {
			exemplarCity => q#हरारे#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#जोहांसबर्ग#,
		},
		'Africa/Juba' => {
			exemplarCity => q#जुबा#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#कंपाला#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#कार्तुम#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#किगाली#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#किंसासा#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#लागोस#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#लिब्रेविले#,
		},
		'Africa/Lome' => {
			exemplarCity => q#लोम#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#लुआंडा#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#लुबुमबासी#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#लुसाका#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#मलाबो#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#मापुटो#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#मासेरू#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#म्-बाबाने#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#मोगादिसु#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#मोनरोविया#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#नाइरोबि#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#द्जामीना#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#नियामी#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#नुआकचॉट#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#औगाडोगू#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#पोर्टो-नोवो#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#साओ टोम#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#त्रिपोली#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#ट्यूनिस#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#विंडहोक#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#मादिनी आप्रिका बेला#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#वेड़ा हॉपु आप्रिका बेला#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#दक्षिण आप्रिका मानांकॉ बेला#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#पस्चिम आप्रिका काराँ मासा बेला#,
				'generic' => q#पस्चिम आप्रिका बेला#,
				'standard' => q#पस्चिम आप्रिका मानांकॉ बेला#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#अलास्‍का डेलाइट बेला#,
				'generic' => q#अलास्का बेला#,
				'standard' => q#अलास्‍का मानांकॉ बेला#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#अमेज़न काराँ मासा बेला#,
				'generic' => q#अमेज़न बेला#,
				'standard' => q#अमेज़न मानांकॉ बेला#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#अडक#,
		},
		'America/Anchorage' => {
			exemplarCity => q#एंकरेज#,
		},
		'America/Anguilla' => {
			exemplarCity => q#एंग्विला#,
		},
		'America/Antigua' => {
			exemplarCity => q#एंटीगुआ#,
		},
		'America/Araguaina' => {
			exemplarCity => q#आराग्वेना#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#ला रिओजा#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#रियो गालेगोस#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#साल्टा#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#स्यान ह्वान#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#स्यान लूति#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#टोकूमन#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#उसुआइया#,
		},
		'America/Aruba' => {
			exemplarCity => q#अरूबा#,
		},
		'America/Asuncion' => {
			exemplarCity => q#एसनसियॉन#,
		},
		'America/Bahia' => {
			exemplarCity => q#बहिया#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#बेहिया बांडेरास#,
		},
		'America/Barbados' => {
			exemplarCity => q#बारबाडोस#,
		},
		'America/Belem' => {
			exemplarCity => q#बेलेम#,
		},
		'America/Belize' => {
			exemplarCity => q#बेलीज़#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#ब्लां-सेबलोन#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#बोआ विस्ता#,
		},
		'America/Bogota' => {
			exemplarCity => q#बोगोटा#,
		},
		'America/Boise' => {
			exemplarCity => q#बॉइसी#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#ब्यूनस आयरस#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#केम्ब्रिज बे#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#क्याम्पो ग्रांडे#,
		},
		'America/Cancun' => {
			exemplarCity => q#क्यानकुन#,
		},
		'America/Caracas' => {
			exemplarCity => q#काराकस#,
		},
		'America/Catamarca' => {
			exemplarCity => q#काटामार्का#,
		},
		'America/Cayenne' => {
			exemplarCity => q#कायेन#,
		},
		'America/Cayman' => {
			exemplarCity => q#केम्यान#,
		},
		'America/Chicago' => {
			exemplarCity => q#सिकागो#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#चिहुआहुआ#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#अटिकोकान#,
		},
		'America/Cordoba' => {
			exemplarCity => q#कोर्डोबा#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#कोस्टा रिका#,
		},
		'America/Creston' => {
			exemplarCity => q#क्रेस्टन#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#क्यूआबा#,
		},
		'America/Curacao' => {
			exemplarCity => q#कुराकाओ#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#डेनमार्कसॉन#,
		},
		'America/Dawson' => {
			exemplarCity => q#डॉसन#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#डॉसन क्रीक#,
		},
		'America/Denver' => {
			exemplarCity => q#डेनवर#,
		},
		'America/Detroit' => {
			exemplarCity => q#डेट्रॉयट#,
		},
		'America/Dominica' => {
			exemplarCity => q#डोमिनिका#,
		},
		'America/Edmonton' => {
			exemplarCity => q#एडमंटन#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#तिरुनेपे#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#अल सल्वाडोर#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#प़ोर्ट नेल्सन#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#प़ोर्टालेज़ा#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#ग्लेस बे#,
		},
		'America/Godthab' => {
			exemplarCity => q#नुक#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#गूस बे#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#ग्रांड टर्क#,
		},
		'America/Grenada' => {
			exemplarCity => q#ग्रेनाडा#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#ग्वाडेलोप#,
		},
		'America/Guatemala' => {
			exemplarCity => q#ग्वाटेमाला#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#ग्वायाकील#,
		},
		'America/Guyana' => {
			exemplarCity => q#गयाना#,
		},
		'America/Halifax' => {
			exemplarCity => q#हेलिपेक्स#,
		},
		'America/Havana' => {
			exemplarCity => q#हवाना#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#हर्मोसिल्लो#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#नॉक्स, इंडियाना#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#मारेंगो, इंडियाना#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#पीटर्सबर्ग, इंडियाना#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#टेल सिटी, इंडियाना#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#वेवे, इंडियाना#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#विंसेनेस, इंडियाना#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#विनामेक, इंडियाना#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#इंडियानापोलिस#,
		},
		'America/Inuvik' => {
			exemplarCity => q#इनूविक#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#इकालुतिट#,
		},
		'America/Jamaica' => {
			exemplarCity => q#जमाइका#,
		},
		'America/Jujuy' => {
			exemplarCity => q#जुजोए#,
		},
		'America/Juneau' => {
			exemplarCity => q#ज्यूनाउ#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#मोंटीसेलो, केंटकी#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#क्रालेन्डिजिक#,
		},
		'America/La_Paz' => {
			exemplarCity => q#ला पाज़#,
		},
		'America/Lima' => {
			exemplarCity => q#लीमा#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#लॉस एंजिल्स#,
		},
		'America/Louisville' => {
			exemplarCity => q#लुइसविले#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#लोअर प्रिंसेस क्वार्टर#,
		},
		'America/Maceio' => {
			exemplarCity => q#मेसीओ#,
		},
		'America/Managua' => {
			exemplarCity => q#मानागुआ#,
		},
		'America/Manaus' => {
			exemplarCity => q#मनोस#,
		},
		'America/Marigot' => {
			exemplarCity => q#मेरिगोट#,
		},
		'America/Martinique' => {
			exemplarCity => q#मार्टिनिक#,
		},
		'America/Matamoros' => {
			exemplarCity => q#माटामोरोस#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#माज़ाटलान#,
		},
		'America/Mendoza' => {
			exemplarCity => q#मेंडोज़ा#,
		},
		'America/Menominee' => {
			exemplarCity => q#मेनोमिनी#,
		},
		'America/Merida' => {
			exemplarCity => q#मेरिडा#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#मेट्लेकाट्ला#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#मेक्सिको सिटी#,
		},
		'America/Miquelon' => {
			exemplarCity => q#मिकेलॉन#,
		},
		'America/Moncton' => {
			exemplarCity => q#मोंकटन#,
		},
		'America/Monterrey' => {
			exemplarCity => q#मोंटेरेरी#,
		},
		'America/Montevideo' => {
			exemplarCity => q#मोंटेवीडियो#,
		},
		'America/Montserrat' => {
			exemplarCity => q#मोंटसेरात#,
		},
		'America/Nassau' => {
			exemplarCity => q#नासाउ#,
		},
		'America/New_York' => {
			exemplarCity => q#न्यूयॉर्क#,
		},
		'America/Nome' => {
			exemplarCity => q#नोम#,
		},
		'America/Noronha' => {
			exemplarCity => q#नोरोन्हा#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#ब्यूला, उतॉरॉ डकोटा#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#मादिनी उतॉरॉ डकोटा#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#न्यू सालेम, उतॉरॉ डकोटा#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ओकाजीनागा#,
		},
		'America/Panama' => {
			exemplarCity => q#पनामा#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#पारामारिबो#,
		},
		'America/Phoenix' => {
			exemplarCity => q#प़ीनिक्स#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#पोर्ट-ऑ-प्रिंस#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#पोर्ट ऑप़ स्पेन#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#पोर्टो वेल्हो#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#पोर्टो रिको#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#पुंटा एरिनास#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#रेंकिन इनलेट#,
		},
		'America/Recife' => {
			exemplarCity => q#रेसाइप़#,
		},
		'America/Regina' => {
			exemplarCity => q#रेजिना#,
		},
		'America/Resolute' => {
			exemplarCity => q#रिसोल्यूट#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#रियो ब्रांको#,
		},
		'America/Santarem' => {
			exemplarCity => q#सेन्टारेम#,
		},
		'America/Santiago' => {
			exemplarCity => q#सेंतिआगो#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#सेंटो डोमिंगो#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#साओ पाउलो#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#इटोकोर्टोरमिट#,
		},
		'America/Sitka' => {
			exemplarCity => q#सिट्का#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#सेंट बार्तेलेमि#,
		},
		'America/St_Johns' => {
			exemplarCity => q#सेंट जॉन्स#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#सेंट किट्स#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#सेंट लूसिया#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#सेंट तॉमस#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#सेंट विंसेंट#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#स्विप़्ट करंट#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#टेगुसिगल्पा#,
		},
		'America/Thule' => {
			exemplarCity => q#तुले#,
		},
		'America/Tijuana' => {
			exemplarCity => q#तिजुआना#,
		},
		'America/Toronto' => {
			exemplarCity => q#टोरंटो#,
		},
		'America/Tortola' => {
			exemplarCity => q#टोर्टोला#,
		},
		'America/Vancouver' => {
			exemplarCity => q#व्यान्कूवर#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#व्हाइटहोर्स#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#विनीपेग#,
		},
		'America/Yakutat' => {
			exemplarCity => q#याकूटाट#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#मादिनी डेलाइट बेला#,
				'generic' => q#मादिनी बेला#,
				'standard' => q#मादिनी मानांकॉ बेला#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#वेड़ा हॉपु डेलाइट बेला#,
				'generic' => q#वेड़ा हॉपु बेला#,
				'standard' => q#वेड़ा हॉपु मानांकॉ बेला#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#हॉर्का डेलाइट बेला#,
				'generic' => q#हॉर्का बेला#,
				'standard' => q#हॉर्का मानांकॉ बेला#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#पेसिपिक डेलाइट बेला#,
				'generic' => q#पेसिपिक बेला#,
				'standard' => q#पेसिपिक मानांकॉ बेला#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#केसी#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#डेविस#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#ड्यूमोंट डी अर्विले#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#मक्वारी#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#मॉसन#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#म्याकमुर्डो#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#पॉमर#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#रोथेरा#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#स्योवा#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ट्रोल#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#वोस्तोक#,
		},
		'Apia' => {
			long => {
				'daylight' => q#एपिआ डेलाइट बेला#,
				'generic' => q#एपिआ बेला#,
				'standard' => q#एपिआ मानांकॉ बेला#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#अरब डेलाइट बेला#,
				'generic' => q#अरब बेला#,
				'standard' => q#अरब मानांकॉ बेला#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#लॉन्गयरब्येन#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#अर्जेंटीना काराँ मासा बेला#,
				'generic' => q#अर्जेंटीना बेला#,
				'standard' => q#अर्जेंटीना मानांकॉ बेला#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#वेड़ा कुण्पु अर्जेंटीना काराँ मासा बेला#,
				'generic' => q#वेड़ा कुण्पु अर्जेंटीना बेला#,
				'standard' => q#वेड़ा कुण्पु अर्जेंटीना मानांकॉ बेला#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#आर्मेनिया काराँ मासा बेला#,
				'generic' => q#आर्मेनिया बेला#,
				'standard' => q#आर्मेनिया मानांकॉ बेला#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#आदेन#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#अल्माटी#,
		},
		'Asia/Amman' => {
			exemplarCity => q#अम्मान#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#अनाडिर#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#अक्ताउ#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#अक्टोबे#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#अस्गाबात#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#एतराउ#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#बगदाद#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#बहरीन#,
		},
		'Asia/Baku' => {
			exemplarCity => q#बाकु#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#ब्यांगकॉक#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#बर्नोल#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#बेरुत#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#बिस्केक#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#ब्रूनेति#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#कोलकाता#,
		},
		'Asia/Chita' => {
			exemplarCity => q#त्सिता#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#कोलंबो#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#दमास्कस#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ढाका#,
		},
		'Asia/Dili' => {
			exemplarCity => q#डिलि#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#दुबति#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#दुसांबे#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#प़ामागुस्ता#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#गाज़ा#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#हेब्रोन#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#हाँग काँग#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#होव्ड#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#इर्कुत्स्क#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#जकार्ता#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#जयापुरा#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#येरुसलेम#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#काबुल#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#कमचत्का#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#कराची#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#काठमांडू#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#काडिंगा#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#क्रास्नोयार्स्क#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#कुआलालंपुर#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#कूचिंग#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#कुवेत#,
		},
		'Asia/Macau' => {
			exemplarCity => q#मकाऊ#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#मागादान#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#मकस्सर#,
		},
		'Asia/Manila' => {
			exemplarCity => q#मनीला#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#मस्कट#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#निकोसिया#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#नोवोकुज़्नेत्स्क#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#नोवोसिबिर्स्क#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#ओम्स्क#,
		},
		'Asia/Oral' => {
			exemplarCity => q#ओरल#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#पनॉम पेन्ह#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#पोंटीयांक#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#प्योंगयांग#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#कतर#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#कोस्टाने#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#किजिलॉर्डा#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#यांगॉन#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#रियाद#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#हो ची मिन्ह सिटी#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#साकालिन#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#समरकंद#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#सिओल#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#संघाति#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#सिंगापुर#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#स्रेद्निकोलिमस्क#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#तातिपेति#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#तासकंत#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#ट्-बिलिसि#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#तेहरान#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#थिंपू#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#टोक्यो#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#तोम्स्क#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#उलानबातर#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#उरूम्की#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#यूस्ट–नेरा#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#विएनतियान#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#व्लादिवोस्तोक#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#याकूत्स्क#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#येकातेरिनबर्ग#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#येरेवान#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#अटलांटिक डेलाइट बेला#,
				'generic' => q#अटलांटिक बेला#,
				'standard' => q#अटलांटिक मानांकॉ बेला#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#अज़ोरेस#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#बरमूडा#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#क्यानेरी#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#केप वर्ड#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#प्यारो#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#मडेरा#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#रेक्याविक#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#दाॅकिणाॅ जाॅर्जिया#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#सेंट हेलेना#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#स्ट्यानली#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#एडिलेड#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#ब्रिस्बन#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#ब्रोकन हिल#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#डार्विन#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#यूक्ला#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#होबार्ट#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#लिंडेमान#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#लॉर्ड होव#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#मेलबोर्न#,
		},
		'Australia/Perth' => {
			exemplarCity => q#पर्थ#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#सिडनी#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#ऑस्‍ट्रेलियाति मादिनी डेलाइट बेला#,
				'generic' => q#मादिनी ऑस्ट्रेलियाति बेला#,
				'standard' => q#ऑस्‍ट्रेलियाति मादिनी मानांकॉ बेला#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#ऑस्‍ट्रेलियाति मादिनी वेड़ा कुण्पु डेलाइट बेला#,
				'generic' => q#ऑस्‍ट्रेलियाति मादिनी वेड़ा कुण्पु बेला#,
				'standard' => q#ऑस्‍ट्रेलियाति मादिनी वेड़ा कुण्पु मानांकॉ बेला#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#ऑस्‍ट्रेलियाति वेड़ा हॉपु डेलाइट बेला#,
				'generic' => q#वेड़ा हॉपु ऑस्ट्रेलिया बेला#,
				'standard' => q#ऑस्‍ट्रेलियाति वेड़ा हॉपु मानांकॉ बेला#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#ऑस्ट्रेलियाति वेड़ा कुण्पु डेलाइट बेला#,
				'generic' => q#वेड़ा कुण्पु ऑस्ट्रेलिया बेला#,
				'standard' => q#ऑस्ट्रेलियाति वेड़ा कुण्पु मानांकॉ बेला#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#अजरबाइजान काराँ मासा बेला#,
				'generic' => q#अजरबाइजान बेला#,
				'standard' => q#अजरबाइजान मानांकॉ बेला#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#अज़ोरेस काराँ मासा बेला#,
				'generic' => q#अज़ोरेस बेला#,
				'standard' => q#अज़ोरेस मानांकॉ बेला#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#बांग्लादेस काराँ मासा बेला#,
				'generic' => q#बांग्लादेस बेला#,
				'standard' => q#बांग्लादेस मानांकॉ बेला#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#बुटान बेला#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#बोलीविया बेला#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#ब्राज़ीलिया काराँ मासा बेला#,
				'generic' => q#ब्राज़ीलिया बेला#,
				'standard' => q#ब्राज़ीलिया मानांकॉ बेला#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#ब्रूनेति दारूस्सलम बेला#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#केप वर्ड काराँ मासा बेला#,
				'generic' => q#केप वर्ड बेला#,
				'standard' => q#केप वर्ड मानांकॉ बेला#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#चामोरो मानांकॉ बेला#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#च्याताम डेलाइट बेला#,
				'generic' => q#च्याताम बेला#,
				'standard' => q#च्याताम मानांकॉ बेला#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#चिली काराँ मासा बेला#,
				'generic' => q#चिली बेला#,
				'standard' => q#चिली मानांकॉ बेला#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#चीन डेलाइट बेला#,
				'generic' => q#चीन बेला#,
				'standard' => q#चीन मानांकॉ बेला#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#क्रिसमस द्वीप बेला#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#कोकोस द्वीप बेला#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#कोलंबिया काराँ मासा बेला#,
				'generic' => q#कोलंबिया बेला#,
				'standard' => q#कोलंबिया मानांकॉ बेला#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#कुक द्वीप आधा काराँ मासा बेला#,
				'generic' => q#कुक द्वीप बेला#,
				'standard' => q#कुक द्वीप मानांकॉ बेला#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#क्यूबा डेलाइट बेला#,
				'generic' => q#क्यूबा बेला#,
				'standard' => q#क्यूबा मानांकॉ बेला#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#डेविस बेला#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ड्यूमोंट डी अर्विले बेला#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#वेड़ा हॉपु तिमोर बेला#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ईस्टर द्वीप काराँ मासा बेला#,
				'generic' => q#ईस्टर द्वीप बेला#,
				'standard' => q#ईस्टर द्वीप मानांकॉ बेला#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#इक्वाडोर बेला#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#पुण्-आँऽ ति गाड़ा#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#एम्स्टर्डम#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#अंडोरा#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#आस्ट्राकान#,
		},
		'Europe/Athens' => {
			exemplarCity => q#एतेन्स#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#बेलग्रेड#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#बर्लिन#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#ब्रातिस्लावा#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#ब्रूसेल्स#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#बुकारेस्ट#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#बुडापेस्ट#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#ब्यूसिनजेन#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#चिसीनाउ#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#कोपेनहेगन#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#डबलिन#,
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#जिब्राल्टर#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#गर्नसी#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#हेलसिंकी#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#आइल ऑप् म्यान#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#इस्तांबुल#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#जर्सी#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#कालीनिनग्राड#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#कीव#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#किरोव#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#लिस्बन#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#ल्यूबेलजाना#,
		},
		'Europe/London' => {
			exemplarCity => q#लंदन#,
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#लक्ज़मबर्ग#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#म्याड्रिड#,
		},
		'Europe/Malta' => {
			exemplarCity => q#माल्टा#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#मारियाहैम#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#मिंस्क#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#मोनाको#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#मॉस्को#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#ओस्लो#,
		},
		'Europe/Paris' => {
			exemplarCity => q#पेरिस#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#पोड्गोरिका#,
		},
		'Europe/Prague' => {
			exemplarCity => q#प्राग#,
		},
		'Europe/Riga' => {
			exemplarCity => q#रीगा#,
		},
		'Europe/Rome' => {
			exemplarCity => q#रोम#,
		},
		'Europe/Samara' => {
			exemplarCity => q#समारा#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#सैन मारीनो#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#साराजेवो#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#सारातोव#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#सिम्प़ेरोपोल#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#स्कोप्ये#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#सोप़िया#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#स्टॉकहोम#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#तेलिन#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#टाइरेन#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#उल्यानोव्स्क#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#वादुज़#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#वेटिकन#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#विएना#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#विल्नियस#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#वोल्गोग्राड#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#वॉरसॉ#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#ज़ाग्रेब#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#ज़्यूरिक़#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#मादिनी युरोप-ति काराँ मासा बेला#,
				'generic' => q#मादिनी युरोप-ति बेला#,
				'standard' => q#मादिनी युरोप-ति मानांकॉ बेला#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#वेड़ा हॉपु युरोप-ति काराँ मासा बेला#,
				'generic' => q#वेड़ा हॉपु युरोप-ति बेला#,
				'standard' => q#वेड़ा हॉपु युरोप-ति मानांकॉ बेला#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ऑरॉ वेड़ा हॉपु युरोप-ति बेला#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#वेड़ा कुण्पु युरोप-ति काराँ मासा बेला#,
				'generic' => q#वेड़ा कुण्पु युरोप-ति बेला#,
				'standard' => q#वेड़ा कुण्पु युरोप-ति मानांकॉ बेला#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#पाक -लेंड द्वीप काराँ मासा बेला#,
				'generic' => q#पाक -लेंड द्वीप बेला#,
				'standard' => q#पाक -लेंड द्वीप मानांकॉ बेला#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#प़िजी काराँ मासा बेला#,
				'generic' => q#प़िजी बेला#,
				'standard' => q#प़िजी मानांकॉ बेला#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#प़्रेंच गुयाना बेला#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#दॉकिणॉ प़्रांस ऑड़े अंटार्कटिक बेला#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ग्रीनविच मीन बेला#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ग्यालापागोस ति बेला#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#ग्याम्बीयर बेला#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#जॉर्जिया काराँ मासा बेला#,
				'generic' => q#जॉर्जिया बेला#,
				'standard' => q#जॉर्जिया मानांकॉ बेला#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#गिल्बर्ट द्वीप बेला#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#वेड़ा हॉपु ग्रीनलेंड काराँ मासा बेला#,
				'generic' => q#वेड़ा हॉपु ग्रीनलेंड बेला#,
				'standard' => q#वेड़ा हॉपु ग्रीनलेंड मानांकॉ बेला#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#वेड़ा कुण्पु ग्रीनलेंड काराँ मासा बेला#,
				'generic' => q#वेड़ा कुण्पु ग्रीनलेंड बेला#,
				'standard' => q#वेड़ा कुण्पु ग्रीनलेंड मानांकॉ बेला#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#गल्प मानांकॉ बेला#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#गुयाना बेला#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#हवाति–आल्यूसन डेलाइट बेला#,
				'generic' => q#हवाति–आल्यूसन बेला#,
				'standard' => q#हवाति–आल्यूसन मानांकॉ बेला#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#हाँग काँग काराँ मासा बेला#,
				'generic' => q#हाँग काँग बेला#,
				'standard' => q#हाँग काँग मानांकॉ बेला#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#होव्ड काराँ मासा बेला#,
				'generic' => q#होव्ड बेला#,
				'standard' => q#होव्ड मानांकॉ बेला#,
			},
		},
		'India' => {
			long => {
				'standard' => q#बारतीय मानांकॉ बेला#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#एंटानानरीवो#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#चागोस#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#क्रिसमस#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#कोकोस#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#कोमोरो#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#करगुलेन#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#माहे#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#मालदीव#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#मॉरीसस#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#मायोत्ते#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#रीयूनियन#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#बारॉत काजा सामुद्री बेला#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#इंडोचाइना बेला#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#मध्य इंडोनेसिया बेला#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#वेड़ा हॉपु इंडोनेसिया बेला#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#वेड़ा कुण्पु इंडोनेसिया बेला#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#तिरान डेलाइट बेला#,
				'generic' => q#इरान बेला#,
				'standard' => q#इरान मानांकॉ बेला#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#इर्कुत्स्क काराँ मासा बेला#,
				'generic' => q#इर्कुत्स्क बेला#,
				'standard' => q#इर्कुत्स्क मानांकॉ बेला#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#इज़राइल डेलाइट बेला#,
				'generic' => q#इज़राइल बेला#,
				'standard' => q#इज़राइल मानांकॉ बेला#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#जापान डेलाइट बेला#,
				'generic' => q#जापान बेला#,
				'standard' => q#जापान मानांकॉ बेला#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#कज़ाकस्तान बेला#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#वेड़ा हॉपु कज़ाकस्तान बेला#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#वेड़ा कुण्पु कज़ाकस्तान बेला#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#कोरियाति डेलाइट बेला#,
				'generic' => q#कोरियाति बेला#,
				'standard' => q#कोरियाति मानांकॉ बेला#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#कोसराए बेला#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#क्रास्नोयार्स्क काराँ मासा बेला#,
				'generic' => q#क्रास्नोयार्स्क बेला#,
				'standard' => q#क्रास्नोयार्स्क मानांकॉ बेला#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#किर्गिस्‍तान बेला#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#लाइन द्वीप बेला#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#लॉर्ड होवे डेलाइट बेला#,
				'generic' => q#लॉर्ड होवे बेला#,
				'standard' => q#लॉर्ड होवे मानांकॉ बेला#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#मागादान काराँ मासा बेला#,
				'generic' => q#मागादान बेला#,
				'standard' => q#मागादान मानांकॉ बेला#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#मलेसिया बेला#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#मालदीव बेला#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#मार्केसस बेला#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#मार्सल द्वीप बेला#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#मॉरीसस काराँ मासा बेला#,
				'generic' => q#मॉरीसस बेला#,
				'standard' => q#मॉरीसस मानांकॉ बेला#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#माव्सन बेला#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#मेक्सिकोति पेसिपिक डेलाइट बेला#,
				'generic' => q#मेक्सिकोति पेसिपिक बेला#,
				'standard' => q#मेक्सिकोति पेसिपिक मानांकॉ बेला#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#उलान बटोर काराँ मासा बेला#,
				'generic' => q#उलान बटोर बेला#,
				'standard' => q#उलान बटोर मानांकॉ बेला#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#मॉस्को काराँ मासा बेला#,
				'generic' => q#मॉस्को बेला#,
				'standard' => q#मॉस्को मानांकॉ बेला#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#म्यांमार बेला#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#नॉउरु बेला#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#नेपाल बेला#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#न्यू केलेडोनिया काराँ मासा बेला#,
				'generic' => q#न्यू केलेडोनिया बेला#,
				'standard' => q#न्यू केलेडोनिया मानांकॉ बेला#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#न्यूज़ीलेंड डेलाइट बेला#,
				'generic' => q#न्यूज़ीलेंड बेला#,
				'standard' => q#न्यूज़ीलेंड मानांकॉ बेला#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#न्यूप़ाउंडलेंड डेलाइट बेला#,
				'generic' => q#न्यूप़ाउंडलेंड बेला#,
				'standard' => q#न्यूप़ाउंडलेंड मानांकॉ बेला#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#नीयू बेला#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#नॉरप़ॉक द्वीप डेलाइट बेला#,
				'generic' => q#नॉरप़ॉक द्वीप बेला#,
				'standard' => q#नॉरप़ॉक द्वीप मानांकॉ बेला#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#प़र्नांर्डो डे नोरोन्हा काराँ मासा बेला#,
				'generic' => q#प़र्नांर्डो डे नोरोन्हा बेला#,
				'standard' => q#प़र्नांर्डो डे नोरोन्हा मानांकॉ बेला#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#नोवोसिबिर्स्क काराँ मासा बेला#,
				'generic' => q#नोवोसिबिर्स्क बेला#,
				'standard' => q#नोवोसिबिर्स्क मानांकॉ बेला#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ओम्स्क काराँ मासा बेला#,
				'generic' => q#ओम्स्क बेला#,
				'standard' => q#ओम्स्क मानांकॉ बेला#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#एपिया#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#ऑकलेंड#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#बोगनविले#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#च्याथम#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#तिस्टर#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#एप़ेट#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#प़ाकाओप़ो#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#प़िजी#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#प़्यूनाप़ुटी#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#गेलापागोस#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#ग्यामबियर#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#ग्वाडलकनाल#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#गुआम#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#केंटन#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#किरीतिमाति#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#कोसराए#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#क्वाज़ालीन#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#माजुरो#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#मार्केसस#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#मिडवे#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#नाॅउरु#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#नीयू#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#नॉरप़ॉक#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#नॉमिया#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#पागो पागो#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#पलाऊ#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#पिटकेर्न#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#पोनपेति#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#पोर्ट मोरेस्बी#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#रारोटोंगा#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#सायपान#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#ताहिती#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#टारावा#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#टोंगाटापू#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#चक#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#वेक#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#वालिस#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#पाकिस्तान काराँ मासा बेला#,
				'generic' => q#पाकिस्तान बेला#,
				'standard' => q#पाकिस्तान मानांकॉ बेला#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#पलाउ बेला#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#पापुआ न्यू गिनी बेला#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#पैराग्वे काराँ मासा बेला#,
				'generic' => q#पैराग्वे बेला#,
				'standard' => q#पैराग्वे मानांकॉ बेला#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#पेरू काराँ मासा बेला#,
				'generic' => q#पेरू बेला#,
				'standard' => q#पेरू मानांकॉ बेला#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#प़िलिपीन काराँ मासा बेला#,
				'generic' => q#प़िलिपीन बेला#,
				'standard' => q#प़िलिपीन मानांकॉ बेला#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#प़ीनिक्स द्वीप बेला#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#सेंट पिएरे ऑड़े मिक्वेलान डेलाइट बेला#,
				'generic' => q#सेंट पिएरे ऑड़े मिक्वेलान बेला#,
				'standard' => q#सेंट पिएरे ऑड़े मिक्वेलान मानांकॉ बेला#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#पिटकेर्न बेला#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#पोनापे बेला#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#प्योंगयांग बेला#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#रीयूनियन बेला#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#रोथेरा बेला#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#सकालिन काराँ मासा बेला#,
				'generic' => q#सकालिन बेला#,
				'standard' => q#सकालिन मानांकॉ बेला#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#समोआ डेलाइट बेला#,
				'generic' => q#समोआ बेला#,
				'standard' => q#समोआ मानांकॉ बेला#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#सेसेल्स बेला#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#सिंगापुर बेला#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#सोलोमन द्वीप बेला#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#दक्षिणी जॉर्जिया बेला#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#सूरीनाम बेला#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#स्योवा बेला#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#ताहिती बेला#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#ताइपे डेलाइट बेला#,
				'generic' => q#ताइपे बेला#,
				'standard' => q#ताइपे मानांकॉ बेला#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#ताजिकिस्तान बेला#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#टोकेलाऊ बेला#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#टोंगा काराँ मासा बेला#,
				'generic' => q#टोंगा बेला#,
				'standard' => q#टोंगा मानांकॉ बेला#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#चुक बेला#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#तुर्कमेनिस्तान काराँ मासा बेला#,
				'generic' => q#तुर्कमेनिस्तान बेला#,
				'standard' => q#तुर्कमेनिस्तान मानांकॉ बेला#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#तुवालू बेला#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#उरुग्वे काराँ मासा बेला#,
				'generic' => q#उरुग्वे बेला#,
				'standard' => q#उरुग्वे मानांकॉ बेला#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#उज़्बेकिस्तान काराँ मासा बेला#,
				'generic' => q#उज़्बेकिस्तान बेला#,
				'standard' => q#उज़्बेकिस्तान मानांकॉ बेला#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#वनुआतू काराँ मासा बेला#,
				'generic' => q#वनुआतू बेला#,
				'standard' => q#वनुआतू मानांकॉ बेला#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#वेनेज़ुएला बेला#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#व्लादिवोस्तोक काराँ मासा बेला#,
				'generic' => q#व्लादिवोस्तोक बेला#,
				'standard' => q#व्लादिवोस्तोक मानांकॉ बेला#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#वोल्गोग्राड काराँ मासा बेला#,
				'generic' => q#वोल्गोग्राड बेला#,
				'standard' => q#वोल्गोग्राड मानांकॉ बेला#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#वोस्तोक बेला#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#वेक द्वीप बेला#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#वालिस ऑड़े प़्यूचूना बेला#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#याकुत्स्क काराँ मासा बेला#,
				'generic' => q#याकुत्स्क बेला#,
				'standard' => q#याकुत्स्क मानांकॉ बेला#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#येकातेरिनबर्ग काराँ मासा बेला#,
				'generic' => q#येकातेरिनबर्ग बेला#,
				'standard' => q#येकातेरिनबर्ग मानांकॉ बेला#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
