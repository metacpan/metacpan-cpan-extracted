#!/usr/bin/perl -w
use strict;

use Test::More tests => 13;
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





my $fragment = '$self->SetStyle';
is(scalar($oDocument->methodCallAt(row => 452, col => 1)), undef, "No perl fragment ok, between stuff");

$fragment = '$self->SetStyle';
is($oDocument->methodCallAt(row => 425, col => 20) . "", $fragment, "Correct perl fragment ok, on method");


$fragment = '$self->rhConst';
is($oDocument->methodCallAt(row => 947, col => 47) . "", $fragment, "Correct perl fragment ok, on inner method");
is(scalar($oDocument->methodCallAt(row => 947, col => 54)), undef, "Didn't find  perl fragment ok, on last arrow");


$fragment = '$self->oSelection';
is($oDocument->methodCallAt(row => 947, col => 14) . "", $fragment, "Correct perl fragment ok, Other chained method call after");


$fragment = 'oSelection->GoTo';
is($oDocument->methodCallAt(row => 947, col => 24) . "", $fragment, "Correct perl fragment ok, Chained method call (looks like class method call, maybe should be a ->oSelection->GoTo)");


$fragment = '->oDocument';    
is($oDocument->methodCallAt(row => 968, col => 19) . "", $fragment, 'Correct perl fragment ok, $rabject[9]->oDocument');

$fragment = 'Win32::OLE->Option';
is($oDocument->methodCallAt(row => 242, col => 18) . "", $fragment, "Correct perl fragment ok, Class method");

$fragment = '$self->MarkDocumentAsSaved';
is($oDocument->methodCallAt(row => 1016, col => 36) . "", $fragment, "Correct perl fragment ok, Should work");





__END__
