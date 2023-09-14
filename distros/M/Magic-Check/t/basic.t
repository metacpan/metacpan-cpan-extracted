#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings ':all';

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

my $var2 = 1;
is_deeply warning { check_variable($var2, $check, 1) }, [], 'Variable 2 satisfies condition at casting';
is $var2, 1, 'variable2 is still 1';
is_deeply warning { $var2 = 11 }, [], 'Can assign 11 to variable 2';
is $var2, 11, 'Variable2 is now 11';
like warning { $var2 = 42 }, qr/Invalid/, 'Can\'t assign 42 to variable2';
is $var2, 42, 'Variable 2 is now 42';

done_testing;
