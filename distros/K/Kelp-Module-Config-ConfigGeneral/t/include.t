use strict;
use warnings;

use Kelp::Base -strict;
use Kelp;
use Test::More;

my $app = Kelp->new( mode => 'include_mode', config_module => 'Config::ConfigGeneral' );

can_ok $app, 'config';
is $app->config('something'), 1;
is $app->config('againdata.key'), 'value';

done_testing;
