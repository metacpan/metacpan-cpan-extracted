#!perl

use Test::More tests => 7;

use HTTP::Headers::Fancy;

my $X = HTTP::Headers::Fancy->new;

is_deeply [ $X->split() ]        => [];
is_deeply [ $X->split('"a"') ]   => ['a'];
is_deeply [ $X->split('W/"a"') ] => [ \'a' ];
is_deeply { $X->split('xxx="yy=yy", yyy="zz,zz"') } =>
  { Xxx => 'yy=yy', Yyy => 'zz,zz' };

my $hash1 = {
    foo => 'xxx=yyy, zzz',
    bar => '"a", "b"',
    baf => 'w/"a", W/"b"',
};

my $hash2 = $X->split( $hash1, qw(foo bar baf) );

my $hash3 = {
    foo => {
        Xxx => 'yyy',
        Zzz => undef,
    },
    bar => [ 'a',  'b' ],
    baf => [ \'a', \'b' ],
};

is_deeply $hash1, $hash2;
is_deeply $hash2, $hash3;
is_deeply $hash3, $hash1;

done_testing;
