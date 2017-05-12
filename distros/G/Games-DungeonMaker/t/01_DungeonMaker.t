#########################

use Test::More tests => 5;

#########################

BEGIN { use_ok( 'Games::DungeonMaker' ); }
require_ok( 'Games::DungeonMaker' );

open(IN, "<t/design") || BAIL_OUT('could not load design file');#die "$!\n";
my @lines = <IN>;
close IN;

my $dm = Games::DungeonMaker->new(join('', @lines));
ok(defined $dm, 'constructor');
ok($dm->plonk(), 'plonk');
cmp_ok($dm->getMap(0,0), '==', 3, 'generate');

