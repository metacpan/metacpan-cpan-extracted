use Test::Simple tests => 10;
use Exception::Resumable;
ok(1, 'loaded');

eval {
    handle {
        handle {
            ok(1, raise bar);
            ok(1, raise foo);
            ok(1, raise baz3);
            ok(1, raise 'still alive');
            ok(0, raise quux);
        } foo => sub { ok(1, "handle foo"); "ok foo" },
            [qw(BAR Bar bar)] => sub { ok(1, "reraise bar"); raise "bar" };
    } qr/b.r/ => sub { ok(1, "handle bar"); "ok bar" },
        { baz => 1, baz3 => 1 } => sub { ok(1, "handle baz"); "ok baz" },
            'still alive' => 'ooooooh';
};

ok($@ =~ /^quux.*eval/, 'yeah: '.$@);
