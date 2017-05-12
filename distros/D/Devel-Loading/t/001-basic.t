#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use lib 't/lib';

my @loaded;
use Devel::Loading sub { push @loaded, $_ };
use MyTest::Module;

is_deeply([splice @loaded], ['MyTest/Module.pm', 'MyTest/Other/Module.pm']);

