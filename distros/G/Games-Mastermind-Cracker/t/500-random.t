use strict;
use warnings;
use Test::More tests => 1;
use Games::Mastermind::Cracker::Random;

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

my $gmcr = Games::Mastermind::Cracker::Random->new(
    get_result => sub { @{ $results{+pop} } },
    holes      => 3,
    pegs       => [qw/A B/],
);

is($gmcr->crack, "ABA", "ABA solution found.");

