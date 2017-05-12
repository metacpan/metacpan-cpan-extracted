use strict;
use warnings;

use Test::More;

use Dios;

{
    my $a;
    ok do{ $a = [ do{ func () {} }, 1 ]; 1 }, 'anonymous function in list is okay';
    is ref $a->[0], "CODE";
    is $a->[1], 1;
}

{
    my $a;
    ok do{ $a = [ do{ method () {} }, 1 ]; 1 }, 'anonymous method in list is okay';
    is ref $a->[0], "CODE";
    is $a->[1], 1;
}

done_testing;
