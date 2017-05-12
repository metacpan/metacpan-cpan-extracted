use strict;
use warnings;
use Games::SGF::Go::Rotator;

use lib 't/lib';
use Games::SGF::Go::Rotator::Test;

use Test::More tests => 2;

local $/ = undef;

my $sgf = Games::SGF::Go::Rotator->new();
$sgf->readFile("t/normal-game.sgf");
$sgf->rotate90();

open(my $rot90fh, 't/normal-game-90.sgf') || die("Can't open rot90 file");
is(normalize($sgf->writeText()), normalize(<$rot90fh>), "90 degree rotation works");

$sgf = Games::SGF::Go::Rotator->new();
$sgf->readFile("t/normal-game.sgf");
$sgf->rotate();

open(my $rot180fh, 't/normal-game-180.sgf') || die("Can't open rot180 file");
is(normalize($sgf->writeText()), normalize(<$rot180fh>), "180 degree rotation works");
