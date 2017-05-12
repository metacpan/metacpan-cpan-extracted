#!/usr/bin/perl
#   /* vim: set ft=perl ai tw=75: */
use Test::More tests => 2;
use strict;
BEGIN {require "t/common.pl";};
sub Test::Gentoo::Probe::process() {
};
runtest(qw( base PkgFiles rfile pkg-files.lst  ));
