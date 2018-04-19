=head1

Locale::CLDR::Locales::As - Package for language Assamese

=cut

package Locale::CLDR::Locales::As;
# This file auto generated from Data\common\main\as.xml
#	on Fri 13 Apr  7:01:25 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'as' => 'অসমীয়া',
 				'es_419' => 'লেটিন আমেৰিকান স্পেনিচ',
 				'ie' => 'উপস্থাপন ভাষা',
 				'km' => 'কম্বোডিয়ান',

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
			'Beng' => 'বঙালী',

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
			'053' => 'অস্ট্রেলেশিয়া',
 			'054' => 'ম্যালেনেশিয়া',
 			'057' => 'মাইক্রোনেশিয়ান অঞ্চল (অনুবাদ সংকেত: সতর্কতা, ডানদিকে তথ্য প্যানেল দেখুন।)',
 			'AC' => 'অ্যাসেনশন আইল্যান্ড',
 			'AD' => 'এ্যান্ডোরা',
 			'AE' => 'UAE',
 			'AF' => 'আফগানিস্তান',
 			'AI' => 'এ্যাঙ্গুইলা',
 			'AL' => 'আল্বেনিয়া',
 			'AM' => 'আরমেনিয়া',
 			'AO' => 'অ্যাঙ্গোলা',
 			'AQ' => 'এন্টাৰ্টিকা',
 			'AR' => 'আর্জিণ্টিনা',
 			'AS' => 'আমেরিকান সামোয়া',
 			'AT' => 'অস্ট্রিয়া',
 			'AU' => 'অস্ট্রেলিয়া',
 			'AX' => 'আলে্যান্ড দ্বীপপুঞ্জ',
 			'AZ' => 'আজেরবাইজান',
 			'BA' => 'বসনিয়া ও হারজেগোভিনা',
 			'BD' => 'বাংলাদেশ',
 			'BE' => 'বেলজিয়াম',
 			'BF' => 'বুর্কিনা ফাসো',
 			'BG' => 'বুলগেরিয়া',
 			'BH' => 'বাহরাইন',
 			'BI' => 'বুরুন্ডি',
 			'BJ' => 'বেনিন',
 			'BN' => 'ব্রুনেই',
 			'BO' => 'বোলিভিয়া',
 			'BR' => 'ব্রাজিল',
 			'BT' => 'ভুটান',
 			'BV' => 'বভেট দ্বীপ',
 			'BW' => 'বোট্স্বানা',
 			'BY' => 'বেলারুশ',
 			'CC' => 'কোকোস (কিলিং) দ্বীপপুঞ্জ',
 			'CD' => 'কঙ্গো - কিনসাসা',
 			'CD@alt=variant' => 'কঙ্গো (DRC)',
 			'CF' => 'মধ্য আফ্রিকান প্রজাতন্ত্র',
 			'CG' => 'কঙ্গো - ব্রাজাভিল',
 			'CG@alt=variant' => 'কঙ্গো (প্রজাতন্ত্র)',
 			'CH' => 'সুইজর্লণ্ড',
 			'CI' => 'আইভরি কোস্ট',
 			'CK' => 'কুক দ্বীপপুঞ্জ',
 			'CL' => 'চিলি',
 			'CM' => 'ক্যামেরুন',
 			'CN' => 'চীন',
 			'CO' => 'কলোমবিয়া',
 			'CP' => 'ক্লিপারটন দ্বীপ',
 			'CV' => 'কেপ ভার্দে',
 			'CX' => 'ক্রিস্টমাস দ্বীপ',
 			'CY' => 'সাইপ্রাসদ্বিপ',
 			'CZ@alt=variant' => 'চেক প্রজাতন্ত্র',
 			'DE' => 'জাৰ্মানি',
 			'DG' => 'দিয়েগো গার্সিয়া',
 			'DJ' => 'জিবুতি',
 			'DK' => 'ডেন্মার্ক্',
 			'DZ' => 'আলজেরিয়া',
 			'EA' => 'কিউটা & ম্লিলা',
 			'EC' => 'ইকোয়াডর',
 			'EE' => 'এস্তোনিয়াদেশ',
 			'EG' => 'মিশর',
 			'EH' => 'পশ্চিম সাহারা',
 			'ER' => 'ইরিত্রিয়া',
 			'ES' => 'স্পেন',
 			'ET' => 'ইথিওপিয়া',
 			'FI' => 'ফিনল্যাণ্ড',
 			'FJ' => 'ফিজি',
 			'FK' => 'ফকল্যান্ড দ্বীপপুঞ্জ',
 			'FM' => 'মাইক্রোনেশিয়া',
 			'FO' => 'ফারো দ্বীপপুঞ্জ',
 			'FR' => 'ফ্ৰান্স',
 			'GA' => 'গাবোনবাদ্যযন্ত্র',
 			'GB' => 'সংযুক্ত ৰাজ্য',
 			'GB@alt=short' => 'যুক্তরাজ্য',
 			'GE' => 'জর্জিয়া',
 			'GF' => 'একটি দেশের নাম',
 			'GG' => 'গেঁজি',
 			'GH' => 'ঘানা',
 			'GI' => 'জিব্রালটার',
 			'GM' => 'গাম্বিয়াদেশ',
 			'GN' => 'গিনি',
 			'GQ' => 'নিরক্ষীয় গিনি',
 			'GR' => 'গ্রীস',
 			'GS' => 'দক্ষিণ জৰ্জিয়া আৰু দক্ষিণ চেণ্ডৱিচ্‌ দ্বীপপুঞ্জ',
 			'GU' => 'গুয়াম',
 			'GW' => 'গিনি-বিসাউ',
 			'GY' => 'গায়ানা',
 			'HK' => 'হংকং এসএআর চীন',
 			'HK@alt=short' => 'হংকং',
 			'HM' => 'হাৰ্ড দ্বীপ আৰু মেক্‌ডোনাল্ড দ্বীপ',
 			'HR' => 'ক্রোয়েশিয়া',
 			'HU' => 'হাঙ্গেরি',
 			'IC' => 'ক্যানারি দ্বীপপুঞ্জ',
 			'ID' => 'ইন্দোনেশিয়া',
 			'IE' => 'আয়ারল্যাণ্ড',
 			'IL' => 'ইস্রায়েল',
 			'IM' => 'আইল অফ ম্যান',
 			'IN' => 'ভারত',
 			'IO' => 'ব্ৰিটিশ্ব ইণ্ডিয়ান মহাসাগৰৰ অঞ্চল',
 			'IQ' => 'ইরাক',
 			'IR' => 'ইরান',
 			'IS' => 'আইস্ল্যাণ্ড',
 			'IT' => 'ইটালি',
 			'JE' => 'জার্সি',
 			'JO' => 'জর্ডন',
 			'JP' => 'জাপান',
 			'KE' => 'কেনিয়া',
 			'KG' => 'কিরগিজস্তান',
 			'KH' => 'কাম্বোজ',
 			'KI' => 'কিরিবাতি',
 			'KM' => 'কমোরোস',
 			'KP' => 'উত্তর কোরিয়া',
 			'KR' => 'দক্ষিণ কোরিয়া',
 			'KW' => 'কুয়েত',
 			'KZ' => 'কাজাকস্থান',
 			'LA' => 'লাত্তস',
 			'LB' => 'লেবানন',
 			'LI' => 'লিচেনস্টেইন',
 			'LK' => 'শ্রীলংকা',
 			'LR' => 'লাইবেরিয়া',
 			'LS' => 'লেসোথো',
 			'LT' => 'লিত্ভা',
 			'LU' => 'লাক্সেমবার্গ',
 			'LV' => 'ল্যাট্ভিআ',
 			'LY' => 'লিবিয়া',
 			'MA' => 'মরক্কো',
 			'MC' => 'মোনাকো',
 			'MD' => 'মোল্দাভিয়া',
 			'ME' => 'মন্টিনিগ্রো',
 			'MG' => 'ম্যাডাগ্যাস্কার',
 			'MH' => 'মার্শাল দ্বীপপুঞ্জ',
 			'MK' => 'ম্যাসাডোনিয়া',
 			'ML' => 'মালি',
 			'MM' => 'মায়ানমার (বার্মা)',
 			'MN' => 'মঙ্গোলিআ',
 			'MO' => 'ম্যাকাও এসএআর চীন',
 			'MO@alt=short' => 'ম্যাকা',
 			'MP' => 'উত্তর মারিয়ানা দ্বীপপুঞ্জ',
 			'MR' => 'মরিতানিয়া',
 			'MT' => 'মালটা',
 			'MU' => 'মরিশাস',
 			'MV' => 'মালদ্বীপ',
 			'MW' => 'মালাউই',
 			'MY' => 'মাল্যাশিয়া',
 			'MZ' => 'মোজাম্বিক',
 			'NA' => 'নামিবিয়া',
 			'NC' => 'নতুন ক্যালেডোনিয়া',
 			'NE' => 'নাইজারনদী',
 			'NF' => 'নরফোক দ্বীপ',
 			'NG' => 'নাইজিরিয়াদেশ',
 			'NL' => 'নেদারল্যান্ডস',
 			'NO' => 'নরত্তএদেশ',
 			'NP' => 'নেপাল',
 			'NR' => 'নাউরু',
 			'NU' => 'নিউই',
 			'NZ' => 'নিউজিল্যান্ড',
 			'OM' => 'ওমান',
 			'PE' => 'পেরু',
 			'PF' => 'ফরাসি পলিনেশিয়া',
 			'PG' => 'পাপুয়া নিউ গিনি',
 			'PH' => 'ফিলিপাইন',
 			'PK' => 'পাকিস্তান',
 			'PL' => 'পোল্যান্ড',
 			'PN' => 'পিটকেয়ার্ন দ্বীপপুঞ্জ',
 			'PS' => 'ফিলিস্তিন অঞ্চল',
 			'PS@alt=short' => 'ফিলিস্তিন',
 			'PT' => 'পর্তুগাল',
 			'PW' => 'পালাউ',
 			'PY' => 'প্যারাগুয়ে',
 			'QA' => 'কাতার',
 			'RE' => 'সাক্ষাৎ',
 			'RO' => 'রুমানিয়া',
 			'RS' => 'সার্বিয়া',
 			'RU' => 'রাশিয়া',
 			'RW' => 'রুয়ান্ডা',
 			'SA' => 'সৌদি আরব',
 			'SB' => 'সলোমান দ্বীপপুঞ্জ',
 			'SC' => 'সিসিলি',
 			'SD' => 'সুদান',
 			'SE' => 'সুইডেন',
 			'SG' => 'সিঙ্গাপুর',
 			'SH' => 'সেন্ট হেলেনা',
 			'SI' => 'স্লোভানিয়া',
 			'SJ' => 'সাভালবার্ড ও জান মেন',
 			'SK' => 'শ্লোভাকিয়া',
 			'SL' => 'সিয়েরা লিওন',
 			'SM' => 'সান মেরিনো',
 			'SN' => 'সেনেগাল',
 			'SO' => 'সোমালিয়া',
 			'SR' => 'সুরিনাম',
 			'SS' => 'দক্ষিণ সুদান',
 			'ST' => 'সাও টোম এবং প্রিনসিপে',
 			'SY' => 'সিরিয়া',
 			'SZ' => 'সোয়াজিল্যান্ড',
 			'TA' => 'ট্রিস্টান ডা কুনা',
 			'TD' => 'মত্স্যবিশেষ',
 			'TF' => 'দক্ষিণ ফ্ৰান্সৰ অঞ্চল',
 			'TG' => 'যাও',
 			'TH' => 'থাইল্যান্ড',
 			'TJ' => 'তাজিকস্থান',
 			'TK' => 'টোকেলাউ',
 			'TL' => 'পূর্ব তিমুর',
 			'TM' => 'তুর্কমেনিয়া',
 			'TN' => 'টিউনিস্',
 			'TO' => 'টাঙ্গা',
 			'TR' => 'তুরস্ক',
 			'TV' => 'টুভালু',
 			'TW' => 'তাইওয়ান',
 			'TZ' => 'তাঞ্জানিয়া',
 			'UA' => 'ইউক্রেইন্',
 			'UG' => 'উগান্ডা',
 			'UM' => 'ইউ এস আউটলিং আইল্যান্ডস',
 			'US' => 'যুক্তৰাষ্ট্ৰ',
 			'UY' => 'উরুগুয়ে',
 			'UZ' => 'উজ্বেকিস্থান',
 			'VA' => 'ভ্যাটিকান সিটি',
 			'VE' => 'ভেনেজুয়েলা',
 			'VN' => 'ভিয়েতনাম',
 			'VU' => 'ভানুয়াতু',
 			'WF' => 'ওয়ালিস ও ফুটুনা',
 			'WS' => 'সামোয়া',
 			'XK' => 'কসোভো',
 			'YE' => 'ইমেন',
 			'YT' => 'মায়োত্তে',
 			'ZA' => 'দক্ষিন আফ্রিকা',
 			'ZM' => 'জাম্বিয়া',
 			'ZW' => 'জিম্বাবুয়ে',
 			'ZZ' => 'অজ্ঞাত অঞ্চল',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'পঞ্জিকা',
 			'collation' => 'শৰীকৰণ',
 			'currency' => 'মুদ্ৰা',

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
 				'buddhist' => q{বৌদ্ধ পঞ্জিকা},
 				'chinese' => q{চীনা পঞ্জিকা},
 				'gregorian' => q{গ্ৰিগোৰীয় পঞ্জিকা},
 				'hebrew' => q{হীব্ৰু পঞ্জিকা},
 				'indian' => q{ভাৰতীয় ৰাষ্ট্ৰীয় পঞ্জিকা},
 				'islamic' => q{ইচলামী পঞ্জিকা},
 				'islamic-civil' => q{ইচলামী-নাগৰিকৰ পঞ্জিকা},
 				'iso8601' => q{iso8601},
 				'japanese' => q{জাপানী পঞ্জিকা},
 				'roc' => q{চীনা গণৰাজ্যৰ পঞ্জিকা},
 			},
 			'collation' => {
 				'big5han' => q{পৰম্পৰাগত চীনা শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম - Big5},
 				'gb2312han' => q{সৰল চীনা শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম - GB2312},
 				'phonebook' => q{টেলিফোন বহিৰ মতেশৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম},
 				'pinyin' => q{পিন্‌য়িন শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম},
 				'standard' => q{standard},
 				'stroke' => q{স্ট্ৰোক শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম},
 				'traditional' => q{পৰম্পৰাগতভাবে শৃঙ্খলাবদ্ধ কৰাৰ ক্ৰম},
 			},
 			'numbers' => {
 				'beng' => q{beng},
 				'latn' => q{latn},
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
			'metric' => q{মেট্ৰিক},
 			'UK' => q{UK},
 			'US' => q{US},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

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
			auxiliary => qr{[‌‍ ৲ ৎ র]},
			index => ['অ', 'আ', 'ই', 'ঈ', 'উ', 'ঊ', 'ঋ', 'ৠ', 'ঌ', 'ৡ', 'এ', 'ঐ', 'ও', 'ঔ', 'ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ', 'ছ', 'জ', 'ঝ', 'ঞ', 'ট', 'ঠ', 'ড', 'ঢ', 'ণ', 'ৎ', 'ত', 'থ', 'দ', 'ধ', 'ন', 'প', 'ফ', 'ব', 'ভ', 'ম', 'য', 'ৰ', 'ল', 'ৱ', 'শ', 'ষ', 'স', 'হ', 'ঽ'],
			main => qr{[় অ আ ই ঈ উ ঊ ঋ এ ঐ ও ঔ ং ঁ ঃ ক খ গ ঘ ঙ চ ছ জ ঝ ঞ ট ঠ ড {ড়} ঢ {ঢ়} ণ ত থ দ ধ ন প ফ ব ভ ম য {য়} ৰ ল ৱ শ ষ স হ {ক্ষ} া ি ী ু ূ ৃ ে ৈ ো ৌ ্]},
			numbers => qr{[\- , . % ‰ + 0০ 1১ 2২ 3৩ 4৪ 5৫ 6৬ 7৭ 8৮ 9৯]},
		};
	},
EOT
: sub {
		return { index => ['অ', 'আ', 'ই', 'ঈ', 'উ', 'ঊ', 'ঋ', 'ৠ', 'ঌ', 'ৡ', 'এ', 'ঐ', 'ও', 'ঔ', 'ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ', 'ছ', 'জ', 'ঝ', 'ঞ', 'ট', 'ঠ', 'ড', 'ঢ', 'ণ', 'ৎ', 'ত', 'থ', 'দ', 'ধ', 'ন', 'প', 'ফ', 'ব', 'ভ', 'ম', 'য', 'ৰ', 'ল', 'ৱ', 'শ', 'ষ', 'স', 'হ', 'ঽ'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(acre),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(চাপসেকেন্ড),
						'one' => q({0}চাপসেকেন্ড),
						'other' => q({0}চাপসেকেন্ড),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(শতাব্দী),
						'one' => q({0} শতাব্দী),
						'other' => q({0} শতাব্দী),
					},
					'coordinate' => {
						'east' => q({0} পূর্ব),
						'north' => q({0}উত্তর),
						'south' => q({0}দক্ষিণ),
						'west' => q({0}পশ্চিমে),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cup),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(দিন),
						'one' => q({0} দিন),
						'other' => q({0} দিন),
						'per' => q({0} প্ৰতি দিন),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(ডিগ্রী),
						'one' => q({0}ডিগ্রী),
						'other' => q({0}ডিগ্রী),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(g-force),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(US gal),
						'one' => q({0} gal US),
						'other' => q({0} gal US),
						'per' => q({0}/gal US),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hectare),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(ঘণ্টা),
						'one' => q({0} ঘণ্টা),
						'other' => q({0} ঘণ্টা),
						'per' => q({0} প্ৰতি ঘণ্টা),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(পার্সি এর ইঞ্চি),
						'one' => q({0}পার্সি এর ইঞ্চি),
						'other' => q({0}পার্সি এর ইঞ্চি),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(কিলোগ্রাম),
						'one' => q({0}কিলোগ্রাম),
						'other' => q({0}কিলোগ্রাম),
						'per' => q({0}কিলোগ্রাম প্রতি),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(প্রতি 100 কিলোমিটার লাইট),
						'one' => q({0}প্রতি 100 কিলোমিটার লাইট),
						'other' => q({0}প্রতি 100 কিলোমিটার লাইট),
					},
					'liter-per-kilometer' => {
						'name' => q(কিলোমিটার প্রতি লিটার),
						'one' => q({0}কিলোমিটার প্রতি লিটার),
						'other' => q({0}কিলোমিটার প্রতি লিটার),
					},
					'lux' => {
						'name' => q(দীপনমাত্রা),
						'one' => q({0}দীপনমাত্রা),
						'other' => q({0}দীপনমাত্রা),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(মেট্রিক টন),
						'one' => q({0} মেট্রিক টন),
						'other' => q({0} metric tons),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(মাইক্ৰছেকেণ্ড),
						'one' => q({0} মাইক্ৰছেকেণ্ড),
						'other' => q({0} মাইক্ৰছেকেণ্ড),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(গ্যালন প্রতি মাইল),
						'one' => q({0}গ্যালন প্রতি মাইল),
						'other' => q({0}গ্যালন প্রতি মাইল),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(মাইল প্রতি Imp পয়সের পাঁচ সের),
						'one' => q(মাইল {0}প্রতি Imp পয়সের পাঁচ সের),
						'other' => q(মাইল {0}প্রতি Imp পয়সের পাঁচ সের),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} millibar),
						'other' => q({0} millibars),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(প্রতি দশমিক মিলিগ্রাম),
						'one' => q({0}প্রতি দশমিক মিলিগ্রাম),
						'other' => q({0}প্রতি দশমিক মিলিগ্রাম),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(মেরি এর মিলিমিটার),
						'one' => q({0}মেরি এর মিলিমিটার),
						'other' => q({0}মেরি এর মিলিমিটার),
					},
					'millimole-per-liter' => {
						'name' => q(লিটার প্রতি মিলি মিলস),
						'one' => q({0}লিটার প্রতি মিলি মিলস),
						'other' => q({0}লিটার প্রতি মিলি মিলস),
					},
					'millisecond' => {
						'name' => q(মিলিছেকেণ্ড),
						'one' => q({0} মিলিছেকেণ্ড),
						'other' => q({0} মিলিছেকেণ্ড),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(মিনিট),
						'one' => q({0} মিনিট),
						'other' => q({0} মিনিট),
						'per' => q({0} প্ৰতি মিনিট),
					},
					'month' => {
						'name' => q(মাহ),
						'one' => q({0} মাহ),
						'other' => q({0} মাহ),
						'per' => q({0} প্ৰতি মাহ),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(নেনোছেকেণ্ড),
						'one' => q({0} নেনোছেকেণ্ড),
						'other' => q({0} নেনোছেকেণ্ড),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(প্রতি লক্ষে),
						'one' => q({0}প্রতি লক্ষে),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(প্রতি ইঞ্চি এক পাউন্ড),
						'one' => q({0}প্রতি ইঞ্চি এক পাউন্ড),
						'other' => q({0}প্রতি ইঞ্চি এক পাউন্ড),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(রেডিয়ানে),
						'one' => q({0}রেডিয়ানে),
						'other' => q({0}রেডিয়ানে),
					},
					'revolution' => {
						'name' => q(বিপ্লব),
						'one' => q({0}বিপ্লব),
						'other' => q({0}বিপ্লব),
					},
					'second' => {
						'name' => q(ছেকেণ্ড),
						'one' => q({0} ছেকেণ্ড),
						'other' => q({0} ছেকেণ্ড),
						'per' => q({0} প্ৰতি ছেকেণ্ড),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(সপ্তাহ),
						'one' => q({0} সপ্তাহ),
						'other' => q({0} সপ্তাহ),
						'per' => q({0} প্ৰতি সপ্তাহ),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(বছৰ),
						'one' => q({0} বছৰ),
						'other' => q({0} বছৰ),
						'per' => q({0} প্ৰতি বছৰ),
					},
				},
				'narrow' => {
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'day' => {
						'name' => q(দিন),
						'one' => q({0} দিন),
						'other' => q({0} দিন),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hour' => {
						'name' => q(ঘণ্টা),
						'one' => q({0} ঘণ্টা),
						'other' => q({0} ঘণ্টা),
					},
					'kilogram' => {
						'name' => q(কিলোগ্রাম),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(মিলিছেকেণ্ড),
						'one' => q({0} মিঃছেঃ),
						'other' => q({0} মিঃছেঃ),
					},
					'minute' => {
						'name' => q(মিনিট),
						'one' => q({0} মিনিট),
						'other' => q({0} মিনিট),
					},
					'month' => {
						'name' => q(মাহ),
						'one' => q({0} মাহ),
						'other' => q({0} মাহ),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'second' => {
						'name' => q(ছেকেণ্ড),
						'one' => q({0} ছেকেণ্ড),
						'other' => q({0} ছেকেণ্ড),
					},
					'week' => {
						'name' => q(সপ্তাহ),
						'one' => q({0} সপ্তাহ),
						'other' => q({0} সপ্তাহ),
					},
					'year' => {
						'name' => q(বছৰ),
						'one' => q({0} বছৰ),
						'other' => q({0} বছৰ),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(acre),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(arcsec),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(শতিকা),
						'one' => q({0} শতিকা),
						'other' => q({0} শতিকা),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cup),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(দিন),
						'one' => q({0} দিন),
						'other' => q({0} দিন),
						'per' => q({0}/দিন),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(ডিগ্রী),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(g-force),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(US gal),
						'one' => q({0} gal US),
						'other' => q({0} gal US),
						'per' => q({0}/gal US),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hectare),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(ঘণ্টা),
						'one' => q({0} ঘণ্টা),
						'other' => q({0} ঘণ্টা),
						'per' => q({0}/ঘণ্টা),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(পার্সি এর ইঞ্চি),
						'one' => q({0}পার্সি এর ইঞ্চি),
						'other' => q({0}পার্সি এর ইঞ্চি),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(কিলোগ্রাম),
						'one' => q({0}কিলোগ্রাম),
						'other' => q({0}কিলোগ্রাম),
						'per' => q({0}/কিলোগ্রাম),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(প্রতি 100 কিলোমিটার লাইট),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(কিলোমিটার প্রতি লিটার),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(দীপনমাত্রা),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(মাইক্ৰছেকেণ্ড),
						'one' => q({0} মাঃছেঃ),
						'other' => q({0} মাঃছেঃ),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg US),
						'one' => q({0} mpg US),
						'other' => q({0} mpg US),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(মেরি এর মিলিমিটার),
						'one' => q({0}মেরি এর মিলিমিটার),
						'other' => q({0}মেরি এর মিলিমিটার),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(মিলিছেকেণ্ড),
						'one' => q({0} মিঃছেঃ),
						'other' => q({0} মিঃছেঃ),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(মিনিট),
						'one' => q({0} মিনিট),
						'other' => q({0} মিনিট),
						'per' => q({0}/মিনিট),
					},
					'month' => {
						'name' => q(মাহ),
						'one' => q({0} মাহ),
						'other' => q({0} মাহ),
						'per' => q({0}/মাহ),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(নেনোছেকেণ্ড),
						'one' => q({0} নেঃছেঃ),
						'other' => q({0} নেঃছেঃ),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(প্রতি লক্ষে),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(রেডিয়ানে),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(ছেকেণ্ড),
						'one' => q({0} ছেকেণ্ড),
						'other' => q({0} ছেকেণ্ড),
						'per' => q({0}/ছেকেণ্ড),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(সপ্তাহ),
						'one' => q({0} সপ্তাহ),
						'other' => q({0} সপ্তাহ),
						'per' => q({0}/সপ্তাহ),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(বছৰ),
						'one' => q({0} বছৰ),
						'other' => q({0} বছৰ),
						'per' => q({0}/বছৰ),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'beng',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'beng',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'beng' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
		},
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
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
				'1000' => {
					'one' => '0 হাজাৰ',
					'other' => '0 হাজাৰ',
				},
				'10000' => {
					'one' => '00 হাজাৰ',
					'other' => '00 হাজাৰ',
				},
				'100000' => {
					'one' => '0 লাখ',
					'other' => '0 লাখ',
				},
				'1000000' => {
					'one' => '00 লাখ',
					'other' => '00 লাখ',
				},
				'10000000' => {
					'one' => '0 ক'.'',
					'other' => '0 ক'.'',
				},
				'100000000' => {
					'one' => '00 ক'.'',
					'other' => '00 ক'.'',
				},
				'1000000000' => {
					'one' => '0 আ'.'',
					'other' => '0 আ'.'',
				},
				'10000000000' => {
					'one' => '00 আ'.'',
					'other' => '00 আ'.'',
				},
				'100000000000' => {
					'one' => '0 খ'.'',
					'other' => '0 খ'.'',
				},
				'1000000000000' => {
					'one' => '00 খ'.'',
					'other' => '00 খ'.'',
				},
				'10000000000000' => {
					'one' => '0 তিল',
					'other' => '0 তিল',
				},
				'100000000000000' => {
					'one' => '00 তিল',
					'other' => '00 তিল',
				},
				'standard' => {
					'default' => '#,##,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 হাজাৰ',
					'other' => '0 হাজাৰ',
				},
				'10000' => {
					'one' => '00 হাজাৰ',
					'other' => '00 হাজাৰ',
				},
				'100000' => {
					'one' => '0 লাখ',
					'other' => '0 লাখ',
				},
				'1000000' => {
					'one' => '00 লাখ',
					'other' => '00 লাখ',
				},
				'10000000' => {
					'one' => '0 কোটি',
					'other' => '0 কোটি',
				},
				'100000000' => {
					'one' => '00 কোটি',
					'other' => '00 কোটি',
				},
				'1000000000' => {
					'one' => '0 আৰব',
					'other' => '0 আৰব',
				},
				'10000000000' => {
					'one' => '00 আৰব',
					'other' => '00 আৰব',
				},
				'100000000000' => {
					'one' => '0 খৰব',
					'other' => '0 খৰব',
				},
				'1000000000000' => {
					'one' => '00 খৰব',
					'other' => '00 খৰব',
				},
				'10000000000000' => {
					'one' => '000 খৰব',
					'other' => '000 খৰব',
				},
				'100000000000000' => {
					'one' => '0000 খৰব',
					'other' => '0000 খৰব',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 হাজাৰ',
					'other' => '0 হাজাৰ',
				},
				'10000' => {
					'one' => '00 হাজাৰ',
					'other' => '00 হাজাৰ',
				},
				'100000' => {
					'one' => '0 লাখ',
					'other' => '0 লাখ',
				},
				'1000000' => {
					'one' => '00 লাখ',
					'other' => '00 লাখ',
				},
				'10000000' => {
					'one' => '0 ক'.'',
					'other' => '0 ক'.'',
				},
				'100000000' => {
					'one' => '00 ক'.'',
					'other' => '00 ক'.'',
				},
				'1000000000' => {
					'one' => '0 আ'.'',
					'other' => '0 আ'.'',
				},
				'10000000000' => {
					'one' => '00 আ'.'',
					'other' => '00 আ'.'',
				},
				'100000000000' => {
					'one' => '0 খ'.'',
					'other' => '0 খ'.'',
				},
				'1000000000000' => {
					'one' => '00 খ'.'',
					'other' => '00 খ'.'',
				},
				'10000000000000' => {
					'one' => '0 তিল',
					'other' => '0 তিল',
				},
				'100000000000000' => {
					'one' => '00 তিল',
					'other' => '00 তিল',
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
					'default' => '#E0',
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
		'beng' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤ #,##,##0.00',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##,##0.00',
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
			symbol => 'AED',
		},
		'AFN' => {
			symbol => 'AFN',
		},
		'ALL' => {
			symbol => 'ALL',
		},
		'AMD' => {
			symbol => 'AMD',
		},
		'ANG' => {
			symbol => 'ANG',
		},
		'AOA' => {
			symbol => 'AOA',
		},
		'ARS' => {
			symbol => 'ARS',
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(অস্ট্রেলিয়ান ডলার),
				'one' => q(অস্ট্রেলিয়ান ডলার),
				'other' => q(অস্ট্রেলিয়ান ডলার),
			},
		},
		'AWG' => {
			symbol => 'AWG',
		},
		'AZN' => {
			symbol => 'AZN',
		},
		'BAM' => {
			symbol => 'BAM',
		},
		'BBD' => {
			symbol => 'BBD',
		},
		'BDT' => {
			symbol => 'BDT',
		},
		'BGN' => {
			symbol => 'BGN',
		},
		'BHD' => {
			symbol => 'BHD',
		},
		'BIF' => {
			symbol => 'BIF',
		},
		'BMD' => {
			symbol => 'BMD',
		},
		'BND' => {
			symbol => 'BND',
		},
		'BOB' => {
			symbol => 'BOB',
		},
		'BRL' => {
			symbol => 'R$',
		},
		'BSD' => {
			symbol => 'BSD',
		},
		'BTN' => {
			symbol => 'BTN',
		},
		'BWP' => {
			symbol => 'BWP',
		},
		'BYN' => {
			symbol => 'BYN',
		},
		'BZD' => {
			symbol => 'BZD',
		},
		'CAD' => {
			symbol => 'CA$',
		},
		'CDF' => {
			symbol => 'CDF',
		},
		'CHF' => {
			symbol => 'CHF',
		},
		'CLP' => {
			symbol => 'CLP',
		},
		'CNH' => {
			symbol => 'CNH',
		},
		'CNY' => {
			symbol => 'CN¥',
		},
		'COP' => {
			symbol => 'COP',
		},
		'CRC' => {
			symbol => 'CRC',
		},
		'CUC' => {
			symbol => 'CUC',
		},
		'CUP' => {
			symbol => 'CUP',
		},
		'CVE' => {
			symbol => 'CVE',
		},
		'CZK' => {
			symbol => 'CZK',
		},
		'DJF' => {
			symbol => 'DJF',
		},
		'DKK' => {
			symbol => 'DKK',
		},
		'DOP' => {
			symbol => 'DOP',
		},
		'DZD' => {
			symbol => 'DZD',
		},
		'EGP' => {
			symbol => 'EGP',
		},
		'ERN' => {
			symbol => 'ERN',
		},
		'ETB' => {
			symbol => 'ETB',
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(ইউরোর),
				'one' => q(ইউরোর),
				'other' => q(ইউরোর),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(ফিজিয়ান ডলার),
				'one' => q(ফিজিয়ান ডলার),
				'other' => q(ফিজিয়ান ডলার),
			},
		},
		'FKP' => {
			symbol => 'FKP',
		},
		'GBP' => {
			symbol => '£',
		},
		'GEL' => {
			symbol => 'GEL',
		},
		'GHS' => {
			symbol => 'GHS',
		},
		'GIP' => {
			symbol => 'GIP',
		},
		'GMD' => {
			symbol => 'GMD',
		},
		'GNF' => {
			symbol => 'GNF',
		},
		'GTQ' => {
			symbol => 'GTQ',
		},
		'GYD' => {
			symbol => 'GYD',
		},
		'HKD' => {
			symbol => 'HK$',
		},
		'HNL' => {
			symbol => 'HNL',
		},
		'HRK' => {
			symbol => 'HRK',
		},
		'HTG' => {
			symbol => 'HTG',
		},
		'HUF' => {
			symbol => 'HUF',
		},
		'IDR' => {
			symbol => 'IDR',
		},
		'ILS' => {
			symbol => '₪',
		},
		'INR' => {
			symbol => '₹',
		},
		'IQD' => {
			symbol => 'IQD',
		},
		'IRR' => {
			symbol => 'IRR',
		},
		'ISK' => {
			symbol => 'ISK',
		},
		'JMD' => {
			symbol => 'JMD',
		},
		'JOD' => {
			symbol => 'JOD',
		},
		'JPY' => {
			symbol => 'JP¥',
		},
		'KES' => {
			symbol => 'KES',
		},
		'KGS' => {
			symbol => 'KGS',
		},
		'KHR' => {
			symbol => 'KHR',
		},
		'KMF' => {
			symbol => 'KMF',
		},
		'KPW' => {
			symbol => 'KPW',
		},
		'KRW' => {
			symbol => '₩',
		},
		'KWD' => {
			symbol => 'KWD',
		},
		'KYD' => {
			symbol => 'KYD',
		},
		'KZT' => {
			symbol => 'KZT',
		},
		'LAK' => {
			symbol => 'LAK',
		},
		'LBP' => {
			symbol => 'LBP',
		},
		'LKR' => {
			symbol => 'LKR',
		},
		'LRD' => {
			symbol => 'LRD',
		},
		'LYD' => {
			symbol => 'LYD',
		},
		'MAD' => {
			symbol => 'MAD',
		},
		'MDL' => {
			symbol => 'MDL',
		},
		'MGA' => {
			symbol => 'MGA',
		},
		'MKD' => {
			symbol => 'MKD',
		},
		'MMK' => {
			symbol => 'MMK',
		},
		'MNT' => {
			symbol => 'MNT',
		},
		'MOP' => {
			symbol => 'MOP',
		},
		'MRO' => {
			symbol => 'MRO',
		},
		'MUR' => {
			symbol => 'MUR',
		},
		'MVR' => {
			symbol => 'MVR',
		},
		'MWK' => {
			symbol => 'MWK',
		},
		'MXN' => {
			symbol => 'MX$',
		},
		'MYR' => {
			symbol => 'MYR',
		},
		'MZN' => {
			symbol => 'MZN',
		},
		'NAD' => {
			symbol => 'NAD',
		},
		'NGN' => {
			symbol => 'NGN',
		},
		'NIO' => {
			symbol => 'NIO',
		},
		'NOK' => {
			symbol => 'NOK',
		},
		'NPR' => {
			symbol => 'NPR',
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(নিউজিল্যান্ড ডলার),
				'one' => q(নিউজিল্যান্ড ডলার),
				'other' => q(নিউজিল্যান্ড ডলার),
			},
		},
		'OMR' => {
			symbol => 'OMR',
		},
		'PAB' => {
			symbol => 'PAB',
		},
		'PEN' => {
			symbol => 'PEN',
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(পাপুয়া নিউ গিনিন কেনিয়া),
				'one' => q(পাপুয়া নিউ গিনিন কেনিয়া),
				'other' => q(পাপুয়া নিউ গিনিন কেনিয়া),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(ফিলিপাইন পেসো),
				'one' => q(ফিলিপাইন পেসো),
				'other' => q(ফিলিপাইন পেসো),
			},
		},
		'PKR' => {
			symbol => 'PKR',
		},
		'PLN' => {
			symbol => 'PLN',
		},
		'PYG' => {
			symbol => 'PYG',
		},
		'QAR' => {
			symbol => 'QAR',
		},
		'RON' => {
			symbol => 'RON',
		},
		'RSD' => {
			symbol => 'RSD',
		},
		'RUB' => {
			symbol => 'RUB',
		},
		'RWF' => {
			symbol => 'RWF',
		},
		'SAR' => {
			symbol => 'SAR',
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(সলোমন দ্বীপপুঞ্জ ডলার),
				'one' => q(সলোমন দ্বীপপুঞ্জ ডলার),
				'other' => q(সলোমন দ্বীপপুঞ্জ ডলার),
			},
		},
		'SCR' => {
			symbol => 'SCR',
		},
		'SDG' => {
			symbol => 'SDG',
		},
		'SEK' => {
			symbol => 'SEK',
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(সিঙ্গাপুর ডলার),
				'one' => q(সিঙ্গাপুর ডলার),
				'other' => q(সিঙ্গাপুর ডলার),
			},
		},
		'SHP' => {
			symbol => 'SHP',
		},
		'SLL' => {
			symbol => 'SLL',
		},
		'SOS' => {
			symbol => 'SOS',
		},
		'SRD' => {
			symbol => 'SRD',
		},
		'SSP' => {
			symbol => 'SSP',
		},
		'STD' => {
			symbol => 'STD',
		},
		'SYP' => {
			symbol => 'SYP',
		},
		'SZL' => {
			symbol => 'SZL',
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(থাই বাত),
				'one' => q(থাই বাত),
				'other' => q(থাই বাত),
			},
		},
		'TJS' => {
			symbol => 'TJS',
		},
		'TMT' => {
			symbol => 'TMT',
		},
		'TND' => {
			symbol => 'TND',
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(টোঙ্গান পাংগা),
				'one' => q(টোঙ্গান পাংগা),
				'other' => q(টোঙ্গান পাংগা),
			},
		},
		'TRY' => {
			symbol => 'TRY',
		},
		'TTD' => {
			symbol => 'TTD',
		},
		'TWD' => {
			symbol => 'NT$',
		},
		'TZS' => {
			symbol => 'TZS',
		},
		'UAH' => {
			symbol => 'UAH',
		},
		'UGX' => {
			symbol => 'UGX',
		},
		'USD' => {
			symbol => 'US$',
		},
		'UYU' => {
			symbol => 'UYU',
		},
		'UZS' => {
			symbol => 'UZS',
		},
		'VEF' => {
			symbol => 'VEF',
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(ভিয়েতনামী ডং),
				'one' => q(ভিয়েতনামী ডং),
				'other' => q(ভিয়েতনামী ডং),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(ভানুয়াতু ভাতু),
				'one' => q(ভানুয়াতু ভাতু),
				'other' => q(ভানুয়াতু ভাতু),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(সামোয়ান তাল),
				'one' => q(সামোয়ান তাল),
				'other' => q(সামোয়ান তাল),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
		},
		'XCD' => {
			symbol => 'EC$',
		},
		'XOF' => {
			symbol => 'CFA',
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP ফ্রাঙ্ক),
				'one' => q(CFP ফ্রাঙ্ক),
				'other' => q(CFP ফ্রাঙ্ক),
			},
		},
		'YER' => {
			symbol => 'YER',
		},
		'ZAR' => {
			symbol => 'ZAR',
		},
		'ZMW' => {
			symbol => 'ZMW',
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
							'জানু',
							'ফেব্ৰু',
							'মাৰ্চ',
							'এপ্ৰিল',
							'মে’',
							'জুন',
							'জুলাই',
							'আগ',
							'ছেপ্তে',
							'অক্টো',
							'নৱে',
							'ডিচে'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'জ',
							'ফ',
							'ম',
							'এ',
							'ম',
							'জ',
							'জ',
							'আ',
							'ছ',
							'অ',
							'ন',
							'ড'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'জানুৱাৰী',
							'ফেব্ৰুৱাৰী',
							'মাৰ্চ',
							'এপ্ৰিল',
							'মে’',
							'জুন',
							'জুলাই',
							'আগষ্ট',
							'ছেপ্তেম্বৰ',
							'অক্টোবৰ',
							'নৱেম্বৰ',
							'ডিচেম্বৰ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'জানু',
							'ফেব্ৰু',
							'মাৰ্চ',
							'এপ্ৰিল',
							'মে’',
							'জুন',
							'জুলাই',
							'আগ',
							'ছেপ্তে',
							'অক্টো',
							'নৱে',
							'ডিচে'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'জানুৱাৰী',
							'ফেব্ৰুৱাৰী',
							'মাৰ্চ',
							'এপ্ৰিল',
							'মে’',
							'জুন',
							'জুলাই',
							'আগষ্ট',
							'ছেপ্তেম্বৰ',
							'অক্টোবৰ',
							'নৱেম্বৰ',
							'ডিচেম্বৰ'
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
						mon => 'সোম',
						tue => 'মঙ্গল',
						wed => 'বুধ',
						thu => 'বৃহ',
						fri => 'শুক্ৰ',
						sat => 'শনি',
						sun => 'দেও'
					},
					narrow => {
						mon => 'স',
						tue => 'ম',
						wed => 'ব',
						thu => 'ব',
						fri => 'শ',
						sat => 'শ',
						sun => 'দ'
					},
					short => {
						mon => 'সোম',
						tue => 'মঙ্গল',
						wed => 'বুধ',
						thu => 'বৃহ',
						fri => 'শুক্ৰ',
						sat => 'শনি',
						sun => 'দেও'
					},
					wide => {
						mon => 'সোমবাৰ',
						tue => 'মঙ্গলবাৰ',
						wed => 'বুধবাৰ',
						thu => 'বৃহস্পতিবাৰ',
						fri => 'শুক্ৰবাৰ',
						sat => 'শনিবাৰ',
						sun => 'দেওবাৰ'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'সোম',
						tue => 'মঙ্গল',
						wed => 'বুধ',
						thu => 'বৃহ',
						fri => 'শুক্ৰ',
						sat => 'শনি',
						sun => 'দেও'
					},
					narrow => {
						mon => 'স',
						tue => 'ম',
						wed => 'ব',
						thu => 'ব',
						fri => 'শ',
						sat => 'শ',
						sun => 'দ'
					},
					short => {
						mon => 'সোম',
						tue => 'মঙ্গল',
						wed => 'বুধ',
						thu => 'বৃহ',
						fri => 'শুক্ৰ',
						sat => 'শনি',
						sun => 'দেও'
					},
					wide => {
						mon => 'সোমবাৰ',
						tue => 'মঙ্গলবাৰ',
						wed => 'বুধবাৰ',
						thu => 'বৃহস্পতিবাৰ',
						fri => 'শুক্ৰবাৰ',
						sat => 'শনিবাৰ',
						sun => 'দেওবাৰ'
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
					abbreviated => {0 => 'তি1',
						1 => 'তি2',
						2 => 'তি3',
						3 => 'তি4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'প্ৰথম প্ৰহৰ',
						1 => 'দ্বিতীয় প্ৰহৰ',
						2 => 'তৃতীয় প্ৰহৰ',
						3 => 'চতুৰ্থ প্ৰহৰ'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'তি1',
						1 => 'তি2',
						2 => 'তি3',
						3 => 'তি4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'প্ৰথম তিনিমাহ',
						1 => 'দ্বিতীয় তিনিমাহ',
						2 => 'তৃতীয় তিনিমাহ',
						3 => 'চতুৰ্থ তিনিমাহ'
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
					'pm' => q{অপৰাহ্ণ},
					'am' => q{পূৰ্বাহ্ণ},
				},
				'narrow' => {
					'am' => q{পূৰ্বাহ্ণ},
					'pm' => q{অপৰাহ্ণ},
				},
				'wide' => {
					'pm' => q{অপৰাহ্ণ},
					'am' => q{পূৰ্বাহ্ণ},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{পূৰ্বাহ্ণ},
					'pm' => q{অপৰাহ্ণ},
				},
				'wide' => {
					'am' => q{পূৰ্বাহ্ণ},
					'pm' => q{অপৰাহ্ণ},
				},
				'abbreviated' => {
					'am' => q{পূৰ্বাহ্ণ},
					'pm' => q{অপৰাহ্ণ},
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
				'0' => 'খ্ৰী.পূ.',
				'1' => 'খ্ৰী.দ.'
			},
			wide => {
				'0' => 'খ্ৰীষ্টপূৰ্ব',
				'1' => 'খ্ৰীষ্টাব্দ'
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
			'full' => q{G y MMMM d, EEEE},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{dd-MM-y},
			'short' => q{d-M-y},
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
			'full' => q{h.mm.ss a zzzz},
			'long' => q{h.mm.ss a z},
			'medium' => q{h.mm.ss a},
			'short' => q{h.mm. a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			E => q{ccc},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E a h:mm},
			Ehms => q{E a h:mm:ss},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, dd-MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{MMMMৰ সপ্তাহ W},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			h => q{a h},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			hmsv => q{a h:mm:ss v},
			hmv => q{a h:mm v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{Yৰ সপ্তাহ w},
		},
		'generic' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{G y},
			yyyy => q{G y},
			yyyyM => q{GGGGG y-MM},
			yyyyMEd => q{GGGGG y-MM-dd, E},
			yyyyMMM => q{G y MMM},
			yyyyMMMEd => q{G y MMM d, E},
			yyyyMMMM => q{G y MMMM},
			yyyyMMMd => q{G y MMM d},
			yyyyMd => q{GGGGG y-MM-dd},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d MMM–d},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a h:mm – a h:mm},
				h => q{a h:mm–h:mm},
				m => q{a h:mm–h:mm},
			},
			hmv => {
				a => q{a h:mm – a h:mm v},
				h => q{a h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a h–h v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM-y – MM-y},
				y => q{MM-y – MM-y},
			},
			yMEd => {
				M => q{dd-MM-y, E – dd-MM-y},
				d => q{dd-MM-y, E – dd-MM-y},
				y => q{dd-MM-y, E – dd-MM-y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM y – E, d MMM},
				d => q{E, d MMM y – E, d MMM},
				y => q{E, d MMM y – d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM y – d MMM},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
			},
		},
		'generic' => {
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			yMEd => {
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			yMMMEd => {
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{G y MMMM–MMMM},
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#আফগানিস্তান সময়#,
			},
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#মধ্য আফ্রিকা সময়#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#পূর্ব আফ্রিকা সময়#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#দক্ষিণ আফ্রিকা মান সময়#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#পশ্চিম আফ্রিকার গ্রীষ্মকালীন সময়#,
				'generic' => q#পশ্চিম আফ্রিকা সময়#,
				'standard' => q#পশ্চিম আফ্রিকার মান সময়#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#আমজান গ্রীষ্মের সময়#,
				'generic' => q#আমজান সময়#,
				'standard' => q#আমজান মান সময়#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curacao#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthelemy#,
		},
		'Apia' => {
			long => {
				'daylight' => q#আপিয়া ডেলাইট টাইম#,
				'generic' => q#আপিয়া সময়#,
				'standard' => q#আপিয়া স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#আরবীয় দিনের আলো#,
				'generic' => q#আরবীয় সময়#,
				'standard' => q#আরবীয় মান সময়#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#আৰ্জেণ্টিনা গ্ৰীষ্ম সময়#,
				'generic' => q#আৰ্জেণ্টিনা সময়#,
				'standard' => q#আৰ্জেণ্টিনা মান সময়#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#ওয়েস্টার্ন আর্জেন্টিনা গ্রীষ্মকালীন সময়#,
				'generic' => q#ওয়েস্টার্ন আর্জেন্টিনা সময়#,
				'standard' => q#ওয়েস্টার্ন আর্জেন্টিনা মান সময়#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#আর্মেনিয়া গ্রীষ্মকালীন সময়#,
				'generic' => q#আর্মেনিয়া টাইম#,
				'standard' => q#আর্মেনিয়া স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Asia/Rangoon' => {
			exemplarCity => q#য়াঙ্গুন#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#অস্ট্রেলিয়ান কেন্দ্রীয় দিবালোক সময়#,
				'generic' => q#কেন্দ্রীয় অস্ট্রেলিয়া সময়#,
				'standard' => q#অস্ট্রেলিয়ান কেন্দ্রীয় স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#অস্ট্রেলিয়ান সেন্ট্রাল ওয়েস্টার্ন ডেলাইট টাইম#,
				'generic' => q#অস্ট্রেলিয়ান সেন্ট্রাল ওয়েস্টার্ন টাইম#,
				'standard' => q#অস্ট্রেলিয়ান সেন্ট্রাল ওয়েস্টার্ন স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#অস্ট্রেলিয়ান পূর্ব দিবালোক সময়#,
				'generic' => q#পূর্ব অস্ট্রেলিয়া সময়#,
				'standard' => q#অস্ট্রেলিয়ান ইস্টার্ন স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#অস্ট্রেলিয়ান ওয়েস্টার্ন ডেলাইট টাইম#,
				'generic' => q#ওয়েস্টার্ন অস্ট্রেলিয়া টাইম#,
				'standard' => q#অস্ট্রেলিয়ান ওয়েস্টার্ন স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#আজারবাইজান গ্রীষ্মকালীন সময়#,
				'generic' => q#আজারবাইজান সময়#,
				'standard' => q#আজারবাইজান স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azores গ্রীষ্মের সময়#,
				'generic' => q#Azores সময়#,
				'standard' => q#Azores মান সময়#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#বাংলাদেশ গ্রীষ্মকালীন সময়#,
				'generic' => q#বাংলাদেশ সময়#,
				'standard' => q#বাংলাদেশ স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#ভুটান টাইম#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#বলিভিয়া সময়#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#ব্ৰাছিলিয়া গ্ৰীষ্ম সময়#,
				'generic' => q#ব্ৰাছিলিয়া সময়#,
				'standard' => q#ব্ৰাছিলিয়া মান সময়#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#ব্রুনেই দারুসসালাম সময়#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#কেপ ভার্দে গ্রীষ্মকালীন সময়#,
				'generic' => q#কেপ ভার্দে সময়#,
				'standard' => q#কেপ ওয়ার্ড স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#চামেরো স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#চ্যাথাম ডেইলাইট টাইম#,
				'generic' => q#চ্যাথাম টাইম#,
				'standard' => q#চ্যাথাম স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#চিলি গ্রীষ্মকালীন সময়#,
				'generic' => q#চিলি সময়#,
				'standard' => q#চিলি স্ট্যান্ডার্ড টাইম#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#চীন ডেইলাইট টাইম#,
				'generic' => q#চীন সময়#,
				'standard' => q#চীন স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#চিব্বলসন গ্রীষ্মকালীন সময়#,
				'generic' => q#চিব্বালান টাইম#,
				'standard' => q#চিব্বলসন স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#ক্রিসমাস আইল্যান্ড সময়#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#কোকোস দ্বীপপুঞ্জ সময়#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#কলম্বিয়া গ্ৰীষ্ম সময়#,
				'generic' => q#কলম্বিয়া সময়#,
				'standard' => q#কলম্বিয়া মান সময়#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#কুক দ্বীপপুঞ্জ হাফ গ্রীষ্মকালীন সময়#,
				'generic' => q#কুক দ্বীপপুঞ্জ সময়#,
				'standard' => q#কুক দ্বীপপুঞ্জ স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#ডেভিস টাইম#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ডামমন্ট-ডি‘উরিভ্যাল টাইম#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#পূর্ব তিমুর সময়#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ইষ্টাৰ দ্বীপ গ্ৰীষ্ম সময়#,
				'generic' => q#ইষ্টাৰ দ্বীপ সময়#,
				'standard' => q#ইষ্টাৰ দ্বীপ মান সময়#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ইকুৱেডৰ সময়#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#সমন্বিত সাৰ্বজনীন সময়#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#অজ্ঞাত চহৰ#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#আইৰিচ মান সময়#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#ব্ৰিটিচ গ্ৰীষ্মকালীন সময়#,
			},
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#মধ্য ইউরোপীয় গ্রীষ্মকালীন সময়#,
				'generic' => q#কেন্দ্রীয় ইউরোপীয় সময়#,
				'standard' => q#কেন্দ্রীয় ইউরোপীয় স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#পূর্ব ইউরোপীয় গ্রীষ্মকালীন সময়#,
				'generic' => q#পূর্ব ইউরোপীয় সময়#,
				'standard' => q#পূর্ব ইউরোপীয় মান সময়#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#আরও পূর্ব ইউরোপীয় সময়#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#পশ্চিম ইউরোপীয় গ্রীষ্মকালীন সময়#,
				'generic' => q#পশ্চিম ইউরোপীয় সময়#,
				'standard' => q#পশ্চিম ইউরোপীয় মান সময়#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ফকল্যান্ড দ্বীপপুঞ্জ গ্রীষ্মকালীন সময়#,
				'generic' => q#ফকল্যান্ড দ্বীপপুঞ্জ সময়#,
				'standard' => q#ফকল্যান্ড দ্বীপ স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#ফিজি গ্রীষ্মকালীন সময়#,
				'generic' => q#ফিজি সময়#,
				'standard' => q#ফিজি স্ট্যান্ডার্ড টাইম#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ফরাসি গায়ানা সময়#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#ফরাসি দক্ষিণ ও অ্যান্টার্কটিক সময়#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#মক্কার সময়#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#গালাপাগোস টাইম#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#গাম্বুর সময়#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#জর্জিয়া গ্রীষ্মকালীন সময়#,
				'generic' => q#জর্জিয়া টাইম#,
				'standard' => q#জর্জিয়া স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#গিলবার্ট দ্বীপপুঞ্জ সময়#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#উপসাগরীয় স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#গায়ানা টাইম#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#হংকং গ্রীষ্মকালীন সময়#,
				'generic' => q#হংকং সময়#,
				'standard' => q#হংকং স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#হওগড গ্রীষ্মকালীন সময়#,
				'generic' => q#হওড টাইম#,
				'standard' => q#হোভড স্ট্যান্ডার্ড টাইম#,
			},
		},
		'India' => {
			long => {
				'standard' => q#ভাৰতীয় সময়#,
			},
			short => {
				'standard' => q#ভা. স.#,
			},
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#ভারত মহাসাগর সময়#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#ইন্দোচীনা টাইম#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#মধ্য ইন্দোনেশিয়া সময়#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#ইস্টার্ন ইন্দোনেশিয়া সময়#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#ওয়েস্টার্ন ইন্দোনেশিয়া সময়#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ইরান দিবালোক সময়#,
				'generic' => q#ইরান সময়#,
				'standard' => q#ইরান স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ইর্কুষস্ক গ্রীষ্মকালীন সময়#,
				'generic' => q#ইর্কুক্স্ক সময়#,
				'standard' => q#ইঙ্কুক্টক স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ইস্রায়েল দিবালোক সময়#,
				'generic' => q#ইস্রায়েল সময়#,
				'standard' => q#ইস্রায়েল স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#জাপান দিনের হালকা সময়#,
				'generic' => q#জাপান সময়#,
				'standard' => q#জাপান স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#পূর্ব কাজাখস্তান সময়#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#পশ্চিম কাসাবালান সময়#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#কোরিয়ান দিনের আলো#,
				'generic' => q#কোরিয়ান সময়#,
				'standard' => q#কোরিয়ান স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#কোসরা টাইম#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#ক্রোয়েশোয়ারস্ক গ্রীষ্মকালীন সময়#,
				'generic' => q#ক্রোশোয়েয়ার্স্ক টাইম#,
				'standard' => q#ক্রোশনোয়ার্স্ক মান সময়#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#লাইন দ্বীপপুঞ্জ সময়#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#লর্ড হ্যালো দিবালোক সময়#,
				'generic' => q#লর্ড হাভী সময়#,
				'standard' => q#লর্ড হাভী স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#ম্যাককুরি আইল্যান্ড টাইম#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#ম্যাগাদান গ্রীষ্মকালীন সময়#,
				'generic' => q#ম্যাগাদান টাইম#,
				'standard' => q#ম্যাগাদান মান সময়#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#মালয়েশিয়া সময়#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#মালদ্বীপের সময়#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#মারকাসাস সময়#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#মার্শাল দ্বীপপুঞ্জ সময়#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius গ্রীষ্মকালীন সময়#,
				'generic' => q#Mauritus সময়#,
				'standard' => q#Mauritius মান সময়#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#মোসন টাইম#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#উলানবাটার গ্রীষ্মকালীন সময়#,
				'generic' => q#উলানবাটার টাইম#,
				'standard' => q#উলানবাটার মান সময়#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#মস্কো গ্রীষ্মকালীন সময়#,
				'generic' => q#মস্কো সময়#,
				'standard' => q#মস্কো স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#মায়ানমার টাইম#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#নাউরু টাইম#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#নেপাল সময়#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#নিউ ক্যালেডোনিয়া গ্রীষ্মকালীন সময়#,
				'generic' => q#নিউ ক্যালেডোনিয়া সময়#,
				'standard' => q#নিউ ক্যালেডোনিয়া স্ট্যান্ডার্ড টাইম#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#নিউজিল্যান্ড ডেলাইট টাইম#,
				'generic' => q#নিউজিল্যান্ড সময়#,
				'standard' => q#নিউজিল্যান্ড স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#নিউইয় টাইম#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#নরফোক দ্বীপ সময়#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ফাৰ্নাণ্ডো ডি নোৰোন্বা গ্ৰীষ্ম সময়#,
				'generic' => q#ফাৰ্নাণ্ডো ডি নোৰোন্বা#,
				'standard' => q#ফাৰ্নাণ্ডো ডি নোৰোন্বা মান সময়#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#নোভোসিবিরস্ক গ্রীষ্মকালীন সময়#,
				'generic' => q#নোভোসিবিরস্ক সময়#,
				'standard' => q#নোভোসিবিরস্ক স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk গ্রীষ্মকালীন সময়#,
				'generic' => q#Omsk সময়#,
				'standard' => q#Omsk আদর্শ সময়#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#পাকিস্তান গ্রীষ্মকালীন সময়#,
				'generic' => q#পাকিস্তান টাইম#,
				'standard' => q#পাকিস্তান স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#পালাউ সময়#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#পাপুয়া নিউ গিনি সময়#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#পাৰাগুৱে গ্ৰীষ্ম সময়#,
				'generic' => q#পাৰাগুৱে সময়#,
				'standard' => q#পাৰাগুৱে মান সময়#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#পেরু গ্রীষ্মকালীন সময়#,
				'generic' => q#পেরু সময়#,
				'standard' => q#পেরু মান সময়#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#ফিলিপাইন গ্রীষ্মকালীন সময়#,
				'generic' => q#ফিলিপাইন টাইম#,
				'standard' => q#ফিলিপাইন স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#ফিনিক্স দ্বীপপুঞ্জ সময়#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#পিটারকনার টাইম#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#পনাপ সময়#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#পিয়ংইয়ং টাইম#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#রিয়ানিয়ন টাইম#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#রোথেরা টাইম#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#সাখালিন গ্রীষ্মের সময়#,
				'generic' => q#সাখালিন টাইম#,
				'standard' => q#সাখালিন মান টাইম#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#সামোয়া ডেলাইট সময়#,
				'generic' => q#সামোয়া সময়#,
				'standard' => q#সামোয়া স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#সেশেলস সময়#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#সিঙ্গাপুর স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#সলোমন দ্বীপপুঞ্জ সময়#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#দক্ষিণ জর্জিয়া টাইম#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#সুরিনাম টাইম#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa টাইম#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#তাহিতি টাইম#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#তাইপে দিনের হালকা সময়#,
				'generic' => q#তাইপে সময়#,
				'standard' => q#তাইপে স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#তাজিকিস্তান টাইম#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#টোকেলাউ সময়#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#টঙ্গা গ্রীষ্মকালীন সময়#,
				'generic' => q#টোঙ্গা টাইম#,
				'standard' => q#টোঙ্গা স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#চুুক টাইম#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#তুর্কমেনিস্তান গ্রীষ্ম সময়#,
				'generic' => q#তুর্কমেনিস্তান সময়#,
				'standard' => q#তুর্কমেনিস্তান মান সময়#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#টুভালু সময়#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#উৰুগুৱে গ্ৰীষ্ম সময়#,
				'generic' => q#উৰুগুৱে সময়#,
				'standard' => q#উৰুগুৱে মান সময়#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#উজবেকিস্তান গ্রীষ্মের সময়#,
				'generic' => q#উজবেকিস্তান সময়#,
				'standard' => q#উজবেকিস্তান মান সময়#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#ভানুয়াতু গ্রীষ্মকালীন সময়#,
				'generic' => q#ভানুয়াতু সময়#,
				'standard' => q#ভানুয়াতু স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#ভেনিজুয়েলা সময়#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ভ্লাদভোস্টক সামার সময়#,
				'generic' => q#ভ্লাদভোস্টক টাইম#,
				'standard' => q#ভ্লাদভোস্টোক স্ট্যান্ডার্ড টাইম#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#ভলগোগ্রেড গ্রীষ্মকালীন সময়#,
				'generic' => q#ভলগোগ্রাদ টাইম#,
				'standard' => q#ভোলগোগ্রাদ মান সময়#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#ভোস্টোক টাইম#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ওয়াক আইল্যান্ড টাইম#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#ওয়ালিস ও ফুটুনা সময়#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk গ্রীষ্মের সময়#,
				'generic' => q#Yakutsk সময়#,
				'standard' => q#Yakutsk মান সময়#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#ইয়েকাতেরিনবার্গ গ্রীষ্মকালীন সময়#,
				'generic' => q#ইয়েকাতেরিনবার্গ সময়#,
				'standard' => q#ইয়েকাতেরিনবার্গ স্ট্যান্ডার্ড সময়#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
