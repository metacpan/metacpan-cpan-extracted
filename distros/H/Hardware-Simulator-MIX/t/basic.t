#!/usr/bin/perl
# vim:set filetype=perl:

use warnings;
use strict;
use lib "./lib";
use Hardware::Simulator::MIX;

use Test::More tests => 5;

BEGIN {
	use_ok 'Hardware::Simulator::MIX';
}

ok('Hardware::Simulator::MIX'->can('new'),   'new');
ok('Hardware::Simulator::MIX'->can('reset'), 'reset');
ok('Hardware::Simulator::MIX'->can('step'),  'step');

my $mix = Hardware::Simulator::MIX->new( max_byte => 100);
ok($mix->{max_byte}==100);

