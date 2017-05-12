#!/usr/bin/perl -w
use strict;

use Test::More tests => 53;
use Test::Exception;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Document::Api");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }

my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm/Bot.pm";
my $nameModule = "Game::Object::Worm::Bot";
my $rexFile = qr/Game.Object.Worm.Bot.pm$/;

my $oLocation;
my $oNode;
my $method;


print "\n* Class\n";

ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

ok(my $oApi = Devel::PerlySense::Document::Api->new(), "new ok");

$method = "probabilityTurnRandomly";
ok($oLocation = $oApi->oLocationSetSub(nameSub => $method, oDocument => $oDocument), " oLocationSetSub without node ok");
like($oLocation->file, $rexFile, "  file correct");
is($oLocation->row, 0, "  row correct");
is($oLocation->col, 0, "  row correct");
is($oLocation->rhProperty->{sub}, $method, "  rhProperty->sub correct");


$method = "moveForward";
ok($oNode = oNodeSub($oDocument, $method), "Got node");

ok($oLocation = $oApi->oLocationSetSub(nameSub => $method, oDocument => $oDocument, oNode => $oNode), " oLocationSetSub without node ok");
like($oLocation->file, $rexFile, "  file correct");
is($oLocation->row, 131, "  row correct");
is($oLocation->col, 1, "  row correct");
is($oLocation->rhProperty->{sub}, $method, "  rhProperty->sub correct");


is_deeply([ sort keys %{$oApi->rhSub} ],
          [ sort qw(
                    probabilityTurnRandomly
                    moveForward
                ) ], "rhSub contains the ok keys");






print "\n* Base class\n";
$fileOrigin = "$dirData/Game/Object/Worm.pm";
$nameModule = "Game::Object::Worm";
my $rexFileBase = qr/Game.Object.Worm.pm$/;


ok(my $oDocumentBase = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
ok($oDocumentBase->parse(file => $fileOrigin), "Parsed file ok");

ok(my $oApiBase = Devel::PerlySense::Document::Api->new(), "new ok");


$method = "isRealPlayer";
ok($oLocation = $oApiBase->oLocationSetSub(nameSub => $method, oDocument => $oDocumentBase), " oLocationSetSub without node ok");
like($oLocation->file, $rexFileBase, "  file correct");
is($oLocation->row, 0, "  row correct");
is($oLocation->col, 0, "  row correct");
is($oLocation->rhProperty->{sub}, $method, "  rhProperty->sub correct");


$method = "moveForward";
ok($oNode = oNodeSub($oDocumentBase, $method), "Got node");

ok($oLocation = $oApiBase->oLocationSetSub(nameSub => $method, oDocument => $oDocumentBase, oNode => $oNode), " oLocationSetSub without node ok");
like($oLocation->file, $rexFileBase, "  file correct");
is($oLocation->row, 186, "  row correct");
is($oLocation->col, 1, "  row correct");
is($oLocation->rhProperty->{sub}, $method, "  rhProperty->sub correct");



$method = "turn";
ok($oNode = oNodeSub($oDocumentBase, $method), "Got node");

ok($oLocation = $oApiBase->oLocationSetSub(nameSub => $method, oDocument => $oDocumentBase, oNode => $oNode), " oLocationSetSub without node ok");
like($oLocation->file, $rexFileBase, "  file correct");
is($oLocation->row, 253, "  row correct");
is($oLocation->col, 1, "  row correct");
is($oLocation->rhProperty->{sub}, $method, "  rhProperty->sub correct");


is_deeply([ sort keys %{$oApiBase->rhSub} ],
          [ sort qw(
                    isRealPlayer
                    moveForward
                    turn
                ) ], "rhSub contains the ok keys");







print "\n* Merging\n";

ok($oApi->mergeWithBase($oApiBase), "Merge ok");

is_deeply([ sort keys %{$oApi->rhSub} ],
          [ sort qw(
                    isRealPlayer
                    moveForward
                    turn
                    
                    probabilityTurnRandomly
                ) ], "rhSub contains the ok keys");

$method = "isRealPlayer";
ok($oLocation = $oApi->rhSub->{$method}, "Got method");
like($oLocation->file, $rexFileBase, "  file correct");
is($oLocation->row, 0, "  row correct");

$method = "moveForward";
ok($oLocation = $oApi->rhSub->{$method}, "Got method");
like($oLocation->file, $rexFile, "  file correct");
is($oLocation->row, 131, "  row correct");

$method = "turn";
ok($oLocation = $oApi->rhSub->{$method}, "Got method");
like($oLocation->file, $rexFileBase, "  file correct");
is($oLocation->row, 253, "  row correct");

$method = "probabilityTurnRandomly";
ok($oLocation = $oApi->rhSub->{$method}, "Got method");
like($oLocation->file, $rexFile, "  file correct");
is($oLocation->row, 0, "  row correct");







sub oNodeSub {
    my ($oDocument, $name) = @_;

    $oDocument->oDocument->find_first(
        sub {
            my ($oTop, $oNode) = @_;
            $oNode->isa("PPI::Statement::Sub") && $oNode->name eq $name and return(1);
            return(0);
        });
}




__END__
