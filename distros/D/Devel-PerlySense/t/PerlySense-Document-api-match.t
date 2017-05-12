#!/usr/bin/perl -w
use strict;

use Test::More tests => 11;
use Test::Exception;


use lib "../lib";

use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Api");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }



ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Lawn.pm";
my $nameModule = "Game::Lawn";

my ($object, $method, $oNodeSub);
my (@aMethod);
my $oApi;
my $oLocation;
my $rexFile = qr/.Game.Lawn.pm$/;


my @aAll = qw/
              END
              width
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
              oLocation
              oLawn
              raBodyLocation
              raBodyChar
              isBlocking
              color
              buildBodyRight
              /;

print "\n* No inheritance\n";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

ok($oDocument->determineLikelyApi(nameModule => $nameModule), " determineLikelyApi ok");

is($oDocument->scoreInterfaceMatch(
    nameModule => $nameModule,
    raMethodRequired => [qw/ fksdjf_missing_sdkfjs /],
    raMethodNice => [qw/ isLocationValidForMove /]),
   0, " Correct scoreInterfaceMatch for missing required");


cmp_ok($oDocument->scoreInterfaceMatch(
    nameModule => $nameModule,
    raMethodRequired => [qw/ isAnythingAt /],
    raMethodNice => [qw/ /]),
   '==', 83.84, " Correct scoreInterfaceMatch for one present required");


cmp_ok($oDocument->scoreInterfaceMatch(
    nameModule => $nameModule,
    raMethodRequired => [qw/ isAnythingAt wormHasCrashed /],
    raMethodNice => [qw/ /]),
   '==', 84.34, " Correct scoreInterfaceMatch for two present required");

cmp_ok(int($oDocument->scoreInterfaceMatch(
    nameModule => $nameModule,
    raMethodRequired => [qw/ isAnythingAt wormHasCrashed /],
    raMethodNice => [qw/ missing_method /])),
   '==', 56.00, " Correct scoreInterfaceMatch for two present required");


cmp_ok(int($oDocument->scoreInterfaceMatch(
    nameModule => $nameModule,
    raMethodRequired => [qw/ isAnythingAt /],
    raMethodNice => \@aAll)),
   '==', 100.00, " Correct scoreInterfaceMatch for full score, all present and all supported");





__END__



