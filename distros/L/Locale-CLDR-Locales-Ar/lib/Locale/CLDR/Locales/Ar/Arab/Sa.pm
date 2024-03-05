=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ar::Arab::Sa - Package for language Arabic

=cut

package Locale::CLDR::Locales::Ar::Arab::Sa;
# This file auto generated from Data\common\main\ar_SA.xml
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

extends('Locale::CLDR::Locales::Ar::Arab');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar_001' => 'العربية الرسمية الحديثة',
 				'arn' => 'المابودونجونية',
 				'gn' => 'الغورانية',
 				'hsb' => 'صوربيا العليا',
 				'lo' => 'اللاوو',
 				'sh' => 'الكرواتية الصربية',
 				'sma' => 'سامي الجنوبية',
 				'sw' => 'السواحيلية',
 				'sw_CD' => 'السواحيلية الكونغولية',
 				'te' => 'التيلوجو',
 				'ti' => 'التيغرينية',

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
			'AC' => 'جزيرة أسينشين',
 			'CZ@alt=variant' => 'التشيك',
 			'EA' => 'سبتة ومليلية',
 			'MO' => 'ماكاو الصينية (منطقة إدارية خاصة)',
 			'MO@alt=short' => 'ماكاو',
 			'MS' => 'مونتيسيرات',
 			'UY' => 'أوروغواي',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'US' => q{الولايت المتحدة},

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
			numbers => qr{[‎ \- ‑ , . ٪ ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return {};
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
						'few' => q({0} أمتار في الثانية المربعة),
						'many' => q({0} مترًا في الثانية المربعة),
						'one' => q({0} متر في الثانية المربعة),
						'other' => q({0} متر في الثانية المربعة),
						'two' => q(متران في الثانية المربعة),
						'zero' => q({0} متر في الثانية المربعة),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} أمتار في الثانية المربعة),
						'many' => q({0} مترًا في الثانية المربعة),
						'one' => q({0} متر في الثانية المربعة),
						'other' => q({0} متر في الثانية المربعة),
						'two' => q(متران في الثانية المربعة),
						'zero' => q({0} متر في الثانية المربعة),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} سنتيمترات مربعة),
						'many' => q({0} سنتيمترًا مربعًا),
						'one' => q({0} سنتيمتر مربع),
						'other' => q({0} سنتيمتر مربع),
						'two' => q(سنتيمتران مربعان),
						'zero' => q({0} سنتيمتر مربع),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} سنتيمترات مربعة),
						'many' => q({0} سنتيمترًا مربعًا),
						'one' => q({0} سنتيمتر مربع),
						'other' => q({0} سنتيمتر مربع),
						'two' => q(سنتيمتران مربعان),
						'zero' => q({0} سنتيمتر مربع),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} أقدام مربعة),
						'many' => q({0} قدمًا مربعة),
						'one' => q(قدم مربعة),
						'other' => q({0} قدم مربعة),
						'two' => q(قدمان مربعتان),
						'zero' => q({0} قدم مربعة),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} أقدام مربعة),
						'many' => q({0} قدمًا مربعة),
						'one' => q(قدم مربعة),
						'other' => q({0} قدم مربعة),
						'two' => q(قدمان مربعتان),
						'zero' => q({0} قدم مربعة),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} بوصات مربعة),
						'many' => q({0} بوصة مربعة),
						'one' => q({0} بوصة مربعة),
						'other' => q({0} بوصة مربعة),
						'two' => q(بوصتان مربعتان),
						'zero' => q({0} بوصة مربعة),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} بوصات مربعة),
						'many' => q({0} بوصة مربعة),
						'one' => q({0} بوصة مربعة),
						'other' => q({0} بوصة مربعة),
						'two' => q(بوصتان مربعتان),
						'zero' => q({0} بوصة مربعة),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} كيلومترات مربعة),
						'many' => q({0} كيلومترًا مربعًا),
						'one' => q({0} كيلومتر مربع),
						'other' => q({0} كيلومتر مربع),
						'two' => q(كيلومتران مربعان),
						'zero' => q({0} كيلومتر مربع),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} كيلومترات مربعة),
						'many' => q({0} كيلومترًا مربعًا),
						'one' => q({0} كيلومتر مربع),
						'other' => q({0} كيلومتر مربع),
						'two' => q(كيلومتران مربعان),
						'zero' => q({0} كيلومتر مربع),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} أمتار مربعة),
						'many' => q({0} مترًا مربعًا),
						'one' => q({0} متر مربع),
						'other' => q({0} متر مربع),
						'two' => q(متران مربعان),
						'zero' => q({0} متر مربع),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} أمتار مربعة),
						'many' => q({0} مترًا مربعًا),
						'one' => q({0} متر مربع),
						'other' => q({0} متر مربع),
						'two' => q(متران مربعان),
						'zero' => q({0} متر مربع),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} أميال مربعة),
						'many' => q({0} ميلًا مربعًا),
						'one' => q({0} ميل مربع),
						'other' => q({0} ميل مربع),
						'two' => q(ميلان مربعان),
						'zero' => q({0} ميل مربع),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} أميال مربعة),
						'many' => q({0} ميلًا مربعًا),
						'one' => q({0} ميل مربع),
						'other' => q({0} ميل مربع),
						'two' => q(ميلان مربعان),
						'zero' => q({0} ميل مربع),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} ياردات مربعة),
						'many' => q({0} ياردة مربعة),
						'one' => q({0} ياردة مربعة),
						'other' => q({0} ياردة مربعة),
						'two' => q(ياردتان مربعتان),
						'zero' => q({0} ياردة مربعة),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} ياردات مربعة),
						'many' => q({0} ياردة مربعة),
						'one' => q({0} ياردة مربعة),
						'other' => q({0} ياردة مربعة),
						'two' => q(ياردتان مربعتان),
						'zero' => q({0} ياردة مربعة),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} أجزاء في المليون),
						'many' => q({0} جزءًا في المليون),
						'one' => q({0} جزء في المليون),
						'other' => q({0} جزء في المليون),
						'two' => q(جزءان في المليون),
						'zero' => q({0} جزء في المليون),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} أجزاء في المليون),
						'many' => q({0} جزءًا في المليون),
						'one' => q({0} جزء في المليون),
						'other' => q({0} جزء في المليون),
						'two' => q(جزءان في المليون),
						'zero' => q({0} جزء في المليون),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} أميال لكل غالون),
						'many' => q({0} ميلًا لكل غالون),
						'one' => q({0} ميل لكل غالون),
						'other' => q({0} ميل لكل غالون),
						'two' => q({0} ميلان لكل غالون),
						'zero' => q({0} ميل لكل غالون),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} أميال لكل غالون),
						'many' => q({0} ميلًا لكل غالون),
						'one' => q({0} ميل لكل غالون),
						'other' => q({0} ميل لكل غالون),
						'two' => q({0} ميلان لكل غالون),
						'zero' => q({0} ميل لكل غالون),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} ثوانٍ),
						'many' => q({0} ثانية),
						'one' => q(ثانية),
						'other' => q({0} ثانية),
						'two' => q(ثانيتان),
						'zero' => q({0} ثانية),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} ثوانٍ),
						'many' => q({0} ثانية),
						'one' => q(ثانية),
						'other' => q({0} ثانية),
						'two' => q(ثانيتان),
						'zero' => q({0} ثانية),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} وحدات فلكية),
						'many' => q({0} وحدة فلكية),
						'one' => q(وحدة فلكية),
						'other' => q({0} وحدة فلكية),
						'two' => q(وحدتان فلكيتان),
						'zero' => q({0} وحدة فلكية),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} وحدات فلكية),
						'many' => q({0} وحدة فلكية),
						'one' => q(وحدة فلكية),
						'other' => q({0} وحدة فلكية),
						'two' => q(وحدتان فلكيتان),
						'zero' => q({0} وحدة فلكية),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} سنتيمترات),
						'many' => q({0} سنتيمترًا),
						'one' => q({0} سنتيمتر),
						'other' => q({0} سنتيمتر),
						'two' => q(سنتيمتران),
						'zero' => q({0} سنتيمتر),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} سنتيمترات),
						'many' => q({0} سنتيمترًا),
						'one' => q({0} سنتيمتر),
						'other' => q({0} سنتيمتر),
						'two' => q(سنتيمتران),
						'zero' => q({0} سنتيمتر),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} كيلومترات),
						'many' => q({0} كيلومترًا),
						'one' => q({0} كيلومتر),
						'other' => q({0} كيلومتر),
						'two' => q(كيلومتران),
						'zero' => q({0} كيلومتر),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} كيلومترات),
						'many' => q({0} كيلومترًا),
						'one' => q({0} كيلومتر),
						'other' => q({0} كيلومتر),
						'two' => q(كيلومتران),
						'zero' => q({0} كيلومتر),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} أمتار),
						'many' => q({0} مترًا),
						'one' => q(متر),
						'other' => q({0} متر),
						'two' => q(متران),
						'zero' => q({0} متر),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} أمتار),
						'many' => q({0} مترًا),
						'one' => q(متر),
						'other' => q({0} متر),
						'two' => q(متران),
						'zero' => q({0} متر),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} مليمتر),
						'many' => q({0} مليمترًا),
						'one' => q({0} مليمتر),
						'other' => q({0} مليمتر),
						'two' => q(مليمتران),
						'zero' => q({0} مليمتر),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} مليمتر),
						'many' => q({0} مليمترًا),
						'one' => q({0} مليمتر),
						'other' => q({0} مليمتر),
						'two' => q(مليمتران),
						'zero' => q({0} مليمتر),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} كيلوغرامات),
						'many' => q({0} كيلوغرامًا),
						'one' => q({0} كيلوغرام),
						'other' => q({0} كيلوغرام),
						'two' => q(كيلوغرامان),
						'zero' => q({0} كيلوغرام),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} كيلوغرامات),
						'many' => q({0} كيلوغرامًا),
						'one' => q({0} كيلوغرام),
						'other' => q({0} كيلوغرام),
						'two' => q(كيلوغرامان),
						'zero' => q({0} كيلوغرام),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} ميكروغرامات),
						'many' => q({0} ميكروغرامًا),
						'one' => q({0} ميكروغرام),
						'other' => q({0} ميكروغرام),
						'two' => q(ميكروغرامان),
						'zero' => q({0} ميكروغرام),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} ميكروغرامات),
						'many' => q({0} ميكروغرامًا),
						'one' => q({0} ميكروغرام),
						'other' => q({0} ميكروغرام),
						'two' => q(ميكروغرامان),
						'zero' => q({0} ميكروغرام),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} مليغرامات),
						'many' => q({0} مليغرامًا),
						'one' => q({0} مليغرام),
						'other' => q({0} مليغرام),
						'two' => q(مليغرامان),
						'zero' => q({0} مليغرام),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} مليغرامات),
						'many' => q({0} مليغرامًا),
						'one' => q({0} مليغرام),
						'other' => q({0} مليغرام),
						'two' => q(مليغرامان),
						'zero' => q({0} مليغرام),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0} أطنان مترية),
						'many' => q({0} طنًا متريًا),
						'one' => q({0} طن متري),
						'other' => q({0} طن متري),
						'two' => q(طنان متريان),
						'zero' => q({0} طن متري),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0} أطنان مترية),
						'many' => q({0} طنًا متريًا),
						'one' => q({0} طن متري),
						'other' => q({0} طن متري),
						'two' => q(طنان متريان),
						'zero' => q({0} طن متري),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} أرطال لكل بوصة مربعة),
						'many' => q({0} رطلًا لكل بوصة مربعة),
						'one' => q({0} رطل لكل بوصة مربعة),
						'other' => q({0} رطل لكل بوصة مربعة),
						'two' => q(رطلان لكل بوصة مربعة),
						'zero' => q({0} رطل لكل بوصة مربعة),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} أرطال لكل بوصة مربعة),
						'many' => q({0} رطلًا لكل بوصة مربعة),
						'one' => q({0} رطل لكل بوصة مربعة),
						'other' => q({0} رطل لكل بوصة مربعة),
						'two' => q(رطلان لكل بوصة مربعة),
						'zero' => q({0} رطل لكل بوصة مربعة),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} كيلومترات في الساعة),
						'many' => q({0} كيلومترًا في الساعة),
						'one' => q({0} كيلومتر في الساعة),
						'other' => q({0} كيلومتر في الساعة),
						'two' => q(كيلومتران في الساعة),
						'zero' => q({0} كيلومتر في الساعة),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} كيلومترات في الساعة),
						'many' => q({0} كيلومترًا في الساعة),
						'one' => q({0} كيلومتر في الساعة),
						'other' => q({0} كيلومتر في الساعة),
						'two' => q(كيلومتران في الساعة),
						'zero' => q({0} كيلومتر في الساعة),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} أمتار في الثانية),
						'many' => q({0} مترًا في الثانية),
						'one' => q({0} متر في الثانية),
						'other' => q({0} متر في الثانية),
						'two' => q(متران في الثانية),
						'zero' => q({0} متر في الثانية),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} أمتار في الثانية),
						'many' => q({0} مترًا في الثانية),
						'one' => q({0} متر في الثانية),
						'other' => q({0} متر في الثانية),
						'two' => q(متران في الثانية),
						'zero' => q({0} متر في الثانية),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} أميال في الساعة),
						'many' => q({0} ميلًا في الساعة),
						'one' => q({0} ميل في الساعة),
						'other' => q({0} ميل في الساعة),
						'two' => q(ميلان في الساعة),
						'zero' => q({0} ميل في الساعة),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} أميال في الساعة),
						'many' => q({0} ميلًا في الساعة),
						'one' => q({0} ميل في الساعة),
						'other' => q({0} ميل في الساعة),
						'two' => q(ميلان في الساعة),
						'zero' => q({0} ميل في الساعة),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} سنتيمترات مكعبة),
						'many' => q({0} سنتيمترًا مكعبًا),
						'one' => q({0} سنتيمتر مكعب),
						'other' => q({0} سنتيمتر مكعب),
						'two' => q(سنتيمتران مكعبان),
						'zero' => q({0} سنتيمتر مكعب),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} سنتيمترات مكعبة),
						'many' => q({0} سنتيمترًا مكعبًا),
						'one' => q({0} سنتيمتر مكعب),
						'other' => q({0} سنتيمتر مكعب),
						'two' => q(سنتيمتران مكعبان),
						'zero' => q({0} سنتيمتر مكعب),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} أقدام مكعبة),
						'many' => q({0} أقدام مكعبة),
						'one' => q(قدم مكعبة),
						'other' => q({0} قدم مكعبة),
						'two' => q(قدمان مكعبتان),
						'zero' => q({0} قدم مكعبة),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} أقدام مكعبة),
						'many' => q({0} أقدام مكعبة),
						'one' => q(قدم مكعبة),
						'other' => q({0} قدم مكعبة),
						'two' => q(قدمان مكعبتان),
						'zero' => q({0} قدم مكعبة),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} بوصات مكعبة),
						'many' => q({0} بوصة³),
						'one' => q({0} بوصة³),
						'other' => q({0} بوصة³),
						'two' => q(بوصتان مكعبات),
						'zero' => q({0} بوصة³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} بوصات مكعبة),
						'many' => q({0} بوصة³),
						'one' => q({0} بوصة³),
						'other' => q({0} بوصة³),
						'two' => q(بوصتان مكعبات),
						'zero' => q({0} بوصة³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} كيلومترات مكعبة),
						'many' => q({0} كيلومترًا مكعبًا),
						'one' => q({0} كيلومتر مكعب),
						'other' => q({0} كيلومتر مكعب),
						'two' => q(كيلومتران مكعبان),
						'zero' => q({0} كيلومتر مكعب),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} كيلومترات مكعبة),
						'many' => q({0} كيلومترًا مكعبًا),
						'one' => q({0} كيلومتر مكعب),
						'other' => q({0} كيلومتر مكعب),
						'two' => q(كيلومتران مكعبان),
						'zero' => q({0} كيلومتر مكعب),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} مترات مكعبة),
						'many' => q({0} مترًا مكعبًا),
						'one' => q({0} متر مكعب),
						'other' => q({0} متر مكعب),
						'two' => q(متران مكعبان),
						'zero' => q({0} متر مكعب),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} مترات مكعبة),
						'many' => q({0} مترًا مكعبًا),
						'one' => q({0} متر مكعب),
						'other' => q({0} متر مكعب),
						'two' => q(متران مكعبان),
						'zero' => q({0} متر مكعب),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} أميال مكعبة),
						'many' => q({0} ميلًا مكعبًا),
						'one' => q({0} ميل مكعب),
						'other' => q({0} ميل مكعب),
						'two' => q(ميلان مكعبان),
						'zero' => q({0} ميل مكعب),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} أميال مكعبة),
						'many' => q({0} ميلًا مكعبًا),
						'one' => q({0} ميل مكعب),
						'other' => q({0} ميل مكعب),
						'two' => q(ميلان مكعبان),
						'zero' => q({0} ميل مكعب),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} ياردات مكعبة),
						'many' => q({0} ياردة مكعبة),
						'one' => q({0} ياردة مكعبة),
						'other' => q({0} ياردة مكعبة),
						'two' => q(ياردتان مكعبتان),
						'zero' => q({0} ياردة مكعبة),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} ياردات مكعبة),
						'many' => q({0} ياردة مكعبة),
						'one' => q({0} ياردة مكعبة),
						'other' => q({0} ياردة مكعبة),
						'two' => q(ياردتان مكعبتان),
						'zero' => q({0} ياردة مكعبة),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} ملاعق كبيرة),
						'many' => q({0} ملعقة كبيرة),
						'one' => q(ملعقة كبيرة),
						'other' => q({0} ملعقة كبيرة),
						'two' => q(ملعقتان كبيرتان),
						'zero' => q({0} ملعقة كبيرة),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} ملاعق كبيرة),
						'many' => q({0} ملعقة كبيرة),
						'one' => q(ملعقة كبيرة),
						'other' => q({0} ملعقة كبيرة),
						'two' => q(ملعقتان كبيرتان),
						'zero' => q({0} ملعقة كبيرة),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} ملاعق صغيرة),
						'many' => q({0} ملعقة صغيرة),
						'one' => q(ملعقة صغيرة),
						'other' => q({0} ملعقة صغيرة),
						'two' => q(ملعقتان صغيرتان),
						'zero' => q({0} ملعقة صغيرة),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} ملاعق صغيرة),
						'many' => q({0} ملعقة صغيرة),
						'one' => q(ملعقة صغيرة),
						'other' => q({0} ملعقة صغيرة),
						'two' => q(ملعقتان صغيرتان),
						'zero' => q({0} ملعقة صغيرة),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} سنوات),
						'many' => q({0} سنة),
						'one' => q(سنة),
						'other' => q({0} سنة),
						'two' => q(سنتان),
						'zero' => q({0} سنة),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} سنوات),
						'many' => q({0} سنة),
						'one' => q(سنة),
						'other' => q({0} سنة),
						'two' => q(سنتان),
						'zero' => q({0} سنة),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(متر),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(متر),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} غم),
						'many' => q({0} غم),
						'name' => q(غم),
						'one' => q({0} غم),
						'other' => q({0} غم),
						'two' => q({0} غم),
						'zero' => q({0} غم),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} غم),
						'many' => q({0} غم),
						'name' => q(غم),
						'one' => q({0} غم),
						'other' => q({0} غم),
						'two' => q({0} غم),
						'zero' => q({0} غم),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} كغم),
						'many' => q({0} كغم),
						'name' => q(كغم),
						'one' => q({0} كغم),
						'other' => q({0} كغم),
						'two' => q({0} كغم),
						'zero' => q({0} كغم),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} كغم),
						'many' => q({0} كغم),
						'name' => q(كغم),
						'one' => q({0} كغم),
						'other' => q({0} كغم),
						'two' => q({0} كغم),
						'zero' => q({0} كغم),
					},
				},
				'short' => {
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} دورات),
						'many' => q({0} دورة),
						'one' => q(دورة),
						'other' => q({0} دورة),
						'two' => q(دورتان),
						'zero' => q({0} دورة),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} دورات),
						'many' => q({0} دورة),
						'one' => q(دورة),
						'other' => q({0} دورة),
						'two' => q(دورتان),
						'zero' => q({0} دورة),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} أفدنة),
						'many' => q({0} فدانًا),
						'one' => q(فدان),
						'other' => q({0} فدان),
						'two' => q(فدانان),
						'zero' => q({0} فدان),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} أفدنة),
						'many' => q({0} فدانًا),
						'one' => q(فدان),
						'other' => q({0} فدان),
						'two' => q(فدانان),
						'zero' => q({0} فدان),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} هكتارات),
						'many' => q({0} هكتارًا),
						'one' => q({0} هكتار),
						'other' => q({0} هكتار),
						'two' => q(هكتاران),
						'zero' => q({0} هكتار),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} هكتارات),
						'many' => q({0} هكتارًا),
						'one' => q({0} هكتار),
						'other' => q({0} هكتار),
						'two' => q(هكتاران),
						'zero' => q({0} هكتار),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} قراريط),
						'many' => q({0} قيراطًا),
						'one' => q(قيراط),
						'other' => q({0} قيراط),
						'two' => q(قيراطان),
						'zero' => q({0} قيراط),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} قراريط),
						'many' => q({0} قيراطًا),
						'one' => q(قيراط),
						'other' => q({0} قيراط),
						'two' => q(قيراطان),
						'zero' => q({0} قيراط),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} أجزاء/مليون),
						'many' => q({0} جزءًا/مليون),
						'one' => q({0} جزء/مليون),
						'other' => q({0} جزء/مليون),
						'two' => q(جزءان/مليون),
						'zero' => q({0} جزء/مليون),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} أجزاء/مليون),
						'many' => q({0} جزءًا/مليون),
						'one' => q({0} جزء/مليون),
						'other' => q({0} جزء/مليون),
						'two' => q(جزءان/مليون),
						'zero' => q({0} جزء/مليون),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} لترات/١٠٠ كم),
						'many' => q({0} لترًا/١٠٠ كم),
						'one' => q({0} لتر/١٠٠ كم),
						'other' => q({0} لتر/١٠٠ كم),
						'two' => q(لتران/١٠٠ كم),
						'zero' => q({0} لتر/١٠٠ كم),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} لترات/١٠٠ كم),
						'many' => q({0} لترًا/١٠٠ كم),
						'one' => q({0} لتر/١٠٠ كم),
						'other' => q({0} لتر/١٠٠ كم),
						'two' => q(لتران/١٠٠ كم),
						'zero' => q({0} لتر/١٠٠ كم),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} لترات/كم),
						'many' => q({0} لترًا/كم),
						'one' => q({0} لتر/كم),
						'other' => q({0} لتر/كم),
						'two' => q(لتران/كم),
						'zero' => q({0} لتر/كم),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} لترات/كم),
						'many' => q({0} لترًا/كم),
						'one' => q({0} لتر/كم),
						'other' => q({0} لتر/كم),
						'two' => q(لتران/كم),
						'zero' => q({0} لتر/كم),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} أميال/غالون),
						'many' => q({0} ميلًا/غالون),
						'one' => q({0} ميل/غالون),
						'other' => q({0} ميل/غالون),
						'two' => q(ميلان/غالون),
						'zero' => q({0} ميل/غالون),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} أميال/غالون),
						'many' => q({0} ميلًا/غالون),
						'one' => q({0} ميل/غالون),
						'other' => q({0} ميل/غالون),
						'two' => q(ميلان/غالون),
						'zero' => q({0} ميل/غالون),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} أميال/غ. إمبراطوري),
						'many' => q({0} ميلًا/غ. إمبراطوري),
						'one' => q({0} ميل/غ. إمبراطوري),
						'other' => q({0} ميل/غ. إمبراطوري),
						'two' => q(ميلان/غ. إمبراطوري),
						'zero' => q({0} ميل/غ. إمبراطوري),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} أميال/غ. إمبراطوري),
						'many' => q({0} ميلًا/غ. إمبراطوري),
						'one' => q({0} ميل/غ. إمبراطوري),
						'other' => q({0} ميل/غ. إمبراطوري),
						'two' => q(ميلان/غ. إمبراطوري),
						'zero' => q({0} ميل/غ. إمبراطوري),
					},
					# Long Unit Identifier
					'coordinate' => {
						'south' => q({0} جنوب),
						'west' => q({0} غرب),
					},
					# Core Unit Identifier
					'coordinate' => {
						'south' => q({0} جنوب),
						'west' => q({0} غرب),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} سنوات),
						'many' => q({0} سنة),
						'name' => q(سنوات),
						'one' => q(سنة),
						'other' => q({0} سنة),
						'two' => q(سنتان),
						'zero' => q({0} سنة),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} سنوات),
						'many' => q({0} سنة),
						'name' => q(سنوات),
						'one' => q(سنة),
						'other' => q({0} سنة),
						'two' => q(سنتان),
						'zero' => q({0} سنة),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} أقدام),
						'many' => q({0} قدمًا),
						'one' => q(قدم),
						'other' => q({0} قدم),
						'two' => q(قدمان),
						'zero' => q({0} قدم),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} أقدام),
						'many' => q({0} قدمًا),
						'one' => q(قدم),
						'other' => q({0} قدم),
						'two' => q(قدمان),
						'zero' => q({0} قدم),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} بوصات),
						'many' => q({0} بوصة),
						'one' => q({0} بوصة),
						'other' => q({0} بوصة),
						'two' => q(بوصتان),
						'zero' => q({0} بوصة),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} بوصات),
						'many' => q({0} بوصة),
						'one' => q({0} بوصة),
						'other' => q({0} بوصة),
						'two' => q(بوصتان),
						'zero' => q({0} بوصة),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} أميال),
						'many' => q({0} ميل),
						'one' => q(ميل),
						'other' => q({0} ميل),
						'two' => q(ميلان),
						'zero' => q({0} ميل),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} أميال),
						'many' => q({0} ميل),
						'one' => q(ميل),
						'other' => q({0} ميل),
						'two' => q(ميلان),
						'zero' => q({0} ميل),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} أميال اسكندنافية),
						'many' => q({0} ميلًا اسكندنافيًا),
						'one' => q({0} ميل اسكندنافي),
						'other' => q({0} ميل اسكندنافي),
						'two' => q(ميلان اسكندنافيان),
						'zero' => q({0} ميل اسكندنافي),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} أميال اسكندنافية),
						'many' => q({0} ميلًا اسكندنافيًا),
						'one' => q({0} ميل اسكندنافي),
						'other' => q({0} ميل اسكندنافي),
						'two' => q(ميلان اسكندنافيان),
						'zero' => q({0} ميل اسكندنافي),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} أميال بحرية),
						'many' => q({0} ميلًا بحريًا),
						'one' => q(ميل بحري),
						'other' => q({0} ميل بحري),
						'two' => q(ميلان بحريان),
						'zero' => q({0} ميل بحري),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} أميال بحرية),
						'many' => q({0} ميلًا بحريًا),
						'one' => q(ميل بحري),
						'other' => q({0} ميل بحري),
						'two' => q(ميلان بحريان),
						'zero' => q({0} ميل بحري),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} فراسخ فلكية),
						'many' => q({0} فرسخًا فلكيًا),
						'one' => q(فرسخ فلكي),
						'other' => q({0} فرسخ فلكي),
						'two' => q(فرسخان فلكيان),
						'zero' => q({0} فرسخ فلكي),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} فراسخ فلكية),
						'many' => q({0} فرسخًا فلكيًا),
						'one' => q(فرسخ فلكي),
						'other' => q({0} فرسخ فلكي),
						'two' => q(فرسخان فلكيان),
						'zero' => q({0} فرسخ فلكي),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} ياردات),
						'many' => q({0} ياردة),
						'one' => q(ياردة),
						'other' => q({0} ياردة),
						'two' => q(ياردتان),
						'zero' => q({0} ياردة),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} ياردات),
						'many' => q({0} ياردة),
						'one' => q(ياردة),
						'other' => q({0} ياردة),
						'two' => q(ياردتان),
						'zero' => q({0} ياردة),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} ضياءات شمسية),
						'many' => q({0} ضياءً شمسيًا),
						'one' => q({0} ضياء شمسي),
						'other' => q({0} ضياء شمسي),
						'two' => q(ضياءان شمسيان),
						'zero' => q({0} ضياء شمسي),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} ضياءات شمسية),
						'many' => q({0} ضياءً شمسيًا),
						'one' => q({0} ضياء شمسي),
						'other' => q({0} ضياء شمسي),
						'two' => q(ضياءان شمسيان),
						'zero' => q({0} ضياء شمسي),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} قراريط),
						'many' => q({0} قيراطًا),
						'one' => q({0} قيراط),
						'other' => q({0} قيراط),
						'two' => q(قيراطان),
						'zero' => q({0} قيراط),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} قراريط),
						'many' => q({0} قيراطًا),
						'one' => q({0} قيراط),
						'other' => q({0} قيراط),
						'two' => q(قيراطان),
						'zero' => q({0} قيراط),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} كتل أرضية),
						'many' => q({0} كتلة أرضية),
						'one' => q({0} كتلة أرضية),
						'other' => q({0} كتلة أرضية),
						'two' => q(كتلتان أرضيتان),
						'zero' => q({0} كتلة أرضية),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} كتل أرضية),
						'many' => q({0} كتلة أرضية),
						'one' => q({0} كتلة أرضية),
						'other' => q({0} كتلة أرضية),
						'two' => q(كتلتان أرضيتان),
						'zero' => q({0} كتلة أرضية),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} غرامات),
						'many' => q({0} غرامًا),
						'one' => q(غرام),
						'other' => q({0} غرام),
						'two' => q(غرامان),
						'zero' => q({0} غرام),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} غرامات),
						'many' => q({0} غرامًا),
						'one' => q(غرام),
						'other' => q({0} غرام),
						'two' => q(غرامان),
						'zero' => q({0} غرام),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} أرطال),
						'many' => q({0} رطلُا),
						'one' => q({0} رطل),
						'other' => q({0} رطل),
						'two' => q(رطلان),
						'zero' => q({0} رطل),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} أرطال),
						'many' => q({0} رطلُا),
						'one' => q({0} رطل),
						'other' => q({0} رطل),
						'two' => q(رطلان),
						'zero' => q({0} رطل),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} كتل شمسية),
						'many' => q({0} كتلة شمسية),
						'one' => q({0} كتلة شمسية),
						'other' => q({0} كتلة شمسية),
						'two' => q(كتلتان شمسيتان),
						'zero' => q({0} كتلة شمسية),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} كتل شمسية),
						'many' => q({0} كتلة شمسية),
						'one' => q({0} كتلة شمسية),
						'other' => q({0} كتلة شمسية),
						'two' => q(كتلتان شمسيتان),
						'zero' => q({0} كتلة شمسية),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} أطنان),
						'many' => q({0} طنًا),
						'one' => q({0} طن),
						'other' => q({0} طن),
						'two' => q(طنان),
						'zero' => q({0} طن),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} أطنان),
						'many' => q({0} طنًا),
						'one' => q({0} طن),
						'other' => q({0} طن),
						'two' => q(طنان),
						'zero' => q({0} طن),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} كيلوباسكال),
						'many' => q({0} كيلوباسكال),
						'name' => q(كيلوباسكال),
						'one' => q({0} كيلوباسكال),
						'other' => q({0} كيلوباسكال),
						'two' => q({0} كيلوباسكال),
						'zero' => q({0} كيلوباسكال),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} كيلوباسكال),
						'many' => q({0} كيلوباسكال),
						'name' => q(كيلوباسكال),
						'one' => q({0} كيلوباسكال),
						'other' => q({0} كيلوباسكال),
						'two' => q({0} كيلوباسكال),
						'zero' => q({0} كيلوباسكال),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} ميغاباسكال),
						'many' => q({0} ميغاباسكال),
						'name' => q(ميغاباسكال),
						'one' => q({0} ميغاباسكال),
						'other' => q({0} ميغاباسكال),
						'two' => q({0} ميغاباسكال),
						'zero' => q({0} ميغاباسكال),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} ميغاباسكال),
						'many' => q({0} ميغاباسكال),
						'name' => q(ميغاباسكال),
						'one' => q({0} ميغاباسكال),
						'other' => q({0} ميغاباسكال),
						'two' => q({0} ميغاباسكال),
						'zero' => q({0} ميغاباسكال),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} أرطال/بوصة²),
						'many' => q({0} رطلًا/بوصة²),
						'one' => q({0} رطل/بوصة²),
						'other' => q({0} رطل/بوصة²),
						'two' => q(رطلان/بوصة²),
						'zero' => q({0} رطل/بوصة²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} أرطال/بوصة²),
						'many' => q({0} رطلًا/بوصة²),
						'one' => q({0} رطل/بوصة²),
						'other' => q({0} رطل/بوصة²),
						'two' => q(رطلان/بوصة²),
						'zero' => q({0} رطل/بوصة²),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} عقد),
						'many' => q({0} عقدة),
						'one' => q({0} عقدة),
						'other' => q({0} عقدة),
						'two' => q(عقدتان),
						'zero' => q({0} عقدة),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} عقد),
						'many' => q({0} عقدة),
						'one' => q({0} عقدة),
						'other' => q({0} عقدة),
						'two' => q(عقدتان),
						'zero' => q({0} عقدة),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} أميال/س),
						'many' => q({0} ميلًا/س),
						'one' => q({0} ميل/س),
						'other' => q({0} ميل/س),
						'two' => q(ميلان/س),
						'zero' => q({0} ميل/س),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} أميال/س),
						'many' => q({0} ميلًا/س),
						'one' => q({0} ميل/س),
						'other' => q({0} ميل/س),
						'two' => q(ميلان/س),
						'zero' => q({0} ميل/س),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} درجة كلفن),
						'many' => q({0} درجة كلفن),
						'name' => q(درجة كلفن),
						'one' => q({0} درجة كلفن),
						'other' => q({0} درجة كلفن),
						'two' => q({0} درجة كلفن),
						'zero' => q({0} درجة كلفن),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} درجة كلفن),
						'many' => q({0} درجة كلفن),
						'name' => q(درجة كلفن),
						'one' => q({0} درجة كلفن),
						'other' => q({0} درجة كلفن),
						'two' => q({0} درجة كلفن),
						'zero' => q({0} درجة كلفن),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} بوصة³),
						'many' => q({0} بوصة³),
						'one' => q({0} بوصة³),
						'other' => q({0} بوصة³),
						'two' => q({0} بوصة³),
						'zero' => q({0} بوصة³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} بوصة³),
						'many' => q({0} بوصة³),
						'one' => q({0} بوصة³),
						'other' => q({0} بوصة³),
						'two' => q({0} بوصة³),
						'zero' => q({0} بوصة³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} أكواب),
						'many' => q({0} كوبًا),
						'one' => q(كوب),
						'other' => q({0} كوب),
						'two' => q(كوبان),
						'zero' => q({0} كوب),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} أكواب),
						'many' => q({0} كوبًا),
						'one' => q(كوب),
						'other' => q({0} كوب),
						'two' => q(كوبان),
						'zero' => q({0} كوب),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} أكواب مترية),
						'many' => q({0} كوبًا متريًا),
						'one' => q({0} كوب متري),
						'other' => q({0} كوب متري),
						'two' => q(كوبان متريان),
						'zero' => q({0} كوب متري),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} أكواب مترية),
						'many' => q({0} كوبًا متريًا),
						'one' => q({0} كوب متري),
						'other' => q({0} كوب متري),
						'two' => q(كوبان متريان),
						'zero' => q({0} كوب متري),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} أونصات سائلة),
						'many' => q({0} أونصة س),
						'one' => q(أونصة س),
						'other' => q({0} أونصة سائلة),
						'two' => q(أونصتان سائلتان),
						'zero' => q({0} أونصة سائلة),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} أونصات سائلة),
						'many' => q({0} أونصة س),
						'one' => q(أونصة س),
						'other' => q({0} أونصة سائلة),
						'two' => q(أونصتان سائلتان),
						'zero' => q({0} أونصة سائلة),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} لترات),
						'many' => q({0} لترًا),
						'one' => q(لتر),
						'other' => q({0} لتر),
						'two' => q(لتران),
						'zero' => q({0} لتر),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} لترات),
						'many' => q({0} لترًا),
						'one' => q(لتر),
						'other' => q({0} لتر),
						'two' => q(لتران),
						'zero' => q({0} لتر),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} مكاييل مترية),
						'many' => q({0} مكيالًا متريًا),
						'one' => q({0} مكيال متري),
						'other' => q({0} مكيال متري),
						'two' => q(مكيالان متريان),
						'zero' => q({0} مكيال متري),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} مكاييل مترية),
						'many' => q({0} مكيالًا متريًا),
						'one' => q({0} مكيال متري),
						'other' => q({0} مكيال متري),
						'two' => q(مكيالان متريان),
						'zero' => q({0} مكيال متري),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} ملاعق ك.),
						'many' => q({0} ملعقة ك.),
						'one' => q(ملعقة ك.),
						'other' => q({0} ملعقة ك.),
						'two' => q({0} ملعقتان ك.),
						'zero' => q({0} ملعقة ك.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} ملاعق ك.),
						'many' => q({0} ملعقة ك.),
						'one' => q(ملعقة ك.),
						'other' => q({0} ملعقة ك.),
						'two' => q({0} ملعقتان ك.),
						'zero' => q({0} ملعقة ك.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} ملاعق ص),
						'many' => q({0} ملعقة ص),
						'one' => q(ملعقة ص),
						'other' => q({0} ملعقة ص),
						'two' => q({0} ملعقتان ص),
						'zero' => q({0} ملعقة ص),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} ملاعق ص),
						'many' => q({0} ملعقة ص),
						'one' => q(ملعقة ص),
						'other' => q({0} ملعقة ص),
						'two' => q({0} ملعقتان ص),
						'zero' => q({0} ملعقة ص),
					},
				},
			} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arab',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'percentSign' => q(٪),
		},
	} }
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
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
					'afternoon1' => q{ظهرًا},
					'afternoon2' => q{بعد الظهر},
					'evening1' => q{مساءً},
					'morning1' => q{فجرًا},
					'morning2' => q{ص},
					'night1' => q{في المساء},
					'night2' => q{ل},
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
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
