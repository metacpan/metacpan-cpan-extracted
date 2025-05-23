use strict;
use warnings;
use Test::More;

use Hash::Merge::Simple qw/merge/;

{
    my $a = { a => 1 };
    my $b = { a => 100, b => 2};

    my $c = merge $a, $b;
    ok($c);
    is_deeply($c, { a => 100, b => 2 });
}

{
    my $a = { a => 1, c => 3, d => { i => 2 }, r => {} };
    my $b = { b => 2, a => 100, d => { l => 4 } };
    my $c = merge $a, $b;
    ok($c);
    is_deeply($c, { a => 100, b => 2, c => 3, d => { i => 2, l => 4 }, r => {} });
}

{
    is_deeply(merge({ a => 1 }, { a => 2 }, { a => 3 }, { a => 4 }, { a => 5 }), { a => 5 });
    is_deeply(merge({ a => 1, b => [] }, { a => 2 }, { a => 3 }, { a => 4 }, { a => 5 }), { a => 5, b => [] });
    is_deeply(merge({ a => 1, b => [ 3 ] }, { a => 2 }, { a => 3 }, { a => 4, b => [ 8 ] }, { a => 5 }), { a => 5, b => [ 8 ] });
    is_deeply(merge({ a => 1 }, { b => 2 }, { c => 3 }, { d => 4 }, { e => 5 }), { qw/a 1 b 2 c 3 d 4 e 5/ });
}

if (0) {

    exit;

    # Infinity-ty-ty-ty-ty
    my $a = {};
    $a->{b} = $a;
    merge $a, $a;
}

done_testing;
