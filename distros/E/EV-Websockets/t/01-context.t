use strict;
use warnings;
use Test::More;
use EV;

use_ok('EV::Websockets');

my $ctx = EV::Websockets::Context->new();
ok($ctx, 'Context created with default loop');

undef $ctx;
pass('Context destroyed without error');

done_testing;
