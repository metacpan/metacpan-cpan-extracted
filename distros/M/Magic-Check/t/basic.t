#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Magic::Check;

sub validate { $_[1] =~ /1/ ? undef : "Invalid" }
my $check = bless {};

my $var = 1;
is exception { check_variable($var, $check); 1 }, undef, 'Variable satisfies condition at casting';
is $var, 1, 'variable is still 1';
is exception { $var = 11 }, undef, 'Can assign 11 to it';
is $var, 11, 'Variable is now 11';
like exception { $var = 42 }, qr/Invalid/, 'Can\'t assign 42';
is $var, 11, 'Variable is still 11';

done_testing;
