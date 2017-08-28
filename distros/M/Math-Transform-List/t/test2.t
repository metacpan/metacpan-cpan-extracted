use Math::Transform::List;
use v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Test::More tests => 2;

# 2

 {my $a = '';

  ok 2 == transform {$a .= "@_\n"} [qw(a b)], [1..2];

  ok $a eq << 'end';
b a
a b
end
 }
