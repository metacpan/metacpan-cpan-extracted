#!/usr/bin/perl -w
use strict;
use Test;
use utf8;
BEGIN { plan tests => 4 }
use Lingua::Slavic::Numbers qw( LANG_BG number_to_slavic );
$Lingua::Slavic::Numbers::DEBUG=1;
use vars qw(%numbers);
do 't/rig.pm';

use vars qw(%numbers);
%numbers = (
	'foo'   => undef,
	'12bar' => undef,
	'12e2'  => 'хиляда и двеста',
	1e80    => undef,
);

# switch off warnings
$SIG{__WARN__} = sub {};

rig(\%numbers, sub { number_to_slavic(LANG_BG, @_) });
