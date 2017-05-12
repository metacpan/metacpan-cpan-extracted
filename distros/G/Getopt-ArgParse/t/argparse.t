use Test::More;
use Test::Exception;

use lib 'lib';
use lib '../lib';

BEGIN { use_ok ( 'Getopt::ArgParse' ) };

require_ok('Getopt::ArgParse::Parser');
require_ok('Getopt::ArgParse::ActionStore');
require_ok('Getopt::ArgParse::ActionAppend');
require_ok('Getopt::ArgParse::ActionCount');

my $ns;

my $parser = Getopt::ArgParse->new_parser();

ok($parser, 'new parser');

lives_ok(
    sub { $parser->add_argument() }
);

$parser->add_argument(
    '-foo',
);

$parser->add_argument(
    '--boo', '-b',
    type     => 'Bool',
    required => 1,
    dest     => 'has_boo',
);

$parser->add_argument(
    '--array',
    type     => 'Array',
    required => 1,
);

throws_ok(
    sub {
        $parser->add_argument('-a', 'b');
    },
    qr/Incorrect number of arguments/,
    'incorrect number of arguments',
);

lives_ok(
    sub {
        $ns = $parser->parse_args(split(/ /, '-foo 10 20 30 --array a --array b --array c hello world'));
    },
);

ok(!$ns->current_command, 'current_command is not defined');

@argv = $parser->argv;
ok(scalar(@argv) == 4, 'argv has got the unconsumed argv');
ok($argv[0] == 20, 'argv[0] is 20');

$parser->namespace(undef);
$ns = $parser->parse_args(split(/ /, '-foo 10 20 30 -b --array a --array b --array c'));

ok($ns->foo eq '10', 'default option');
ok($ns->has_boo, 'has boo store true');
my @values = $ns->array;
diag(join(',', @values));
ok( scalar(@values) eq 3, 'append array' );

# positional args
$p = Getopt::ArgParse->new_parser();
$p->add_argument(
    'command',
);

$ns = $p->parse_args(split(/ /, 'submit hello'));

ok($ns->command eq 'submit', 'simple position');

throws_ok(
    sub {
        $p->add_argument(
            'command2',
            type => 'Array2',
            nargs => 2,
        );
    },
    qr/Unknown type/,
    'unknown type',
);


$p->add_argument(
    'command2',
    type => 'Array',
    nargs => 2,
);

$ns = $p->parse_args(split(/ /, 'submit hello1 hello2'));
$cmd2 = $ns->command2;

ok(scalar(@$cmd2) == 2, 'nargs 2');

done_testing;

1;
