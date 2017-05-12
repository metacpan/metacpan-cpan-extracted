#!/usr/bin/perl
package main;
use strict;
use Test::More tests=>2;

my $expected_var = {vars=>{qw/top_secret nothing/}};
require Fry::Config::Default;
is_deeply(Fry::Config::Default->read('t/testlib/shell.conf'),$expected_var,'Fry::Config::Default::read');

SKIP: {
eval {require YAML};
skip "YAML not installed",1 if $@;
require Fry::Config::YAML;
is_deeply(Fry::Config::YAML->read('t/testlib/shell.yaml'),$expected_var,'Fry::Config::YAML::read');
}
