use Math::Transform::List;
use v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Test::More tests => 2;

# 4a

if (1)
 {my $a = '';

  ok 4 == transform {$a .= "@_\n"} [qw(a b c d)], [[1..4]];

  ok $a eq << 'end';
b c d a
c d a b
d a b c
a b c d
end
 }
