
use lib "../lib";
use lib "lib";
use Test::More; # tests => 4;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

$p->add_argument('--foo', type => 'Scalar');

$p->add_argument('--vv', type => 'Bool');
$p->add_argument('-q', type => 'Bool', default => 1);

$line = '--vv';

$ns = $p->parse_args($line);

ok ($ns->vv, 'v - true');
ok ($ns->q, 'q - true');

$ns = $p->parse_args(split(' ', '-q'));

ok (!$ns->vv, 'vv - false');
ok (!$ns->q, 'q - false');

ok ($ns->no_vv, 'no_vv - true');
ok ($ns->no_q, 'no_q - true');

throws_ok(
    sub { $n = $p->parse_args(split(' ', '--foo 100 --foo 200')); },
    qr/foo can only have one value/,
    'foo can only have one value',
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', '--foo 200')); },
);
ok ($ns->foo eq 200, '200 ok');

# positional args
$p = Getopt::ArgParse::Parser->new();

$p->add_argument('boo');

$n = $p->parse_args(split(' ', 100, 200));

ok($n->boo == 100, 'boo is 100');

done_testing;
