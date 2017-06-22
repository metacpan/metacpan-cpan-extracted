use warnings;
use strict;

use Test::More;
use Dios;

plan tests => 10;

sub plain {
    my $n = shift;
    ok 1 => "plain($n)";
    if ($n < 10) {
       callwith $n+1;
   }
}

plain(1);

done_testing();

