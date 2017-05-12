#!/usr/bin/perl -w
use strict;

use Test::More tests => 16;
use Test::Exception;

use Data::Dumper;
use File::Basename;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";
my $oLocation;
my $fileTarget = "./$dirData/lib/Win32/Word/Writer/Table.pm";


ok(! $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 160, col => 7), "Didn't find rhConst");


ok($oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 157, col => 11), "Found source ok, use module");
like($oLocation->file, qr/Writer.Table\.pm/, " file same");
is($oLocation->row, 1, " row ok");
is($oLocation->col, 1, " col ok");


ok($oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 321, col => 20), "Found source ok, on module in class method call");
like($oLocation->file, qr/File.Spec\.pm$/, " file ok");
is($oLocation->row, 1, " row ok");
is($oLocation->col, 1, " col ok");


ok($oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 156, col => 15), "Found source ok, class in string");
like($oLocation->file, qr/Writer.Table\.pm/, " file same");
is($oLocation->row, 1, " row ok");
is($oLocation->col, 1, " col ok");






__END__
