use Test::More tests => 2;
use Games::Goban;

use strict;

my $board = Games::Goban->new;

my $k = $board->register(sub { my ($k, $b) = @_; $b->notes($k)->{moves}++; });

$board->move('aa');
is($board->notes($k)->{moves}, 1, "one move captured by callback");

$board->move('qp');
is($board->notes($k)->{moves}, 2, "two moves captured by callback");
