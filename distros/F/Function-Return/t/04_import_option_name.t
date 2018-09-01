use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Function::Return name => 'Hoge';
use Types::Standard -types;

sub single :Hoge(Str) { @_ }

ok(!exception { single('hello') });
like(exception { single({}) }, qr!Invalid return!);

done_testing;
