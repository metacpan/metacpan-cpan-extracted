use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 7;
    eval "use Test::NoWarnings";
    $tests++ unless ($@);
    plan tests => $tests;
}

use_ok( 'List::Uniq', ':all' );

HAPPY_PATH: {
    note('happy path');

    # make sure that list refs in the input elements get flattened
    my $in       = [qw|foo bar baz quux gzonk bar quux|];
    my @expected = qw|foo bar baz quux gzonk|;
    is_deeply scalar uniq($in), \@expected, 'one of two duplicates removed';
}

FLATTEN_OPTION: {
    note('flatten option');

    my $elements = [ ['foo'], ['bar'], [ 'baz', 'quux' ] ];

    is_deeply scalar uniq($elements), [qw|foo bar baz quux|], 'arrayrefs flatten implicitly';
    is_deeply scalar uniq( { flatten => 1 }, $elements ), [qw|foo bar baz quux|], 'arrayrefs flatten explicitly';

    my $ret = ( uniq( { flatten => 0 }, $elements ) )[0];
    for ( 1 .. 3 ) {
        is $ret->[$_], $elements->[$_], "arrayrefs do not flatten explicitly $_/3";
    }
}
