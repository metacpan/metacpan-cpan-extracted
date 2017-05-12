#!/usr/bin/perl -w
use strict;

use Test::More tests => 18;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";
my $oLocation;



ok(! $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 420, col => 17), "Didn't find hOpt");

ok(! $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 420, col => 5234), "Didn't find point at far right");


ok(
    $oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 423, col => 21),
    "Found source ok, on method"
);
is($oLocation->file, $fileOrigin, " file same");
is($oLocation->row, 446, " row ok");
is($oLocation->col, 1, " col ok");


# $self -> Write ($text);
ok(
    $oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 429, col => 14),
    "Found source ok, on method with spaces around it"
);
is($oLocation->file, $fileOrigin, " file same");
is($oLocation->row, 396, " row ok");
is($oLocation->col, 1, " col ok");



# shift->Set|Style("Default Paragraph Font");
ok(
    $oLocation = $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 514, col => 14),
    "Found source ok, on method for self is shift"
);
is($oLocation->file, $fileOrigin, " file same");
is($oLocation->row, 477, " row ok");
is($oLocation->col, 1, " col ok");

# shift with $self - no match
# shift->Set|Style("Default Paragraph Font");
ok(
    ! $oPs->oLocationSmartGoTo(file => $fileOrigin, row => 483, col => 14),
    "Did not find source ok, on method for self is shift, but with self also in the sub"
);


__END__
