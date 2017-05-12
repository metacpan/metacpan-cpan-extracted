#!/usr/bin/perl
# vim: set ft=perl ai tw=75:
use strict;
use Test::More tests => 2;

BEGIN { require "t/common.pl" };
runtest(base=>'Pkg', rfile=>"pat.lst",pats=>[qw(x)]);
sub Test::Gentoo::Probe::process() {
};
