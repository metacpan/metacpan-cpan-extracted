use strict;
use warnings;
use Test::More tests => 2;
use Games::Mastermind::Cracker::Sequential;

# correct tune: ABA
my %results = (
    AAA => [2, 0],
    AAB => [2, 1],
    ABA => [3, 0],
    ABB => [2, 0],
    BAA => [1, 2],
    BAB => [0, 2],
    BBA => [2, 0],
    BBB => [1, 0],
);

my @expected_guesses = qw/AAA AAB ABA/;
my @guesses;

my $gmcr = Games::Mastermind::Cracker::Sequential->new(
    get_result => sub { push @guesses, pop; @{ $results{$guesses[-1]} } },
    holes      => 3,
    pegs       => [qw/A B/],
);

is($gmcr->crack, "ABA", "ABA solution found.");
is_deeply(\@guesses, \@expected_guesses, "Guesses were sequential, and stopped when the solution was found.");

