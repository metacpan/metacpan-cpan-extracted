use strict;
use warnings;
use Test::More;
use Hash::Compact;

subtest 'empty hash' => sub {
    my $hash = Hash::Compact->new;

    ok        $hash;
    isa_ok    $hash, 'Hash::Compact';
    is_deeply $hash->compact, +{};
};

subtest 'normal hash' => sub {
    my $hash = Hash::Compact->new({
        foo => 'foo',
        bar => 'bar',
    });

    ok     $hash;
    isa_ok $hash, 'Hash::Compact';

    is $hash->param('foo'), 'foo';
    is $hash->param('bar'), 'bar';

    $hash->param(baz => 'baz');
    is $hash->param('baz'), 'baz';

    is_deeply $hash->compact, +{
        foo => 'foo',
        bar => 'bar',
        baz => 'baz',
    };
};

subtest 'hash with options' => sub {
    my $hash = Hash::Compact->new({
            foo => 'foo',
        },
        {
            foo => {
                alias_for => 'f',
            },
            bar => {
                default => 'bar',
            },
            baz => {
                alias_for => 'b',
                default   => 'baz',
            }
        },
    );

    is $hash->param('foo'), 'foo';
    is $hash->param('bar'), 'bar';
    is $hash->param('baz'), 'baz';

    is_deeply $hash->compact, +{
        f => 'foo',
    };

    $hash->param(bar => 'hoge');
    is $hash->param('bar'), 'hoge';
    is_deeply $hash->compact, +{
        f   => 'foo',
        bar => 'hoge',
    };

    $hash->param(bar => 'bar');
    is $hash->param('bar'), 'bar';
    ok !exists $hash->{bar};
    is_deeply $hash->compact, +{
        f => 'foo',
    };

    $hash->param(baz => 'fuga');
    is $hash->param('baz'), 'fuga';
    is_deeply $hash->compact, +{
        f => 'foo',
        b => 'fuga',
    };

    $hash->param(baz => 'baz');
    is $hash->param('baz'), 'baz';
    ok !exists $hash->{baz};
    is_deeply $hash->compact, +{
        f => 'foo',
    };
};

subtest 'compact hash with options' => sub {
    my $hash = Hash::Compact->new({
            f => 'foo',
        }, {
            foo => {
                alias_for => 'f',
            },
            bar => {
                alias_for => 'b',
                default   => 'bar',
            },
        },
    );

    is $hash->param('foo'), 'foo';
    is $hash->param('bar'), 'bar';
    is_deeply $hash->compact, +{
        f => 'foo',
    };
};

subtest 'pass some refs' => sub {
    my $hash = Hash::Compact->new;
    $hash->param(array => [qw(foo bar)]);

    is_deeply $hash->param('array'), +[qw(foo bar)];
    is_deeply $hash->compact, +{
        array => [qw(foo bar)]
    };

    my $hash2 = Hash::Compact->new({
        baz => 'baz',
    }, {
        baz => {
            alias_for => 'b',
        },
    });
    $hash->param(hash => $hash2);

    is_deeply $hash->compact, +{
        array => [qw(foo bar)],
        hash  => {
            b => 'baz',
        },
    };
};

subtest 'keys' => sub {
    my $hash;

    $hash = Hash::Compact->new({ foo => 'foo' });

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw(foo)];

    $hash = Hash::Compact->new({});

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw()];

    $hash = Hash::Compact->new({ foo => 'foo' }, {
        foo => { alias_for => 'f' }
    });

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw(foo)];

    $hash = Hash::Compact->new({}, {
        foo => { alias_for => 'f' }
    });

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw()];

    $hash = Hash::Compact->new({ foo => 'foo' }, {
        foo => { default => 'foo' }
    });

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw(foo)];

    $hash = Hash::Compact->new({}, {
        foo => { default => 'foo' }
    });

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw(foo)];

    $hash = Hash::Compact->new({ foo => 'foo' }, {
        foo => { default => 'bar' }
    });

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw(foo)];

    $hash = Hash::Compact->new({ foo => 'foo' }, {
        foo => { alias_for => 'f', default => 'foo' }
    });

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw(foo)];

    $hash = Hash::Compact->new({}, {
        foo => { alias_for => 'f', default   => 'foo' }
    });

    is_deeply [sort { $a cmp $b } $hash->keys],
              [sort { $a cmp $b } qw(foo)];
};

subtest 'original' => sub {
    my $hash = Hash::Compact->new({
            foo => 'foo',
            baz => 'baz',
        },
        {
            foo => {
                alias_for => 'f',
            },
            bar => {
                alias_for => 'b',
                default   => 'bar',
            },
            baz => {
                default   => 'baz',
            },
        },
    );

    is_deeply $hash->original, +{
        foo => 'foo',
        bar => 'bar',
        baz => 'baz',
    };
};

done_testing;
