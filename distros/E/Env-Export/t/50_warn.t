#!/usr/bin/perl

use strict;
use warnings;
use vars qw($code);

use Test::More;

# TEST SCOPE: These tests exercise the ":warn" and ":nowarn" keywords

plan tests => 3;

my $caught = 0;
$SIG{__WARN__} = sub { $caught++ if ($_[0] =~ /REDEFINE/) };

$ENV{REDEFINE1} = 0;
eval q|
sub REDEFINE1 { 1 }

use Env::Export qw(REDEFINE1);
|;
warn "eval fail: $@" if $@;

ok($caught, 'Caught warning for redefining');

$caught = 1;
$SIG{__WARN__} = sub { $caught-- if ($_[0] =~ /REDEFINE/) };

$ENV{REDEFINE2} = 0;
eval q|
sub REDEFINE2 { 1 }

use Env::Export qw(:nowarn REDEFINE2);
|;
warn "eval fail: $@" if $@;

ok($caught, 'No warning for redefining issued');

$caught = 0;
$SIG{__WARN__} = sub { $caught++ if ($_[0] =~ /REDEFINE/) };

$ENV{REDEFINE3} = 0;
$ENV{REDEFINE4} = 0;
eval q|
sub REDEFINE3 { 1 }
sub REDEFINE4 { 1 }

use Env::Export qw(:nowarn REDEFINE3 :warn REDEFINE4);
|;
warn "eval fail: $@" if $@;

is($caught, 1, 'Only one warning issued when both keywords used');

exit;
