use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Math::Expression::Evaluator::Lexer');
}


my $lex = \&Math::Expression::Evaluator::Lexer::lex;

eval {
    $lex->(undef, []);
};

ok $@, 'lex(undef, ...) -> error';

is_deeply $lex->('', [[Int => qr/\d+/]]),
          [],
          'lex("", ...) returns []';

is_deeply $lex->('20', [['Int', qr/\d+/, sub { return }]]),
          [],
          'callbacks in lex() may return undef';

is_deeply
    $lex->('20', [['Int', qr/\d+/, sub { '' }]]),
    [['Int', '', 0, 1]],
    'callbacks in lex() may return empty string';

is_deeply
    $lex->('20+', [['Int', qr/\d+/], ['Punct', qr/\+/]]),
    [['Int', '20', 0, 1], ['Punct', '+', 2, 1] ],
    'Two tokens';

eval {
    &$lex('20', [['Int', qr/(?=\d+)/]]);
};

ok $@, 'A token may note have zero length';

# TODO: many more lexer tests
