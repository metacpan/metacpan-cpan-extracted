use strict;
use warnings;

use Kelp::Base -strict;
use Kelp;
use Test::More;
$ENV{KELP_CONFIG_DIR} = "./t/conf/";

my $app = Kelp->new( mode => 'include_mode', config_module => 'Config::General' );

can_ok $app, 'config';
is $app->config('something'), 1;
is $app->config('againdata.key'), 'value';

done_testing;
