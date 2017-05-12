use lib "lib";
use Test::More; # tests => 4;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

# Miminal set up
$p->add_argument(
    '--email', '-e',
    type => 'Array',
);

$line = '-e abc@perl.org -e xyz@perl.org';

$ns = $p->parse_args(split(' ', $line));

@emails = $ns->email;
diag(join ', ', @emails);
ok(scalar @emails == 2, 'append - minimal setup');

$p->add_argument('--foo');
$line = '--foo 1';
$p->namespace(undef);
$ns = $p->parse_args(split(' ', $line));
@emails = $ns->email;
diag(join ', ', @emails);
ok(scalar @emails == 0, 'append - minimal setup,not specified');

$p = Getopt::ArgParse::Parser->new();
$p->add_argument('--foo');
$p->add_argument(
    '--email', '-e',
    type     => 'Array',
    default  => 'mytram2@perl.org',
    required => 1,
);

$line = '--foo 1';
$ns = $p->parse_args(split(' ', $line));

@emails = $ns->email;
diag(join ', ', @emails);

ok(scalar @emails == 1, 'append - required with default');

# append default but specified
$line = '--foo 1 -e abc@perl.org';
$p->namespace(undef);
$ns = $p->parse_args(split(' ', $line));

@emails = $ns->email;
diag(join ', ', @emails);
ok(scalar @emails == 1, 'append - specified - size');
ok($emails[0] eq 'abc@perl.org', 'append - specified - element');

$emails = $ns->email;
ok(scalar(@$emails) == 1, 'append - ref - size');
ok($emails->[0] eq 'abc@perl.org', 'append - ref - element');

# positional options
$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

$p->add_argument('boo', nargs => 3, type => 'Array');

throws_ok(
    sub { $n = $p->parse_args(split(' ', '1 2')) },
    qr/expected:3,actual:2/,
    'not enough arguments',
);

$p->add_argument('boo2');

lives_ok(
    sub { $n = $p->parse_args(split(' ', '1 2 3')) },
);

ok(!defined($n->boo2), 'boo2 not defined');

$p->add_argument('boo3', required => 1);

throws_ok(
    sub { $n = $p->parse_args(split(' ', '1 2 3 4')) },
    qr/boo3 is required/,
    'required option boo3 not value',
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', '1 2 3 4 5')) },
);

ok($n->boo3 eq '5', 'boo3 is 5');

done_testing;
