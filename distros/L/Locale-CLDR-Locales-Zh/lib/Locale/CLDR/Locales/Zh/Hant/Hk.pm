=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Zh::Hant::Hk - Package for language Chinese

=cut

package Locale::CLDR::Locales::Zh::Hant::Hk;
# This file auto generated from Data\common\main\zh_Hant_HK.xml
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

extends('Locale::CLDR::Locales::Zh::Hant');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => '阿法爾文',
 				'am' => '岩哈拉語',
 				'az' => '阿塞拜疆文',
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
 				'fa_AF' => '達利文',
 				'fr_CA' => '加拿大法文',
 				'fr_CH' => '瑞士法文',
 				'gil' => '吉爾伯特文',
 				'gl' => '加里西亞文',
 				'gsw' => '瑞士德文',
 				'hr' => '克羅地亞文',
 				'ig' => '伊博文',
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
 			'AZ' => '亞塞拜疆',
 			'BA' => '波斯尼亞和黑塞哥維那',
 			'BB' => '巴巴多斯',
 			'BF' => '布基納法索',
 			'BI' => '布隆迪',
 			'BJ' => '貝寧',
 			'BL' => '聖巴泰勒米',
 			'BV' => '鮑威特島',
 			'BW' => '博茨瓦納',
 			'BZ' => '伯利茲',
 			'CC' => '科科斯 (基林) 群島',
 			'CI' => '科特迪瓦',
 			'CI@alt=variant' => '象牙海岸',
 			'CP' => '克里珀頓島',
 			'CR' => '哥斯達黎加',
 			'CV' => '佛得角',
 			'CY' => '塞浦路斯',
 			'DJ' => '吉布提',
 			'DO' => '多米尼加共和國',
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
 			'KE' => '肯尼亞',
 			'KM' => '科摩羅',
 			'KN' => '聖基茨和尼維斯',
 			'LA' => '老撾',
 			'LC' => '聖盧西亞',
 			'LI' => '列支敦士登',
 			'LR' => '利比里亞',
 			'LS' => '萊索托',
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
 			'PG' => '巴布亞新畿內亞',
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
 			'SM' => '聖馬力諾',
 			'SO' => '索馬里',
 			'SR' => '蘇里南',
 			'ST' => '聖多美和普林西比',
 			'SZ' => '斯威士蘭',
 			'TC' => '特克斯和凱科斯群島',
 			'TD' => '乍得',
 			'TF' => '法屬南部領地',
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
 			'REVISED' => '已修訂拼字法',
 			'SCOTLAND' => '蘇格蘭標準英語',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
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
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(米/平方秒),
						'other' => q({0} 米/平方秒),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(米/平方秒),
						'other' => q({0} 米/平方秒),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'per' => q({0} 每平方厘米),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q({0} 每平方厘米),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'per' => q({0} 每平方吋),
					},
					# Core Unit Identifier
					'square-inch' => {
						'per' => q({0} 每平方吋),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'per' => q({0} 每平方公里),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'per' => q({0} 每平方公里),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'per' => q({0} 每平方米),
					},
					# Core Unit Identifier
					'square-meter' => {
						'per' => q({0} 每平方米),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'per' => q({0} 每平方英里),
					},
					# Core Unit Identifier
					'square-mile' => {
						'per' => q({0} 每平方英里),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(每公升毫摩爾),
						'other' => q(每公升 {0} 毫摩爾),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(每公升毫摩爾),
						'other' => q(每公升 {0} 毫摩爾),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(公升/100公里),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(公升/100公里),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(公升/公里),
						'other' => q({0} 公升/公里),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(公升/公里),
						'other' => q({0} 公升/公里),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(英里/加侖),
						'other' => q({0} 英里/加侖),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(英里/加侖),
						'other' => q({0} 英里/加侖),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(東經 {0}),
						'north' => q(北緯 {0}),
						'south' => q(南緯 {0}),
						'west' => q(西經 {0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(東經 {0}),
						'north' => q(北緯 {0}),
						'south' => q(南緯 {0}),
						'west' => q(西經 {0}),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(位元),
						'other' => q({0} 個位元),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(位元),
						'other' => q({0} 個位元),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(位元組),
						'other' => q({0} 位元組),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(位元組),
						'other' => q({0} 位元組),
					},
					# Long Unit Identifier
					'duration-century' => {
						'other' => q({0} 世紀),
					},
					# Core Unit Identifier
					'century' => {
						'other' => q({0} 世紀),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} 每日),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} 每日),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} 每小時),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} 每小時),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'per' => q({0} 每分鐘),
					},
					# Core Unit Identifier
					'minute' => {
						'per' => q({0} 每分鐘),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} 每個月),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} 每個月),
					},
					# Long Unit Identifier
					'duration-second' => {
						'per' => q({0}每秒),
					},
					# Core Unit Identifier
					'second' => {
						'per' => q({0}每秒),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0} 每星期),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0} 每星期),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} 每年),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} 每年),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(英制熱量單位),
						'other' => q({0} 英制熱量單位),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(英制熱量單位),
						'other' => q({0} 英制熱量單位),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'other' => q({0} 卡路里),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'other' => q({0} 卡路里),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0} 千焦),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0} 千焦),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'other' => q({0}每百公里千瓦小時),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'other' => q({0}每百公里千瓦小時),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'per' => q({0} 每厘米),
					},
					# Core Unit Identifier
					'centimeter' => {
						'per' => q({0} 每厘米),
					},
					# Long Unit Identifier
					'length-foot' => {
						'other' => q({0} 呎),
						'per' => q({0} 每呎),
					},
					# Core Unit Identifier
					'foot' => {
						'other' => q({0} 呎),
						'per' => q({0} 每呎),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q({0} 吋),
						'per' => q({0} 每吋),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0} 吋),
						'per' => q({0} 每吋),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'per' => q({0} 每公里),
					},
					# Core Unit Identifier
					'kilometer' => {
						'per' => q({0} 每公里),
					},
					# Long Unit Identifier
					'length-meter' => {
						'per' => q({0} 每米),
					},
					# Core Unit Identifier
					'meter' => {
						'per' => q({0} 每米),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(道爾頓),
						'other' => q({0} 道爾頓),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(道爾頓),
						'other' => q({0} 道爾頓),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'other' => q({0}格令),
					},
					# Core Unit Identifier
					'grain' => {
						'other' => q({0}格令),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'per' => q({0} 每克),
					},
					# Core Unit Identifier
					'gram' => {
						'per' => q({0} 每克),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'per' => q({0} 每公斤),
					},
					# Core Unit Identifier
					'kilogram' => {
						'per' => q({0} 每公斤),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'per' => q({0} 每安士),
					},
					# Core Unit Identifier
					'ounce' => {
						'per' => q({0} 每安士),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q({0} 每磅),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q({0} 每磅),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}每{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}每{1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(匹),
						'other' => q({0} 匹),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(匹),
						'other' => q({0} 匹),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(千瓦),
						'other' => q({0} 千瓦),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(千瓦),
						'other' => q({0} 千瓦),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(兆瓦),
						'other' => q({0} 兆瓦),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(兆瓦),
						'other' => q({0} 兆瓦),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(毫瓦),
						'other' => q({0} 毫瓦),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(毫瓦),
						'other' => q({0} 毫瓦),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0}二次方),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0}二次方),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q({0}三次方),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q({0}三次方),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(百帕斯卡),
						'other' => q({0} 百帕斯卡),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(百帕斯卡),
						'other' => q({0} 百帕斯卡),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(兆帕斯卡),
						'other' => q({0} 兆帕斯卡),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(兆帕斯卡),
						'other' => q({0} 兆帕斯卡),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(磅/平方吋),
						'other' => q({0} 磅/平方吋),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(磅/平方吋),
						'other' => q({0} 磅/平方吋),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(蒲福氏風級),
						'other' => q(蒲福氏風級 {0} 級),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(蒲福氏風級),
						'other' => q(蒲福氏風級 {0} 級),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(公里每小時),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(公里每小時),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(米/秒),
						'other' => q({0} 米/秒),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(米/秒),
						'other' => q({0} 米/秒),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(英里每小時),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(英里每小時),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(攝氏度),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(攝氏度),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(華氏度),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(華氏度),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(開爾文),
						'other' => q({0} 開爾文),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(開爾文),
						'other' => q({0} 開爾文),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(磅尺),
						'other' => q({0} 磅尺),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(磅尺),
						'other' => q({0} 磅尺),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'per' => q({0} 每立方厘米),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'per' => q({0} 每立方厘米),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'per' => q({0} 每立方米),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'per' => q({0} 每立方米),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0} 每加侖),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0} 每加侖),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'per' => q({0} 每公升),
					},
					# Core Unit Identifier
					'liter' => {
						'per' => q({0} 每公升),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-revolution' => {
						'other' => q({0} 周),
					},
					# Core Unit Identifier
					'revolution' => {
						'other' => q({0} 周),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'other' => q({0} 個項目),
					},
					# Core Unit Identifier
					'item' => {
						'other' => q({0} 個項目),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Long Unit Identifier
					'duration-century' => {
						'other' => q({0}世紀),
					},
					# Core Unit Identifier
					'century' => {
						'other' => q({0}世紀),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0}日),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0}日),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(10年),
						'other' => q({0}0年),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(10年),
						'other' => q({0}0年),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0}小時),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0}小時),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0}毫秒),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0}毫秒),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(分),
						'other' => q({0}分),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(分),
						'other' => q({0}分),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0}個月),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0}個月),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'other' => q({0}刻),
					},
					# Core Unit Identifier
					'quarter' => {
						'other' => q({0}刻),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0}秒),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0}秒),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0}週),
						'per' => q({0} 每星期),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0}週),
						'per' => q({0} 每星期),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0}年),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0}年),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'other' => q({0}千卡),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'other' => q({0}千卡),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0}千焦),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0}千焦),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'other' => q({0}厘米),
					},
					# Core Unit Identifier
					'centimeter' => {
						'other' => q({0}厘米),
					},
					# Long Unit Identifier
					'length-meter' => {
						'other' => q({0}米),
					},
					# Core Unit Identifier
					'meter' => {
						'other' => q({0}米),
					},
					# Long Unit Identifier
					'length-mile' => {
						'other' => q({0}哩),
					},
					# Core Unit Identifier
					'mile' => {
						'other' => q({0}哩),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'other' => q({0}毫米),
					},
					# Core Unit Identifier
					'millimeter' => {
						'other' => q({0}毫米),
					},
					# Long Unit Identifier
					'length-point' => {
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'light-candela' => {
						'other' => q({0}坎德拉),
					},
					# Core Unit Identifier
					'candela' => {
						'other' => q({0}坎德拉),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'other' => q({0}格令),
					},
					# Core Unit Identifier
					'grain' => {
						'other' => q({0}格令),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'other' => q({0} 公斤),
					},
					# Core Unit Identifier
					'kilogram' => {
						'other' => q({0} 公斤),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'other' => q({0} 安士),
					},
					# Core Unit Identifier
					'ounce' => {
						'other' => q({0} 安士),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(蒲福氏風級),
						'other' => q(蒲福氏風級 {0} 級),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(蒲福氏風級),
						'other' => q(蒲福氏風級 {0} 級),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'other' => q({0}kph),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'other' => q({0}kph),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q({0}mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q({0}mph),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'other' => q({0} 量杯),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'other' => q({0} 量杯),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'other' => q({0}英制甜品匙),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'other' => q({0}英制甜品匙),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'other' => q({0}英液安士),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'other' => q({0}英液安士),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0} 每加侖),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0} 每加侖),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'per' => q({0} 每升),
					},
					# Core Unit Identifier
					'liter' => {
						'per' => q({0} 每升),
					},
				},
				'short' => {
					# Long Unit Identifier
					'1024p1' => {
						'1' => q({0} 千位元組),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q({0} 千位元組),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q({0} 百萬位元組),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q({0} 百萬位元組),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q({0} 吉位元組),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q({0} 吉位元組),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q({0} 兆位元組),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q({0} 兆位元組),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q({0} 拍位元組),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q({0} 拍位元組),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q({0} 艾位元組),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q({0} 艾位元組),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q({0} 皆位元組),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q({0} 皆位元組),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q({0} 佑位元組),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q({0} 佑位元組),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q({0} 分米),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q({0} 分米),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q({0} 厘米),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q({0} 厘米),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q({0} 介米),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q({0} 介米),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q({0} 攸米),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q({0} 攸米),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q({0} 毫米),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q({0} 毫米),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q({0} 納米),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q({0} 納米),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q({0} 澤米),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q({0} 澤米),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q({0} 百萬米),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q({0} 百萬米),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(米每平方秒),
						'other' => q({0} 米每平方秒),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(米每平方秒),
						'other' => q({0} 米每平方秒),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(度),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(度),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(周),
						'other' => q({0} 周),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(周),
						'other' => q({0} 周),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0} 平方厘米),
						'per' => q({0} 每平方厘米),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0} 平方厘米),
						'per' => q({0} 每平方厘米),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(平方呎),
						'other' => q({0} 平方呎),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(平方呎),
						'other' => q({0} 平方呎),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(平方吋),
						'other' => q({0} 平方吋),
						'per' => q({0} 每平方吋),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(平方吋),
						'other' => q({0} 平方吋),
						'per' => q({0} 每平方吋),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'per' => q({0} 每平方公里),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'per' => q({0} 每平方公里),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(平方米),
						'other' => q({0} 平方米),
						'per' => q({0} 每平方米),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(平方米),
						'other' => q({0} 平方米),
						'per' => q({0} 每平方米),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'per' => q({0} 每平方英里),
					},
					# Core Unit Identifier
					'square-mile' => {
						'per' => q({0} 每平方英里),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(毫摩爾/公升),
						'other' => q({0} 毫摩爾/公升),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(毫摩爾/公升),
						'other' => q({0} 毫摩爾/公升),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'other' => q({0} 升每公里),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'other' => q({0} 升每公里),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'other' => q({0} 英里每加侖),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'other' => q({0} 英里每加侖),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} 東),
						'north' => q({0} 北),
						'south' => q({0} 南),
						'west' => q({0} 西),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} 東),
						'north' => q({0} 北),
						'south' => q({0} 南),
						'west' => q({0} 西),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(日),
						'other' => q({0} 日),
						'per' => q({0} 每日),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(日),
						'other' => q({0} 日),
						'per' => q({0} 每日),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} 每小時),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} 每小時),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'per' => q({0} 每分鐘),
					},
					# Core Unit Identifier
					'minute' => {
						'per' => q({0} 每分鐘),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(個月),
						'per' => q({0} 每月),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(個月),
						'per' => q({0} 每月),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(納秒),
						'other' => q({0} 納秒),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(納秒),
						'other' => q({0} 納秒),
					},
					# Long Unit Identifier
					'duration-second' => {
						'per' => q({0}每秒),
					},
					# Core Unit Identifier
					'second' => {
						'per' => q({0}每秒),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(星期),
						'other' => q({0} 星期),
						'per' => q({0} 每週),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(星期),
						'other' => q({0} 星期),
						'per' => q({0} 每週),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} 每年),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} 每年),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'other' => q({0} 焦耳),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0} 焦耳),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(千焦),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(千焦),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(厘米),
						'other' => q({0} 厘米),
						'per' => q({0} 每厘米),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(厘米),
						'other' => q({0} 厘米),
						'per' => q({0} 每厘米),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(分米),
						'other' => q({0} 分米),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(分米),
						'other' => q({0} 分米),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(呎),
						'per' => q({0} 每呎),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(呎),
						'per' => q({0} 每呎),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(吋),
						'per' => q({0} 每吋),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(吋),
						'per' => q({0} 每吋),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'per' => q({0} 每公里),
					},
					# Core Unit Identifier
					'kilometer' => {
						'per' => q({0} 每公里),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(米),
						'other' => q({0} 米),
						'per' => q({0} 每米),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(米),
						'other' => q({0} 米),
						'per' => q({0} 每米),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(哩),
						'other' => q({0} 哩),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(哩),
						'other' => q({0} 哩),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(毫米),
						'other' => q({0} 毫米),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(毫米),
						'other' => q({0} 毫米),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(納米),
						'other' => q({0} 納米),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(納米),
						'other' => q({0} 納米),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(浬),
						'other' => q({0} 浬),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(浬),
						'other' => q({0} 浬),
					},
					# Long Unit Identifier
					'length-point' => {
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(坎德拉),
						'other' => q({0} 坎德拉),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(坎德拉),
						'other' => q({0} 坎德拉),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(格令),
						'other' => q({0} 格令),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(格令),
						'other' => q({0} 格令),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'per' => q({0} 每克),
					},
					# Core Unit Identifier
					'gram' => {
						'per' => q({0} 每克),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'per' => q({0} 每公斤),
					},
					# Core Unit Identifier
					'kilogram' => {
						'per' => q({0} 每公斤),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(安士),
						'other' => q({0} 安士),
						'per' => q({0} 每安士),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(安士),
						'other' => q({0} 安士),
						'per' => q({0} 每安士),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(金衡安士),
						'other' => q({0} 金衡安士),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(金衡安士),
						'other' => q({0} 金衡安士),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q({0} 每磅),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q({0} 每磅),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(兆瓦),
						'other' => q({0} 兆瓦),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(兆瓦),
						'other' => q({0} 兆瓦),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(瓦),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(瓦),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(吋汞柱),
						'other' => q({0} 吋汞柱),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(吋汞柱),
						'other' => q({0} 吋汞柱),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(磅每平方吋),
						'other' => q({0} 磅每平方吋),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(磅每平方吋),
						'other' => q({0} 磅每平方吋),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(蒲福氏風級),
						'other' => q(蒲福氏風級 {0} 級),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(蒲福氏風級),
						'other' => q(蒲福氏風級 {0} 級),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(公里每小時),
						'other' => q({0} 公里每小時),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(公里每小時),
						'other' => q({0} 公里每小時),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(米每秒),
						'other' => q({0} 米/秒),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(米每秒),
						'other' => q({0} 米/秒),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(英里每小時),
						'other' => q({0} 英里每小時),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(英里每小時),
						'other' => q({0} 英里每小時),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(英畝呎),
						'other' => q({0} 英畝呎),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(英畝呎),
						'other' => q({0} 英畝呎),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(厘升),
						'other' => q({0} 厘升),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(厘升),
						'other' => q({0} 厘升),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0} 立方厘米),
						'per' => q({0} 每立方厘米),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0} 立方厘米),
						'per' => q({0} 每立方厘米),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(立方呎),
						'other' => q({0} 立方呎),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(立方呎),
						'other' => q({0} 立方呎),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(立方吋),
						'other' => q({0} 立方吋),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(立方吋),
						'other' => q({0} 立方吋),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0} 立方米),
						'per' => q({0} 每立方米),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0} 立方米),
						'per' => q({0} 每立方米),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} 量杯),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} 量杯),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'other' => q({0} 公制量杯),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'other' => q({0} 公制量杯),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(液安士),
						'other' => q({0} 液安士),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(液安士),
						'other' => q({0} 液安士),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(英制液安士),
						'other' => q({0} 英制液安士),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(英制液安士),
						'other' => q({0} 英制液安士),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0} 每加侖),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0} 每加侖),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(升),
						'per' => q({0} 每升),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(升),
						'per' => q({0} 每升),
					},
				},
			} }
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
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(澳元),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(阿魯巴盾),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(亞塞拜疆馬納特),
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
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(巴巴多斯元),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(比利時法郎（可兌換）),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(布隆迪法郎),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(百慕達元),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(博茨瓦納普拉),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(伯利茲元),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(加拿大元),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(哥斯達黎加科郎),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(佛得角埃斯庫多),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(吉布提法郎),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(多米尼加披索),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(埃塞俄比亞比爾),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(格魯吉亞拉里),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(加納塞地),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(岡比亞達拉西),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(危地馬拉格查爾),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(港元),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(克羅地亞庫納),
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
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(柬埔寨里爾),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(北韓圜),
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
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(老撾基普),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(利比利亞元),
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
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(毛里塔尼亞烏吉亞 \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(毛里塔尼亞烏吉亞),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(毛里裘斯盧布),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(馬爾代夫盧非亞),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(莫桑比克梅蒂卡爾),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(尼日利亞奈拉),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(紐西蘭元),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(阿曼里奧),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(巴布亞新幾內亞基那),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(卡塔爾里亞爾),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(塞爾維亞第納爾),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(盧旺達法郎),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(沙特阿拉伯里亞爾),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(所羅門群島元),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(塞舌爾盧比),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(新加坡元),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(塞拉利昂利昂),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(塞拉利昂利昂 \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(索馬里先令),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(蘇里南元),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(聖多美和普林西比多布拉 \(1977–2017\)),
				'other' => q(聖多美和普林西比多布拉 \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(聖多美和普林西比多布拉),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(敍利亞鎊),
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
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(千里達和多巴哥元),
			},
		},
		'TWD' => {
			symbol => 'NT$',
		},
		'TZS' => {
			display_name => {
				'currency' => q(坦桑尼亞先令),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(瓦努阿圖瓦圖),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(中非法郎),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(東加勒比元),
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
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(也門里雅),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(贊比亞克瓦查),
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
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
				'abbreviated' => {
					'afternoon1' => q{中午},
					'afternoon2' => q{下午},
					'evening1' => q{晚上},
					'midnight' => q{午夜},
					'morning1' => q{早上},
					'morning2' => q{上午},
					'night1' => q{凌晨},
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
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => '公元前',
				'1' => '公元'
			},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gy/M/d},
		},
		'gregorian' => {
			'full' => q{y年M月d日EEEE},
			'long' => q{y年M月d日},
			'medium' => q{y年M月d日},
			'short' => q{d/M/y},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{ah:mm:ss [zzzz]},
			'long' => q{ah:mm:ss [z]},
			'medium' => q{ah:mm:ss},
			'short' => q{ah:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
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
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
		'buddhist' => {
			MEd => q{M-d（E）},
			Md => q{M-d},
		},
		'chinese' => {
			Ed => q{d日E},
			GyMMMM => q{r(U)年MMMM},
			GyMMMMEd => q{r(U)年MMMMd日 E},
			GyMMMMd => q{r(U)年MMMMd日},
			H => q{HH},
			h => q{ah時},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			yyyyMMMMEd => q{r(U)年MMMMd日 E},
			yyyyMMMMd => q{r(U)年MMMMd日},
		},
		'generic' => {
			Ed => q{d日E},
			Ehm => q{E ah:mm},
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
			Ehm => q{E ah:mm},
			Ehms => q{E ah:mm:ss},
			GyMMMEd => q{Gy年M月d日E},
			MEd => q{d/M（E）},
			MMMEd => q{M月d日E},
			MMMMW => q{M月第W週},
			MMdd => q{dd/MM},
			Md => q{d/M},
			h => q{ah時},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			hmsv => q{ah:mm:ss [v]},
			hmv => q{ah:mm [v]},
			yM => q{M/y},
			yMEd => q{d/M/y（E）},
			yMM => q{MM/y},
			yMMMEd => q{y年M月d日E},
			yMd => q{d/M/y},
			yw => q{Y年第w週},
		},
		'japanese' => {
			h => q{ah時},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
		},
		'roc' => {
			MEd => q{d-M（E）},
			Md => q{d-M},
			yyyyMEd => q{Gy/M/dE},
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
		'buddhist' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'chinese' => {
			h => {
				a => q{ah時至ah時},
				h => q{ah時至h時},
			},
			hm => {
				a => q{ah:mm至ah:mm},
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				a => q{ah:mm至ah:mm [v]},
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				a => q{ah時至ah時 [v]},
				h => q{ah時至h時 [v]},
			},
		},
		'coptic' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'dangi' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'ethiopic' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'generic' => {
			MEd => {
				M => q{d/M（E） 至 d/M（E）},
				d => q{d/M（E） 至 d/M（E）},
			},
			Md => {
				M => q{d/M 至 d/M},
				d => q{d/M 至 d/M},
			},
			h => {
				a => q{ah時至ah時},
				h => q{ah時至h時},
			},
			hm => {
				a => q{ah:mm至ah:mm},
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				a => q{ah:mm至ah:mm [v]},
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				a => q{ah時至ah時 [v]},
				h => q{ah時至h時 [v]},
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
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
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
		'hebrew' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'indian' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'islamic' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'japanese' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'persian' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
			},
		},
		'roc' => {
			h => {
				h => q{ah時至h時},
			},
			hm => {
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				h => q{ah時至h時 [v]},
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
			exemplarCity => q#芝娃娃#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#華雷斯城#,
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
			exemplarCity => q#埃里温#,
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
