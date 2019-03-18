use warnings;
use strict;

use Test::More;

plan tests => 3;


use Keyword::Declare;

keyword example () {{{}}}

example;

my $n = 1;
for my $datum (readline *DATA) {
    is $datum, "data line $n\n", "DATA line $n";
    $n++;
}


done_testing();

__DATA__
data line 1
data line 2
data line 3
