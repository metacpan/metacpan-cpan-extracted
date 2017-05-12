use strict;
use warnings;

use Test::More tests => 6;
use Test::Deep;

require_ok('Log::Dispatch');
require_ok('Log::Dispatch::Array');

my $dispatcher = Log::Dispatch->new;
isa_ok($dispatcher, 'Log::Dispatch');

my $array_dispatch = Log::Dispatch::Array->new(
  name      => 'test_logger',
  min_level => 'debug',
);

isa_ok($array_dispatch, 'Log::Dispatch::Array');
isa_ok($array_dispatch, 'Log::Dispatch::Output');

$dispatcher->add($array_dispatch);

$dispatcher->alert("this is your face");
$dispatcher->alert("this is your face on drugs");

cmp_deeply(
  $array_dispatch->array,
  [
    superhashof({ message => 'this is your face' }),
    superhashof({ message => 'this is your face on drugs' }),
  ],
  "we logged stuff",
);

