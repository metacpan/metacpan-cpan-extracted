#!/usr/bin/perl -w
use strict;

use Test::More tests => 31;
use Test::Exception;

use Data::Dumper;


use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Class");


BEGIN { -d "t" and chdir("t"); }


throws_ok(
    sub { Devel::PerlySense::Class->new(
        oPerlySense => Devel::PerlySense->new(),
    ) },
    qr/name/,
    "new fails ok with missing name",
);

lives_ok(
    sub { Devel::PerlySense::Class->new(
        oPerlySense => Devel::PerlySense->new(),
        name => "dummy",
        raDocument => [],
    ) },
    "new ok with name",
);





throws_ok(
    sub {
        Devel::PerlySense::Class->newFromFileAt(
            oPerlySense => Devel::PerlySense->new(),
            file => "lost_file.pm",
            row => 1,
            col => 1,
        )
    },
    qr/Could not parse file .lost_file.pm/,
    "newFromFileAt dies ok with missing file",
);
         



my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm/ShaiHulud.pm";


ok(
    my $oClassDefault = Devel::PerlySense::Class->newFromFileAt(
        oPerlySense => Devel::PerlySense->new(),
        file => $fileOrigin,
        row => 1,
        col => 1,
    ),
    "newFromFileAt at main finds default package ok",
);
is($oClassDefault->name, "Game::Object::Worm::ShaiHulud", "  with correct class name");
          

ok(
    my $oClassOjectWormShai = Devel::PerlySense::Class->newFromFileAt(
        oPerlySense => Devel::PerlySense->new(),
        file => $fileOrigin,
        row => 20,
        col => 1,
    ),
    "newFromFileAt at proper package location ok",
);


note("Game::Object::Worm::ShaiHulud");
isa_ok($oClassOjectWormShai, "Devel::PerlySense::Class");
is($oClassOjectWormShai->name, "Game::Object::Worm::ShaiHulud", "  Got correct class name");

is(scalar @{$oClassOjectWormShai->raDocument}, 1, "  Has one Document");
ok(my $oDocumentOjectWormShai = $oClassOjectWormShai->raDocument->[0], "    Got document");
like($oDocumentOjectWormShai->file, qr|Game.Object.Worm.ShaiHulud.pm$|, "    Document file ok");

is_deeply(
    [ sort keys %{$oClassOjectWormShai->rhClassBase} ],
    [ "Game::Lawn", "Game::Object::Worm" ],
    "  Has the correct base classes",
);

ok(my $oClassLawn = $oClassOjectWormShai->rhClassBase->{"Game::Lawn"}, "  Got Lawn");
ok(my $oClassGameObjectWorm = $oClassOjectWormShai->rhClassBase->{"Game::Object::Worm"}, "  Got Worm");




note("Game::Object::Worm");
isa_ok($oClassGameObjectWorm, "Devel::PerlySense::Class");
is($oClassGameObjectWorm->name, "Game::Object::Worm", "  Got correct class name");

is(scalar @{$oClassGameObjectWorm->raDocument}, 1, "  Has one Document");
ok(my $oDocumentGameObjectWorm = $oClassGameObjectWorm->raDocument->[0], "    Got document");
like($oDocumentGameObjectWorm->file, qr|Game.Object.Worm.pm$|, "    Document file ok");

is_deeply(
    [ sort keys %{$oClassGameObjectWorm->rhClassBase} ],
    [ "Game::Object" ],
    "  Has the correct base classes",
);

ok(my $oClassGameObjectFromWorm = $oClassGameObjectWorm->rhClassBase->{"Game::Object"}, "  Got Game::Object");





note("Game::Lawn");
isa_ok($oClassLawn, "Devel::PerlySense::Class");
is($oClassLawn->name, "Game::Lawn", "  Got correct class name");

is(scalar @{$oClassLawn->raDocument}, 1, "  Has one Document");
ok(my $oDocumentLawn = $oClassLawn->raDocument->[0], "    Got document");
like($oDocumentLawn->file, qr|Game.Lawn.pm$|, "    Document file ok");

is_deeply(
    [ sort keys %{$oClassLawn->rhClassBase} ],
    [ "Game::Object" ],
    "  Has the correct base classes",
);

ok(my $oClassGameObjectFromLawn = $oClassLawn->rhClassBase->{"Game::Object"}, "  Got Object");



note("Game::Object");
is($oClassGameObjectFromLawn, $oClassGameObjectFromWorm, "Game::Object class are the same");





# is_deeply([ sort $oClass->aNameModuleUse() ],
#           [ sort qw/
#                     Data::Dumper
#                     Game::Location
#                     Game::Direction
#                     Game::Event::Timed
#                     Exception::Class
#                     Class::MethodMaker
#                     / ], "Found used modules ok");




__END__
