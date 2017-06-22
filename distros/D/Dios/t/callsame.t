use warnings;
use strict;

use Test::More;
use Dios;

plan tests => 10;

my $n = 1;
sub plain {
    ok 1 => "plain($n)";
    if ($n++ < 10) {
       callsame;
   }
}

plain();

done_testing();


