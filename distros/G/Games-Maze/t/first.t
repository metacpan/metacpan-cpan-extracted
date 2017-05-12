# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::Simple tests => 2;

use Games::Maze;

my $minos = Games::Maze->new();
$minos->make();
my $theseus = $minos->new();
my $xd_minos = $minos->to_hex_dump();
my $xd_theseus = $theseus->to_hex_dump();

ok(($xd_minos eq $xd_theseus), "Copy test");

$minos = Games::Maze->new(cell => 'hex', form => 'hexagon');
$minos->make();
$theseus = $minos->new();
$xd_minos = $minos->to_hex_dump();
$xd_theseus = $theseus->to_hex_dump();

ok(($xd_minos eq $xd_theseus), "Copy test X");

