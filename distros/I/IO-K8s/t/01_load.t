#!/usr/bin/env perl

use Test::More;
use Test::Class::Moose::Load qw(lib auto-lib);

pass('all classes load');

done_testing;
