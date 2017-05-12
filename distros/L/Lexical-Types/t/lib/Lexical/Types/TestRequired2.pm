package Lexical::Types::TestRequired2;

use Lexical::Types;

BEGIN {
 delete $INC{'Lexical/Types/TestRequired1.pm'};
}

use lib 't/lib';
use Lexical::Types::TestRequired1;

my Int $x;
Test::More::is($x, 't/lib/Lexical/Types/TestRequired2.pm:' . (__LINE__-1), 'pragma in use in require');

eval q!
 my Int $y;
 my $desc = 'pragma in use in eval in require';
 if ("$]" <  5.009_005) {
  Test::More::is($y, undef, $desc);
 } else {
  Test::More::like($y, qr/^\(eval +\d+\):2$/, $desc);
 }
!;

1;
