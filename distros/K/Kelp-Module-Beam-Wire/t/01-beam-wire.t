use strict;
use warnings;

use Test::More;
use Kelp;

my $app = Kelp->new(mode => 'test');

can_ok $app, 'container';
is $app->can('container'), Kelp->can('container'), 'same container method ok';

isa_ok $app->container, 'Beam::Wire';
is $app->container->get('app'), Kelp->container->get('app'), 'Kelp instance available ok';

done_testing;

