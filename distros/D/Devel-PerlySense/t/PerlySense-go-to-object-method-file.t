#!/usr/bin/perl -w
use strict;

use Test::More tests => 7;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Lawn.pm";
my $oLocation;
my $rexFile = qr/Game.Location.pm$/;


ok($oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 391, col => 53), "Found source ok, on method");
like($oLocation->file, $rexFile, " file same");
is($oLocation->row, 44, " row ok");
is($oLocation->col, 1, " col ok");






__END__
