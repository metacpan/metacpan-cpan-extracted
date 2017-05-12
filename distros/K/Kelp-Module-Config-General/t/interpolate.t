use strict;
use warnings;

use Kelp::Base -strict;
use Kelp;
use Test::More;

my $app = Kelp->new( mode => 'interpolate', config_module => 'Config::General' );

can_ok $app, 'config';
is $app->config('something'), 'value';

done_testing;