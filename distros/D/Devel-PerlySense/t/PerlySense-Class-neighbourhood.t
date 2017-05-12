#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;
use Test::Exception;

use Data::Dumper;


use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Class");


BEGIN { -d "t" and chdir("t"); }



my $dirData = "data/project-lib";
my $dirOrigin = "$dirData/Game/Object";
my $fileOrigin = "$dirOrigin/Worm.pm";

ok(
    my $oClassOject = Devel::PerlySense::Class->newFromFileAt(
        oPerlySense => Devel::PerlySense->new(),
        file => $fileOrigin,
        row => 20,
        col => 1,
    ),
    "newFromFileAt at proper package location ok",
);


note("Classes in ($dirOrigin)");
is_deeply(
    [ sort $oClassOject->aNameClassInDir(dir => $dirOrigin) ],
    [ sort qw/
              Game::Object::Worm
              Game::Object::WormVisible
              Game::Object::Prize
              Game::Object::Wall
              /],
    "Classes in dir found correct classes",
);



note("Classes in the neighbourhood of ($fileOrigin)");

ok(
    my $rhDirClass = $oClassOject->rhDirNameClassInNeighbourhood(),
    "rhDirNameClassInNeighbourhood ok",
);


is_deeply(
    [ sort @{$rhDirClass->{current}} ],
    [ sort qw/
              Game::Object::Worm
              Game::Object::WormVisible
              Game::Object::Prize
              Game::Object::Wall
              /],
    "Classes in current dir found correct classes",
);

is_deeply(
    [ sort @{$rhDirClass->{up}} ],
    [ sort qw/
              Game::ObjectVisible
              Game::Application
              Game::Controller
              Game::Direction
              Game::Lawn
              Game::Location
              Game::Object
              Game::UI
              /],
    "Classes in up dir found correct classes",
);

is_deeply(
    [ sort @{$rhDirClass->{down}} ],
    [ sort qw/
              Game::Object::Worm::Bot
              Game::Object::Worm::Shaitan
              Game::Object::Worm::ShaiHulud
              /],
    "Classes in up dir found correct classes",
);





__END__
