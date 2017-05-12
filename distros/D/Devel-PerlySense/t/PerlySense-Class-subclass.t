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
my $fileOrigin = "$dirData/Game/Object.pm";


ok(
    my $oClassOject = Devel::PerlySense::Class->newFromFileAt(
        oPerlySense => Devel::PerlySense->new(),
        file => $fileOrigin,
        row => 20,
        col => 1,
    ),
    "newFromFileAt at proper package location ok",
);



note("Game::Object");
isa_ok($oClassOject, "Devel::PerlySense::Class");
is($oClassOject->name, "Game::Object", "  Got correct class name");

is(scalar @{$oClassOject->raDocument}, 1, "  Has one Document");

ok(my $rhClassObjecClassSub = $oClassOject->rhClassSub, "Got subclasses");

is_deeply(
    [ sort keys %$rhClassObjecClassSub ],
    [ sort qw/ Game::Object::Prize Game::Object::Wall Game::Object::Worm Game::Lawn / ],
    "  And it's the correct class names",
);



__END__
