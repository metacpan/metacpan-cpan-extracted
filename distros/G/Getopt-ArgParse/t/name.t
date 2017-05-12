use lib 'lib';
use Test::More tests => 10;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

lives_ok(
    sub { $p->add_argument('-f'); },
    "add option -f",
);

throws_ok(
    sub {
        $p->add_argument('--foo', '-f');
    },
    qr/already used for a different option/,
    "-f already used for a different option"
);

throws_ok(
    sub {
        $p->add_argument('--', '-foo');
    },
    qr/Empty option name/,
    "non-empty name is required"
);

lives_ok(
    sub { $p->add_argument('--boo', '-b', dest => 'boo_option'); },
    "add multiple flag option"
);

lives_ok(
    sub {
        $ns = $p->parse_args(
            split(' ', '-f 10 --boo 300')
        );
    },
    "parse args"
);

ok($ns->f == 10, "use name to refer to option");

ok($ns->boo_option == 300, "use dest to refer to option");

$ns = $p->parse_args(
    split(' ', '-b 400')
);

ok($ns->boo_option == 400, "use alternative flag");

$p->add_argument('--dash-option');

$ns = $p->parse_args(
    split(' ', '--dash-option 400')
);

ok ($ns->dash_option, "dashes replaced with underscores in dest");

done_testing;
