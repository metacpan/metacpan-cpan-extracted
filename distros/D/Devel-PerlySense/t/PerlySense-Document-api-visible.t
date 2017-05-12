#!/usr/bin/perl -w
use strict;

use Test::More tests => 25;
use Test::Exception;

use File::Basename;
use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Api");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


{
        
    my $dirData = "data/project-lib";
    my $fileOrigin = "$dirData/Game/Object/WormVisible.pm";
    my $nameModule = "Game::Object::WormVisible";

    my ($object, $method, $oNodeSub);
    my (@aMethod);
    my $oApi;
    my $oLocation;
    my $rexFileWorm = qr/.Game.Object.WormVisible.pm$/;
    my $rexFileObject = qr/.Game.ObjectVisible.pm$/;
    my $rexFileTable = qr/.Writer.TableVisible.pm$/;

    my $dirCpanFake = "data/simple-lib/lib";

    #So that Win32::Word::Writer::TableVisible can be found outside of the project
    local @INC;
    push(@INC, $dirCpanFake);

    #Limit what the project is
    no warnings;
    local *Devel::PerlySense::Project::dirProject = sub {
        $dirData;
    };


    my $oPs = Devel::PerlySense->new();
    ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => $oPs), "new ok");


    print "\n* MI inheritance, one project ancestor, one CPAN ancestor\n";

    ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

    ok($oDocument->determineLikelyApi("nameModule", $nameModule), " determineLikelyApi ok");
    is(scalar(keys %{$oDocument->rhPackageApiLikely}), 1, " rhPackageApiLikely key count ok")
            or die(Dumper($oDocument->rhPackageApiLikely));
    ok($oApi = $oDocument->rhPackageApiLikely->{$nameModule}, " Got Game::Object::WormVisible API");

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
                       _buildBodyRight

                       init
                       ColumnBegin
                       createdColumnCount
                       columnPos
                       alreadyCreatedRow
                       oWriter
                       _privateTableMethod

                       /],
              " API raSub ok");

    ok($oLocation = $oApi->rhSub->{_buildBodyRight}, " Got location for _buildBodyRight");
    like($oLocation->file, $rexFileObject, "   Correct file name");
    is($oLocation->row, 153, "   row");
    is($oLocation->col, 1, "   col");
    is($oLocation->rhProperty->{sub}, "_buildBodyRight", "   rhProperty->sub");

    ok($oLocation = $oApi->rhSub->{new}, " Got location for new");
    like($oLocation->file, $rexFileWorm, "   Correct file name");
    is($oLocation->row, 142, "   row");
    is($oLocation->col, 1, "   col");
    is($oLocation->rhProperty->{sub}, "new", "   rhProperty->sub");

    ok($oLocation = $oApi->rhSub->{_privateTableMethod}, " Got location for _privateTableMethod");
    like($oLocation->file, $rexFileTable, "   Correct file name");
    is($oLocation->row, 122, "   row");
    is($oLocation->col, 1, "   col");
    is($oLocation->rhProperty->{sub}, "_privateTableMethod", "   rhProperty->sub");

    is_deeply(
        [sort $oApi->aNameSubVisible(
            oPerlySense => $oPs,
            fileCurrent => $fileOrigin,
        )],
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
                    _buildBodyRight

                    init
                    ColumnBegin
                    createdColumnCount
                    columnPos
                    alreadyCreatedRow
                    oWriter
                /],
        " API aNameSubVisible ok");
    
    
    #print Dumper($oLocation);
    #print Dumper([ sort keys %{$oApi->rhSub} ]);

}





__END__
