use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

# WALKS AGAINST THE SEARCH. The engine's reach visits each hole once. Here a
# chain may go anywhere it likes, revisiting holes, for as many hops as the
# longest simple chain could need (a chain keeps the hop class, and the largest
# class is 37 holes, so 36 hops). The search is layered by the number of hops
# taken, so a revisit is a new state and nothing is pruned for having been seen.
# It uses only hops() and steps(), which t/07-twin.t holds to the twin.

sub walk_reach {
    my ($bd, $from) = @_;
    my %stop = map { $_ => 1 } $bd->steps($from);
    my %layer = ($from => 1);
    for my $depth (1 .. 36) {
        my %next;
        for my $at (keys %layer) {
            $next{$_} = 1 for $bd->hops($at, $from);
        }
        last unless %next;
        $stop{$_} = 1 for keys %next;
        %layer = %next;
    }
    delete $stop{$from};
    return join ',', sort { $a <=> $b } keys %stop;
}

srand 20261016;
my ($boards, $pieces, $agree) = (0, 0, 1);
my @first_bad;
for my $seats (2, 3, 4, 6) {
    for my $k (1 .. 125) {
        my $bd = $E->new(seats => $seats, empty => 1);
        my @free = 0 .. HOLES - 1;
        my $per = 10;
        for my $seat (0 .. $seats - 1) {
            $bd->put(splice(@free, int rand @free, 1), $seat) for 1 .. $per;
        }
        $boards++;
        for my $h (grep { defined $bd->at($_) } 0 .. HOLES - 1) {
            $pieces++;
            my $walk = walk_reach($bd, $h);
            my $search = join ',', $bd->reach($h);
            next if $walk eq $search;
            $agree = 0;
            push @first_bad, $bd->to_string . " from $h\n  walks:  $walk\n  search: $search" if @first_bad < 3;
        }
    }
}
is($boards, 500, '500 random boards');
cmp_ok($pieces, '>', 15_000, "$pieces pieces");
ok($agree, '  and on every one the walks reach exactly what the search reaches')
    or diag join "\n", @first_bad;

done_testing();
