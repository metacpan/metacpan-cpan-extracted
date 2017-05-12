use strict;
use warnings;
use Test::More tests => 6;

use Hash::Type;


my $t = Hash::Type->new('a' .. 'f');

my $h1 = $t->new(1 .. 6);
my $h2 = $t->new(map {$_ * 100} 1 .. 6);

print scalar(%$h1), "\n";

my $t1 = Hash::Type->new;
my %th1;
tie %th1, $t1;
tie my(%th2), $t, 2, 3;
tie my(%th3), $t;

print scalar(%th1), "\n";




my %sum;
while (my ($k1, $v1) = each %$h1) {
  while (my ($k2, $v2) = each %$h2) {
    $sum{$k1 . $k2} = $v1 + $v2;
  }
}

is(scalar(keys %sum), 36, "36 entries");
is($sum{aa}, 101, "aa 101");
is($sum{af}, 601, "af 601");
is($sum{ba}, 102, "ba 102");
is($sum{fa}, 106, "fa 106");
is($sum{ff}, 606, "ff 606");


