use lib "lib";
use lib "../lib";
use Test::More; # tests => 4;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();

$p->add_argument(
    '--count', '-c',
    type => 'Count',
);

$p->add_argument(
    'boo',
    type  => 'Array',
    nargs => '2',
);

$n = $p->parse_args(split(' ', '-c -c 100 -c 200'));

# use Data::Dumper;
# print STDERR Dumper($p->{-argv});

ok($n->count eq 3, 'count 3');
ok($n->boo->[0] == 100, 'positional arg: 100');
ok($n->boo->[1] == 200, 'positional arg: 200');

$n = $p->parse_args(split(' ', '-c -c -c'));

ok($n->count == 6, 'count again now is 6');

$p->add_argument('--count', '-c', type => 'Count', default => 3, reset => 1);

$n->set_attr('count', undef);

$n = $p->parse_args();

diag($n->count);
ok($n->count == 3, 'count default is 3');

$n->set_attr('count', undef);
$n = $p->parse_args(split(' ', '-c -c -c'));
ok($n->count == 3, 'count default is still 3');

done_testing;
