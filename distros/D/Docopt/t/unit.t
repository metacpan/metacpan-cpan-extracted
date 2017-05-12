use strict;
use warnings;
use utf8;
use Test::More;
use Docopt;
use Docopt::Util qw(repl pyprint);
use Data::Dumper;
use t::Util;
use boolean;

subtest 'match' => sub {
    my $argv=[Argument(None, 'this')];
    my $patterns=Required(Argument('<p>', []));
    my ($match, $left, $collected) = $patterns->match($argv);
    is_deeply($match, true);
    is_deeply($left, []);
    is_deeply($collected, [Argument('<p>', ['this'])]);
} or die;

subtest 'transform' => sub {
    my $got = transform(Required(OneOrMore(Optional(Argument('<p>', undef)))));
    is_deeply(
        $got,
        Either(Required(Argument('<p>', None), Argument('<p>', None))),
    ) or die repl($got); 
};

subtest 'fix_repeating_arguments' => sub {
    my $stuff = Required(OneOrMore(Optional(Argument('<p>', undef))));
    my $got= $stuff->fix_repeating_arguments();
    is_deeply(
        $got,
        Required(OneOrMore(Optional(Argument('<p>', []))))
    ) or die repl($got); 
};

subtest 'parse_section' => sub {
    my @ret = Docopt::parse_section('usage', <<'...');
    usage: myapp
...
    is_deeply(\@ret, [
        'usage: myapp'
    ]);
};

subtest 'parse_defaults' => sub {
    my $doc = <<'...';
options:
    -h, --help  Print help message.
    -o FILE     Output file.
    --verbose   Verbose mode.
...

    my @defaults = Docopt::parse_defaults($doc);
    is(0+@defaults, 3);
    is($defaults[0]->__repl__, 'Option("-h", "--help", 0, undef)');
    is($defaults[1]->__repl__, 'Option("-o", undef, 1, undef)');
    is($defaults[2]->__repl__, 'Option(undef, "--verbose", 0, undef)');
};

subtest 'formal_usage' => sub {
    my $doc = <<'...';
usage:
    foo x y
    foo a b
...
    my $expected = '( x y ) | ( a b )';
    is(Docopt::formal_usage($doc), $expected);
};

subtest 'Tokens.from_pattern' => sub {
    subtest 'complex' => sub {
        is(Docopt::Tokens->from_pattern('(-h|-v[--file=<f>]N...)')->__repl__,
            q!["(", "-h", "|", "-v", "[", "--file=<f>", "]", "N", "...", ")"]!
        );
    };
    subtest 'simple' => sub {
        my $doc = <<'...';
usage:
    foo x y
    foo a b
...
        is(Docopt::Tokens->from_pattern(Docopt::formal_usage($doc))->__repl__,
            '["(", "x", "y", ")", "|", "(", "a", "b", ")"]',
        );
    };
};

subtest 'parse_pattern' => sub {
    subtest 'simple' => sub {
        my $doc = <<'...';
usage:
    foo bar
...
        my $formal = Docopt::formal_usage($doc);
        note(Docopt::Tokens->from_pattern($formal)->__repl__);
        my $options = [];
        my $result = Docopt::parse_pattern($formal, $options);
        is($result->__repl__, q!Required(Required(Command("bar", undef)))!);
    };
};

done_testing;

