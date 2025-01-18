=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kxv::Telu - Package for language Kuvi

=cut

package Locale::CLDR::Locales::Kxv::Telu;
# This file auto generated from Data\common\main\kxv_Telu.xml
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
				'af' => 'ఆప్రికాన్స్',
 				'am' => 'ఆమ్హెరి',
 				'ar' => 'ఆరబిక్',
 				'ar_001' => 'అదునిక ప్రామాణిక్ అరబిక్',
 				'as' => 'ఆసమీజ్',
 				'az' => 'అజరబైజాని',
 				'az@alt=short' => 'ఆజెరి',
 				'be' => 'బెలారుసియన్',
 				'bg' => 'బుల్గారియన్',
 				'bn' => 'బంగ్లా',
 				'bo' => 'తిబ్బతన్',
 				'brx' => 'బొడొ',
 				'bs' => 'బొస్ నిఆన్',
 				'ca' => 'కాటాలాన్',
 				'chr' => 'చెరొకీ',
 				'cs' => 'చెక్',
 				'da' => 'డెనిస్',
 				'de' => 'జర్మన్',
 				'de_AT' => 'అస్ట్రీయన్ జర్మన్',
 				'de_CH' => 'స్విస్ హఇ జర్మన్',
 				'doi' => 'డోగ్రి',
 				'el' => 'గ్రిక్',
 				'en' => 'ఇంగ్లిస్',
 				'en_AU' => 'అస్ట్రె లియన్ ఇంగ్లిస్',
 				'en_CA' => 'కనెడయన్ ఇంగ్లిస్',
 				'en_GB' => 'బ్రిటిస్ ఇంగ్లిస్',
 				'en_GB@alt=short' => 'యు.కె. ఇంగ్లిస్',
 				'en_US' => 'అమెరికాన్ ఇంగ్లిస్',
 				'en_US@alt=short' => 'యు.ఎస్. ఇంగ్లిస్',
 				'es' => 'స్పెనిస్',
 				'es_419' => 'లాటిన్ అమెరికన్ స్పెనిస్',
 				'es_ES' => 'యురోపియన్ స్పెనిస్',
 				'es_MX' => 'మెక్సికాన్ స్పాస్పెనిస్',
 				'et' => 'ఎస్టొ నియన్',
 				'eu' => 'బాస్క్',
 				'fa' => 'పర్సియన్',
 				'fa_AF' => 'డారి',
 				'fi' => 'పినిస్',
 				'fil' => 'పిలిపినో',
 				'fr' => 'ప్రెంచ్',
 				'fr_CA' => 'కానడియెన్ ప్రేంచ్',
 				'fr_CH' => 'స్విస్ ప్రెంచ్',
 				'gl' => 'గాలసియన్',
 				'gu' => 'గుజరాటి',
 				'he' => 'హిబ్రూ',
 				'hi' => 'హిందీ',
 				'hr' => 'క్రొయేసియన్',
 				'hu' => 'హంగేరియన్',
 				'hy' => 'అర్మేనియన్',
 				'id' => 'ఇండోనేసియన్',
 				'is' => 'అఇస్లెండిక్',
 				'it' => 'ఇటాలియన్',
 				'ja' => 'జపనిస్',
 				'ka' => 'జర్జియన్',
 				'kk' => 'కజక్',
 				'km' => 'కమెర్',
 				'kn' => 'కన్నడ',
 				'ko' => 'కొరియన్',
 				'kok' => 'కొంకణి',
 				'ks' => 'కాస్మిరి',
 				'kxv' => 'కువి',
 				'ky' => 'కిర్గజ్',
 				'lo' => 'లావో',
 				'lt' => 'లితువేనియన్',
 				'lv' => 'లాట్వియన్',
 				'mai' => 'మైతలి',
 				'mk' => 'మాసిడోనియన్',
 				'ml' => 'మలయాలం',
 				'mn' => 'మగోంలియన్',
 				'mni' => 'మణిపురి',
 				'mr' => 'మరాటి',
 				'ms' => 'మలయ్',
 				'my' => 'బర్మీస్',
 				'nb' => 'సార్వేజియన్ బొకమల్',
 				'ne' => 'సేపాలి',
 				'nl' => 'డచ్',
 				'nl_BE' => 'ప్లెమిస్',
 				'or' => 'ఒడియా',
 				'pa' => 'పంజాబి',
 				'pl' => 'పోలిస్',
 				'pt' => 'పోర్తుగీస్',
 				'pt_BR' => 'బ్రెజిలియన్ పోర్తుగీస్',
 				'pt_PT' => 'యురోపియన్ పోర్తుగిస్',
 				'ro' => 'రోమేనియన్',
 				'ro_MD' => 'మెల్డావియన్',
 				'ru' => 'రస్వన్',
 				'sa' => 'సంస్కృతం',
 				'sat' => 'సంతాలి',
 				'sd' => 'సిందీ',
 				'si' => 'సింహళం',
 				'sk' => 'స్లోవక్',
 				'sl' => 'స్లోవేనియన్',
 				'sq' => 'అల్బేనియన్',
 				'sr' => 'సెర్బియన్',
 				'sv' => 'స్విడిస్',
 				'sw' => 'స్వాహిలి',
 				'sw_CD' => 'కాగోం స్వాహిలి',
 				'ta' => 'తమిళము',
 				'te' => 'తెలుగు',
 				'th' => 'తాఇ',
 				'tr' => 'టర్కిస్',
 				'uk' => 'యుక్రెయనియన్',
 				'ur' => 'ఉర్దూ',
 				'uz' => 'ఉజ్బెక్',
 				'vi' => 'వియత్నామీస్',
 				'zh' => 'చైనీస్',
 				'zh@alt=menu' => 'చైనీస్, మాండరిన్',
 				'zh_Hans' => 'సరళీకృత చైనీస్',
 				'zh_Hans@alt=long' => 'సరళీకృత మాండరిన్ చైనీస్',
 				'zh_Hant' => 'సాంప్రదాయక చైనీస్',
 				'zh_Hant@alt=long' => 'సాంప్రదాయకా మాండరిన్ చైనీస్',
 				'zu' => 'జాలూ',

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
			'Arab' => 'ఆరబిక్',
 			'Beng' => 'బాంగ్లా',
 			'Brah' => 'బ్రాహ్మి',
 			'Cher' => 'చిరోకి',
 			'Cyrl' => 'సిరిలిక్',
 			'Deva' => 'దేవనాగరి',
 			'Gujr' => 'గుజరాతి',
 			'Guru' => 'గురుముకి',
 			'Hans' => 'సరళీకృతం',
 			'Hans@alt=stand-alone' => 'సరళీకృత హాన్',
 			'Hant' => 'సాంప్రదాయక',
 			'Hant@alt=stand-alone' => 'సాంప్రదాయక హాన్',
 			'Knda' => 'కన్నడ',
 			'Latn' => 'లాటిన్',
 			'Mlym' => 'మలయాళం',
 			'Orya' => 'ఒడియా',
 			'Saur' => 'సౌరాస్ట్ర',
 			'Taml' => 'తమిళము',
 			'Telu' => 'తెలుగు',
 			'Zxxx' => 'లిపి లేని',
 			'Zzzz' => 'తెలియని లిపి',

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
			'001' => 'ప్రపంచం',
 			'419' => 'లాటిన్ ఆమెరిక',
 			'AD' => 'ఆండొర',
 			'AE' => 'యునైటెడ్ ఆరబ్ ఎమిరేబ్స్',
 			'AF' => 'ఆప్గనిస్తాన్',
 			'AG' => 'ఆంటిగ్వా మరియు బార్బుడా',
 			'AI' => 'ఆంగ్విల్లా',
 			'AL' => 'ఆల్లేనియా',
 			'AM' => 'ఆర్మేనియా',
 			'AO' => 'ఆంగోలా',
 			'AQ' => 'ఆంటార్కటికా',
 			'AR' => 'ఆర్జెంటినా',
 			'AS' => 'ఆమెరికన్ సమూవా',
 			'AT' => 'ఆస్ట్రీయా',
 			'AU' => 'ఆస్ట్రేలియా',
 			'AW' => 'ఆరుబా',
 			'AX' => 'ఆలాండ్ దీపులు',
 			'AZ' => 'ఆజర్బైజాన్',
 			'BA' => 'బోస్నియా మరియు బెర్జిగోవినా',
 			'BB' => 'బార్బడోస్',
 			'BD' => 'బంగ్లాదేస్',
 			'BE' => 'బెల్జియం',
 			'BF' => 'బుర్కినా పాసో',
 			'BG' => 'బుల్గేరియ',
 			'BH' => 'బహరిన్',
 			'BI' => 'బురుండి',
 			'BJ' => 'బెనిన్',
 			'BL' => 'సెంట్ బర్తెలిమి',
 			'BM' => 'బర్ముడా',
 			'BN' => 'బ్రునేఇ',
 			'BO' => 'బొలివియా',
 			'BQ' => 'కరీబియన్ నెదర్లాండ్స',
 			'BR' => 'బ్రాజిల్',
 			'BS' => 'బహామాస్',
 			'BT' => 'బుటాన్',
 			'BW' => 'బోట్స్వానా',
 			'BY' => 'బెలారస్',
 			'BZ' => 'బెలిజ్',
 			'CA' => 'కెనడా',
 			'CC' => 'కోకోస్ (కీలింగ్) దీవులు',
 			'CD' => 'కాంగో కిన్సాసా',
 			'CD@alt=variant' => 'కాంగో (DRC)',
 			'CF' => 'సెంట్రల్ ఆప్రికన్ రిపబ్లిక్',
 			'CG' => 'కాంగో- బ్రాజావిల్లి',
 			'CG@alt=variant' => 'కాంగో (రిపబ్లిక్)',
 			'CH' => 'స్విజర్లాండ్',
 			'CI' => 'కోట్ డి ఐవోర్',
 			'CI@alt=variant' => 'ఐవరీ కోస్ట్',
 			'CK' => 'కుక్ దీపులు',
 			'CL' => 'చిలి',
 			'CM' => 'కామెరూన్',
 			'CN' => 'చినా',
 			'CO' => 'కొలంబియా',
 			'CR' => 'కోస్టా రికా',
 			'CU' => 'క్యూబా',
 			'CV' => 'కేప్ వడ్',
 			'CW' => 'క్వురసో',
 			'CX' => 'క్రిస్ట మాస్ దీపుపు',
 			'CY' => 'సైప్రస్',
 			'CZ' => 'చెకియా',
 			'CZ@alt=variant' => 'చెక్ రిపబ్లిక్',
 			'DE' => 'జర్మనీ',
 			'DG' => 'డియాగో గార్సియా',
 			'DJ' => 'జిబుతి',
 			'DK' => 'డెన్మార్క',
 			'DM' => 'డొమినికా',
 			'DO' => 'డొమినికాన్ రిపబ్లిక్',
 			'DZ' => 'ఆల్జిరియా',
 			'EA' => 'స్యూటా & మెలిల్లా',
 			'EC' => 'ఈక్వడార్',
 			'EE' => 'ఎస్టోనియా',
 			'EG' => 'ఈజిప్ట్',
 			'EH' => 'పడమటి సహారా',
 			'ER' => 'ఇరిట్రియా',
 			'ES' => 'స్పెన్',
 			'ET' => 'ఇతియోపియా',
 			'FI' => 'పిన్లాండ్',
 			'FJ' => 'పిజీ',
 			'FK' => 'ఫాక్‌ల్యాండ్ దీవులు',
 			'FK@alt=variant' => 'ఫాక్‌ల్యాండ్ దీవులు (ఇస్లాస్ మాల్వినాస్)',
 			'FM' => 'మైక్రోనేసియా',
 			'FO' => 'పెరొ దీప',
 			'FR' => 'ప్రాన్స్',
 			'GA' => 'గాబన్',
 			'GB' => 'యునైటెడ్ కింగ్‌డమ్',
 			'GB@alt=short' => 'యు.కె.',
 			'GD' => 'గ్రెనడా',
 			'GE' => 'జార్జియా',
 			'GF' => 'ప్రెంచ్ గుయానా',
 			'GG' => 'గర్నసీ',
 			'GH' => 'గనా',
 			'GI' => 'జిబ్రాల్టర్',
 			'GL' => 'గ్రీన్లండ్',
 			'GM' => 'గంబియా',
 			'GN' => 'గినియా',
 			'GP' => 'గ్వడెలుప్',
 			'GQ' => 'ఈక్వటోరియల్ గినియా',
 			'GR' => 'గ్రీస్',
 			'GS' => 'దకిన జర్జిఆ అదే దకిన సండవిచ్ దిప',
 			'GT' => 'గ్వటెమాలా',
 			'GU' => 'గ్వమ్',
 			'GW' => 'గినియా-బిస్సావ్',
 			'GY' => 'గుయానా',
 			'HK' => 'హాంకాంగ్ ఎస్ఎఆర్ చినా',
 			'HK@alt=short' => 'హంకం',
 			'HN' => 'హండురాస్',
 			'HR' => 'క్రొయేసియా',
 			'HT' => 'హైటి',
 			'HU' => 'హంగేరీ',
 			'IC' => 'కేనరీ దీపులు',
 			'ID' => 'ఇండోనేసియా',
 			'IE' => 'ఐర్లాండ్',
 			'IL' => 'ఇజ్రాయెల్',
 			'IM' => 'ఐల్ ఆప్ మాన్',
 			'IN' => 'బారతదెసాం',
 			'IO' => 'బ్రిటిస్ హీందూ మహాసముద్ర ప్రాంతం',
 			'IQ' => 'ఇరాక్',
 			'IR' => 'ఇరాన్',
 			'IS' => 'ఐస్లాండ్',
 			'IT' => 'ఇటలి',
 			'JE' => 'జెర్సీ',
 			'JM' => 'జమైకా',
 			'JO' => 'జోర్డాన్',
 			'JP' => 'జపాన్',
 			'KE' => 'కెన్యా',
 			'KG' => 'కిర్గజిస్తాన్',
 			'KH' => 'కంబోడియా',
 			'KI' => 'కీరిబాటి',
 			'KM' => 'కొమొరోస్',
 			'KN' => 'సెయింట్ కిట్స్ మరియు నెవిస్',
 			'KP' => 'ఉత్తర కొరియా',
 			'KR' => 'దకిణ కొరియా',
 			'KW' => 'కువైట్',
 			'KY' => 'కేమాన్ దీపులు',
 			'KZ' => 'కజకిస్తాన్',
 			'LA' => 'లావోస్',
 			'LB' => 'లెబనాన్',
 			'LC' => 'సెయింట్ లూసియా',
 			'LI' => 'లిక్టెన్‌స్టెయిన్',
 			'LK' => 'స్రీ లంక',
 			'LR' => 'లైబీరియా',
 			'LS' => 'లెసోతో',
 			'LT' => 'లీతువేనియ',
 			'LU' => 'లక్సెంబర్గ్',
 			'LV' => 'లాత్వియా',
 			'LY' => 'లిబియా',
 			'MA' => 'మొరాకో',
 			'MC' => 'మొనాకో',
 			'MD' => 'మోల్డొవా',
 			'ME' => 'మాంటెనెగ్రో',
 			'MF' => 'సెయింట్ మార్టిన్',
 			'MG' => 'మడగాస్కర్',
 			'MH' => 'మార్సాల్ దీపులు',
 			'MK' => 'ఉత్తర మాసిడోనియా',
 			'ML' => 'మాలి',
 			'MM' => 'మయన్మార్ (బర్మా)',
 			'MN' => 'మంగోలియా',
 			'MO' => 'మకావ్ ఎస్ఏఆర్ చైనా',
 			'MO@alt=short' => 'మకాఉ',
 			'MP' => 'ఉత్తర మరియానా దీవులు',
 			'MQ' => 'మార్ర్టనీక్',
 			'MR' => 'మౌరిటేనియా',
 			'MS' => 'మాంట్సెరాట్',
 			'MT' => 'మాల్డా',
 			'MU' => 'మారిసస్',
 			'MV' => 'మాలదిపి',
 			'MW' => 'మలావీ',
 			'MX' => 'మెక్సికో',
 			'MY' => 'మలేసియా',
 			'MZ' => 'మొజాంబిక్',
 			'NA' => 'నమీబియా',
 			'NC' => 'క్రొత్త కెలెడోనియా',
 			'NE' => 'నఇజర్',
 			'NF' => 'నార్పోక్ దీవ',
 			'NG' => 'నౌజీరియా',
 			'NI' => 'నికరాగువా',
 			'NL' => 'నెదర్లాండ్స్',
 			'NO' => 'నార్వే',
 			'NP' => 'నేపాల్',
 			'NR' => 'నౌరు',
 			'NU' => 'నియూ',
 			'NZ' => 'న్యూజిలాండ్',
 			'OM' => 'ఓమన్',
 			'PA' => 'పనామా',
 			'PE' => 'పెరూ',
 			'PF' => 'ప్రెంచ్ పోలినిసియా',
 			'PG' => 'పాపువా న్యూ గనియా',
 			'PH' => 'పిలిప్పైన్స్',
 			'PK' => 'పాకిస్తాన్',
 			'PL' => 'పోలాండ్',
 			'PM' => 'సెయింట్ పియెర్ మరియు మికెలాన్',
 			'PN' => 'పిట్‌కెయిర్న్ దీవులు',
 			'PR' => 'ప్యూర్టో రికో',
 			'PS' => 'పాలస్తీనియన్ ప్రాంతాలు',
 			'PS@alt=short' => 'పాలస్తీనా',
 			'PT' => 'పోర్చుగల్',
 			'PW' => 'పాలావ్',
 			'PY' => 'పరాగ్వే',
 			'QA' => 'కతార',
 			'RE' => 'రీయూనియన్',
 			'RO' => 'రోమేనియా',
 			'RS' => 'సెర్బియా',
 			'RU' => 'రస్యా',
 			'RW' => 'రువాండా',
 			'SA' => 'సౌదీ అరేబియా',
 			'SB' => 'సోలమన్ దీవులు',
 			'SC' => 'సీషెల్స్',
 			'SD' => 'సూడాన్',
 			'SE' => 'స్వీడన్',
 			'SG' => 'సింగపూర్',
 			'SH' => 'సెయింట్ హెలెనా',
 			'SI' => 'స్లోవేనియా',
 			'SJ' => 'స్వాల్‌బార్డ్ మరియు జాన్ మాయెన్',
 			'SK' => 'స్లొవేకియా',
 			'SL' => 'సియెర్రా లియాన్',
 			'SM' => 'సస్ మారిసో',
 			'SN' => 'సెనెగల్',
 			'SO' => 'సోమలియా',
 			'SR' => 'సూరినామ్',
 			'SS' => 'దక్షిణ సూడాన్',
 			'ST' => 'సావో టోమ్ మరియు ప్రిన్సిపి',
 			'SV' => 'ఎల్ సాల్వడోర్',
 			'SX' => 'సింట్ మార్టెన్',
 			'SY' => 'సిరియా',
 			'SZ' => 'ఈస్వాటిని',
 			'SZ@alt=variant' => 'స్వాజిల్యాండ్',
 			'TC' => 'టర్క్స్ మరియు కైకోస్ దీవులు',
 			'TD' => 'చాద్',
 			'TF' => 'ప్రెంచ్ దకినియ టెరిటొరి',
 			'TG' => 'టోగో',
 			'TH' => 'తయిలాండ్',
 			'TJ' => 'తాజాకిస్తాన',
 			'TK' => 'టోకెలావ్',
 			'TL' => 'టిమోర్-లెస్టె',
 			'TL@alt=variant' => 'తూర్పు టిమోర్',
 			'TM' => 'తుర్క్‍మెనిస్తన్',
 			'TN' => 'ట్యునీషియా',
 			'TO' => 'టోంగా',
 			'TR' => 'టర్కీ',
 			'TT' => 'ట్రినిడాడ్ మరియు టొబాగో',
 			'TV' => 'టువాలు',
 			'TW' => 'తైవాన్',
 			'TZ' => 'టాంజానియా',
 			'UA' => 'ఉక్రెయిన్',
 			'UG' => 'ఉగాండా',
 			'UM' => 'సంయుక్త రాజ్య అమెరికా బయట ఉన్న దీవులు',
 			'US' => 'యునైటెడ్ స్టేట్స్',
 			'US@alt=short' => 'యు.ఎస్.',
 			'UY' => 'ఉరుగ్వే',
 			'UZ' => 'ఉజ్బెకిస్తాన్',
 			'VA' => 'బాటికాన్ సిటి',
 			'VC' => 'సెయింట్ విన్సెంట్ మరియు గ్రెనడీన్స్',
 			'VE' => 'వెనిజులా',
 			'VG' => 'బ్రిటిష్ వర్జిన్ దీవులు',
 			'VI' => 'యు.ఎస్. వర్జిన్ దీవులు',
 			'VN' => 'వియత్నాం',
 			'VU' => 'వనాటు',
 			'WF' => 'వాల్లిస్ మరియు ఫుటునా',
 			'WS' => 'సమోవా',
 			'XK' => 'కొసోవో',
 			'YE' => 'యెమెన్',
 			'YT' => 'మాయొట్',
 			'ZA' => 'దకిణ అప్రికా',
 			'ZM' => 'జంబియా',
 			'ZW' => 'జింబాబ్వే',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'క్యాలెండర్',
 			'cf' => 'కరెన్సీ ఫార్మాట్',
 			'collation' => 'క్రమబద్ధీకరణ క్రమం',
 			'currency' => 'కరెన్సీ',
 			'hc' => 'గంటల పద్ధతి (౧౨ వర్సెస్౨౪)',
 			'lb' => 'లైన్ బ్రేక్ సైలి',
 			'ms' => 'కొలమాన పద్ధతి',
 			'numbers' => 'సంక్యాలు',

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
 				'gregorian' => q{గ్రేగోరియన్ క్యాలెండర్},
 				'indian' => q{భారతీయ జాతీయ క్యాలెండర్},
 			},
 			'cf' => {
 				'standard' => q{ప్రామాణిక కరెన్సీ ఫార్మాట్},
 			},
 			'collation' => {
 				'ducet' => q{డిపాల్ట్ యూనీకోడ్ క్రమబద్ధీకరణ క్రమం},
 				'phonebook' => q{పోన్‌బుక్ క్రమబద్ధీకరణ క్రమం},
 				'search' => q{సాధారణ-ప్రయోజన సోధన},
 				'standard' => q{ప్రామాణిక క్రమబద్ధీకరణ క్రమం},
 			},
 			'hc' => {
 				'h11' => q{౧౨ గంటల పద్ధతి (0–౧౧)},
 				'h12' => q{౧౨ గంటల పద్ధతి (౧–౧౨)},
 				'h23' => q{౨౪ గంటల పద్ధతి (0–౨౩)},
 				'h24' => q{౨౪ గంటల పద్ధతి (౧–౨౪)},
 			},
 			'ms' => {
 				'metric' => q{మెట్రిక్ పద్ధతి},
 				'uksystem' => q{ఇంపీరియల్ కొలమాన పద్ధతి},
 				'ussystem' => q{యు.ఎస్. కొలమాన పద్ధతి},
 			},
 			'numbers' => {
 				'arab' => q{అరబిక్-ఇండిక్ అంకెలు},
 				'arabext' => q{పొడిగించబడిన అరబిక్-ఇండిక్ అంకెలు},
 				'beng' => q{బెంగాలీ అంకెలు},
 				'deva' => q{దేవనాగరి అంకెలు},
 				'gujr' => q{గుజరాతీ అంకెలు},
 				'guru' => q{గుర్ముకి అంకెలు},
 				'knda' => q{కన్నడ అంకెలు},
 				'latn' => q{పస్చిమ అంకెలు},
 				'mlym' => q{మలయాళం అంకెలు},
 				'orya' => q{ఒరియా అంకెలు},
 				'roman' => q{రోమన్ సంఖ్యలు},
 				'romanlow' => q{రోమన్ చిన్నబడి సంఖ్యలు},
 				'taml' => q{సాంప్రదాయ తమిళ సంక్యలు},
 				'tamldec' => q{తమిళ అంకెలు},
 				'telu' => q{తెలుగు అంకెలు},
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
			'metric' => q{దసాంసం},
 			'UK' => q{యుకె},
 			'US' => q{యుఎస్},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'భాస: {0}',
 			'script' => 'లిపి: {0}',
 			'region' => 'ప్రాంతం: {0}',

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
			main => qr{[ఁంః అ ఆ ఇ ఈ ఉ ఊ ఎ ఏ ఒ ఓ క గ చ జ ఞ ట డ{డ఼} ణ త ద న ప బ మ య ర ల వ స హ ా ి ీ ు ూ ె ే ొ ో ్]},
			numbers => qr{[\- ‑ , . % ‰ + 0 ౧ ౨ ౩ ౪ ౫ ౬ ౭ ౮ ౯]},
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
				end => q({0}, మరియు {1}),
				2 => q({0} మరియు {1}),
		} }
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'telu',
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
				'currency' => q(బ్రెజిలియన్ రియల్),
				'other' => q(బ్రెజిలియన్ రియల్‌లు),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(చైనా దేశ యువాన్),
				'other' => q(చైనా దేశ యువాన్),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(యురొ),
				'other' => q(యురోలు),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(బ్రిటిష్ పౌండ్),
				'other' => q(బ్రిటిష్ పౌండ్‌లు),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(భారతదేశ రూపాయి),
				'other' => q(భారతదేశ రూపాయలు),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(జపాను దేశ యెన్),
				'other' => q(జపాను దేశ యెన్),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(రష్యన్ రూబల్),
				'other' => q(రష్యన్ రూబల్‌లు),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(అమెరికా డాలర్),
				'other' => q(అమెరికా డాలర్‌లు),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(తెలియని కరెన్సీ),
				'other' => q(తెలియని కరెన్సీ),
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
					wide => {
						nonleap => [
							'మాగ',
							'గుండు',
							'హిరెఇ',
							'బెసెకి',
							'లండి',
							'రాత',
							'బాన్దపాణా',
							'బార్సి',
							'అస్ర',
							'దివెడి',
							'పాండు',
							'పుసు'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'మా',
							'గు',
							'హి',
							'బె',
							'ల',
							'రా',
							'బా',
							'బా',
							'అ',
							'ది',
							'పా',
							'పు'
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
					wide => {
						mon => 'నమారా',
						tue => 'మాంగాడా',
						wed => 'వుదారా',
						thu => 'లాకివరా',
						fri => 'నుక్ వరా',
						sat => 'సానివరా',
						sun => 'వారమి'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'న',
						tue => 'మా',
						wed => 'వు',
						thu => 'ల',
						fri => 'ను',
						sat => 'సా',
						sun => 'వా'
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
					abbreviated => {0 => 'త్రై౧',
						1 => 'త్రై౨',
						2 => 'త్రై౩',
						3 => 'త్రై౪'
					},
					wide => {0 => '౧వ త్రైమాసికం',
						1 => '౨వ త్రైమాసికర',
						2 => '౩వ త్రైమాసికర',
						3 => '౪వ త్రైమాసికర'
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
					'am' => q{ఎ ఎమ్},
					'pm' => q{పి ఎమ్},
				},
				'narrow' => {
					'am' => q{ఎ},
					'pm' => q{పి},
				},
				'wide' => {
					'am' => q{ఎ ఎమ్},
					'pm' => q{పి ఎమ్},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ఎ ఎమ్},
					'pm' => q{పి ఎమ్},
				},
				'narrow' => {
					'am' => q{ఎ ఎమ్},
					'pm' => q{పి ఎమ్},
				},
				'wide' => {
					'am' => q{ఎ ఎమ్},
					'pm' => q{పి ఎమ్},
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
				'0' => 'క్రీపూ',
				'1' => 'క్రీశ'
			},
			wide => {
				'0' => 'క్రీన్తు వూర్వం',
				'1' => 'క్రీస్తు సకం'
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
			'full' => q{{1} త {0}},
			'long' => q{{1} త {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} త {0}},
			'long' => q{{1} త {0}},
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
			MMMMW => q{MMMM తి వారా W},
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
			yw => q{Y తి వారా w},
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
		regionFormat => q({0} సమయం),
		regionFormat => q({0} పగటి వెలుతురు సమయం),
		regionFormat => q({0} ప్రామాణిక సమయం),
		'Afghanistan' => {
			long => {
				'standard' => q#ఆఫ్ఘనిస్తాన్ సమయం#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#అబిడ్జాన్#,
		},
		'Africa/Accra' => {
			exemplarCity => q#అక్రా#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#యాడిస్ అబాబా#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#అల్జియర్స్#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#అస్మారా#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#బామాకో#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#బాంగుయ్#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#బంజూల్#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#బిస్సావ్#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#బ్లాన్టైర్#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#బ్రాజావిల్లే#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#బుజమ్బురా#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#కైరో#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#కాసాబ్లాంకా#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#స్యూటా#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#కోనాక్రీ#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#డకార్#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#దార్ ఎస్ సలామ్#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#డిజ్బౌటి#,
		},
		'Africa/Douala' => {
			exemplarCity => q#డౌలా#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#ఎల్ ఎయున్#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#ఫ్రీటౌన్#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#గబోరోన్#,
		},
		'Africa/Harare' => {
			exemplarCity => q#హరారే#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#జొహెన్స్‌బర్గ్#,
		},
		'Africa/Juba' => {
			exemplarCity => q#జుబా#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#కంపాలా#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#ఖార్టోమ్#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#కీగలి#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#కిన్షాసా#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#లాగోస్#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#లెబర్విల్లే#,
		},
		'Africa/Lome' => {
			exemplarCity => q#లోమ్#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#లువాండా#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#లుబంబాషి#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#లుసాకా#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#మలాబో#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#మాపుటో#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#మసేరు#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#బాబెన్#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#మోగాదిషు#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#మోన్రోవియా#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#నైరోబీ#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#డ్జామెనా#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#నియామే#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#న్వాక్షోట్#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#ఔగాడౌగోవ్#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#పోర్టో-నోవో#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#సావో టోమ్#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#ట్రిపోలి#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#ట్యునిస్#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#విండ్హోక్#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#సెంట్రల్ ఆఫ్రికా సమయం#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#తూర్పు ఆఫ్రికా సమయం#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#దక్షిణ ఆఫ్రికా ప్రామాణిక సమయం#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#పశ్చిమ ఆఫ్రికా వేసవి సమయం#,
				'generic' => q#పశ్చిమ ఆఫ్రికా సమయం#,
				'standard' => q#పశ్చిమ ఆఫ్రికా ప్రామాణిక సమయం#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#అలాస్కా పగటి వెలుతురు సమయం#,
				'generic' => q#అలాస్కా సమయం#,
				'standard' => q#అలాస్కా ప్రామాణిక సమయం#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#అమెజాన్ వేసవి సమయం#,
				'generic' => q#అమెజాన్ సమయం#,
				'standard' => q#అమెజాన్ ప్రామాణిక సమయం#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#అడాక్#,
		},
		'America/Anchorage' => {
			exemplarCity => q#యాంకరేజ్#,
		},
		'America/Anguilla' => {
			exemplarCity => q#ఎంగ్విల్లా#,
		},
		'America/Antigua' => {
			exemplarCity => q#ఆంటిగ్వా#,
		},
		'America/Araguaina' => {
			exemplarCity => q#అరాగ్వేయీనా#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#లా రియోజ#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#రియో గల్లేగోస్#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#సాల్టా#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#శాన్ జ్యూన్#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#శాన్ లూయిస్#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#టుకుమన్#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#ఉష్యూయ#,
		},
		'America/Aruba' => {
			exemplarCity => q#అరుబా#,
		},
		'America/Asuncion' => {
			exemplarCity => q#అసున్సియోన్#,
		},
		'America/Bahia' => {
			exemplarCity => q#బహియ#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#బహియా బండరాస్#,
		},
		'America/Barbados' => {
			exemplarCity => q#బార్బడోస్#,
		},
		'America/Belem' => {
			exemplarCity => q#బెలెమ్#,
		},
		'America/Belize' => {
			exemplarCity => q#బెలీజ్#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#బ్లాంక్-సబ్లోన్#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#బోవా విస్టా#,
		},
		'America/Bogota' => {
			exemplarCity => q#బగోటా#,
		},
		'America/Boise' => {
			exemplarCity => q#బొయిసీ#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#బ్యూనోస్ ఎయిర్స్#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#కేంబ్రిడ్జ్ బే#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#కాంపో గ్రాండ్#,
		},
		'America/Cancun' => {
			exemplarCity => q#కన్‌కూన్#,
		},
		'America/Caracas' => {
			exemplarCity => q#కారాకస్#,
		},
		'America/Catamarca' => {
			exemplarCity => q#కటమార్కా#,
		},
		'America/Cayenne' => {
			exemplarCity => q#కయేన్#,
		},
		'America/Cayman' => {
			exemplarCity => q#కేమాన్#,
		},
		'America/Chicago' => {
			exemplarCity => q#చికాగో#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#చువావా#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#అటికోకన్#,
		},
		'America/Cordoba' => {
			exemplarCity => q#కోర్డోబా#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#కోస్టా రికా#,
		},
		'America/Creston' => {
			exemplarCity => q#క్రెస్టన్#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#కుయబా#,
		},
		'America/Curacao' => {
			exemplarCity => q#కురాకవో#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#డెన్మార్క్‌షాన్#,
		},
		'America/Dawson' => {
			exemplarCity => q#డాసన్#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#డాసన్ క్రీక్#,
		},
		'America/Denver' => {
			exemplarCity => q#డెన్వెర్#,
		},
		'America/Detroit' => {
			exemplarCity => q#డిట్రోయిట్#,
		},
		'America/Dominica' => {
			exemplarCity => q#డొమినికా#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ఎడ్మోంటన్#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#ఇరునెప్#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ఎల్ సాల్వడోర్#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#ఫోర్ట్ నెల్సన్#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#ఫోర్టలేజా#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#గ్లేస్ బే#,
		},
		'America/Godthab' => {
			exemplarCity => q#నూక్#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#గూస్ బే#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#గ్రాండ్ టర్క్#,
		},
		'America/Grenada' => {
			exemplarCity => q#గ్రెనడా#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#గ్వాడెలోప్#,
		},
		'America/Guatemala' => {
			exemplarCity => q#గ్వాటిమాలా#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#గయాక్విల్#,
		},
		'America/Guyana' => {
			exemplarCity => q#గయానా#,
		},
		'America/Halifax' => {
			exemplarCity => q#హాలిఫాక్స్#,
		},
		'America/Havana' => {
			exemplarCity => q#హవానా#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#హెర్మోసిల్లో#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#నోక్స్, ఇండియాన#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#మరెంగో, ఇండియాన#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#పీటర్స్‌బర్గ్, ఇండియాన#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#టెల్ నగరం, ఇండియాన#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#వెవయ్, ఇండియాన#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#విన్‌సెన్నెస్, ఇండియాన#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#వినామాక్, ఇండియాన#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#ఇండియానపోలిస్#,
		},
		'America/Inuvik' => {
			exemplarCity => q#ఇనువిక్#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ఇక్వాలిట్#,
		},
		'America/Jamaica' => {
			exemplarCity => q#జమైకా#,
		},
		'America/Jujuy' => {
			exemplarCity => q#జుజుయ్#,
		},
		'America/Juneau' => {
			exemplarCity => q#జూనో#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#మోంటిసెల్లో, కెన్‌టుక్కీ#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#క్రలెండ్జిక్#,
		},
		'America/La_Paz' => {
			exemplarCity => q#లా పాజ్#,
		},
		'America/Lima' => {
			exemplarCity => q#లిమా#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#లాస్ ఏంజల్స్#,
		},
		'America/Louisville' => {
			exemplarCity => q#లూయివిల్#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#లోయర్ ప్రిన్స్ క్వార్టర్#,
		},
		'America/Maceio' => {
			exemplarCity => q#మాసియో#,
		},
		'America/Managua' => {
			exemplarCity => q#మనాగువా#,
		},
		'America/Manaus' => {
			exemplarCity => q#మనాస్#,
		},
		'America/Marigot' => {
			exemplarCity => q#మారిగోట్#,
		},
		'America/Martinique' => {
			exemplarCity => q#మార్టినీక్#,
		},
		'America/Matamoros' => {
			exemplarCity => q#మాటమొరోస్#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#మాసట్‌లాన్#,
		},
		'America/Mendoza' => {
			exemplarCity => q#మెండోజా#,
		},
		'America/Menominee' => {
			exemplarCity => q#మెనోమినీ#,
		},
		'America/Merida' => {
			exemplarCity => q#మెరిడా#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#మెట్లకట్ల#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#మెక్సికో నగరం#,
		},
		'America/Miquelon' => {
			exemplarCity => q#మికెలాన్#,
		},
		'America/Moncton' => {
			exemplarCity => q#మోన్‌క్టోన్#,
		},
		'America/Monterrey' => {
			exemplarCity => q#మోంటెర్రే#,
		},
		'America/Montevideo' => {
			exemplarCity => q#మోంటెవీడియో#,
		},
		'America/Montserrat' => {
			exemplarCity => q#మాంట్సెరాట్#,
		},
		'America/Nassau' => {
			exemplarCity => q#నాస్సావ్#,
		},
		'America/New_York' => {
			exemplarCity => q#న్యూయార్క్#,
		},
		'America/Nome' => {
			exemplarCity => q#నోమ్#,
		},
		'America/Noronha' => {
			exemplarCity => q#నరోన్హా#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#బ్యులా, ఉత్తర డకోట#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#సెంటర్, ఉత్తర డకోటా#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#న్యూ సలేమ్, ఉత్తర డకోట#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ఒజినగ#,
		},
		'America/Panama' => {
			exemplarCity => q#పనామా#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#పరామారిబో#,
		},
		'America/Phoenix' => {
			exemplarCity => q#ఫినిక్స్#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#పోర్ట్-అవ్-ప్రిన్స్#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#పోర్ట్ ఆఫ్ స్పెయిన్#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#పోర్టో వెల్హో#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#ప్యూర్టో రికో#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#పుంటా అరీనస్#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#రన్‌కిన్ ఇన్‌లెట్#,
		},
		'America/Recife' => {
			exemplarCity => q#రెసిఫీ#,
		},
		'America/Regina' => {
			exemplarCity => q#రెజీనా#,
		},
		'America/Resolute' => {
			exemplarCity => q#రిజల్యూట్#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#రియో బ్రాంకో#,
		},
		'America/Santarem' => {
			exemplarCity => q#సాంటరెమ్#,
		},
		'America/Santiago' => {
			exemplarCity => q#శాంటియాగో#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#శాంటో డోమింగో#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#సావో పాలో#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#ఇటోక్కోర్టూర్మిట్#,
		},
		'America/Sitka' => {
			exemplarCity => q#సిట్కా#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#సెయింట్ బర్తెలెమీ#,
		},
		'America/St_Johns' => {
			exemplarCity => q#సెయింట్ జాన్స్#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#సెయింట్ కిట్స్#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#సెయింట్ లూసియా#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#సెయింట్ థామస్#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#సెయింట్ విన్సెంట్#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#స్విఫ్ట్ కరెంట్#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#తెగుసిగల్పా#,
		},
		'America/Thule' => {
			exemplarCity => q#థులే#,
		},
		'America/Tijuana' => {
			exemplarCity => q#టిజువానా#,
		},
		'America/Toronto' => {
			exemplarCity => q#టొరంటో#,
		},
		'America/Tortola' => {
			exemplarCity => q#టోర్టోలా#,
		},
		'America/Vancouver' => {
			exemplarCity => q#వాన్కూవర్#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#వైట్‌హార్స్#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#విన్నిపెగ్#,
		},
		'America/Yakutat' => {
			exemplarCity => q#యకుటాట్#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#మధ్యమ పగటి వెలుతురు సమయం#,
				'generic' => q#మధ్యమ సమయం#,
				'standard' => q#మధ్యమ ప్రామాణిక సమయం#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#తూర్పు పగటి వెలుతురు సమయం#,
				'generic' => q#తూర్పు సమయం#,
				'standard' => q#తూర్పు ప్రామాణిక సమయం#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#మౌంటెయిన్ పగటి వెలుతురు సమయం#,
				'generic' => q#మౌంటెయిన్ సమయం#,
				'standard' => q#మౌంటెయిన్ ప్రామాణిక సమయం#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#పసిఫిక్ పగటి వెలుతురు సమయం#,
				'generic' => q#పసిఫిక్ సమయం#,
				'standard' => q#పసిఫిక్ ప్రామాణిక సమయం#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#కేసీ#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#డెవిస్#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#డ్యూమాంట్ డి’ఉర్విల్లే#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#మకారీ#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#మాసన్#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#మెక్‌ముర్డో#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#పాల్మర్#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#రొతేరా#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#స్యోవా#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ట్రోల్#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#వోస్టోక్#,
		},
		'Apia' => {
			long => {
				'daylight' => q#ఏపియా పగటి సమయం#,
				'generic' => q#ఏపియా సమయం#,
				'standard' => q#ఏపియా ప్రామాణిక సమయం#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#అరేబియన్ పగటి వెలుతురు సమయం#,
				'generic' => q#అరేబియన్ సమయం#,
				'standard' => q#అరేబియన్ ప్రామాణిక సమయం#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#లాంగ్‌యియర్‌బైయన్#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ఆర్జెంటీనా వేసవి సమయం#,
				'generic' => q#అర్జెంటీనా సమయం#,
				'standard' => q#అర్జెంటీనా ప్రామాణిక సమయం#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#పశ్చిమ అర్జెంటీనా వేసవి సమయం#,
				'generic' => q#పశ్చిమ అర్జెంటీనా సమయం#,
				'standard' => q#పశ్చిమ అర్జెంటీనా ప్రామాణిక సమయం#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ఆర్మేనియా వేసవి సమయం#,
				'generic' => q#ఆర్మేనియా సమయం#,
				'standard' => q#ఆర్మేనియా ప్రామాణిక సమయం#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#ఎడెన్#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#ఆల్మాటి#,
		},
		'Asia/Amman' => {
			exemplarCity => q#అమ్మన్#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#అనడైర్#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#అక్టావ్#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#అక్టోబ్#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#యాష్గాబాట్#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#ఆటిరా#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#బాగ్దాద్#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#బహ్రెయిన్#,
		},
		'Asia/Baku' => {
			exemplarCity => q#బాకు#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#బ్యాంకాక్#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#బార్నాల్#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#బీరట్#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#బిష్కెక్#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#బ్రూనై#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#కోల్‌కతా#,
		},
		'Asia/Chita' => {
			exemplarCity => q#చితా#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#కొలంబో#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#డమాస్కస్#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ఢాకా#,
		},
		'Asia/Dili' => {
			exemplarCity => q#డిలి#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#దుబాయి#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#డుషన్బీ#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#ఫామగుస్టా#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#గాజా#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#హెబ్రాన్#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#హాంకాంగ్#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#హోవ్డ్#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#ఇర్కుట్స్క్#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#జకార్తా#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#జయపుర#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#జరూసలేం#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#కాబుల్#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#కమ్‌చత్కా#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#కరాచీ#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#ఖాట్మండు#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#కంద్యాగ#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#క్రసనోయార్స్క్#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#కౌలాలంపూర్#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#కుచింగ్#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#కువైట్#,
		},
		'Asia/Macau' => {
			exemplarCity => q#మకావ్#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#మగడాన్#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#మకాస్సర్#,
		},
		'Asia/Manila' => {
			exemplarCity => q#మనీలా#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#మస్కట్#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#నికోసియా#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#నొవొకుజ్‌నెట్‌స్క్#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#నవోసిబిర్స్క్#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#ఓమ్స్క్#,
		},
		'Asia/Oral' => {
			exemplarCity => q#ఓరల్#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#నోమ్‌పెన్హ్#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#పొన్టియనాక్#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#ప్యోంగాంగ్#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#ఖతార్#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#కోస్తానే#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#క్విజిలోర్డా#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#యాంగన్#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#రియాధ్#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#హో చి మిన్హ్ నగరం#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#సఖాలిన్#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#సమర్కాండ్#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#సియోల్#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#షాంఘై#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#సింగపూర్#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#స్రెడ్నెకొలిమ్స్క్#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#తైపీ#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#తాష్కెంట్#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#టిబిలిసి#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#టెహ్రాన్#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#థింఫు#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#టోక్యో#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#టామ్స్క్#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#ఉలాన్బాటర్#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#ఉరుమ్‌కీ#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#అస్ట్-నెరా#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#వియన్టైన్#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#వ్లాడివోస్టోక్#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#యకుట్స్క్#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#యెకటెరింబర్గ్#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#యెరెవన్#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#అట్లాంటిక్ పగటి వెలుతురు సమయం#,
				'generic' => q#అట్లాంటిక్ సమయం#,
				'standard' => q#అట్లాంటిక్ ప్రామాణిక సమయం#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#అజోర్స్#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#బెర్ముడా#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#కెనరీ#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#కేప్ వెర్డె#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#ఫారో#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#మదైరా#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#రెక్జావిక్#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#దక్షిణ జార్జియా#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#సెయింట్ హెలెనా#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#స్టాన్లీ#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#<exemplarCity>అడెలైడ్</exemplarCity>#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#బ్రిస్‌బెయిన్#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#బ్రోకెన్ హిల్#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#డార్విన్#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#యుక్లా#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#హోబర్ట్#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#లిండెమాన్#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#లార్డ్ హౌ#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#మెల్బోర్న్#,
		},
		'Australia/Perth' => {
			exemplarCity => q#పెర్త్#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#సిడ్నీ#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#ఆస్ట్రేలియా మధ్యమ పగటి వెలుతురు సమయం#,
				'generic' => q#ఆస్ట్రేలియా మధ్యమ సమయం#,
				'standard' => q#ఆస్ట్రేలియా మధ్యమ ప్రామాణిక సమయం#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#ఆస్ట్రేలియా మధ్యమ పశ్చిమ పగటి వెలుతురు సమయం#,
				'generic' => q#ఆస్ట్రేలియా మధ్యమ పశ్చిమ సమయం#,
				'standard' => q#మధ్యమ ఆస్ట్రేలియన్ పశ్చిమ ప్రామాణిక సమయం#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#ఆస్ట్రేలియన్ తూర్పు పగటి వెలుతురు సమయం#,
				'generic' => q#తూర్పు ఆస్ట్రేలియా సమయం#,
				'standard' => q#ఆస్ట్రేలియన్ తూర్పు ప్రామాణిక సమయం#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#ఆస్ట్రేలియన్ పశ్చిమ పగటి వెలుతురు సమయం#,
				'generic' => q#పశ్చిమ ఆస్ట్రేలియా సమయం#,
				'standard' => q#ఆస్ట్రేలియన్ పశ్చిమ ప్రామాణిక సమయం#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#అజర్బైజాన్ వేసవి సమయం#,
				'generic' => q#అజర్బైజాన్ సమయం#,
				'standard' => q#అజర్బైజాన్ ప్రామాణిక సమయం#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#అజోర్స్ వేసవి సమయం#,
				'generic' => q#అజోర్స్ సమయం#,
				'standard' => q#అజోర్స్ ప్రామాణిక సమయం#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#బంగ్లాదేశ్ వేసవి సమయం#,
				'generic' => q#బంగ్లాదేశ్ సమయం#,
				'standard' => q#బంగ్లాదేశ్ ప్రామాణిక సమయం#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#భూటాన్ సమయం#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#బొలీవియా సమయం#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#బ్రెజిలియా వేసవి సమయం#,
				'generic' => q#బ్రెజిలియా సమయం#,
				'standard' => q#బ్రెజిలియా ప్రామాణిక సమయం#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#బ్రూనే దరుసలామ్ సమయం#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#కేప్ వెర్డె వేసవి సమయం#,
				'generic' => q#కేప్ వెర్డె సమయం#,
				'standard' => q#కేప్ వెర్డె ప్రామాణిక సమయం#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#చామర్రో ప్రామాణిక సమయం#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#చాథమ్ పగటి వెలుతురు సమయం#,
				'generic' => q#చాథమ్ సమయం#,
				'standard' => q#చాథమ్ ప్రామాణిక సమయం#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#చిలీ వేసవి సమయం#,
				'generic' => q#చిలీ సమయం#,
				'standard' => q#చిలీ ప్రామాణిక సమయం#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#చైనా పగటి వెలుతురు సమయం#,
				'generic' => q#చైనా సమయం#,
				'standard' => q#చైనా ప్రామాణిక సమయం#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#క్రిస్మస్ దీవి సమయం#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#కోకోస్ దీవుల సమయం#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#కొలంబియా వేసవి సమయం#,
				'generic' => q#కొలంబియా సమయం#,
				'standard' => q#కొలంబియా ప్రామాణిక సమయం#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#కుక్ దీవుల అర్ధ వేసవి సమయం#,
				'generic' => q#కుక్ దీవుల సమయం#,
				'standard' => q#కుక్ దీవుల ప్రామాణిక సమయం#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#క్యూబా పగటి వెలుతురు సమయం#,
				'generic' => q#క్యూబా సమయం#,
				'standard' => q#క్యూబా ప్రామాణిక సమయం#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#డేవిస్ సమయం#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#డ్యూమాంట్-డి’ఉర్విల్లే సమయం#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#తూర్పు తైమూర్ సమయం#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ఈస్టర్ దీవి వేసవి సమయం#,
				'generic' => q#ఈస్టర్ దీవి సమయం#,
				'standard' => q#ఈస్టర్ దీవి ప్రామాణిక సమయం#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ఈక్వడార్ సమయం#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#సమన్వయ సార్వజనీన సమయం#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#తెలియని నగరం#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#ఆమ్‌స్టర్‌డామ్#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#అండోరా#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#అస్ట్రఖాన్#,
		},
		'Europe/Athens' => {
			exemplarCity => q#ఏథెన్స్#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#బెల్‌గ్రేడ్#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#బెర్లిన్#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#బ్రాటిస్లావా#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#బ్రస్సెల్స్#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#బుకారెస్ట్#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#బుడాపెస్ట్#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#బసింజన్#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#చిసినావ్#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#కోపెన్హాగన్#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#డబ్లిన్#,
			long => {
				'daylight' => q#ఐరిష్ ప్రామాణిక సమయం#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#జిబ్రాల్టర్#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#గ్వెర్న్సే#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#హెల్సింకి#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#ఐల్ ఆఫ్ మేన్#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#ఇస్తాంబుల్#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#జెర్సీ#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#కలినిన్‌గ్రద్#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#కీవ్#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#కిరోవ్#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#లిస్బన్#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#ల్యూబ్ల్యానా#,
		},
		'Europe/London' => {
			exemplarCity => q#లండన్#,
			long => {
				'daylight' => q#బ్రిటీష్ వేసవి సమయం#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#లక్సెంబర్గ్#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#మాడ్రిడ్#,
		},
		'Europe/Malta' => {
			exemplarCity => q#మాల్టా#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#మారీయుహమ్#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#మిన్స్క్#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#మొనాకో#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#మాస్కో#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#ఓస్లో#,
		},
		'Europe/Paris' => {
			exemplarCity => q#ప్యారిస్#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#పోడ్గోరికా#,
		},
		'Europe/Prague' => {
			exemplarCity => q#ప్రాగ్#,
		},
		'Europe/Riga' => {
			exemplarCity => q#రీగా#,
		},
		'Europe/Rome' => {
			exemplarCity => q#రోమ్#,
		},
		'Europe/Samara' => {
			exemplarCity => q#సమార#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#శాన్ మారినో#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#సరాజోవో#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#సరాటవ్#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#సిమ్‌ఫెరోపోల్#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#స్కోప్‌యే#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#సోఫియా#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#స్టాక్హోమ్#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#తాల్లిన్#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#టిరేన్#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#ఉల్యనోవ్స్క్#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#వాడుజ్#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#వాటికన్#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#వియన్నా#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#విల్నియస్#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#వోల్గోగ్రాడ్#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#వార్షా#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#జాగ్రెబ్#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#జ్యూరిచ్#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#సెంట్రల్ యూరోపియన్ వేసవి సమయం#,
				'generic' => q#సెంట్రల్ యూరోపియన్ సమయం#,
				'standard' => q#సెంట్రల్ యూరోపియన్ ప్రామాణిక సమయం#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#తూర్పు యూరోపియన్ వేసవి సమయం#,
				'generic' => q#తూర్పు యూరోపియన్ సమయం#,
				'standard' => q#తూర్పు యూరోపియన్ ప్రామాణిక సమయం#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#సుదూర-తూర్పు యూరోపియన్ సమయం#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#పశ్చిమ యూరోపియన్ వేసవి సమయం#,
				'generic' => q#పశ్చిమ యూరోపియన్ సమయం#,
				'standard' => q#పశ్చిమ యూరోపియన్ ప్రామాణిక సమయం#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ఫాక్‌ల్యాండ్ దీవుల వేసవి సమయం#,
				'generic' => q#ఫాక్‌ల్యాండ్ దీవుల సమయం#,
				'standard' => q#ఫాక్‌ల్యాండ్ దీవుల ప్రామాణిక సమయం#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#ఫిజీ వేసవి సమయం#,
				'generic' => q#ఫిజీ సమయం#,
				'standard' => q#ఫిజీ ప్రామాణిక సమయం#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ఫ్రెంచ్ గయానా సమయం#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#ఫ్రెంచ్ దక్షిణ మరియు అంటార్కిటిక్ సమయం#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#గ్రీన్‌విచ్ సగటు సమయం#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#గాలాపాగోస్ సమయం#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#గాంబియర్ సమయం#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#జార్జియా వేసవి సమయం#,
				'generic' => q#జార్జియా సమయం#,
				'standard' => q#జార్జియా ప్రామాణిక సమయం#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#గిల్బర్ట్ దీవుల సమయం#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#తూర్పు గ్రీన్‌ల్యాండ్ వేసవి సమయం#,
				'generic' => q#తూర్పు గ్రీన్‌ల్యాండ్ సమయం#,
				'standard' => q#తూర్పు గ్రీన్‌ల్యాండ్ ప్రామాణిక సమయం#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#పశ్చిమ గ్రీన్‌ల్యాండ్ వేసవి సమయం#,
				'generic' => q#పశ్చిమ గ్రీన్‌ల్యాండ్ సమయం#,
				'standard' => q#పశ్చిమ గ్రీన్‌ల్యాండ్ ప్రామాణిక సమయం#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#గల్ఫ్ ప్రామాణిక సమయం#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#గయానా సమయం#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#హవాయ్-అల్యూషియన్ పగటి వెలుతురు సమయం#,
				'generic' => q#హవాయ్-అల్యూషియన్ సమయం#,
				'standard' => q#హవాయ్-అల్యూషియన్ ప్రామాణిక సమయం#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#హాంకాంగ్ వేసవి సమయం#,
				'generic' => q#హాంకాంగ్ సమయం#,
				'standard' => q#హాంకాంగ్ ప్రామాణిక సమయం#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#హోవ్డ్ వేసవి సమయం#,
				'generic' => q#హోవ్డ్ సమయం#,
				'standard' => q#హోవ్డ్ ప్రామాణిక సమయం#,
			},
		},
		'India' => {
			long => {
				'standard' => q#భారతదేశ ప్రామాణిక సమయం#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#అంటానానారివో#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#చాగోస్#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#క్రిస్మస్#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#కోకోస్#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#కొమోరో#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#కెర్గ్యూలెన్#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#మాహె#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#మాల్దీవులు#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#మారిషస్#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#మయోట్#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#రీయూనియన్#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#హిందూ మహా సముద్ర సమయం#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#ఇండోచైనా సమయం#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#సెంట్రల్ ఇండోనేషియా సమయం#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#తూర్పు ఇండోనేషియా సమయం#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#పశ్చిమ ఇండోనేషియా సమయం#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ఇరాన్ పగటి వెలుతురు సమయం#,
				'generic' => q#ఇరాన్ సమయం#,
				'standard' => q#ఇరాన్ ప్రామాణిక సమయం#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ఇర్కుట్స్క్ వేసవి సమయం#,
				'generic' => q#ఇర్కుట్స్క్ సమయం#,
				'standard' => q#ఇర్కుట్స్క్ ప్రామాణిక సమయం#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ఇజ్రాయిల్ పగటి వెలుతురు సమయం#,
				'generic' => q#ఇజ్రాయిల్ సమయం#,
				'standard' => q#ఇజ్రాయిల్ ప్రామాణిక సమయం#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#జపాన్ పగటి వెలుతురు సమయం#,
				'generic' => q#జపాన్ సమయం#,
				'standard' => q#జపాన్ ప్రామాణిక సమయం#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#కజకి‌స్తాన్ సమయం#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#తూర్పు కజకి‌స్తాన్ సమయం#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#పశ్చిమ కజకిస్తాన్ సమయం#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#కొరియన్ పగటి వెలుతురు సమయం#,
				'generic' => q#కొరియన్ సమయం#,
				'standard' => q#కొరియన్ ప్రామాణిక సమయం#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#కోస్రాయి సమయం#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#క్రాస్నోయార్స్క్ వేసవి సమయం#,
				'generic' => q#క్రాస్నోయార్స్క్ సమయం#,
				'standard' => q#క్రాస్నోయార్స్క్ ప్రామాణిక సమయం#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#కిర్గిస్తాన్ సమయం#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#లైన్ దీవుల సమయం#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#లార్డ్ హోవ్ పగటి సమయం#,
				'generic' => q#లార్డ్ హోవ్ సమయం#,
				'standard' => q#లార్డ్ హోవ్ ప్రామాణిక సమయం#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#మగడాన్ వేసవి సమయం#,
				'generic' => q#మగడాన్ సమయం#,
				'standard' => q#మగడాన్ ప్రామాణిక సమయం#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#మలేషియా సమయం#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#మాల్దీవుల సమయం#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#మార్క్వేసాస్ సమయం#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#మార్షల్ దీవుల సమయం#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#మారిషస్ వేసవి సమయం#,
				'generic' => q#మారిషస్ సమయం#,
				'standard' => q#మారిషస్ ప్రామాణిక సమయం#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#మాసన్ సమయం#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#మెక్సికన్ పసిఫిక్ పగటి వెలుతురు సమయం#,
				'generic' => q#మెక్సికన్ పసిఫిక్ సమయం#,
				'standard' => q#మెక్సికన్ పసిఫిక్ ప్రామాణిక సమయం#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ఉలన్ బతోర్ వేసవి సమయం#,
				'generic' => q#ఉలన్ బతోర్ సమయం#,
				'standard' => q#ఉలన్ బతోర్ ప్రామాణిక సమయం#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#మాస్కో వేసవి సమయం#,
				'generic' => q#మాస్కో సమయం#,
				'standard' => q#మాస్కో ప్రామాణిక సమయం#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#మయన్మార్ సమయం#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#నౌరు సమయం#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#నేపాల్ సమయం#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#న్యూ కాలెడోనియా వేసవి సమయం#,
				'generic' => q#న్యూ కాలెడోనియా సమయం#,
				'standard' => q#న్యూ కాలెడోనియా ప్రామాణిక సమయం#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#న్యూజిల్యాండ్ పగటి వెలుతురు సమయం#,
				'generic' => q#న్యూజిల్యాండ్ సమయం#,
				'standard' => q#న్యూజిల్యాండ్ ప్రామాణిక సమయం#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#న్యూఫౌండ్‌ల్యాండ్ పగటి వెలుతురు సమయం#,
				'generic' => q#న్యూఫౌండ్‌ల్యాండ్ సమయం#,
				'standard' => q#న్యూఫౌండ్‌ల్యాండ్ ప్రామాణిక సమయం#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#నియూ సమయం#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#నార్ఫోక్ దీవి పగటి సమయం#,
				'generic' => q#నార్ఫోక్ దీవి సమయం#,
				'standard' => q#నార్ఫోక్ దీవి ప్రామాణిక సమయం#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ఫెర్నాండో డి నొరోన్హా వేసవి సమయం#,
				'generic' => q#ఫెర్నాండో డి నొరోన్హా సమయం#,
				'standard' => q#ఫెర్నాండో డి నొరోన్హా ప్రామాణిక సమయం#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#నోవోసిబిర్స్క్ వేసవి సమయం#,
				'generic' => q#నోవోసిబిర్స్క్ సమయం#,
				'standard' => q#నోవోసిబిర్క్స్ ప్రామాణిక సమయం#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ఓమ్స్క్ వేసవి సమయం#,
				'generic' => q#ఓమ్స్క్ సమయం#,
				'standard' => q#ఓమ్స్క్ ప్రామాణిక సమయం#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#ఏపియా#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#ఆక్లాండ్#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#బొగెయిన్‌విల్లే#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#చాథమ్#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#ఈస్టర్#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#ఇఫేట్#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#ఫాకోఫో#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#ఫీజీ#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#ఫునాఫుటి#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#గాలాపాగోస్#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#గాంబియేర్#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#గ్వాడల్కెనాల్#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#గ్వామ్#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#కాంటన్#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#కిరీటిమాటి#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#కోస్రే#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#క్వాజాలైన్#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#మజురో#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#మార్క్వేసాస్#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#మిడ్వే#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#నౌరు#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#నియూ#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#నోర్ఫోక్#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#నౌమియా#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#పాగో పాగో#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#పాలావ్#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#పిట్‌కైర్న్#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#పోన్‌పై#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#పోర్ట్ మోరెస్బే#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#రరోటోంగా#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#సాయ్పాన్#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#తహితి#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#టరావా#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#టోంగాటాపు#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#చుక్#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#వేక్#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#వాల్లిస్#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#పాకిస్తాన్ వేసవి సమయం#,
				'generic' => q#పాకిస్తాన్ సమయం#,
				'standard' => q#పాకిస్తాన్ ప్రామాణిక సమయం#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#పాలావ్ సమయం#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#పాపువా న్యూ గినియా సమయం#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#పరాగ్వే వేసవి సమయం#,
				'generic' => q#పరాగ్వే సమయం#,
				'standard' => q#పరాగ్వే ప్రామాణిక సమయం#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#పెరూ వేసవి సమయం#,
				'generic' => q#పెరూ సమయం#,
				'standard' => q#పెరూ ప్రామాణిక సమయం#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#ఫిలిప్పైన్ వేసవి సమయం#,
				'generic' => q#ఫిలిప్పైన్ సమయం#,
				'standard' => q#ఫిలిప్పైన్ ప్రామాణిక సమయం#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#ఫినిక్స్ దీవుల సమయం#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#సెయింట్ పియర్ మరియు మిక్వెలాన్ పగటి వెలుతురు సమయం#,
				'generic' => q#సెయింట్ పియెర్ మరియు మిక్వెలాన్ సమయం#,
				'standard' => q#సెయింట్ పియెర్ మరియు మిక్వెలాన్ ప్రామాణిక సమయం#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#పిట్‌కైర్న్ సమయం#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#పొనేప్ సమయం#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#ప్యోంగాంగ్ సమయం#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#రీయూనియన్ సమయం#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#రొతేరా సమయం#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#సఖాలిన్ వేసవి సమయం#,
				'generic' => q#సఖాలిన్ సమయం#,
				'standard' => q#సఖాలిన్ ప్రామాణిక సమయం#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#సమోవా పగటి వెలుతురు సమయం#,
				'generic' => q#సమోవా సమయం#,
				'standard' => q#సమోవా ప్రామాణిక సమయం#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#సీషెల్స్ సమయం#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#సింగపూర్ ప్రామాణిక సమయం#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#సోలమన్ దీవుల సమయం#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#దక్షిణ జార్జియా సమయం#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#సూరినామ్ సమయం#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#స్యోవా సమయం#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#తహితి సమయం#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#తైపీ పగటి వెలుతురు సమయం#,
				'generic' => q#తైపీ సమయం#,
				'standard' => q#తైపీ ప్రామాణిక సమయం#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#తజికిస్తాన్ సమయం#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#టోకెలావ్ సమయం#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#టాంగా వేసవి సమయం#,
				'generic' => q#టాంగా సమయం#,
				'standard' => q#టాంగా ప్రామాణిక సమయం#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#చక్ సమయం#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#తుర్క్‌మెనిస్తాన్ వేసవి సమయం#,
				'generic' => q#తుర్క్‌మెనిస్తాన్ సమయం#,
				'standard' => q#తుర్క్‌మెనిస్తాన్ ప్రామాణిక సమయం#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#తువాలు సమయం#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#ఉరుగ్వే వేసవి సమయం#,
				'generic' => q#ఉరుగ్వే సమయం#,
				'standard' => q#ఉరుగ్వే ప్రామాణిక సమయం#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ఉజ్బెకిస్తాన్ వేసవి సమయం#,
				'generic' => q#ఉజ్బెకిస్తాన్ సమయం#,
				'standard' => q#ఉజ్బెకిస్తాన్ ప్రామాణిక సమయం#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#వనౌటు వేసవి సమయం#,
				'generic' => q#వనౌటు సమయం#,
				'standard' => q#వనౌటు ప్రామాణిక సమయం#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#వెనిజులా సమయం#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#వ్లాడివోస్టోక్ వేసవి సమయం#,
				'generic' => q#వ్లాడివోస్టోక్ సమయం#,
				'standard' => q#వ్లాడివోస్టోక్ ప్రామాణిక సమయం#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#వోల్గోగ్రాడ్ వేసవి సమయం#,
				'generic' => q#వోల్గోగ్రాడ్ సమయం#,
				'standard' => q#వోల్గోగ్రాడ్ ప్రామాణిక సమయం#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#వోస్టోక్ సమయం#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#వేక్ దీవి సమయం#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#వాలీస్ మరియు ఫుటునా సమయం#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#యాకుట్స్క్ వేసవి సమయం#,
				'generic' => q#యాకుట్స్క్ సమయం#,
				'standard' => q#యాకుట్స్క్ ప్రామాణిక సమయం#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#యెకటెరిన్‌బర్గ్ వేసవి సమయం#,
				'generic' => q#యెకటెరిన్‌బర్గ్ సమయం#,
				'standard' => q#యెకటెరిన్‌బర్గ్ ప్రామాణిక సమయం#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
