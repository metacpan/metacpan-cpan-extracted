use lib "lib";
use Test::More; # tests => 4;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

$p->add_argument(
    '--single',
    type => 'Array',
    split => ',',
);

$p->add_argument(
    '--e',
    type  => 'Array',
    split => ',',
);

$n = $p->parse_args(split(' ', '--single 1,2,3 --single 4,5,6 --e a,b,c'));

@s = $n->single;
ok (scalar @s eq 6, "split count");
ok (join(',', @s) eq '1,2,3,4,5,6', "split value: single");

@e = $n->e;

ok (scalar @e eq 3, "split count");
ok (join(',', @e) eq 'a,b,c', "split value");


$p->add_argument(
    '--pairs',
    split => ',',
    type   => 'Pair',
);

$n = $p->parse_args(split(' ', '--pairs a=1,b=2,c=3'));

$p = $n->pairs;

ok($p->{'a'} eq '1', 'a=1');
ok($p->{'b'} eq '2', 'b=2');
ok($p->{'c'} eq '3', 'c=3');

done_testing;

1;



