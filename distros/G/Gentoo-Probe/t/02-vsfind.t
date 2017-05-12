#!/usr/bin/perl -w
#   /* vim: set ft=perl ai tw=75: */
BEGIN { require "t/common.pl" };
use strict;
plan(tests => 2);
runtest("base", "Pkg", "rfile", "vsfind.lst");
sub Test::Gentoo::Probe::process() {
	s#/+#/#g;
};

