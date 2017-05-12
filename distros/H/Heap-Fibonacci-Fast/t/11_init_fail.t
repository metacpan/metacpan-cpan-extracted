use strict;
use Test::More tests => 3;
use Test::Exception;
use Heap::Fibonacci::Fast;

throws_ok {Heap::Fibonacci::Fast->new('wrong')} qr/Unknown type supplied/;
throws_ok {Heap::Fibonacci::Fast->new('code')} qr/valid coderef/;
throws_ok {Heap::Fibonacci::Fast->new('code', 12)} qr/valid coderef/;
