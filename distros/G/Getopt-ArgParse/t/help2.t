use Test::More;
use Test::Exception;

use lib 'lib';
use Getopt::ArgParse;

$p = Getopt::ArgParse->new_parser(
    prog => 'mysvn',
    error_prefix => 'mysvn:error: ',
);

$p->add_argument('--verbose', '-v', type => 'Bool');

$p->add_subparsers(
    title => 'subcommands',
);

$sp = $p->add_parser(
    'list',
    help => 'list the directories',
);

$sp->add_argument(
    '--verbose', '-v',
    type => 'Count',
    help => 'verbosity',
);

if (fork()) {
    $pid = wait();
    ok($pid, "pid return");
    done_testing;
} else {
    $p->parse_args('help', 'list');
}

1;

