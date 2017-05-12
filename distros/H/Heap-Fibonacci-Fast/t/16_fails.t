use strict;
use Test::More tests => 12;
use Test::Exception;
use Heap::Fibonacci::Fast;

my $t1 = Heap::Fibonacci::Fast->new();

my $undef = undef;

throws_ok {$t1->remove(undef)} qr/Undef supplied/;
throws_ok {$t1->extract_upto(undef)} qr/Undef supplied/;
throws_ok {$t1->remove($undef)} qr/Undef supplied/;
throws_ok {$t1->extract_upto($undef)} qr/Undef supplied/;

my $t2 = Heap::Fibonacci::Fast->new('max');

throws_ok {$t2->key_insert(1)} qr/Odd number/;
throws_ok {$t2->key_insert(1, undef)} qr/Undef supplied/;
throws_ok {$t2->key_insert(1, $undef)} qr/Undef supplied/;
throws_ok {$t2->insert(1)} qr/not applicable/;

my $t3 = Heap::Fibonacci::Fast->new('code', sub {});

throws_ok {$t3->top_key()} qr/only applicable for keyed/;
throws_ok {$t3->key_insert()} qr/only applicable for keyed/;
throws_ok {$t3->insert(undef)} qr/Undef supplied/;
throws_ok {$t3->insert($undef)} qr/Undef supplied/;
