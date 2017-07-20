use Test2::V0;
use JSON::Path::Tokenizer qw(tokenize);

my @EXPRESSIONS = (
    q{$[1:3:2].foobar}                       => [qw/$ [ 1:3:2 ] . foobar/],
    q{$.[0].title}                           => [qw/$ . [ 0 ] . title/],
    q{$.store.book[?(@.price < 10)].title}   => [ qw/$ . store . book [?(/, '@.price < 10', qw/)] . title/ ],
    '$.[*].id'                               => [qw/$ . [ * ] . id/],
    q{$.[1].title}                           => [qw/$ . [ 1 ] . title/],
    q{$..labels[?(@.name==bug)]}             => [qw/$ .. labels [?( @.name==bug )]/],
    q{$.store.book[(@.length-1)].title}      => [qw/$ . store . book [( @.length-1 )] . title/],
    q{$.store.book[?(@.price < 10)].title}   => [ qw/$ . store . book [?(/, '@.price < 10', qw/)] . title/ ],
    q{$.store.book[?(@.price <= 10)].title}  => [ qw/$ . store . book [?(/, '@.price <= 10', qw/)] . title/ ],
    q{$.store.book[?(@.price >= 10)].title}  => [ qw/$ . store . book [?(/, '@.price >= 10', qw/)] . title/ ],
    q{$.store.book[?(@.price === 10)].title} => [ qw/$ . store . book [?(/, '@.price === 10', qw/)] . title/ ],
    q{$['store']['book'][0]['author']} =>
        [ '$', '[', q(store), ']', '[', q(book), ']', '[', 0, ']', '[', q(author), ']' ],
    q{$['store']['book'][1]['author']} =>
        [ '$', '[', q(store), ']', '[', q(book), ']', '[', 1, ']', '[', q(author), ']' ],
    q{$.[*].user[?(@.login == 'laurilehmijoki')]} => [ qw/$ . [ * ] . user [?(/, q{@.login == 'laurilehmijoki'}, ')]' ],
    q{$.path\.one.two}                            => [qw/$ . path.one . two/],
    q{$.'path.one'.two}                           => [qw/$ . path.one . two/],
);

for ( 0 .. ( $#EXPRESSIONS / 2 ) ) {
    my $expression = $EXPRESSIONS[ $_ * 2 ];
    my $expected   = $EXPRESSIONS[ $_ * 2 + 1 ];
    my $tokens;
    subtest $expression => sub {
        ok lives { $tokens = [ tokenize($expression) ] }, q{tokenize() did not die};
        is $tokens, $expected, q{Token stream correct};
    };
}

done_testing;
