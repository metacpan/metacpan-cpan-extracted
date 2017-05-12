#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;
use Test::Exception;


use lib "../lib";

use_ok("Devel::PerlySense::Util");


my @aParam;
my %hArg;
my @aResult;


@aParam = ("file", "row", "col");

%hArg = (file => "dsf", row => 32, col => 34);
lives_ok( sub { @aResult = Devel::PerlySense::Util::aNamedArg(\@aParam, %hArg) }, "All args there");
is_deeply(\@aResult, ["dsf", 32, 34], " Correct return values");

%hArg = (row => 32, col => 34);
throws_ok( sub { @aResult = Devel::PerlySense::Util::aNamedArg(\@aParam, %hArg) }, qr/Missing argument \(file\)/, "Dies on missing file arg");


%hArg = (file => "dsf", row => 32, col => 34, extra => "all");
lives_ok( sub { @aResult = Devel::PerlySense::Util::aNamedArg(\@aParam, %hArg) }, "All args there, plus some");
is_deeply(\@aResult, ["dsf", 32, 34], " Correct return values");




__END__
