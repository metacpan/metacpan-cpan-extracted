#!/usr/bin/perl -w
use strict;

use Test::More tests => 15;
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



my $fragment;




is(scalar($oDocument->moduleAt(row => 452, col => 1)), undef, "No perl fragment ok, between stuff");

$fragment = 'File::Temp';
is($oDocument->moduleAt(row => 154, col => 10), $fragment, "On use module");


$fragment = 'Win32::OLE::Const';
is($oDocument->moduleAt(row => 160, col => 25), $fragment, "On class method call ");

$fragment = 'Class::MethodMaker';
is($oDocument->moduleAt(row => 193, col => 14), $fragment, "On use with params");


$fragment = 'Win32::Word::Writer::Table';
is($oDocument->moduleAt(row => 157, col => 11), $fragment, "On use");



is(scalar($oDocument->moduleAt(row => 287, col => 18)), undef, "No perl fragment ok, on object->method");

is(scalar($oDocument->moduleAt(row => 290, col => 25)), undef, "No perl fragment ok, on variable");

is(scalar($oDocument->moduleAt(row => 288, col => 38)), undef, "No perl fragment ok, on chained method call");

is(scalar($oDocument->moduleAt(row => 288, col => 38)), undef, "No perl fragment ok, on chained method call");

is(scalar($oDocument->moduleAt(row => 279, col => 13)), undef, "No perl fragment ok, on self method call");

is(scalar($oDocument->moduleAt(row => 146, col => 7)), undef, "No perl fragment ok, on use pragma");



#Don't check this, we can't determine that this isn't a module by lexical method
#But if the module lookup fails, we could say it's something else, like a bareword sub or somehting

#is(scalar($oDocument->moduleAt(row => 592, col => 32)), undef, "No perl fragment ok, on hash key token");





__END__
