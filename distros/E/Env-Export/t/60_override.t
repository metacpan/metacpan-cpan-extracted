#!/usr/bin/perl

use strict;
use warnings;
use subs qw(sub_count);

use Test::More;

# TEST SCOPE: These tests exercise the ":override" and ":nooverride" keywords

# N.B.: The routines that do/n't get overridden are not declared to be
#       constant subs, because the warnings trigged by such can't be
#       suppressed via 'no warnings'. Indeed, the ":nowarn" keyword is used
#       to prevent the Env::Export warnings as well, since we've already
#       tested/validated it.

plan tests => 9;

my $namespace = 'namespace0000';

$ENV{OVERRIDE} = 'no';
eval qq|
package $namespace;
sub OVERRIDE { 'yes' }
use Env::Export qw(:nowarn OVERRIDE);
package main;
is(${namespace}::OVERRIDE(), 'yes',
   'Basic test to ensure sub does not override');
|;
warn "eval fail: $@" if $@;

$ENV{OVERRIDE} = 'yes';
$namespace++;
eval qq|
package $namespace;
sub OVERRIDE { 'no' }
use Env::Export qw(:nowarn :override OVERRIDE);
package main;
is(${namespace}::OVERRIDE(), 'yes', 'Test :override');
|;
warn "eval fail: $@" if $@;

$ENV{OVERRIDE1} = 'yes';
$ENV{OVERRIDE2} = 'no';
$namespace++;
eval qq|
package $namespace;
sub OVERRIDE1 { 'no' }
sub OVERRIDE2 { 'yes' }
use Env::Export qw(:nowarn :override OVERRIDE1 :nooverride OVERRIDE2);
package main;
is(${namespace}::OVERRIDE1(), 'yes', 'Test :override+:nooverride [1]');
is(${namespace}::OVERRIDE2(), 'yes', 'Test :override+:nooverride [2]');
|;
warn "eval fail: $@" if $@;

$ENV{OVERRIDE1} = 'yes';
$ENV{OVERRIDE2} = 'yes';
$ENV{OVERRIDE3} = 'no';
$ENV{OVERRIDE4} = 'yes';
$ENV{OVERRIDE5} = 'yes';
$namespace++;
eval qq|
package $namespace;
sub OVERRIDE1 { 'no' }
sub OVERRIDE2 { 'no' }
sub OVERRIDE3 { 'yes' }
sub OVERRIDE4 { 'no' }
sub OVERRIDE5 { 'no' }
use Env::Export qw(:nowarn
                   :override OVERRIDE1 OVERRIDE2
                   :nooverride OVERRIDE3
                   :override OVERRIDE4 OVERRIDE5);
package main;
is(${namespace}::OVERRIDE1(), 'yes', 'Test three-step toggling [1]');
is(${namespace}::OVERRIDE2(), 'yes', 'Test three-step toggling [2]');
is(${namespace}::OVERRIDE3(), 'yes', 'Test three-step toggling [3]');
is(${namespace}::OVERRIDE4(), 'yes', 'Test three-step toggling [4]');
is(${namespace}::OVERRIDE5(), 'yes', 'Test three-step toggling [5]');
|;
warn "eval fail: $@" if $@;

exit;
