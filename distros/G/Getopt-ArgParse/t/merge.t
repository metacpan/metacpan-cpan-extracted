use Test::More;
use Test::Exception;

use lib 'lib';
use lib '../lib';

use Getopt::ArgParse;

$common_parser = Getopt::ArgParse->new_parser();

$common_parser->add_argument(
    '--dry-run',
    type => 'Bool',
);

$parser = Getopt::ArgParse->new_parser();

$parser->add_arguments(
    [ '--foo' ],
);

$parser->add_subparsers();

$sp = $parser->add_parser('list');

$sp->copy_args($common_parser);

$sp = $parser->add_parser('copy');

$sp->copy_args($common_parser);

$n = $parser->parse_args('list', '--dry-run');

ok($n->dry_run, 'dry-run');

$n = $parser->parse_args('copy', '');

ok($n->no_dry_run, 'no dry-run');

throws_ok(
    sub { $parser->parse_args('--dry-run'); },
    qr/Unknown option: dry-run/,
    'unknown option',
);

# copy parsers
$parser1 = Getopt::ArgParse->new_parser(
    prog => 'parser1',
);

$parser1->copy_parsers($parser);

throws_ok(
    sub { $parser1->parse_args('--foo 123'); },
    qr/Unknown option: foo/,
    'unknown option: foo',
);

$n = $parser1->parse_args('list', '--dry-run');

ok($n->dry_run, 'parse1: dry-run');

$n = $parser1->parse_args('copy', '');

ok($n->no_dry_run, 'parse1: no dry-run');

# copy parsers
$parser2 = Getopt::ArgParse->new_parser(
    prog => 'parser2',
    parents => [ $parser ],
);

$n = $parser2->parse_args('list', '--dry-run');

ok($n->dry_run, 'parse2: dry-run');

$n = $parser2->parse_args('copy', '');

ok($n->no_dry_run, 'parse2: no dry-run');

done_testing;
