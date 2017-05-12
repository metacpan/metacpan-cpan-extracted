#!/usr/bin/perl
#   /* vim: set ft=perl ai tw=75: */
use Test::More tests => 2;
use strict;
BEGIN {require "t/common.pl";};
sub Test::Gentoo::Probe::process() {
};
runtest(qw(rfile pkg-of.lst base PkgOf));
