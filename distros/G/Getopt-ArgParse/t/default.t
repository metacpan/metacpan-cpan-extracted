use lib 'lib';
use Test::More;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

$p->add_argument('--foo');
$p->add_argument('--required-option', required => 1, default => 10);
$p->add_argument('--optional-option', default => [ 20 ]);

$n = $p->parse_args(split(' ', '--foo 20'));

ok($n->required_option eq 10, "required default 10");
ok($n->optional_option eq 20, "optional default 20");
ok($n->foo eq 20, "foo 20");

throws_ok(
    sub { $p->add_argument('--optional-option', default => [ 10, 20 ]); },
    qr/Multiple default values/,
    'multiple default values not allowed',
);

# hash default
throws_ok(
    sub { $p->add_argument('--optional-option', default => { a => 1 }); },
    qr/HASH default only for/,
    'non-hash type',
);

lives_ok(
    sub { $p->add_argument('--optional-option', type => 'Pair', default => { a => 1 }, reset => 1); },
);

$p->namespace(undef);
$n = $p->parse_args(split(' ', '--foo 20'));

ok($n->optional_option->{a} == 1, 'hash = 1');

done_testing;
