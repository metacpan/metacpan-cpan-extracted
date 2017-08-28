use Math::Transform::List;
use v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Test::More tests => 2 ;

# 4c

 {my $a = '';

  ok 4 == transform {$a .= "@_\n"} [qw(a b c d)], [1..2], [3..4];

  ok $a eq << 'end';
b a c d
a b d c
b a d c
a b c d
end
 }
