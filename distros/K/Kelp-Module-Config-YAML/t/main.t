
# Allow the redefining of globs at Kelp::Module
BEGIN {
    $ENV{KELP_REDEFINE} = 1;
}

use Kelp::Base -strict;
use Kelp;
use Test::More;

my $app = Kelp->new( config_module => 'Config::YAML', mode => 'test' );
can_ok $app, $_ for qw/config/;
is $app->config("something"), 1;
is $app->config("hash.something"), 2;

my $array = $app->config('array');
is scalar @$array, 3, 'array count ok';
is $array->[0], 'something1';
is $array->[1], 'something2';
is $array->[2], 'something3';

done_testing;

