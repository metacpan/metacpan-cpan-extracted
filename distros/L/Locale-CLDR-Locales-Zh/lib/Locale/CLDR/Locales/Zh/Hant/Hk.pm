=head1

Locale::CLDR::Locales::Zh::Hant::Hk - Package for language Chinese

=cut

package Locale::CLDR::Locales::Zh::Hant::Hk;
# This file auto generated from Data\common\main\zh_Hant_HK.xml
#	on Fri 13 Apr  7:38:00 am GMT

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

extends('Locale::CLDR::Locales::Zh::Hant');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'aa' => '阿法爾文',
 				'az' => '阿塞拜疆文',
 				'az@alt=short' => '阿塞拜疆文',
 				'az_Arab' => '南阿塞拜疆文',
 				'ba' => '巴什基爾文',
 				'br' => '布里多尼文',
 				'bs' => '波斯尼亞文',
 				'ca' => '加泰隆尼亞文',
 				'crh' => '克里米亞韃靼文',
 				'crs' => '塞舌爾克里奧爾法文',
 				'de_AT' => '奧地利德文',
 				'de_CH' => '瑞士德語',
 				'den' => '斯拉夫文',
 				'en_AU' => '澳洲英文',
 				'en_CA' => '加拿大英文',
 				'en_GB' => '英國英文',
 				'en_GB@alt=short' => '英式英文',
 				'en_US' => '美國英文',
 				'en_US@alt=short' => '美式英文',
 				'eo' => '世界語',
 				'es_419' => '拉丁美洲西班牙文',
 				'es_ES' => '歐洲西班牙文',
 				'es_MX' => '墨西哥西班牙文',
 				'fr_CA' => '加拿大法文',
 				'fr_CH' => '瑞士法文',
 				'gil' => '吉爾伯特文',
 				'gl' => '加里西亞文',
 				'gsw' => '瑞士德文',
 				'hi' => '印度文',
 				'hmn' => '苗語',
 				'hr' => '克羅地亞文',
 				'it' => '意大利文',
 				'jpr' => '猶太波斯文',
 				'ka' => '格魯吉亞文',
 				'kiu' => '扎扎其文',
 				'kn' => '坎納達文',
 				'kri' => '克裡奧爾文',
 				'lo' => '老撾文',
 				'luo' => '盧歐文',
 				'mfe' => '毛里裘斯克里奧爾文',
 				'mg' => '馬拉加斯文',
 				'ml' => '馬拉雅拉姆文',
 				'mt' => '馬耳他文',
 				'nl_BE' => '比利時荷蘭文',
 				'nqo' => '西非書面語言（N’ko）',
 				'or' => '奧里雅文',
 				'pcm' => '尼日利亞皮欽文',
 				'ps@alt=variant' => '普什圖語',
 				'pt_BR' => '巴西葡萄牙文',
 				'pt_PT' => '歐洲葡萄牙文',
 				'ro_MD' => '摩爾多瓦羅馬尼亞文',
 				'rup' => '阿羅馬尼亞語',
 				'rw' => '盧旺達文',
 				'sd' => '信德語',
 				'sl' => '斯洛文尼亞文',
 				'sn' => '修納文',
 				'so' => '索馬里文',
 				'sw_CD' => '剛果史瓦希里文',
 				'syr' => '敍利亞文',
 				'ta' => '泰米爾文',
 				'tn' => '突尼西亞文',
 				'to' => '湯加文',
 				'ug@alt=variant' => '維吾爾語',
 				'ur' => '烏爾都文',
 				'wbp' => '瓦爾皮里文',
 				'yue' => '廣東話',
 				'zgh' => '摩洛哥標準塔馬齊格特文',

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
			'Cyrl' => '西里爾文',
 			'Ethi' => '埃塞俄比亞文',
 			'Geor' => '格魯吉亞文',
 			'Guru' => '古木基文',
 			'Hans' => '簡體字',
 			'Hant' => '繁體字',
 			'Knda' => '坎納達文',
 			'Laoo' => '老撾文',
 			'Latn' => '拉丁字母',
 			'Mlym' => '馬拉雅拉姆文',
 			'Newa' => '尼瓦爾文',
 			'Orya' => '奧里雅文',
 			'Sinh' => '僧伽羅文',
 			'Taml' => '泰米爾文',
 			'Thaa' => '它拿字母',

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
			'013' => '中美洲',
 			'029' => '加勒比',
 			'053' => '澳大拉西亞',
 			'061' => '波利尼西亞',
 			'AE' => '阿拉伯聯合酋長國',
 			'AG' => '安提瓜和巴布達',
 			'AW' => '阿魯巴',
 			'AZ' => '阿塞拜疆',
 			'BA' => '波斯尼亞和黑塞哥維那',
 			'BB' => '巴巴多斯',
 			'BF' => '布基納法索',
 			'BI' => '布隆迪',
 			'BJ' => '貝寧',
 			'BL' => '聖巴泰勒米',
 			'BV' => '鮑威特島',
 			'BW' => '博茨瓦納',
 			'BZ' => '伯利茲',
 			'CC' => '可可斯群島',
 			'CI' => '科特迪瓦',
 			'CI@alt=variant' => '象牙海岸',
 			'CP' => '克里珀頓島',
 			'CR' => '哥斯達黎加',
 			'CV' => '佛得角',
 			'CY' => '塞浦路斯',
 			'DJ' => '吉布提',
 			'EC' => '厄瓜多爾',
 			'ER' => '厄立特里亞',
 			'ET' => '埃塞俄比亞',
 			'GA' => '加蓬',
 			'GD' => '格林納達',
 			'GE' => '格魯吉亞',
 			'GH' => '加納',
 			'GM' => '岡比亞',
 			'GS' => '南佐治亞島與南桑威奇群島',
 			'GT' => '危地馬拉',
 			'GW' => '幾內亞比紹',
 			'GY' => '圭亞那',
 			'HN' => '洪都拉斯',
 			'HR' => '克羅地亞',
 			'IM' => '馬恩島',
 			'IT' => '意大利',
 			'KE' => '肯雅',
 			'KM' => '科摩羅',
 			'KN' => '聖基茨和尼維斯',
 			'LA' => '老撾',
 			'LC' => '聖盧西亞',
 			'LI' => '列支敦士登',
 			'LR' => '利比里亞',
 			'LV' => '拉脱維亞',
 			'ME' => '黑山',
 			'ML' => '馬里',
 			'MR' => '毛里塔尼亞',
 			'MS' => '蒙特塞拉特',
 			'MT' => '馬耳他',
 			'MU' => '毛里裘斯',
 			'MV' => '馬爾代夫',
 			'MW' => '馬拉維',
 			'MZ' => '莫桑比克',
 			'NE' => '尼日爾',
 			'NG' => '尼日利亞',
 			'NR' => '瑙魯',
 			'PF' => '法屬波利尼西亞',
 			'PG' => '巴布亞新幾內亞',
 			'PN' => '皮特凱恩島',
 			'PS' => '巴勒斯坦領土',
 			'QA' => '卡塔爾',
 			'RW' => '盧旺達',
 			'SA' => '沙地阿拉伯',
 			'SB' => '所羅門群島',
 			'SC' => '塞舌爾',
 			'SI' => '斯洛文尼亞',
 			'SJ' => '斯瓦爾巴特群島及揚馬延島',
 			'SL' => '塞拉利昂',
 			'SO' => '索馬里',
 			'SR' => '蘇里南',
 			'ST' => '聖多美和普林西比',
 			'SZ' => '斯威士蘭',
 			'TC' => '特克斯和凱科斯群島',
 			'TD' => '乍得',
 			'TF' => '法屬南部領地',
 			'TG' => '多哥共和國',
 			'TO' => '湯加',
 			'TT' => '千里達和多巴哥',
 			'TV' => '圖瓦盧',
 			'TZ' => '坦桑尼亞',
 			'VC' => '聖文森特和格林納丁斯',
 			'VG' => '英屬維爾京群島',
 			'VI' => '美屬維爾京群島',
 			'VU' => '瓦努阿圖',
 			'YE' => '也門',
 			'YT' => '馬約特',
 			'ZM' => '贊比亞',
 			'ZW' => '津巴布韋',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => '傳統德國拼字法',
 			'1996' => '1996 德國拼字法',
 			'ABL1943' => 'ABL1943',
 			'REVISED' => '已修訂拼字法',
 			'SCOTLAND' => '蘇格蘭標準英語',
 			'SOTAV' => 'SOTAV',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'hc' => '時間週期（12 與 24 小時制',
 			'ms' => '度量衡系統',
 			'x' => '專用區',

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
 				'ethiopic' => q{埃塞俄比亞曆},
 				'ethiopic-amete-alem' => q{埃塞俄比亞阿美德阿萊姆曆},
 			},
 			'collation' => {
 				'big5han' => q{繁體中文排序 (Big5)},
 				'dictionary' => q{詞典排序},
 				'gb2312han' => q{簡體中文排序 (GB2312)},
 				'reformed' => q{改革版排序},
 			},
 			'ms' => {
 				'uksystem' => q{英制},
 				'ussystem' => q{美制},
 			},
 			'numbers' => {
 				'deva' => q{天城體數字},
 				'ethi' => q{埃塞俄比亞數字},
 				'geor' => q{格魯吉亞數字},
 				'knda' => q{卡納達數字},
 				'laoo' => q{老撾數字},
 				'mlym' => q{馬拉雅拉姆數字},
 				'orya' => q{奧里亞數字},
 				'taml' => q{泰米爾數字},
 				'tamldec' => q{泰米爾數字},
 			},

		}
	},
);

has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}⋯',
			'initial' => '⋯{0}',
			'medial' => '{0}⋯{1}',
			'word-final' => '{0}⋯',
			'word-initial' => '⋯{0}',
			'word-medial' => '{0}⋯{1}',
		};
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre-foot' => {
						'name' => q(英畝呎),
						'other' => q({0} 英畝呎),
					},
					'bit' => {
						'name' => q(位元),
						'other' => q({0} 個位元),
					},
					'byte' => {
						'name' => q(位元組),
						'other' => q({0} 位元組),
					},
					'celsius' => {
						'name' => q(攝氏度),
					},
					'centiliter' => {
						'name' => q(厘升),
						'other' => q({0} 厘升),
					},
					'centimeter' => {
						'name' => q(厘米),
						'other' => q({0} 厘米),
						'per' => q({0} 每厘米),
					},
					'century' => {
						'other' => q({0} 世紀),
					},
					'coordinate' => {
						'east' => q(東經 {0}),
						'north' => q(北緯 {0}),
						'south' => q(南緯 {0}),
						'west' => q(西經 {0}),
					},
					'cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0} 立方厘米),
						'per' => q({0} 每立方厘米),
					},
					'cubic-foot' => {
						'name' => q(立方呎),
						'other' => q({0} 立方呎),
					},
					'cubic-inch' => {
						'name' => q(立方吋),
						'other' => q({0} 立方吋),
					},
					'cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0} 立方米),
						'per' => q({0} 每立方米),
					},
					'cup' => {
						'other' => q({0} 量杯),
					},
					'cup-metric' => {
						'other' => q({0} 公制量杯),
					},
					'day' => {
						'name' => q(日),
						'other' => q({0} 日),
						'per' => q({0} 每日),
					},
					'decimeter' => {
						'name' => q(分米),
						'other' => q({0} 分米),
					},
					'degree' => {
						'name' => q(度),
					},
					'fahrenheit' => {
						'name' => q(華氏度),
					},
					'fluid-ounce' => {
						'name' => q(液安士),
						'other' => q({0} 液安士),
					},
					'foodcalorie' => {
						'other' => q({0} 卡路里),
					},
					'foot' => {
						'name' => q(呎),
						'other' => q({0} 呎),
						'per' => q({0} 每呎),
					},
					'gallon' => {
						'per' => q({0} 每加侖),
					},
					'gram' => {
						'per' => q({0} 每克),
					},
					'hectopascal' => {
						'name' => q(百帕斯卡),
						'other' => q({0} 百帕斯卡),
					},
					'horsepower' => {
						'name' => q(匹),
						'other' => q({0} 匹),
					},
					'hour' => {
						'per' => q({0} 每小時),
					},
					'inch' => {
						'name' => q(吋),
						'other' => q({0} 吋),
						'per' => q({0} 每吋),
					},
					'inch-hg' => {
						'name' => q(英吋汞柱),
						'other' => q({0} 英吋汞柱),
					},
					'kelvin' => {
						'name' => q(開爾文),
						'other' => q({0} 開爾文),
					},
					'kilocalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					'kilogram' => {
						'per' => q({0} 每公斤),
					},
					'kilometer' => {
						'per' => q({0} 每公里),
					},
					'kilometer-per-hour' => {
						'name' => q(公里每小時),
					},
					'kilowatt' => {
						'name' => q(千瓦),
						'other' => q({0} 千瓦),
					},
					'liter' => {
						'per' => q({0} 每公升),
					},
					'liter-per-kilometer' => {
						'name' => q(公升/公里),
						'other' => q({0} 公升/公里),
					},
					'megawatt' => {
						'name' => q(兆瓦),
						'other' => q({0} 兆瓦),
					},
					'meter' => {
						'name' => q(米),
						'other' => q({0} 米),
						'per' => q({0} 每米),
					},
					'meter-per-second' => {
						'name' => q(米/秒),
						'other' => q({0} 米/秒),
					},
					'meter-per-second-squared' => {
						'name' => q(米/平方秒),
						'other' => q({0} 米/平方秒),
					},
					'mile-per-gallon' => {
						'name' => q(英里每加侖),
					},
					'mile-per-hour' => {
						'name' => q(英里每小時),
					},
					'millimeter' => {
						'name' => q(毫米),
						'other' => q({0} 毫米),
					},
					'milliwatt' => {
						'name' => q(毫瓦),
						'other' => q({0} 毫瓦),
					},
					'minute' => {
						'per' => q({0} 每分鐘),
					},
					'month' => {
						'name' => q(個月),
						'per' => q({0} 每個月),
					},
					'nanometer' => {
						'name' => q(納米),
						'other' => q({0} 納米),
					},
					'nanosecond' => {
						'name' => q(納秒),
						'other' => q({0} 納秒),
					},
					'ounce' => {
						'name' => q(安士),
						'other' => q({0} 安士),
						'per' => q({0} 每安士),
					},
					'ounce-troy' => {
						'name' => q(金衡安士),
						'other' => q({0} 金衡安士),
					},
					'part-per-million' => {
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}每{1}),
					},
					'point' => {
						'other' => q({0} pt),
					},
					'pound' => {
						'per' => q({0} 每磅),
					},
					'pound-per-square-inch' => {
						'name' => q(磅/平方吋),
						'other' => q({0} 磅/平方吋),
					},
					'revolution' => {
						'name' => q(周),
						'other' => q({0} 周),
					},
					'second' => {
						'per' => q({0}每秒),
					},
					'square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0} 平方厘米),
						'per' => q({0} 每平方厘米),
					},
					'square-foot' => {
						'name' => q(平方呎),
						'other' => q({0} 平方呎),
					},
					'square-inch' => {
						'name' => q(平方吋),
						'other' => q({0} 平方吋),
						'per' => q({0} 每平方吋),
					},
					'square-kilometer' => {
						'per' => q({0} 每平方公里),
					},
					'square-meter' => {
						'name' => q(平方米),
						'other' => q({0} 平方米),
						'per' => q({0} 每平方米),
					},
					'square-mile' => {
						'per' => q({0} 每平方英里),
					},
					'week' => {
						'name' => q(星期),
						'other' => q({0} 星期),
						'per' => q({0} 每星期),
					},
					'year' => {
						'per' => q({0} 每年),
					},
				},
				'narrow' => {
					'acre-foot' => {
						'name' => q(英畝呎),
					},
					'centimeter' => {
						'name' => q(厘米),
						'other' => q({0}厘米),
						'per' => q({0} 每厘米),
					},
					'century' => {
						'other' => q({0}世紀),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(立方厘米),
						'per' => q({0} 每立方厘米),
					},
					'cubic-foot' => {
						'name' => q(立方呎),
					},
					'cubic-inch' => {
						'name' => q(立方吋),
					},
					'cubic-meter' => {
						'name' => q(立方米),
					},
					'cubic-mile' => {
						'other' => q({0}mi³),
					},
					'cup-metric' => {
						'other' => q({0} 量杯),
					},
					'day' => {
						'name' => q(日),
						'other' => q({0}日),
						'per' => q({0} 每日),
					},
					'decimeter' => {
						'name' => q(分米),
					},
					'degree' => {
						'name' => q(度),
					},
					'fahrenheit' => {
						'name' => q(°F),
					},
					'foot' => {
						'name' => q(呎),
						'per' => q({0} 每呎),
					},
					'gallon' => {
						'per' => q({0} 每加侖),
					},
					'gram' => {
						'per' => q({0} 每克),
					},
					'hour' => {
						'other' => q({0}小時),
						'per' => q({0} 每小時),
					},
					'inch' => {
						'name' => q(吋),
						'per' => q({0} 每吋),
					},
					'inch-hg' => {
						'name' => q(英吋汞柱),
						'other' => q({0}″ Hg),
					},
					'kilogram' => {
						'per' => q({0} 每公斤),
					},
					'kilojoule' => {
						'name' => q(千焦),
					},
					'kilometer' => {
						'per' => q({0} 每公里),
					},
					'kilometer-per-hour' => {
						'other' => q({0}kph),
					},
					'liter' => {
						'name' => q(升),
						'per' => q({0} 每升),
					},
					'liter-per-100kilometers' => {
						'other' => q({0}L/100km),
					},
					'megawatt' => {
						'name' => q(兆瓦),
					},
					'meter' => {
						'name' => q(米),
						'other' => q({0}米),
						'per' => q({0} 每米),
					},
					'meter-per-second' => {
						'name' => q(米每秒),
						'other' => q({0}m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(米每平方秒),
					},
					'mile' => {
						'name' => q(哩),
					},
					'mile-per-hour' => {
						'name' => q(英里每小時),
						'other' => q({0}mph),
					},
					'millimeter' => {
						'name' => q(毫米),
						'other' => q({0}毫米),
					},
					'millisecond' => {
						'other' => q({0}毫秒),
					},
					'minute' => {
						'name' => q(分),
						'other' => q({0}分),
						'per' => q({0} 每分鐘),
					},
					'month' => {
						'other' => q({0}個月),
						'per' => q({0} 每月),
					},
					'nanometer' => {
						'name' => q(納米),
					},
					'nanosecond' => {
						'name' => q(納秒),
					},
					'nautical-mile' => {
						'name' => q(浬),
					},
					'ounce' => {
						'name' => q(安士),
						'other' => q({0} 安士),
						'per' => q({0} 每安士),
					},
					'ounce-troy' => {
						'name' => q(金衡安士),
					},
					'part-per-million' => {
						'other' => q({0} ppm),
					},
					'point' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'per' => q({0} 每磅),
					},
					'pound-per-square-inch' => {
						'name' => q(磅每平方吋),
					},
					'revolution' => {
						'name' => q(周),
						'other' => q({0} 周),
					},
					'second' => {
						'other' => q({0}秒),
					},
					'square-centimeter' => {
						'name' => q(平方厘米),
						'per' => q({0} 每平方厘米),
					},
					'square-foot' => {
						'name' => q(平方呎),
						'other' => q({0}ft²),
					},
					'square-inch' => {
						'name' => q(平方吋),
						'per' => q({0} 每平方吋),
					},
					'square-kilometer' => {
						'per' => q({0} 每平方公里),
					},
					'square-meter' => {
						'name' => q(平方米),
						'per' => q({0} 每平方米),
					},
					'square-mile' => {
						'other' => q({0}mi²),
						'per' => q({0} 每平方英里),
					},
					'watt' => {
						'name' => q(瓦),
					},
					'week' => {
						'other' => q({0}週),
						'per' => q({0} 每週),
					},
					'year' => {
						'other' => q({0}年),
						'per' => q({0} 每年),
					},
				},
				'short' => {
					'acre-foot' => {
						'name' => q(英畝呎),
						'other' => q({0} 英畝呎),
					},
					'arc-minute' => {
						'name' => q(分),
						'other' => q({0} 分),
					},
					'arc-second' => {
						'other' => q({0} 秒),
					},
					'celsius' => {
						'name' => q(°C),
					},
					'centiliter' => {
						'name' => q(厘升),
						'other' => q({0} 厘升),
					},
					'centimeter' => {
						'name' => q(厘米),
						'other' => q({0} 厘米),
						'per' => q({0} 每厘米),
					},
					'coordinate' => {
						'east' => q({0} 東),
						'north' => q({0} 北),
						'south' => q({0} 南),
						'west' => q({0} 西),
					},
					'cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0} 立方厘米),
						'per' => q({0} 每立方厘米),
					},
					'cubic-foot' => {
						'name' => q(立方呎),
						'other' => q({0} 立方呎),
					},
					'cubic-inch' => {
						'name' => q(立方吋),
						'other' => q({0} 立方吋),
					},
					'cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0} 立方米),
						'per' => q({0} 每立方米),
					},
					'cup' => {
						'other' => q({0} 量杯),
					},
					'cup-metric' => {
						'other' => q({0} 公制量杯),
					},
					'day' => {
						'name' => q(日),
						'other' => q({0} 日),
						'per' => q({0} 每日),
					},
					'decimeter' => {
						'name' => q(分米),
						'other' => q({0} 分米),
					},
					'degree' => {
						'name' => q(度),
					},
					'fahrenheit' => {
						'name' => q(°F),
					},
					'fluid-ounce' => {
						'name' => q(液安士),
						'other' => q({0} 液安士),
					},
					'foodcalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					'foot' => {
						'name' => q(呎),
						'per' => q({0} 每呎),
					},
					'g-force' => {
						'other' => q({0} G),
					},
					'gallon' => {
						'per' => q({0} 每加侖),
					},
					'gram' => {
						'per' => q({0} 每克),
					},
					'hour' => {
						'per' => q({0} 每小時),
					},
					'inch' => {
						'name' => q(吋),
						'per' => q({0} 每吋),
					},
					'inch-hg' => {
						'name' => q(英吋汞柱),
						'other' => q({0} 英吋汞柱),
					},
					'joule' => {
						'other' => q({0} 焦耳),
					},
					'kilogram' => {
						'per' => q({0} 每公斤),
					},
					'kilojoule' => {
						'name' => q(千焦),
					},
					'kilometer' => {
						'per' => q({0} 每公里),
					},
					'kilometer-per-hour' => {
						'name' => q(公里每小時),
						'other' => q({0} 公里每小時),
					},
					'liter' => {
						'name' => q(升),
						'per' => q({0} 每升),
					},
					'liter-per-kilometer' => {
						'other' => q({0} 升每公里),
					},
					'megawatt' => {
						'name' => q(兆瓦),
						'other' => q({0} 兆瓦),
					},
					'meter' => {
						'name' => q(米),
						'other' => q({0} 米),
						'per' => q({0} 每米),
					},
					'meter-per-second' => {
						'name' => q(米每秒),
						'other' => q({0} 米/秒),
					},
					'meter-per-second-squared' => {
						'name' => q(米每平方秒),
						'other' => q({0} 米每平方秒),
					},
					'mile' => {
						'name' => q(哩),
						'other' => q({0} 哩),
					},
					'mile-per-gallon' => {
						'other' => q({0} 英里每加侖),
					},
					'mile-per-hour' => {
						'name' => q(英里每小時),
						'other' => q({0} 英里每小時),
					},
					'millimeter' => {
						'name' => q(毫米),
						'other' => q({0} 毫米),
					},
					'minute' => {
						'per' => q({0} 每分鐘),
					},
					'month' => {
						'name' => q(個月),
						'per' => q({0} 每月),
					},
					'nanometer' => {
						'name' => q(納米),
						'other' => q({0} 納米),
					},
					'nanosecond' => {
						'name' => q(納秒),
						'other' => q({0} 納秒),
					},
					'nautical-mile' => {
						'name' => q(浬),
						'other' => q({0} 浬),
					},
					'ounce' => {
						'name' => q(安士),
						'other' => q({0} 安士),
						'per' => q({0} 每安士),
					},
					'ounce-troy' => {
						'name' => q(金衡安士),
						'other' => q({0} 金衡安士),
					},
					'part-per-million' => {
						'other' => q({0} ppm),
					},
					'point' => {
						'other' => q({0} pt),
					},
					'pound' => {
						'per' => q({0} 每磅),
					},
					'pound-per-square-inch' => {
						'name' => q(磅每平方吋),
						'other' => q({0} 磅每平方吋),
					},
					'revolution' => {
						'name' => q(周),
						'other' => q({0} 周),
					},
					'second' => {
						'per' => q({0}每秒),
					},
					'square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0} 平方厘米),
						'per' => q({0} 每平方厘米),
					},
					'square-foot' => {
						'name' => q(平方呎),
						'other' => q({0} 平方呎),
					},
					'square-inch' => {
						'name' => q(平方吋),
						'other' => q({0} 平方吋),
						'per' => q({0} 每平方吋),
					},
					'square-kilometer' => {
						'per' => q({0} 每平方公里),
					},
					'square-meter' => {
						'name' => q(平方米),
						'other' => q({0} 平方米),
						'per' => q({0} 每平方米),
					},
					'square-mile' => {
						'per' => q({0} 每平方英里),
					},
					'watt' => {
						'name' => q(瓦),
					},
					'week' => {
						'name' => q(星期),
						'other' => q({0} 星期),
						'per' => q({0} 每週),
					},
					'year' => {
						'per' => q({0} 每年),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:是|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:否|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}及{1}),
				2 => q({0}及{1}),
		} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'short' => {
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0B',
				},
				'10000000000' => {
					'other' => '00B',
				},
				'100000000000' => {
					'other' => '000B',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
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
				'currency' => q(阿拉伯聯合酋長國迪爾汗),
				'other' => q(阿拉伯聯合酋長國迪爾汗),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(澳元),
				'other' => q(澳元),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(阿魯巴盾),
				'other' => q(阿魯巴盾),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(亞塞拜疆馬納特),
				'other' => q(亞塞拜疆馬納特),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(波斯尼亞-赫塞哥維納第納爾),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(波斯尼亞-赫塞哥維納可轉換馬克),
				'other' => q(波斯尼亞-赫塞哥維納可轉換馬克),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(巴巴多斯元),
				'other' => q(巴巴多斯元),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(布隆迪法郎),
				'other' => q(布隆迪法郎),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(百慕達元),
				'other' => q(百慕達元),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(博茨瓦納普拉),
				'other' => q(博茨瓦納普拉),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(伯利茲元),
				'other' => q(伯利茲元),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(加拿大元),
				'other' => q(加拿大元),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(哥斯達黎加科郎),
				'other' => q(哥斯達黎加科郎),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(佛得角埃斯庫多),
				'other' => q(佛得角埃斯庫多),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(吉布提法郎),
				'other' => q(吉布提法郎),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(多米尼加披索),
				'other' => q(多米尼加披索),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(埃塞俄比亞比爾),
				'other' => q(埃塞俄比亞比爾),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(格魯吉亞拉里),
				'other' => q(格魯吉亞拉里),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(加納塞地),
				'other' => q(加納塞地),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(岡比亞達拉西),
				'other' => q(岡比亞達拉西),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(危地馬拉格查爾),
				'other' => q(危地馬拉格查爾),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(港元),
				'other' => q(港元),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(克羅地亞庫納),
				'other' => q(克羅地亞庫納),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(意大利里拉),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(肯雅先令),
				'other' => q(肯雅先令),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(柬埔寨里爾),
				'other' => q(柬埔寨里爾),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(北韓圜),
				'other' => q(北韓圜),
			},
		},
		'KRW' => {
			symbol => '₩',
		},
		'KYD' => {
			display_name => {
				'other' => q(開曼群島美元),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(哈薩克坦吉),
				'other' => q(哈薩克坦吉),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(老撾基普),
				'other' => q(老撾基普),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(利比利亞元),
				'other' => q(利比利亞元),
			},
		},
		'LTL' => {
			display_name => {
				'other' => q(立陶宛里塔),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(摩爾多瓦列伊),
				'other' => q(摩爾多瓦列伊),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(毛里塔尼亞烏吉亞),
				'other' => q(毛里塔尼亞烏吉亞),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(毛里裘斯盧布),
				'other' => q(毛里裘斯盧布),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(馬爾代夫盧非亞),
				'other' => q(馬爾代夫盧非亞),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(莫桑比克梅蒂卡爾),
				'other' => q(莫桑比克梅蒂卡爾),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(尼日利亞奈拉),
				'other' => q(尼日利亞奈拉),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(紐西蘭元),
				'other' => q(紐西蘭元),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(阿曼里奧),
				'other' => q(阿曼里奧),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(巴布亞新幾內亞基那),
				'other' => q(巴布亞新幾內亞基那),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(卡塔爾里亞爾),
				'other' => q(卡塔爾里亞爾),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(塞爾維亞第納爾),
				'other' => q(塞爾維亞第納爾),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(盧旺達法郎),
				'other' => q(盧旺達法郎),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(沙特阿拉伯里亞爾),
				'other' => q(沙特阿拉伯里亞爾),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(所羅門群島元),
				'other' => q(所羅門群島元),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(塞舌爾盧比),
				'other' => q(塞舌爾盧比),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(新加坡元),
				'other' => q(新加坡元),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(塞拉利昂利昂),
				'other' => q(塞拉利昂利昂),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(索馬里先令),
				'other' => q(索馬里先令),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(蘇里南元),
				'other' => q(蘇里南元),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(聖多美和普林西比多布拉),
				'other' => q(聖多美和普林西比多布拉),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(敍利亞鎊),
				'other' => q(敍利亞鎊),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(斯威士蘭里朗吉尼),
				'other' => q(斯威士蘭里朗吉尼),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(湯加潘加),
				'other' => q(湯加潘加),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(千里達和多巴哥元),
				'other' => q(千里達和多巴哥元),
			},
		},
		'TWD' => {
			symbol => 'NT$',
		},
		'TZS' => {
			display_name => {
				'currency' => q(坦桑尼亞先令),
				'other' => q(坦桑尼亞先令),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(瓦努阿圖瓦圖),
				'other' => q(瓦努阿圖瓦圖),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(中非法郎),
				'other' => q(中非法郎),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(東加勒比元),
				'other' => q(東加勒比元),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(多哥非洲共同體法郎),
				'other' => q(西非法郎),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(太平洋法郎),
				'other' => q(太平洋法郎),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(也門里雅),
				'other' => q(也門里雅),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(贊比亞克瓦查),
				'other' => q(贊比亞克瓦查),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'chinese' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'十一月',
							'十二月'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'正',
							'二',
							'三',
							'四',
							'五',
							'六',
							'七',
							'八',
							'九',
							'十',
							'十一',
							'十二'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'十一月',
							'十二月'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'十一月',
							'十二月'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'正',
							'二',
							'三',
							'四',
							'五',
							'六',
							'七',
							'八',
							'九',
							'十',
							'十一',
							'十二'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'十一月',
							'十二月'
						],
						leap => [
							
						],
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
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
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 800
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'night1' if $time >= 0
						&& $time < 500;
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
				'narrow' => {
					'morning1' => q{早上},
					'afternoon1' => q{中午},
					'night1' => q{凌晨},
					'evening1' => q{晚上},
					'midnight' => q{午夜},
					'morning2' => q{上午},
					'afternoon2' => q{下午},
				},
				'wide' => {
					'evening1' => q{晚上},
					'morning2' => q{上午},
					'midnight' => q{午夜},
					'afternoon2' => q{下午},
					'morning1' => q{早上},
					'afternoon1' => q{中午},
					'night1' => q{凌晨},
				},
				'abbreviated' => {
					'night1' => q{凌晨},
					'afternoon1' => q{中午},
					'morning1' => q{早上},
					'afternoon2' => q{下午},
					'midnight' => q{午夜},
					'evening1' => q{晚上},
					'morning2' => q{上午},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'evening1' => q{晚上},
					'morning2' => q{上午},
					'afternoon2' => q{下午},
					'morning1' => q{早上},
					'afternoon1' => q{中午},
					'night1' => q{凌晨},
				},
				'wide' => {
					'evening1' => q{晚上},
					'morning2' => q{上午},
					'afternoon2' => q{下午},
					'afternoon1' => q{中午},
					'morning1' => q{早上},
					'night1' => q{凌晨},
				},
				'narrow' => {
					'afternoon2' => q{下午},
					'morning2' => q{上午},
					'evening1' => q{晚上},
					'night1' => q{凌晨},
					'morning1' => q{早上},
					'afternoon1' => q{中午},
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
		'buddhist' => {
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => '公元前',
				'1' => '公元'
			},
			wide => {
				'0' => '公元前',
				'1' => '公元'
			},
		},
		'roc' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
			'full' => q{U（r）年MMMdEEEE},
			'long' => q{U（r）年MMMd},
			'medium' => q{U年MMMd},
			'short' => q{U/M/d},
		},
		'generic' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gy/M/d},
		},
		'gregorian' => {
			'full' => q{y年M月d日EEEE},
			'short' => q{d/M/y},
		},
		'roc' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'generic' => {
			'full' => q{{1} {0}},
		},
		'gregorian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'roc' => {
			Ed => q{d日E},
			MEd => q{d-M（E）},
			Md => q{d-M},
			yyyyMEd => q{Gy/M/dE},
		},
		'generic' => {
			Ed => q{d日E},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			MEd => q{d/M（E）},
			MMMEd => q{M月d日E},
			Md => q{d/M},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy/M},
			yyyyMEd => q{Gy/M/dE},
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年M月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{Gy/M/d},
			yyyyQQQ => q{Gy年QQQ},
			yyyyQQQQ => q{Gy年QQQQ},
		},
		'gregorian' => {
			Ed => q{d日E},
			GyMMMEd => q{Gy年M月d日E},
			MEd => q{d/M（E）},
			MMMEd => q{M月d日E},
			MMMMW => q{M月第W週},
			MMdd => q{dd/MM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{d/M/y（E）},
			yMM => q{MM/y},
			yMMMEd => q{y年M月d日E},
			yMd => q{d/M/y},
			yw => q{Y年第w週},
		},
		'buddhist' => {
			MEd => q{M-d（E）},
			Md => q{M-d},
		},
		'chinese' => {
			Ed => q{d日E},
			H => q{HH},
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
				M => q{d/M（E） 至 d/M（E）},
				d => q{d/M（E） 至 d/M（E）},
			},
			Md => {
				M => q{d/M 至 d/M},
				d => q{d/M 至 d/M},
			},
			y => {
				y => q{Gy年至y年},
			},
			yM => {
				M => q{Gy/M至y/M},
				y => q{Gy/M至y/M},
			},
			yMEd => {
				M => q{Gy/M/dE至y/M/dE},
				d => q{Gy/M/dE至y/M/dE},
				y => q{Gy/M/dE至y/M/dE},
			},
			yMMM => {
				M => q{Gy年M月至M月},
				y => q{Gy年M月至y年M月},
			},
			yMMMEd => {
				M => q{Gy年M月d日E至M月d日E},
				d => q{Gy年M月d日E至d日E},
				y => q{Gy年M月d日E至y年M月d日E},
			},
			yMMMM => {
				M => q{Gy年M月至M月},
				y => q{Gy年M月至y年M月},
			},
			yMMMd => {
				M => q{Gy年M月d日至M月d日},
				d => q{Gy年M月d日至d日},
				y => q{Gy年M月d日至y年M月d日},
			},
			yMd => {
				M => q{Gy/M/d至y/M/d},
				d => q{Gy/M/d至y/M/d},
				y => q{Gy/M/d至y/M/d},
			},
		},
		'gregorian' => {
			MEd => {
				M => q{d/M（E） 至 d/M（E）},
				d => q{d/M（E） 至 d/M（E）},
			},
			Md => {
				M => q{d/M 至 d/M},
				d => q{d/M 至 d/M},
			},
			yM => {
				M => q{M/y 至 M/y},
				y => q{M/y 至 M/y},
			},
			yMEd => {
				M => q{d/M/y（E） 至 d/M/y（E）},
				d => q{d/M/y（E） 至 d/M/y（E）},
				y => q{d/M/y（E） 至 d/M/y（E）},
			},
			yMd => {
				M => q{d/M/y 至 d/M/y},
				d => q{d/M/y 至 d/M/y},
				y => q{d/M/y 至 d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0}夏令時間),
		regionFormat => q({0}標準時間),
		'Africa/Abidjan' => {
			exemplarCity => q#阿比贊#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#阿斯馬拉#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#班基#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#科納克里#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#達累斯薩拉姆#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#吉布提#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#約翰內斯堡#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#金沙薩#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#拉各斯#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#利布維#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#盧安達#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#盧薩卡#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#馬塞魯#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#摩加迪沙#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#內羅畢#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#努瓦克肖特#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#溫特和克#,
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#南非時間#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#埃達克#,
		},
		'America/Anchorage' => {
			exemplarCity => q#安克雷奇#,
		},
		'America/Anguilla' => {
			exemplarCity => q#安圭拉#,
		},
		'America/Antigua' => {
			exemplarCity => q#安提瓜#,
		},
		'America/Araguaina' => {
			exemplarCity => q#阿拉瓜伊納#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#拉里奧哈#,
		},
		'America/Aruba' => {
			exemplarCity => q#阿魯巴#,
		},
		'America/Asuncion' => {
			exemplarCity => q#阿松森#,
		},
		'America/Bahia' => {
			exemplarCity => q#巴希雅#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#巴伊亞德班德拉斯#,
		},
		'America/Barbados' => {
			exemplarCity => q#巴巴多斯#,
		},
		'America/Belize' => {
			exemplarCity => q#伯利茲#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#博阿維斯塔#,
		},
		'America/Boise' => {
			exemplarCity => q#博伊西#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#大坎普#,
		},
		'America/Caracas' => {
			exemplarCity => q#加拉加斯#,
		},
		'America/Cayenne' => {
			exemplarCity => q#卡宴#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#芝華華#,
		},
		'America/Cordoba' => {
			exemplarCity => q#科爾多瓦#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#哥斯達黎加#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#庫亞巴#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#道森灣#,
		},
		'America/Edmonton' => {
			exemplarCity => q#愛民頓#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#福塔萊薩#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#格萊斯灣#,
		},
		'America/Grenada' => {
			exemplarCity => q#格林納達#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#瓜德羅普#,
		},
		'America/Guatemala' => {
			exemplarCity => q#危地馬拉#,
		},
		'America/Guyana' => {
			exemplarCity => q#圭亞那#,
		},
		'America/Halifax' => {
			exemplarCity => q#哈利法克斯#,
		},
		'America/Havana' => {
			exemplarCity => q#夏灣拿#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#印第安納州諾克斯#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#印第安納州馬倫哥#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#印第安納州彼得堡#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#印第安納州特爾城#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#印第安納州韋韋#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#印第安納州溫森斯#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#印第安納州威納馬克#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#印第安納波利斯#,
		},
		'America/Inuvik' => {
			exemplarCity => q#伊努維克#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#肯塔基州蒙蒂塞洛#,
		},
		'America/Louisville' => {
			exemplarCity => q#路易維爾#,
		},
		'America/Maceio' => {
			exemplarCity => q#馬塞約#,
		},
		'America/Managua' => {
			exemplarCity => q#馬那瓜#,
		},
		'America/Martinique' => {
			exemplarCity => q#馬提尼克#,
		},
		'America/Menominee' => {
			exemplarCity => q#梅諾米尼#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#墨西哥城#,
		},
		'America/Miquelon' => {
			exemplarCity => q#密克隆#,
		},
		'America/Monterrey' => {
			exemplarCity => q#蒙特雷#,
		},
		'America/Montevideo' => {
			exemplarCity => q#蒙得維的亞#,
		},
		'America/Montserrat' => {
			exemplarCity => q#蒙塞拉特島#,
		},
		'America/Nassau' => {
			exemplarCity => q#拿騷#,
		},
		'America/Nipigon' => {
			exemplarCity => q#尼皮貢#,
		},
		'America/Noronha' => {
			exemplarCity => q#諾羅尼亞#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#北達科他州比尤拉#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#北達科他州中心市#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#北達科他州新薩勒姆#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#韋柳港#,
		},
		'America/Recife' => {
			exemplarCity => q#累西腓#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#里約布蘭科#,
		},
		'America/Santiago' => {
			exemplarCity => q#聖地亞哥#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#聖多明各#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#聖巴泰勒米#,
		},
		'America/St_Johns' => {
			exemplarCity => q#聖約翰斯#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#聖盧西亞#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#聖文森特#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#特古西加爾巴#,
		},
		'America/Thule' => {
			exemplarCity => q#圖勒#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#雷灣#,
		},
		'America/Tijuana' => {
			exemplarCity => q#蒂華納#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#白馬市#,
		},
		'America/Yakutat' => {
			exemplarCity => q#亞庫塔特#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#黃刀鎮#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#北美中部夏令時間#,
				'generic' => q#北美中部時間#,
				'standard' => q#北美中部標準時間#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#北美東部夏令時間#,
				'generic' => q#北美東部時間#,
				'standard' => q#北美東部標準時間#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#北美山區夏令時間#,
				'generic' => q#北美山區時間#,
				'standard' => q#北美山區標準時間#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#北美太平洋夏令時間#,
				'generic' => q#北美太平洋時間#,
				'standard' => q#北美太平洋標準時間#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#凱西站#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#戴維斯站#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#杜蒙迪維爾站#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#麥夸里#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#莫森站#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#麥克默多站#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#帕爾默#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#羅瑟拉站#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#昭和站#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#特羅爾站#,
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#朗伊爾城#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#阿納德爾#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#阿什哈巴德#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#比斯凱克#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#科倫坡#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#杜尚別#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#加沙#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#希伯侖#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#伊爾庫茨克#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#查雅普拉#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#卡拉奇#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#錫江#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#馬斯喀特#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#尼科西亞#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#卡塔爾#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#利雅得#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#雅庫茨克#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#葉卡捷琳堡#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#耶烈萬#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#加那利#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#佛得角#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#馬德拉島#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#雷克雅未克#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#史丹利#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#阿德萊德#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#布里斯本#,
		},
		'Australia/Currie' => {
			exemplarCity => q#卡里#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#荷伯特#,
		},
		'Australia/Perth' => {
			exemplarCity => q#珀斯#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#悉尼#,
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#亞塞拜疆夏令時間#,
				'generic' => q#亞塞拜疆時間#,
				'standard' => q#亞塞拜疆標準時間#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#佛得角夏令時間#,
				'generic' => q#佛得角時間#,
				'standard' => q#佛得角標準時間#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#可可斯群島時間#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#迪蒙迪維爾時間#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#厄瓜多爾時間#,
			},
		},
		'Europe/Belgrade' => {
			exemplarCity => q#貝爾格萊德#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#伯拉第斯拉瓦#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#基希訥烏#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#根西島#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#馬恩島#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#盧布爾雅那#,
		},
		'Europe/Malta' => {
			exemplarCity => q#馬耳他#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#波德戈里察#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#薩拉熱窩#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#斯科普里#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#烏日哥羅德#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#華杜茲#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#薩格勒布#,
		},
		'Galapagos' => {
			long => {
				'standard' => q#加拉帕戈群島時間#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#格魯吉亞夏令時間#,
				'generic' => q#格魯吉亞時間#,
				'standard' => q#格魯吉亞標準時間#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#波斯灣海域時間#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#圭亞那時間#,
			},
		},
		'India' => {
			long => {
				'standard' => q#印度時間#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#安塔那那利佛#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#查戈斯群島#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#可可斯群島#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#科摩羅#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#凱爾蓋朗群島#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#馬爾代夫#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#毛里裘斯#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#馬約特#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#留尼旺#,
		},
		'Indochina' => {
			long => {
				'standard' => q#中南半島時間#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#伊爾庫茨克夏令時間#,
				'generic' => q#伊爾庫茨克時間#,
				'standard' => q#伊爾庫茨克標準時間#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#科斯雷時間#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#麥夸里群島時間#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#馬爾代夫時間#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#馬克薩斯時間#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#毛里裘斯夏令時間#,
				'generic' => q#毛里裘斯時間#,
				'standard' => q#毛里裘斯標準時間#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#瑙魯時間#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#新喀里多尼亞夏令時間#,
				'generic' => q#新喀里多尼亞時間#,
				'standard' => q#新喀里多尼亞標準時間#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#費爾南多迪諾羅尼亞夏令時間#,
				'generic' => q#費爾南多迪諾羅尼亞時間#,
				'standard' => q#費爾南多迪諾羅尼亞標準時間#,
			},
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#布干維爾島#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#查塔姆#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#恩德伯里島#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#法考福環礁#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#甘比爾#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#瓜達爾卡納爾島#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#約翰斯頓環礁#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#科斯雷#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#瓜加林環礁#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#馬久羅#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#馬克薩斯群島#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#瑙魯#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#努美阿#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#帕果帕果#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#皮特康群島#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#湯加塔布島#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#威克島#,
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#巴布亞新畿內亞時間#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#皮特康時間#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#塞舌爾時間#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#新加坡時間#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#所羅門群島時間#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#蘇里南時間#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#湯加夏令時間#,
				'generic' => q#湯加時間#,
				'standard' => q#湯加標準時間#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#圖瓦盧時間#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#瓦努阿圖夏令時間#,
				'generic' => q#瓦努阿圖時間#,
				'standard' => q#瓦努阿圖標準時間#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#雅庫茨克夏令時間#,
				'generic' => q#雅庫茨克時間#,
				'standard' => q#雅庫茨克標準時間#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
