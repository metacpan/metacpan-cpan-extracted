use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine;
use Game::Shogi::Move;
my $E = 'Game::Shogi::Engine';
my $M = 'Game::Shogi::Move';

# ---- every legal move of real positions round-trips -----------------------------------

{
    srand(20261015);
    my ($moves, $bad, $drops) = (0, 0, 0);
    my $b = $E->new;
    for my $ply (1 .. 300) {
        my @legal = $b->legal;
        if (!@legal) { $b = $E->new; next }
        for my $usi (@legal) {
            my $m = $M->of($usi);
            $moves++;
            $drops++ if $m && $m->is_drop;
            $bad++ unless $m && $m->usi eq $usi;
            my $again = $m && ($m->is_drop
                ? $M->of_parts(drop => $m->drop, to => $m->to)
                : $M->of_parts(from => $m->from, to => $m->to, promote => $m->promote));
            $bad++ unless $again && $again->usi eq $usi;
        }
        $b->do_move($legal[ int rand @legal ]);
    }
    is($bad, 0, "$moves legal moves read and rebuilt from their parts, unchanged");
    cmp_ok($drops, '>', 0, "  $drops of them drops");
}

# ---- the parts ------------------------------------------------------------------------

{
    my $m = $M->of('8h2b+');
    is_deeply([ $m->from, $m->to, $m->promote, $m->drop, $m->is_drop ], [ '8h', '2b', 1, undef, 0 ],
        '8h2b+: from 8h, to 2b, promoting');
    my $d = $M->of('P*5e');
    is_deeply([ $d->from, $d->to, $d->promote, $d->drop, $d->is_drop ], [ undef, '5e', 0, 'P', 1 ],
        'P*5e: a pawn dropped on 5e');
    is($M->new(usi => '7g7f')->usi, '7g7f', 'new takes a USI move');
}

# ---- what is not a move ------------------------------------------------------------------

for my $bad ('7g7g', '7g', 'p*5e', 'K*5e', '+P*5e', '7g7f++', '0a1a', '7j7f', 'P*5', '7g7f ', '', undef) {
    my $show = defined $bad ? "'$bad'" : 'undef';
    is($M->of($bad), undef, "$show is not a move");
    ok(!eval { $M->new(usi => $bad); 1 }, '  and new croaks on it');
}
ok(!eval { $M->new(usii => '7g7f'); 1 }, 'a misspelt attribute name is not a move either');
is($M->of_parts(from => '7g', to => '7g'), undef, 'nor are parts that make a move to where it stands');

done_testing();
