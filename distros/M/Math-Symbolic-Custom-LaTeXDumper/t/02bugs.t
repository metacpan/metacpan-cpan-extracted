#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 1;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::LaTeXDumper;

my $ms = parse_from_string("1 + x^2 * -(2)");
ok($ms->to_latex =~ /left/, "Contains parenthesis");

