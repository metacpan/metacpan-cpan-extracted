use lib "lib";
use Test::More; # tests => 4;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();

$p->add_argument(
    '--pair', '-p',
    type  => 'Pair',
);

$p->add_argument(
    '--pairs',
    type   => 'Pair',
);

$n = $p->parse_args('--pair', 'hello=\'hello world\'', split(' ', '--pairs a=1 --pairs b=2'));

$p = $n->pair;
diag($p->{'hello'});
ok($p->{'hello'} eq '\'hello world\'', 'hello=world');

$p = $n->pairs;

ok($p->{'a'} eq '1', 'a=1');
ok($p->{'b'} eq '2', 'b=2');

# positional

$p = Getopt::ArgParse::Parser->new();

$p->add_argument('command');
$p->add_argument('params', type => 'Pair', nargs => '+');

lives_ok (
    sub { $n = $p->parse_args('list', 'a=b', 'b=1', 'c=2'); }
);

ok($n->command eq 'list', 'command=list');
ok($n->params->{a} eq 'b', 'a=b');
ok($n->params->{b} eq '1', 'b=1');
ok($n->params->{c} eq '2', 'c=2');

$p->namespace(undef);

throws_ok(
    sub { $p->add_argument('params', type => 'Pair', nargs => '?', default => { a => 10 }); },
    qr/Redefine option params without reset/,
    'redefine option with reset',
);
lives_ok(
    sub { $p->add_argument('params', type => 'Pair', nargs => '?', default => { a => 10 }, reset => 1); },
);

lives_ok (
    sub { $n = $p->parse_args('list') }
);

ok($n->params->{a} eq '10', 'a=10, from default');

done_testing;

1;
