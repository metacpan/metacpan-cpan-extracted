use Test::More;

use_ok 'GD::Graph::radar';

my $g = GD::Graph::radar->new(400, 400);
isa_ok $g, 'GD::Graph::radar';

done_testing();
