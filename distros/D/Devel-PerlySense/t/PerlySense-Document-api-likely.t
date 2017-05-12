#!/usr/bin/perl -w
use strict;

use Test::More tests => 40;
use Test::Exception;

use File::Basename;
use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Api");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


{

    ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

    my $dirData = "data/project-lib";
    my $fileOrigin = "$dirData/Game/Lawn.pm";
    my $nameModule = "Game::Lawn";

    my ($object, $method, $oNodeSub);
    my (@aMethod);
    my $oApi;
    my $oLocation;
    my $rexFile = qr/.Game.Lawn.pm$/;



    print "\n* No inheritance\n";

    ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

    ok($oDocument->determineLikelyApi(nameModule => $nameModule), " determineLikelyApi ok");
    is(scalar(keys %{$oDocument->rhPackageApiLikely}), 1, " rhPackageApiLikely key count ok");
    ok($oApi = $oDocument->rhPackageApiLikely->{"Game::Lawn"}, " Got Game::Lawn API");
#warn(Dumper($oApi->rhSub));
    is_deeply([sort keys %{$oApi->rhSub}],
              [sort qw/
                       END
                       width
                       buildBodyRight
                       color
                       oLocation
                       oLawn
                       raBodyLocation
                       raBodyChar
                       isBlocking
                       height
                       rhGrid
                       oUI
                       oController
                       rhPrize
                       new
                       oPlaceWorm
                       oPlacePrize
                       prizeWasClaimedBy
                       placeObjectAt
                       objectHasMoved
                       removeObject
                       isObjectAt
                       isAnythingAt
                       isAnythingBlockingAt
                       oLocationRandom
                       isLocationOnLawn
                       isLocationValidForMove
                       isLocationValidForPlacement
                       isObjectLocationValidForPlacement
                       oDirectionToPrize
                       placeObjectBodyPartAt
                       removeObjectBodyPartAt
                       wormHasCrashed
                       /],
              " API raSub ok");

    ok($oLocation = $oApi->rhSub->{width}, " Got location");
    like($oLocation->file, $rexFile, "   Correct file name");
    is($oLocation->row, 0, "   row");
    is($oLocation->col, 0, "   row");
    is($oLocation->rhProperty->{sub}, "width", "   rhProperty->sub");

    ok($oLocation = $oApi->rhSub->{removeObject}, " Got location");
    like($oLocation->file, $rexFile, "   Correct file name");
    is($oLocation->row, 280, "   row");
    is($oLocation->col, 1, "   row");
    is($oLocation->rhProperty->{sub}, "removeObject", "   rhProperty->sub");


    #print Dumper($oLocation);
    #print Dumper([ sort keys %{$oApi->rhSub} ]);

}





{

    ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

    my $dirData = "data/project-lib";
    my $fileOrigin = "$dirData/Game/Object/Worm.pm";
    my $nameModule = "Game::Object::Worm";

    my ($object, $method, $oNodeSub);
    my (@aMethod);
    my $oApi;
    my $oLocation;
    my $rexFileWorm = qr/.Game.Object.Worm.pm$/;
    my $rexFileObject = qr/.Game.Object.pm$/;



    print "\n* Single inheritance, one ancestor\n";

    ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

    ok($oDocument->determineLikelyApi("nameModule", $nameModule), " determineLikelyApi ok");
    is(scalar(keys %{$oDocument->rhPackageApiLikely}), 1, " rhPackageApiLikely key count ok");
    ok($oApi = $oDocument->rhPackageApiLikely->{"Game::Object::Worm"}, " Got Game::Object::Worm API");

    is_deeply([sort keys %{$oApi->rhSub}],
              [sort qw/
                       isRealPlayer
                       oDirection
                       oEventMove
                       score
                       lengthIdeal
                       lengthActual

                       oLocation
                       oLawn
                       raBodyLocation
                       raBodyChar
                       isBlocking
                       color

                       moveForward
                       oValidLocationAfterMove
                       turn
                       grow
                       crash
                       checkTick
                       awardScorePoints
                       loadFile

                       new
                       buildBodyRight
                       /],
              " API raSub ok");

    ok($oLocation = $oApi->rhSub->{oLocation}, " Got location");
    like($oLocation->file, $rexFileObject, "   Correct file name");
    is($oLocation->row, 0, "   row");
    is($oLocation->col, 0, "   row");
    is($oLocation->rhProperty->{sub}, "oLocation", "   rhProperty->sub");

    ok($oLocation = $oApi->rhSub->{buildBodyRight}, " Got location");
    like($oLocation->file, $rexFileObject, "   Correct file name");
    is($oLocation->row, 153, "   row");
    is($oLocation->col, 1, "   row");
    is($oLocation->rhProperty->{sub}, "buildBodyRight", "   rhProperty->sub");

    ok($oLocation = $oApi->rhSub->{new}, " Got location");
    like($oLocation->file, $rexFileWorm, "   Correct file name");
    is($oLocation->row, 142, "   row");
    is($oLocation->col, 1, "   row");
    is($oLocation->rhProperty->{sub}, "new", "   rhProperty->sub");


    #print Dumper($oLocation);
    #print Dumper([ sort keys %{$oApi->rhSub} ]);

}





#buildBodyRight
#new


__END__



