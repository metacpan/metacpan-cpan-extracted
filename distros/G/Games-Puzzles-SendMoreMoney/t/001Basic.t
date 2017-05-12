######################################################################
# Test suite for Games::Puzzles::SendMoreMoney
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok('Games::Puzzles::SendMoreMoney') };
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

use Games::Puzzles::SendMoreMoney;

my $solver = Games::Puzzles::SendMoreMoney->new(
    values    => [1,2],
    puzzle    => "A = B + 1",
    reporter  => sub { $Games::Puzzles::SendMoreMoney::STOP_SOLVER = 1; },
);

my $results = $solver->solve();
is($results->[0]->{A}, "2", "Simple puzzle");
is($results->[0]->{B}, "1", "Simple puzzle");
