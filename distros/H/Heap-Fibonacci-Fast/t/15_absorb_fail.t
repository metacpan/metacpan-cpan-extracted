use strict;
use Test::More skip_all => "Not yet done";
#use Test::More tests => 3;
use Test::Exception;
use Heap::Fibonacci::Fast;

sub cmp1 {}
sub cmp2 {}

my $t1 = Heap::Fibonacci::Fast->new();
my $t2 = Heap::Fibonacci::Fast->new('code', \&cmp1);
my $t3 = Heap::Fibonacci::Fast->new('code', \&cmp2);
my $t4 = Heap::Fibonacci::Fast->new('code', \&cmp2);

throws_ok {$t1->absorb($t2)} qr/different types/;
throws_ok {$t2->absorb($t3)} qr/different compare callbacks/;
lives_ok  {$t3->absorb($t4)};
