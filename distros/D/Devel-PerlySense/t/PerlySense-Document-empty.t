#!/usr/bin/perl -w
use strict;

use Test::More tests => 17;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");




is(scalar($oDocument->isEmptyAt(row => 452, col => 1)), 1, "No perl fragment ok, between stuff");
is($oDocument->isEmptyAt(row => 154, col => 10), 0, "On use module");
is($oDocument->isEmptyAt(row => 160, col => 25), 0, "On class method call ");
is($oDocument->isEmptyAt(row => 193, col => 14), 0, "On use with params");
is($oDocument->isEmptyAt(row => 157, col => 11), 0, "On use");

is(scalar($oDocument->isEmptyAt(row => 287, col => 18)), 0, "Some perl fragment ok, on object->method");


is(scalar($oDocument->isEmptyAt(row => 288, col => 2)), 1, "Nothing at left margin");
is(scalar($oDocument->isEmptyAt(row => 286, col => 20)), 1, "Nothing at right of statement");
is(scalar($oDocument->isEmptyAt(row => 298, col => 1)), 1, "Nothing between statements");
is(scalar($oDocument->isEmptyAt(row => 288, col => 23)), 1, "Nothing in small whitespace");


print "\nTesting things that may change in the future when they become parsed for\n";
is(scalar($oDocument->isEmptyAt(row => 290, col => 25)), 1, "Some perl fragment ok, on variable");
is(scalar($oDocument->isEmptyAt(row => 290, col => 31)), 1, "Some perl fragment ok, on semicolon");
is(scalar($oDocument->isEmptyAt(row => 295, col => 1)), 1, "Some perl fragment ok, on {");






__END__
