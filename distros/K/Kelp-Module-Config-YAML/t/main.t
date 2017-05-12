
# Allow the redefining of globs at Kelp::Module
BEGIN {
    $ENV{KELP_REDEFINE} = 1;
}

use Kelp::Base -strict;
use Kelp;
use Test::More;

my $app = Kelp->new( config_module => 'Config::YAML' );
can_ok $app, $_ for qw/config/;
is $app->config("something"), 1;

done_testing;
