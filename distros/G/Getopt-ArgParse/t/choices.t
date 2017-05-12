use lib "lib";
use Test::More;
use Test::Exception;

use Getopt::ArgParse::Parser;

$p = Getopt::ArgParse::Parser->new();
ok($p, "new argparser");

$p->add_argument(
    '--choice',
    choices => [ 'a', 'b', 'c' ],
);

throws_ok(
    sub { $n = $p->parse_args(split(' ', '--choice hello')); },
    qr/not in/,
    'choice error: not in choices - arrayref'
);

$p->add_argument(
    '--choice1',
    choices => sub {
        die "not in ['a', 'b', 'c']" unless $_[0] =~ /^(a|b|c)$/i;
    }
);

throws_ok(
    sub { $n = $p->parse_args(split(' ', '--choice1 hello')); },
    qr/not in/,
    'choice error: not in choices - coderef'
);

$n = $p->parse_args(split(' ', '--choice1 A --choice a'));

ok($n->choice eq 'a', 'choice ok - fixed value a');

ok($n->choice1 eq 'A', 'choice ok - case insensative A');

$p = Getopt::ArgParse::Parser->new();

throws_ok ( sub {
                $p->add_argument(
                    '--choice',
                    choices => [ 'a', 'b', 'c' ],
                    choices_i => [ 'A', 'B', 'C' ],
                );
            },
            qr/Not allow to specify/,
            'not allow to specify choices and choices_i',
);

throws_ok(
    sub {
        $p->add_argument(
            '--choice',
            choices_i => sub { die 'choices' },
        );
    },
    qr/arrayref/,
    'only allow arrayref',
);

lives_ok(
    sub {
        $p->add_argument(
            '--choice',
            choices_i => [ 'hello', 'world' ],
        );
});

throws_ok(
    sub { $n = $p->parse_args('--choice', 'abc'); },
    qr/not in choices/,
    'not in allowed choices_i',
);

$n = $p->parse_args('--choice', 'WORLD');

ok($n->choice eq 'WORLD', "WORLD is OK");
$n = $p->parse_args('--choice', 'HEllo');
ok($n->choice eq 'HEllo', "HEllo is OK too");

done_testing;
