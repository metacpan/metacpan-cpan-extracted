#!/usr/bin/perl -w
use strict;

use Test::More tests => 10;
use Test::Exception;

use File::Basename;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm.pm";
my $dirOrigin = dirname($fileOrigin);
my $raModule;
my $raMethodRequired;
my $raMethodNice;
my @aDocumentFound;

$raModule = [qw/ Game::Lawn Game::Location Game::Direction Game::Event::Timed /];
$raMethodRequired = ["placeObjectBodyPartAt"];
$raMethodNice = ["wormHasCrashed", "objectHasMoved", "placeObjectBodyPartAt"];
ok(@aDocumentFound = $oPs->aDocumentFindModuleWithInterface(
    raNameModule => $raModule,
    raMethodRequired => $raMethodRequired,
    raMethodNice => $raMethodNice,
    dirOrigin => $dirOrigin,
), "aDocumentFindModuleWithInterface Found modules");
is(scalar(@aDocumentFound), 1, " Found correct no of modules");
like($aDocumentFound[0]->file, qr/Game.Lawn.pm$/, " Found correct modules");



$raModule = [qw/ Game::Object Game::Object::Worm::Bot Game::Event::Timed  /];
$raMethodRequired = ["raBodyLocation"];
$raMethodNice = ["buildBodyRight", "crash", "checkTick"];
ok(@aDocumentFound = $oPs->aDocumentFindModuleWithInterface(
    raNameModule => $raModule,
    raMethodRequired => $raMethodRequired,
    raMethodNice => $raMethodNice,
    dirOrigin => $dirOrigin,
), "aDocumentFindModuleWithInterface Found modules");
is(scalar(@aDocumentFound), 2, " Found correct no of modules");
like($aDocumentFound[0]->file, qr/Game.Object.pm$/, " Found correct modules");
like($aDocumentFound[1]->file, qr/Game.Object.Worm.Bot.pm$/, " Found correct modules");






__END__
