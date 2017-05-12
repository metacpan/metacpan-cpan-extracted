package Locale::CLDR::MeasurementSystem;
# This file auto generated from Data.xml
#	on Fri 29 Apr  6:48:39 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo::Role;

has 'measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				'001'	=> 'metric',
				'LR'	=> 'US',
				'MM'	=> 'US',
				'US'	=> 'US',
				'LR'	=> 'metric',
				'MM'	=> 'metric',
				'BS'	=> 'US',
				'BZ'	=> 'US',
				'KY'	=> 'US',
				'PR'	=> 'US',
				'PW'	=> 'US',
				'GB'	=> 'UK',
			} },
);

has 'paper_size' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				'001'	=> 'A4',
				'BZ'	=> 'US-Letter',
				'CA'	=> 'US-Letter',
				'CL'	=> 'US-Letter',
				'CO'	=> 'US-Letter',
				'CR'	=> 'US-Letter',
				'GT'	=> 'US-Letter',
				'MX'	=> 'US-Letter',
				'NI'	=> 'US-Letter',
				'PA'	=> 'US-Letter',
				'PH'	=> 'US-Letter',
				'PR'	=> 'US-Letter',
				'SV'	=> 'US-Letter',
				'US'	=> 'US-Letter',
				'VE'	=> 'US-Letter',
			} },
);

no Moo::Role;

1;

# vim: tabstop=4
