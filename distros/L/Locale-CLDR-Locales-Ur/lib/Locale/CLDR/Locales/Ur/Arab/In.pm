=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ur::Arab::In - Package for language Urdu

=cut

package Locale::CLDR::Locales::Ur::Arab::In;
# This file auto generated from Data\common\main\ur_IN.xml
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

extends('Locale::CLDR::Locales::Ur::Arab');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar_001' => 'جدید معیاری عربی',
 				'awa' => 'اودھی',
 				'ckb' => 'سورانی کردی',
 				'ckb@alt=variant' => 'سورانی کردی',
 				'dje' => 'زرمہ',
 				'hr' => 'کروشین',
 				'jv' => 'جاوانیز',
 				'ka' => 'جارجيائى',
 				'kl' => 'کلالیسٹ',
 				'kn' => 'کنڑ',
 				'ku' => 'کرد',
 				'mag' => 'مگہی',
 				'zgh' => 'معیاری مراقشی تمازیقی',
 				'zh_Hans' => 'آسان چینی',

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
			'AC' => 'جزیرہ اسینشن',
 			'AX' => 'جزائر آلینڈ',
 			'BV' => 'جزیرہ بوویت',
 			'CC' => 'جزائر (کیلنگ) کوکوس',
 			'CK' => 'جزائر کک',
 			'CP' => 'جزیرہ کلپرٹن',
 			'DG' => 'ڈیگو گارشیا',
 			'FK' => 'جزائر فاکلینڈ',
 			'FK@alt=variant' => 'جزائر فاکلینڈ (اسلاس مالویناس)',
 			'FO' => 'جزائر فیرو',
 			'GF' => 'فرانسیسی گیانا',
 			'HM' => 'جزائر ہرڈ و مکڈونلڈ',
 			'IC' => 'جزائر کناری',
 			'IO' => 'برطانوی بحرہند خطہ',
 			'MH' => 'جزائر مارشل',
 			'MP' => 'جزائر شمالی ماریانا',
 			'NF' => 'جزیرہ نارفوک',
 			'PN' => 'جزائر پٹکیرن',
 			'SB' => 'جزائر سلیمان',
 			'TA' => 'ترسٹان دا کونیا',
 			'TC' => 'جزائر کیکس و ترکیہ',
 			'UM' => 'امریکی بیرونی جزائر',
 			'VG' => 'برطانوی جزائر ورجن',
 			'VI' => 'امریکی جزائر ورجن',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'numbers' => {
 				'armnlow' => q{آرمینیائی لوئر کیس اعداد},
 				'greklow' => q{یونانی لوئر کیس اعداد},
 				'tibt' => q{تبتی ہندسے},
 			},

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(فلکیاتی اکائیاں),
						'one' => q({0} فلکیاتی اکائی),
						'other' => q({0} فلکیاتی اکائیاں),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(فلکیاتی اکائیاں),
						'one' => q({0} فلکیاتی اکائی),
						'other' => q({0} فلکیاتی اکائیاں),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:نہیں|نہ|no|n)$' }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arabext',
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arabext' => {
			'pattern' => {
				'default' => {
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
		'CRC' => {
			display_name => {
				'currency' => q(کوسٹا ریکا کولون),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(قابل منتقلی کیوبائی پیسو),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(کیوبائی پیسو),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(کیپ ورڈی اسکیوڈو),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(برطانوی پاونڈ سٹرلنگ),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(گھانی سیڈی),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'one' => q(پاکستانی روپیہ),
				'other' => q(پاکستانی روپے),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(ساموآئی ٹالا),
			},
		},
	} },
);


has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(GMT{0}),
		regionFormat => q({0} دن کا وقت),
		'Afghanistan' => {
			long => {
				'standard' => q#افغانستان ٹائم#,
			},
		},
		'Africa/Accra' => {
			exemplarCity => q#اکرا#,
		},
		'Amazon' => {
			long => {
				'daylight' => q#ایمیزون سمر ٹائم#,
				'generic' => q#ایمیزون ٹائم#,
				'standard' => q#ایمیزون سٹینڈرڈ ٹائم#,
			},
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#کیمبرج بے#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#گلیس بے#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#گوس بے#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#گرینڈ ترک#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#اتتوققورتورمیت#,
		},
		'America/Thule' => {
			exemplarCity => q#تھولے#,
		},
		'Arabian' => {
			long => {
				'daylight' => q#عرب ڈے لائٹ ٹائم#,
				'generic' => q#عرب ٹائم#,
				'standard' => q#عرب سٹینڈرڈ ٹائم#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#مغربی ارجنٹینا سمر ٹائم#,
				'generic' => q#مغربی ارجنٹینا ٹائم#,
				'standard' => q#مغربی ارجنٹینا سٹینڈرڈ ٹائم#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#آرمینیا سمر ٹائم#,
				'generic' => q#آرمینیا ٹائم#,
				'standard' => q#آرمینیا سٹینڈرڈ ٹائم#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#آذربائیجان سمر ٹائم#,
				'generic' => q#آذربائیجان ٹائم#,
				'standard' => q#آذربائیجان سٹینڈرڈ ٹائم#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#بنگلہ دیش سمر ٹائم#,
				'generic' => q#بنگلہ دیش ٹائم#,
				'standard' => q#بنگلہ دیش سٹینڈرڈ ٹائم#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#بھوٹان ٹائم#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#بولیویا ٹائم#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#برازیلیا سمر ٹائم#,
				'generic' => q#برازیلیا ٹائم#,
				'standard' => q#برازیلیا سٹینڈرڈ ٹائم#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#چلی سمر ٹائم#,
				'generic' => q#چلی ٹائم#,
				'standard' => q#چلی سٹینڈرڈ ٹائم#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#کولمبیا سمر ٹائم#,
				'generic' => q#کولمبیا ٹائم#,
				'standard' => q#کولمبیا سٹینڈرڈ ٹائم#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ایسٹر آئلینڈ سمر ٹائم#,
				'generic' => q#ایسٹر آئلینڈ ٹائم#,
				'standard' => q#ایسٹر آئلینڈ سٹینڈرڈ ٹائم#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ایکواڈور ٹائم#,
			},
		},
		'Europe/Budapest' => {
			exemplarCity => q#بوڈاپیسٹ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#وسطی یورپ کا موسم گرما کا وقت#,
				'generic' => q#وسطی یورپ کا وقت#,
				'standard' => q#وسطی یورپ کا معیاری وقت#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#فاک لینڈ آئلینڈز سمر ٹائم#,
				'generic' => q#فاک لینڈ آئلینڈز ٹائم#,
				'standard' => q#فاک لینڈ آئلینڈز سٹینڈرڈ ٹائم#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#فرینچ گیانا ٹائم#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#گرین وچ مین ٹائم#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#گالاپاگوز ٹائم#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#جارجیا سمر ٹائم#,
				'generic' => q#جارجیا ٹائم#,
				'standard' => q#جارجیا سٹینڈرڈ ٹائم#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#خلیج سٹینڈرڈ ٹائم#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#گیانا ٹائم#,
			},
		},
		'India' => {
			long => {
				'standard' => q#انڈیا سٹینڈرڈ ٹائم#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ایران ڈے لائٹ ٹائم#,
				'generic' => q#ایران ٹائم#,
				'standard' => q#ایران سٹینڈرڈ ٹائم#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#اسرائیل ڈے لائٹ ٹائم#,
				'generic' => q#اسرائیل ٹائم#,
				'standard' => q#اسرائیل سٹینڈرڈ ٹائم#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#مشرقی قزاخستان ٹائم#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#مغربی قزاخستان ٹائم#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#کرغستان ٹائم#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#مالدیپ ٹائم#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#نیپال ٹائم#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#نیوزی لینڈ ڈے لائٹ ٹائم#,
				'generic' => q#نیوزی لینڈ ٹائم#,
				'standard' => q#نیوزی لینڈ سٹینڈرڈ ٹائم#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#فرنانڈو ڈی نورونہا سمر ٹائم#,
				'generic' => q#فرنانڈو ڈی نورنہا ٹائم#,
				'standard' => q#فرنانڈو ڈی نورنہا سٹینڈرڈ ٹائم#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#پاکستان سمر ٹائم#,
				'generic' => q#پاکستان ٹائم#,
				'standard' => q#پاکستان سٹینڈرڈ ٹائم#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#پیراگوئے سمر ٹائم#,
				'generic' => q#پیراگوئے ٹائم#,
				'standard' => q#پیراگوئے سٹینڈرڈ ٹائم#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#پیرو سمر ٹائم#,
				'generic' => q#پیرو ٹائم#,
				'standard' => q#پیرو سٹینڈرڈ ٹائم#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#روتھیرا ٹائم#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#سورینام ٹائم#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#تاجکستان ٹائم#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ترکمانستان سمر ٹائم#,
				'generic' => q#ترکمانستان ٹائم#,
				'standard' => q#ترکمانستان سٹینڈرڈ ٹائم#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#یوروگوئے سمر ٹائم#,
				'generic' => q#یوروگوئے ٹائم#,
				'standard' => q#یوروگوئے سٹینڈرڈ ٹائم#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ازبکستان سمر ٹائم#,
				'generic' => q#ازبکستان ٹائم#,
				'standard' => q#ازبکستان سٹینڈرڈ ٹائم#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#وینزوئیلا ٹائم#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#ووسٹاک ٹائم#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
