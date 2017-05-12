use lib "lib";
use Test::More; # tests => 4;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

$p->add_argument(
    'boo',
    # nargs => 1,
);

$n = $p->parse_args(split(' ', '100'));

ok($n->boo == 100, 'boo is 100 nargs=>1');

$p->add_argument(
    'boo1',
    type => 'Array',
    nargs => 2,
);

$p->add_argument(
    'boo2',
    nargs => '?',
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', 'abc 100 200')); }
);

ok(!$n->boo2, 'boo2 is not taken nargs=>?');

lives_ok(
    sub { $n = $p->parse_args(split(' ', 'abc 100 200 300')); }
);

ok($n->boo2 == 300, 'boo2 is 300 nargs=>?');

$p->add_argument(
    'boo3',
    type  => 'Array',
    nargs => '+',
);

throws_ok(
    sub { $n = $p->parse_args(split(' ', 'abc 100 200 300')); },
    qr/Too few arguments/,
    'too few arguments for +',
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', 'abc 100 200 300 400 500')); },
);

$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

$p->add_argument(
    'boo',
    # nargs => 1,
);

$p->add_argument(
    'boo1',
    type => 'Array',
    nargs => '*',
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', 'abc')); },
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', 'abc 100 200 300 400 500')); },
);

ok($n->boo1->[4] == 500, 'nargs=>* boo1->[4] is 500');


throws_ok (
    sub { $p->add_argument('-f', nargs => 10) },
    qr/only allow/,
    'not allowed for optional options',
);

$p->add_argument('f', nargs => 'abc');
throws_ok (
    sub { $p->parse_args('abc') },
    qr/Invalid nargs/,
    'invalid nargs',
);

done_testing;

