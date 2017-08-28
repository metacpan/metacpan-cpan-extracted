use Math::Transform::List;
use v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Test::More tests => 2;

# 3

 {my $a = '';

  ok 3 == transform {$a .= "@_\n"} [qw(a b c)], [1..3];

  ok $a eq << 'end';
b c a
c a b
a b c
end
 }
