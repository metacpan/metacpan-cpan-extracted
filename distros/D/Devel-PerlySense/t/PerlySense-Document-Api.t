#!/usr/bin/perl -w
use strict;

use Test::More tests => 10;
use Test::Exception;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Document::Api");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }

my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Event/Timed.pm";
my $nameModule = "Game::Event::Timed";

my $oLocation;
my $method;


print "\n* Class\n";

ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

ok($oDocument->determineLikelyApi(nameModule => $nameModule), "determineLikelyApi ok");

ok(my $oApi = $oDocument->rhPackageApiLikely->{$nameModule}, "Got package API ok");



ok( ! $oApi->isSubSupported("missing_method"), " isSubSupported didn't find missing sub ok");

$method = "probabilityTurnRandomly";
ok($oLocation = $oApi->oLocationSetSub(nameSub => $method, oDocument => $oDocument), " oLocationSetSub without node ok");

ok($oApi->isSubSupported($method), " isSubSupported found present sub ok");






__END__
