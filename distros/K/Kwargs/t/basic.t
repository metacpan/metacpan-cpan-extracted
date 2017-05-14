use Kwargs;
use Test::More tests => 7;

sub tkw {
    my $aref = shift;
    [ kw(@$aref, @_) ];
}

sub tkwn {
    my $aref = shift;
    [ kwn(@$aref, @_) ];
}

is_deeply(
    tkw([foo => 'one', bar => 'two', baz => 'three'], qw(foo bar baz)),
    [qw(one two three)],
    'just named',
);

is_deeply(
    tkwn(['one', foo => 'two', bar => 'three'], 1, qw(foo bar)),
    [qw(one two three)],
    'positional followed by named',
);

is_deeply(
    tkw([foo => 'one', bar => 'two']),
    [{ foo => 'one', bar => 'two' }],
    'just a hashref',
);

is_deeply(
    tkwn(['one', 'two', foo => 'three', bar => 'four'], 2),
    ['one', 'two', { foo => 'three', bar => 'four' }],
    'positional followed by hashref',
);

is_deeply(
    tkw([foo => 'one', bar => 'two']),
    tkw([{ foo => 'one', bar => 'two' }]),
    'kw styles equivalent',
);

is_deeply(
    tkwn(['one', foo => 'two', bar => 'three'], 1),
    tkwn(['one', { foo => 'two', bar => 'three' }], 1),
    'kwn styles equivalent',
);

is_deeply(
    [ sub { kwn @_, 1, qw(foo bar) }->('one', foo => 'two', bar => 'three') ],
    [qw( one two three)],
    'an actual sub call',
);
