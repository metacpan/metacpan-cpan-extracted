use strict;
use Test::More;

use_ok 'GD::Graph::lines';

my $g = GD::Graph::lines->new();
$g->set(
    x_tick_number => 'auto',
    x_min_value => 100,
    x_max_value => 800,
);

$g->set_legend('Thanks to Bob Rogers');
ok eval { $g->plot([
    [map 100+$_*10,  1 .. 30],
    [map rand() - 0.5, 1..30],
]) } or diag "error: ". ($g->error||$@);

done_testing();
