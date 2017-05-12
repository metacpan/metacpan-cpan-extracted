#!/usr/bin/perl -w
use strict;

use Test::More tests => 14;
use Test::Exception;

use Data::Dumper;


use lib "../lib";

use_ok("Devel::PerlySense") or die;
use_ok("Devel::PerlySense::Class") or die;


BEGIN { -d "t" and chdir("t"); }



my $dirData = "data/project-lib";
my $dirOrigin = "$dirData/Game/Object";
my $fileOrigin = "$dirOrigin/Worm.pm";

ok(
    my $oClassWorm = Devel::PerlySense::Class->newFromFileAt(
        oPerlySense => Devel::PerlySense->new(),
        file => $fileOrigin,
        row => 20,
        col => 1,
    ),
    "newFromFileAt at proper package location ok",
);



my $oLocation;



note("POD");
ok(
    $oLocation = $oClassWorm->oLocationMethodDoc(method => "turn"),
    "Location for method turn found",
);
is($oLocation->row, 244, "Location row ok");



ok(
    ! $oClassWorm->oLocationMethodDoc(method => "missing_method"),
    "Location for missing_method not found ok",
);



ok(
    $oLocation = $oClassWorm->oLocationMethodDoc(method => "buildBodyRight"),
    "Location for method buildBodyRight in base class found",
);
is($oLocation->row, 144, "Location row ok");
like($oLocation->file, qr/Game.Object.pm/, "Location file ok");









note("Goto");
ok(
    $oLocation = $oClassWorm->oLocationMethodGoTo(method => "turn"),
    "Location for method turn found",
);
is($oLocation->row, 253, "Location row ok");



ok(
    $oLocation = $oClassWorm->oLocationMethodGoTo(method => "buildBodyRight"),
    "Location for method buildBodyRight in base class found",
);
is($oLocation->row, 153, "Location row ok");
like($oLocation->file, qr/Game.Object.pm/, "Location file ok");





__END__
