use Test::Most;
use JSON::Path::Tokenizer qw(tokenize);

my %EXPRESSIONS = (
    '$.[*].id'                              => [qw/$ . [ * ] . id/],
    q{$.[0].title}                          => [qw/$ . [ 0 ] . title/],
    q{$..labels[?(@.name==bug)]}            => [qw/$ .. labels [?( @ . name == bug )]/],
    q{$.store.book[(@.length-1)].title}     => [qw/$ . store . book [( @ . length-1 )] . title/],
    q{$.store.book[?(@.price < 10)].title}  => [ qw/$ . store . book [?( @ . /, 'price ', '<', ' 10', qw/)] . title/ ],
    q{$.store.book[?(@.price <= 10)].title} => [ qw/$ . store . book [?( @ . /, 'price ', '<=', ' 10', qw/)] . title/ ],
    q{$.store.book[?(@.price >= 10)].title} => [ qw/$ . store . book [?( @ . /, 'price ', '>=', ' 10', qw/)] . title/ ],
    q{$.store.book[?(@.price === 10)].title} =>
        [ qw/$ . store . book [?( @ . /, 'price ', '===', ' 10', qw/)] . title/ ],
    q{$['store']['book'][0]['author']} =>
        [ '$', '[', q('store'), ']', '[', q('book'), ']', '[', 0, ']', '[', q('author'), ']' ],
    q{$.[*].user[?(@.login == 'laurilehmijoki')]} =>
        [ qw/$ . [ * ] . user [?( @ ./, 'login ', '==', q{ 'laurilehmijoki'}, ')]' ],
    q{$.path\.one.two} => [qw/$ . path.one . two/],
);

for my $expression ( keys %EXPRESSIONS ) {
    my @tokens;
    lives_and { is_deeply [ tokenize($expression) ], $EXPRESSIONS{$expression} }
    qq{Expression "$expression" tokenized correctly};
}

done_testing;
