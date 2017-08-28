use Math::Transform::List;
use v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Test::More tests => 2 ;

# 4b

 {my $a = '';

  ok 2 == transform {$a .= "@_\n"} ['a'..'d'], [[1,3], [2,4]];

  ok $a eq << 'end';
c d a b
a b c d
end
 }
