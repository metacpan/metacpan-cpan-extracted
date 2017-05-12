use strict;
use warnings;
use Test::More tests => 3;
use Games::Mastermind::Cracker::Basic;

# correct tune: DEADEE
my %results;
my @guesses;

my $gmcb = Games::Mastermind::Cracker::Basic->new(
    get_result => sub { push @guesses, pop; @{ $results{$guesses[-1]} } },
    holes      => 5,
    pegs       => ['A' .. 'G'],
);

%results = map { $_ => [$gmcb->score($_, 'DEADE')] }
           keys %{ $gmcb->all_codes };

is(keys %results, 16807, "16807 possible 5x A..G codes");
is($gmcb->crack, "DEADE", "DEADE solution found.");
cmp_ok(@guesses, '<', 50, "got it in less than 50/16807 guesses")
    or diag join ', ', @guesses;

