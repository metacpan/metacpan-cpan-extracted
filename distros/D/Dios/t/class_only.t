use warnings;
use strict;

use Test::More;

plan tests => 3;

use Dios;

class Alpha {
    sub test1 { ::ok 1, 'Alpha' }
}

class Beta::Class is Alpha {
    sub test2 { ::ok 1, 'Beta::Class' }
}

class Gamma is Beta::Class {
    sub test3 { ::ok 1, 'Gamma' }
}

my $obj = Gamma->new();

$obj->test1;
$obj->test2;
$obj->test3;


done_testing();

