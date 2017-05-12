#!/usr/bin/perl
# vim: set ft=perl ai tw=75
use Cwd;
use Test::More tests => 4;
use strict;
BEGIN {require "t/common.pl";};
sub Test::Gentoo::Probe::process() {
	s#/+#/#g;
};
runtest(base=>'Pkg', rfile=>"pat.lst",       pats=>[qw(x)]);
runtest(base=>'Pkg', rfile=>'installed.lst', installed=>1);
