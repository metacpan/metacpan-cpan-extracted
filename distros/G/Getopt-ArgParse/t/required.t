use lib 'lib';
use Test::More; # tests => 10;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new(
    print_usage_if_help => 0, # no
);
ok($p, "new argparser");

$p->add_argument('--required-option', required => 1);
$p->add_argument('--optional-option');

lives_ok(
    sub {$n = $p->parse_args(split(' ', '--required-option hello'));},
);

ok($n->required_option eq "hello", "required_option");
ok( !defined($n->optional_option), "optional_option is undef");

lives_ok(
    sub { $n = $p->parse_args( split(' ', '--optional-option hello') ); },
);
ok($n->required_option eq "hello", "required_option");
ok($n->optional_option eq 'hello', "optional_option is hello");

$p->namespace(Getopt::ArgParse::Namespace->new()); # Clear out required-option
# multiple parsing preserves previous values
$n = $p->namespace;

$p->add_argument('--optional-option', reset => 1);

throws_ok(
    sub { $n = $p->parse_args( split(' ', '--optional-option hello') ); },
    qr/required/,
    "required option",
);
lives_ok(
    sub { $n = $p->parse_args('--help') },
);

ok($n->help, 'help');

$p = Getopt::ArgParse::Parser->new(
    print_usage_if_help => 0, # no
);

$p->add_subparsers();
$lp = $p->add_parser('list');

$lp->add_arguments(
    [ '--type', required => 1],
    [ 'branch', required => 1],
);

lives_ok(
sub { $n = $p->parse_args('list', '--help'); },
);

ok($n->help, 'list -help');

# postional options
$p = Getopt::ArgParse::Parser->new();

$p->add_argument('-f');
$p->add_argument('boo'); # not required

$n = $p->parse_args(split(' ', '-f 10'));

ok (!$n->boo, 'boo is not required');

$p->add_argument('boo', required => 1, reset => 1);

throws_ok (
    sub { $n = $p->parse_args(split(' ', '-f 10')); },
    qr /required/,
    'required positional arg: boo'
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', '-f 10 100')); },
);

ok($n->boo == 100, 'boo is 100');

throws_ok(
    sub { $p->add_argument('boo', nargs => 2); },
    qr/Redefine option boo without reset/,
    'Redfine option boo'
);

lives_ok(
    sub { $p->add_argument('boo', nargs => 2, reset => 1); },
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', '-f 10')); },
);

throws_ok(
    sub { $n = $p->parse_args(split(' ', '-f 10 111')); },
    qr/Too few arguments for boo/,
    'not enough args for boo',
);

$p->add_argument('boo', type => 'Array', nargs => 2, required => 1, reset => 1);

# $n = $p->parse_args(split(' ', '-f 10'));
$n->set_attr('boo', undef);

# Now it will fail for it's required
throws_ok(
    sub { $n = $p->parse_args(split(' ', '-f 10')); },
    qr/required/,
    'boo is required',
);

throws_ok(
    sub { $n = $p->parse_args(split(' ', '-f 10 100')); },
    qr/Too few arguments for boo/,
    'not enough args for boo',
);

lives_ok(
    sub { $n = $p->parse_args(split(' ', '-f 10 100 20')); },
);

ok($n->boo->[0] == 100, 'boo 0 - 100');
ok($n->boo->[1] == 20, 'boo 1 - 20');

done_testing;

