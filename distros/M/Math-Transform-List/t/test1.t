use Math::Transform::List;
use v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Test::More tests => 2 ;

# 1

 {my $a = '';

  ok 1 == transform {$a .= "@_\n"} [qw(a)];

  ok $a eq << 'end';
a
end
 }
