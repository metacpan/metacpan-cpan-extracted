#!perl

use Test::More tests => 7;

use HTTP::Headers::Fancy qw(split_field_list);

is_deeply [ split_field_list('"a"') ]          => ['a'];
is_deeply [ split_field_list('"a",   "b"') ]   => [ 'a', 'b' ];
is_deeply [ split_field_list('w/"a", W/"b"') ] => [ \'a', \'b' ];
is_deeply [ split_field_list('",",","') ]      => [ ',', ',' ];

my $hash1 = {
    foo => '"a", "b"',
    bar => 'w/"a", W/"b"',
};

my $hash2 = split_field_list( $hash1, qw(foo bar) );

my $hash3 = {
    foo => [ 'a',  'b' ],
    bar => [ \'a', \'b' ],
};

is_deeply $hash1, $hash2;
is_deeply $hash2, $hash3;
is_deeply $hash3, $hash1;

done_testing;
