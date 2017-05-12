#

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok('Log::Dispatch');
    use_ok('Log::Dispatch::MacGrowl');
}

my $dispatcher = Log::Dispatch->new;
isa_ok($dispatcher, 'Log::Dispatch');

my $growl_dispatch = Log::Dispatch::MacGrowl->new(
    name => 'growl',
    min_level => 'debug',
);

isa_ok($growl_dispatch, 'Log::Dispatch::MacGrowl');
isa_ok($growl_dispatch, 'Log::Dispatch::Output');

$dispatcher->add($growl_dispatch);

