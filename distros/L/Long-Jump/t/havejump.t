use Test2::V0;

use Long::Jump qw/setjump longjump havejump/;

ok(!havejump('foo'), "No jump point set, havejump is false");
is(havejump('foo'), 0, "havejump returns 0 when no jump point is set");

setjump foo => sub {
    ok(havejump('foo'), "havejump is true inside the named jump point");
    is(havejump('foo'), 1, "havejump returns 1 when jump point is set");
    ok(!havejump('bar'), "havejump is false for an unrelated name");
};

ok(!havejump('foo'), "havejump is false again after setjump returns");

setjump outer => sub {
    ok(havejump('outer'), "outer is visible from outer");
    ok(!havejump('inner'), "inner is not yet set");

    setjump inner => sub {
        ok(havejump('outer'), "outer is still visible from inner");
        ok(havejump('inner'), "inner is visible from inner");
        ok(!havejump('missing'), "unrelated name is not visible");
    };

    ok(havejump('outer'), "outer is still set after inner returns");
    ok(!havejump('inner'), "inner is no longer set after it returns");
};

my $got = setjump foo => sub {
    longjump(foo => 'x') if havejump('foo');
    ok(0, "Should not get here");
};
is($got, ['x'], "guarded longjump fires when havejump is true");

my $ran = 0;
$got = setjump foo => sub {
    if (havejump('nope')) {
        longjump('nope');
        ok(0, "Should not get here");
    }
    $ran = 1;
};
is($got, undef, "guarded longjump skipped when havejump is false");
is($ran, 1, "body ran instead of jumping");

done_testing;
