use Test::More;
use Test::Exception;

use lib '../lib';
use lib 'lib';

use Getopt::ArgParse;
$p = Getopt::ArgParse->new_parser();

ok($p, 'new parser');


throws_ok(
    sub { $p->add_subparsers( 'parser', ); },
    qr /Incorrect number of arguments/,
    'incorrect number of args',
);

throws_ok(
    sub { $p->add_subparsers( something => 'parser', something2 => 'parser'); },
    qr /Unknown parameters: something/,
    'unknown parameters',
);

lives_ok(
    sub { $p->add_subparsers(); },
);

throws_ok(
    sub { $p->add_subparsers(); },
    qr/Subparsers already added/,
    'subparsers already added',
);


$p = Getopt::ArgParse->new_parser();

$p->add_argument(
    '--foo',
);

throws_ok(
    sub { $pp = $p->add_parser('list') },
    qr /add_subparsers\(\) is not called/,
    'add_subparsers is not called'
);

$sp = $p->add_subparsers(
    title       => 'Here are some subcommands',
    description => 'Use subcommands to do something',
);

throws_ok(
    sub { $pp = $p->add_parser() },
    qr /Subcommand is empty/,
    'Subcommand is empty',
);

throws_ok(
    sub { $pp = $p->add_parser(listx => 'add listx') },
    qr/Incorrect number of arg/,
    'Incorrect number of args',
);

throws_ok(
    sub { $p->add_parser( 'listx', something => 'parser', something2 => 'parser'); },
    qr /Unknown parameters: something/,
    'Unknown parameters',
);

$sp->add_parser(
    'listx', aliases => [ qw(lx) ],
);

throws_ok(
    sub { $pp = $p->add_parser('listx') },
    qr /Subcommand listx already defined/,
    'subcommand listx already defined',
);

throws_ok(
    sub {
        $pp = $sp->add_parser(
            'list',
            aliases => qw(ls) ,
            help => 'This is the list subcommand',
        );
    },
    qr/Aliases is not an arrayref/,
    'aliases is not an arrayref',
);

throws_ok(
    sub {
        $pp = $sp->add_parser(
            'list',
            aliases => [ qw(ls lx) ],
            help => 'This is the list subcommand',
        );
    },
    qr/Alias=lx already used/,
    'alias already used'
);


$list_p = $sp->add_parser(
    'list',
    aliases => [ qw(ls) ],
    help => 'This is the list subcommand',
);

$list_p->add_argument(
    '--foo', '-x',
    type => 'Bool',
    help => 'this is list foo',
);

$list_p->add_argument(
    '--boo', '-b',
    type => 'Bool',
    help => 'this is list boo',
);

# parse for the top command
$n = $p->parse_args(split(' ', '--foo 100'));
ok($n->foo == 100, 'foo is 100');
throws_ok(
    sub { $n->boo },
    qr /unknown option: boo/,
    'unknown option',
);

throws_ok(
    sub {
        $n = $p->parse_args(split(' ', 'list2 --foo'));
    },
   qr/list2 is not a .* command. See help/,
   'list2 is not a command',
);

lives_ok(
    sub {
        $n = $p->parse_args(split(' ', 'list --boo -foo'));
    },
);

ok($n->current_command eq 'list', 'current_command is list');
ok($n->foo, "list's foo is true");
ok($n->boo, "list's boo is true");

done_testing;

