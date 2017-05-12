#!/usr/bin/perl -w
use strict;

use Test::More tests => 15;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense::Document");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
is($oDocument->file, "", " file is ok");
is($oDocument->oDocument, undef, " oDocument is ok");

throws_ok( sub { $oDocument->parse() }, qr/Missing argument \(file\)/, "Parse died ok on missing param");

dies_ok( sub { $oDocument->parse(file => "sldkfjsd/missing/sldkfjs.pm") }, "Parse died ok on missing file");
is($oDocument->file, "", " file is ok");
is($oDocument->oDocument, undef, " oDocument is ok");



my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer/Table.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
is($oDocument->file, $fileOrigin, " file set ok");
isnt($oDocument->oDocument, undef, " oDocument is ok");

is($oDocument->packageAt(row => 1), "main", "Correct package main ok");

is($oDocument->packageAt(row => 143), "Win32::Word::Writer::Table", "Correct package Table ok");

throws_ok(sub { $oDocument->packageAt(row => 0) }, qr/row/, "Dies ok when outside document");
throws_ok(sub { $oDocument->packageAt(row => -1) }, qr/row/, "Dies ok when outside document");





__END__
