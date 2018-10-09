package Locale::CLDR::CalendarPreferences;
# This file auto generated from Data.xml
#	on Sun  7 Oct 10:18:12 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo::Role;

has 'calendar_preferences' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'001' => ['gregorian'],
		'DJ' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'DZ' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'EH' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'ER' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'IQ' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'JO' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'KM' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'LB' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'LY' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'MA' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'MR' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'OM' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'PS' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'SD' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'SY' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'TD' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'TN' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'YE' => ['gregorian','islamic','islamic-civil','islamic-tbla'],
		'AE' => ['gregorian','islamic-umalqura','islamic','islamic-civil','islamic-tbla'],
		'BH' => ['gregorian','islamic-umalqura','islamic','islamic-civil','islamic-tbla'],
		'KW' => ['gregorian','islamic-umalqura','islamic','islamic-civil','islamic-tbla'],
		'QA' => ['gregorian','islamic-umalqura','islamic','islamic-civil','islamic-tbla'],
		'AF' => ['persian','gregorian','islamic','islamic-civil','islamic-tbla'],
		'IR' => ['persian','gregorian','islamic','islamic-civil','islamic-tbla'],
		'CN' => ['gregorian','chinese'],
		'CX' => ['gregorian','chinese'],
		'HK' => ['gregorian','chinese'],
		'MO' => ['gregorian','chinese'],
		'SG' => ['gregorian','chinese'],
		'EG' => ['gregorian','coptic','islamic','islamic-civil','islamic-tbla'],
		'ET' => ['gregorian','ethiopic'],
		'IL' => ['gregorian','hebrew','islamic','islamic-civil','islamic-tbla'],
		'IN' => ['gregorian','indian'],
		'JP' => ['gregorian','japanese'],
		'KR' => ['gregorian','dangi'],
		'SA' => ['islamic-umalqura','gregorian','islamic','islamic-rgsa'],
		'TH' => ['buddhist','gregorian'],
		'TW' => ['gregorian','roc','chinese'],
	}},
);

no Moo::Role;

1;

# vim: tabstop=4
