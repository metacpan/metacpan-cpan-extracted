#!/usr/bin/perl -w
use strict;

use Test::More tests => 57;
use Test::Exception;

use Data::Dumper;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";
my $oLocation;



note("Find sub by name");

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
is(my $package = $oDocument->packageAt(row => 429), "Win32::Word::Writer", "Correct package Table ok");

is($oDocument->oLocationSub(name => "Write", package => "missing package"), undef, "Didn't find missing package declaration");
ok($oLocation = $oDocument->oLocationSub(name => "Write", package => $package), "Found correct declaration");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 396, "  row");
is($oLocation->col, 1, "  col");

ok($oLocation = $oDocument->oLocationSub(name => "main_sub"), "Found correct declaration in default package main");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 132, "  row");
is($oLocation->col, 1, "  col");

ok($oLocation = $oDocument->oLocationSub(name => "NewParagraph", package => $package), "Found correct declaration");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 446, "  row");
is($oLocation->col, 1, "  col");





note("Find the sub at row/col");
$oLocation =  $oDocument->oLocationSubAt(row => 2, col => 1);
ok( ! $oLocation, "Missing sub returned undef") or warn(Dumper($oLocation));

ok(
    ! $oDocument->oLocationSubAt(row => 395, col => 1),
    "Missing sub (edge case: just before) returned undef",
);
ok( $oLocation = $oDocument->oLocationSubAt(row => 396, col => 1), "Found sub on start line");
is($oLocation->row, 396, "  Got correct sub start row");
is($oLocation->col, 1, "  Got correct sub start col");
is($oLocation->rhProperty->{nameSub}, "Write", "  Got correct sub name");
ok(my $oLocationEnd = $oLocation->rhProperty->{oLocationEnd}, "  Got and end oLocation");
is($oLocationEnd->row, 404, "  Got correct sub end row");
is($oLocationEnd->col, 2, "  Got correct sub end col");

ok( $oLocation = $oDocument->oLocationSubAt(row => 404, col => 1), "Found sub on end line");
ok(
    ! $oDocument->oLocationSubAt(row => 405, col => 1),
    "Missing sub (edge case: just after) returned undef",
);

#is($oLocation->file







ok($oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
$fileOrigin = "$dirData/lib/Game/Event/Timed.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
ok($oLocation = $oDocument->oLocationSubDefinition(name => "checkTick", row => 107), "Found sub from col package");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 123, "  row");
is($oLocation->col, 1, "  col");


ok($oLocation = $oDocument->oLocationSubDefinition(name => "checkTick", row => 1), "Found sub from col package main");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 21, "  row");
is($oLocation->col, 1, "  col");



ok($oLocation = $oDocument->oLocationSubDefinition(name => "checkTick", package => "main"), "Found sub from param package main");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 21, "  row");
is($oLocation->col, 1, "  col");


ok($oLocation = $oDocument->oLocationSubDefinition(name => "checkTick"), "Found sub from default package main");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 21, "  row");
is($oLocation->col, 1, "  col");


ok($oLocation = $oDocument->oLocationSubDefinition(name => "checkTick", package => "Game::Event::Timed"), "Found sub from default package main");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 123, "  row");
is($oLocation->col, 1, "  col");






print "\n*** Parent modules\n";

$dirData = "data/project-lib";
my $rexFileDest = qr/Game.Object.Worm.pm/;

ok($oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
$fileOrigin = "$dirData/Game/Object/Worm/Bot.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
ok($oLocation = $oDocument->oLocationSubDefinition(name => "loadFile", package => "Game::Object::Worm::Bot"), "Found sub in parent package");
like($oLocation->file, $rexFileDest, " Got file");
is($oLocation->row, 360, "  row");
is($oLocation->col, 1, "  col");




__END__
