#!/usr/bin/perl -w
use strict;

use Test::More tests => 16;
use Test::Exception;

use Data::Dumper;
use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense::Document");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");


is($oDocument->aNameBase() + 0, 0, "No base classes ok");



sub test_inheritance_mechanism {
    my ($file, $raBaseExpected, $mechanism) = @_;
    note("Checking that inheritance via ($mechanism) works");

    ok($oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

    $dirData = "data/project-lib";
    $fileOrigin = "$dirData/$file";

    ok($oDocument->parse(file => $fileOrigin), "Parsed file ($fileOrigin) ok");

    is_deeply(
        [ sort $oDocument->aNameBase() ],
        $raBaseExpected,
        "One base class ($mechanism) ok",
    );
}

test_inheritance_mechanism("Game/Object/Worm/Bot.pm", ["Game::Object::Worm"], "use base");
test_inheritance_mechanism("Game/Object/Worm.pm",     ["Game::Object"],       "use parent");
test_inheritance_mechanism(
    "Game/Object/Worm/ShaiHulud.pm",
    ["Game::Lawn", "Game::Object::Worm"],
    '@ISA = ..., with two base classes',
);
test_inheritance_mechanism(
    "Game/Object/Worm/Shaitan.pm",
    ["Game::Lawn", "Game::Object::Worm"],
    'push @ISA, with two base classes',
);





__END__
