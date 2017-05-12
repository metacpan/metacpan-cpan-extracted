#!/usr/bin/perl -w
use strict;

use Test::More tests => 19;
use Test::Exception;
use Test::Differences;

use Data::Dumper;


use lib "lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Class");
use_ok("Devel::PerlySense::Editor::Emacs");



throws_ok(
    sub { Devel::PerlySense::Editor::Emacs->new(
    ) },
    qr/oPerlySense/,
    "new fails ok with missing name",
);

lives_ok(
    sub { Devel::PerlySense::Editor::Emacs->new(
        oPerlySense => Devel::PerlySense->new(),
        widthDisplay => undef,
    ) },
    "new ok with name",
);




ok(my $oPerlySense = Devel::PerlySense->new(), "Created PerlySense object ok");
ok(
    my $oEditor = Devel::PerlySense::Editor::Emacs->new(
        oPerlySense => $oPerlySense,
        widthDisplay => 59,
    ),
    "Created Editor ok",
);
$oEditor->widthDisplay(70);


my $s = " ";
my $sNone = "       ";


{
    my $dirData = "t/data/project-lib";
    my $fileOrigin = "$dirData/Game/Object/Worm/ShaiHulud.pm";

    ok(
        my $oClassOjectWormShai = Devel::PerlySense::Class->newFromFileAt(
            oPerlySense => $oPerlySense,
            file => $fileOrigin,
            row => 20,
            col => 1,
        ),
        "newFromFileAt at proper package location ok",
    );

    $oPerlySense->setFindProject(file => $fileOrigin);
    local $oPerlySense->rhConfig->{bookmark} = [
        {
            moniker => "Todo",
            rex => 'qr/\# \s* TODO: \s* ( .+ )/x',
        },
        {
            moniker => "Note",
            rex => 'qr/\# \s* XXX \s* .+/x',
        },
    ];


    ok(
        my $textShai = $oEditor->classOverview(
            oClass => $oClassOjectWormShai,
            raShow => [ @{$oEditor->raClassOverviewShowDefault}, "neighbourhood" ],
        ),
        " render classOverview ok",
    );
    #warn("-----\n$textShai\n-----\n");
    my $textExpected = q/* Inheritance *
[ Game::Object                  ] <-----+
[ Game::Object::Worm            ]       |
[<Game::Object::Worm::ShaiHulud>] --> [ Game::Lawn ]

* API *
\>color
\>height
\>isBlocking
\>isRealPlayer
\>lengthIdeal
\>oController
\>oDirection
\>oEventMove
\>oLawn
\>oLocation, $value)
->oppositeDirection
\>oUI
->probabilityTurnRandomly
->probabilityTurnTowardsPrize
\>raBodyChar
\>raBodyLocation
->randomDirection
\>rhGrid
\>rhPrize
\>score
\>width
\>awardScorePoints($points)
\>buildBodyRight($length, $oLocation, $rcChar)
\>checkTick($timeWorld)
\>crash()
\>END
\>grow([$sizeIncrease = 1])
\>isAnythingAt($oLocation)
\>isAnythingBlockingAt($oLocation)
\>isLocationOnLawn($oLocation)
\>isLocationValidForMove($oObject, $oLocation)
\>isLocationValidForPlacement($oLocation)
\>isObjectAt($oObject, $left, $top)
\>isObjectLocationValidForPlacement($oObject)
\>lengthActual
\>loadFile($file)
\>moveForward()
->new([$left = 11], [$top = 12], [$direction = "left"], [$length = 3)
\>objectHasMoved($oObject)
\>oDirectionToPrize($oLocation)
\>oLocationRandom()
\>oPlacePrize($oLocation, $value)
\>oPlaceWorm($left, $top)
\>oValidLocationAfterMove()
\>placeObjectAt($oObject)
\>placeObjectBodyPartAt($oObject, $oLocation, $char)
->possiblyTurnRandomly()
->possiblyTurnTowardsPrize()
\>prizeWasClaimedBy($oPrize, $oObject)
\>removeObject($oObject)
\>removeObjectBodyPartAt($oObject, $oLocation)
\>turn($direction)
\>wormHasCrashed($oObject)

* Bookmarks *
- Todo
ShaiHulud.pm:76: Fix something here
ShaiHulud.pm:127: Find a Prize
ShaiHulud.pm:134: Turn
- Note
ShaiHulud.pm:96:         #XXX fix before checkin

* Uses *
[ Carp ] [ Class::MethodMaker ] [ Data::Dumper ]

* NeighbourHood *
[ Game::Object::Prize       ] [ Game::Object::Worm::Bot       ] -none-
[ Game::Object::Wall        ] [<Game::Object::Worm::ShaiHulud>]
[ Game::Object::Worm        ] [ Game::Object::Worm::Shaitan   ]
[ Game::Object::WormVisible ]/;

    # The inheritance diagram is a bit flaky, test it separetly from
    # the rest of the output
    my ($expectedInheritance, $expectedRest) = split(/\Q* API */, $textExpected);
    my ($shaiInheritance, $shaiRest) = split(/\Q* API */, $textShai);
    eq_or_diff(
        $shaiRest,
        $expectedRest,
        "  And got correct overview output",
    );

    note "Don't compare the exact diagram, it's not deterministic.";
    note "Just make sure all the classes are on there";
    sub get_classes {
        my ($text) = @_;
        return sort ( $text =~ / \[ \s+ ([\w:]+) /xgsm );
    }
    eq_or_diff(
        [ get_classes($shaiInheritance) ],
        [ get_classes($expectedInheritance) ],
        "  And got correct inheritance output",
    );


# * Structure *
# ==;"";;;;===;==S{;;;;";;;;}=S{;;{;'{;;";};}";}=S{;{";";";;'
# {;;";};}";};


}



{
    my $dirData = "t/data/project-lib";
    my $fileOrigin = "$dirData/Game/Object.pm";

    ok(
        my $oClassOject = Devel::PerlySense::Class->newFromFileAt(
            oPerlySense => $oPerlySense,
            file => $fileOrigin,
            row => 1,
            col => 1,
        ),
        "newFromFileAt at proper package location ok",
    );


    ok(
        my $textShai = $oEditor->classOverview(
            oClass => $oClassOject,
            raShow => [ @{$oEditor->raClassOverviewShowDefault}, "neighbourhood" ],
        ),
        " render classOverview ok",
    );
    #warn("-----\n$textShai\n-----\n");

    my $textInheritance = q/* Inheritance *
[<Game::Object>]/;
    my $textApi = q/* API *
->color      ->raBodyChar
->isBlocking ->raBodyLocation
->oLawn      ->buildBodyRight($length, $oLocation, $rcChar)
->oLocation  ->new($oLocation)/;
    my $textBookmarks = q/* Bookmarks */;
    my $textUses = q/* Uses *
[ Class::MethodMaker ] [ Game::Event::Timed ]
[ Data::Dumper       ] [ Game::Location     ]/;
    my $textNeighbourHood = q/* NeighbourHood *
-none- [ Game::Application   ] [ Game::Object::Prize       ]
       [ Game::Controller    ] [ Game::Object::Wall        ]
       [ Game::Direction     ] [ Game::Object::Worm        ]
       [ Game::Lawn          ] [ Game::Object::WormVisible ]
       [ Game::Location      ]
       [<Game::Object       >]
       [ Game::ObjectVisible ]
       [ Game::UI            ]/;


    my $textExpectedAll = qq/$textInheritance

$textApi

$textBookmarks

$textUses

$textNeighbourHood/;

    eq_or_diff($textShai, $textExpectedAll, "  And got correct output");

# * Structure *
# ==;;;;;==;=;=;=;=;=;==S{;;;;";;;;;;;}=S{;;{;;}";;};


    my $rhTest = {
        inheritance => $textInheritance,
        api => $textApi,
        bookmarks => $textBookmarks,
        uses => $textUses,
        neighbourhood => $textNeighbourHood,
    };

    for my $show (sort keys %$rhTest) {
        note("Testing ($show)");
        my $textRendered = $oEditor->classOverview(
            oClass => $oClassOject,
            raShow => [ $show ],
        );
        eq_or_diff($textRendered, $rhTest->{$show}, "  And got correct output for ($show)");
    }

}





__END__


+-------------------------------+
[         Game::Object          ] <-----+
+-------------------------------+       |
  ^                                     |
  |                                     |
  |                                     |
+-------------------------------+       |
[      Game::Object::Worm       ]       |
+-------------------------------+       |
  ^                                     |
  |                                     |
  |                                     |
+-------------------------------+     +------------+
[ Game::Object::Worm::ShaiHulud ] --> [ Game::Lawn ]
+-------------------------------+     +------------+



.................................
:         Game::Object          : <-----+
:...............................:       |
  ^                                     |
  |                                     |
  |                                     |
.................................       |
:      Game::Object::Worm       :       |
:...............................:       |
  ^                                     |
  |                                     |
  |                                     |
.................................     ..............
: Game::Object::Worm::ShaiHulud : --> : Game::Lawn :
:...............................:     :............:
