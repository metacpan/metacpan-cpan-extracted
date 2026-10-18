use strict;
use warnings;
use Test::More;

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

# THE BUDGET IS NODES, plan_game_senet/07. The first level always finishes; a
# deeper level that runs out part way is thrown away; nothing reads a clock.

my $START = 'dldldldldl/........../.......... l 5';
my $MID   = '.l.dl..d../.l.d....l./d...l..... l 5';

subtest 'the node count never passes the budget by more than the first level' => sub {
    for my $pos ($START, $MID) {
        my $bd = $E->new(position => $pos);
        my $first = $bd->search(3, rules => 'kendall', depth => 1)->{nodes};
        for my $budget (1, 10, 100, 1_000, 10_000, 50_000) {
            my $found = $bd->search(3, rules => 'kendall', budget => $budget);
            my $ceiling = ($budget > $first ? $budget : $first) + 1;
            cmp_ok($found->{nodes}, '<=', $ceiling, "budget $budget: $found->{nodes} nodes, depth $found->{depth}");
        }
    }
};

subtest 'a budget of 1 still answers' => sub {
    my $found = $E->new(position => $START)->search(3, rules => 'kendall', budget => 1);
    is($found->{depth}, 1, 'the first level finished');
    cmp_ok($found->{index}, '>=', 0, 'and a move was chosen');
};

subtest 'a larger budget never reaches a shallower depth' => sub {
    my $bd = $E->new(position => $MID);
    my ($last, @bad) = (0);
    for my $budget (map { 2 ** $_ } 0 .. 18) {
        my $depth = $bd->search(4, rules => 'skyruk', budget => $budget)->{depth};
        push @bad, "$budget: $depth after $last" if $depth < $last;
        $last = $depth;
    }
    is("@bad", '', "from a budget of 1 to 262,144, the depth only grows (to $last)");
};

subtest 'a level the budget cut short is thrown away' => sub {
    my ($stopped, @bad) = (0);
    for my $pos ($START, $MID) {
        my $bd = $E->new(position => $pos);
        for my $roll (1 .. 5) {
            for my $budget (map { 3 ** $_ } 2 .. 9) {
                my $found = $bd->search($roll, rules => 'skyruk', budget => $budget);
                next unless $found->{stopped};
                $stopped++;
                my $whole = $bd->search($roll, rules => 'skyruk', depth => $found->{depth});
                push @bad, "roll $roll budget $budget" unless $whole->{index} == $found->{index}
                                                           && $whole->{value} == $found->{value};
            }
        }
    }
    cmp_ok($stopped, '>', 10, "$stopped searches stopped part way through a level");
    is("@bad", '', 'and each answered the move and value of the last level it finished');
};

subtest 'the same arguments, the same answer, in another process' => sub {
    my $here = join ',', map { my $f = $E->new(position => $MID)->search($_, rules => 'kendall', budget => 20_000);
                               "$f->{index}/$f->{nodes}/$f->{depth}/$f->{value}" } 1 .. 5;
    my $code = 'use Game::Senet::Engine; print join q{,}, map { my $f = Game::Senet::Engine->new(position => q{'
             . $MID . '})->search($_, rules => q{kendall}, budget => 20_000); "$f->{index}/$f->{nodes}/$f->{depth}/$f->{value}" } 1 .. 5';
    my $there = `"$^X" -Mblib -e '$code'`;
    is($there, $here, 'five searches agree, index, nodes, depth and value');
};

subtest 'a budget the XSUB cannot hold is refused, not wrapped' => sub {
    my $bd = $E->new(position => $START);
    ok(!eval { $bd->search(3, rules => 'kendall', budget => 2 ** 31); 1 }, 'a budget of 2^31 croaks');
    like($@, qr/a budget is a whole number of nodes from 0 to 2000000000/, '  saying what a budget is');
    ok(!eval { $bd->search(3, rules => 'kendall', budget => -1); 1 }, 'and so does -1');
    ok(!eval { $bd->search(3, rules => 'kendall', depth => 33); 1 }, 'and a depth of 33');
    ok(!eval { $bd->search(3, rules => 'kendall', budgte => 5); 1 }, 'and an option that is not one');
};

done_testing();
