#!/usr/bin/perl -w
use strict;

use Test::More tests => 11;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Application.pm";
my $oLocation;
my $rexDestination;

$rexDestination = qr/Game.Object.Worm.Bot.pm$/;
ok($oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 115, col => 45), "Found source ok, on method");
like($oLocation->file, $rexDestination, " file found");
is($oLocation->row, 81, " row ok");
is($oLocation->col, 1, " col ok");


$rexDestination = qr/Game.Object.Worm.pm$/;
ok($oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 163, col => 39), "Found source ok, on method");
like($oLocation->file, $rexDestination, " file found");
is($oLocation->row, 360, " row ok");
is($oLocation->col, 1, " col ok");







__END__
