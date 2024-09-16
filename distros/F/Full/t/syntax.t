use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Log::Any qw($log);

# If we have ::TAP, use it - but no need to list it as a dependency
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import(qw(TAP));
};

$log->infof('starting');

# Assorted syntax helper checks. So much eval.

subtest 'enables strict' => sub {
    fail('eval should not succeed with global var') if eval(q{
        package local::strict::vars;
        use Full::Class qw(:v1);
        $x = 123;
    });
    like($@, qr/Global symbol \S+ requires explicit package/, 'strict vars enabled');
    fail('eval should not succeed with symbolic refs') if eval(q{
        package local::strict::refs;
        use Full::Class qw(:v1);
        my $var = 123;
        my $name = 'var';
        print $$var;
    });
    like($@, qr/as a SCALAR ref/, 'strict refs enabled');
    fail('eval should not succeed with poetry') if eval(q{
        package local::strict::subs;
        use Full::Class qw(:v1);
        MissingSub;
    });
    like($@, qr/Bareword \S+ not allowed/, 'strict subs enabled');
};

subtest 'disables indirect object syntax' => sub {
    fail('indirect call should be fatal') if eval(q{
        package local::indirect;
        use Full::Class qw(:v1);
        indirect { 'local::indirect' => 1 };
    });
    like($@, qr/Indirect call/, 'no indirect enabled');
};

subtest 'try/catch available' => sub {
    is(eval(q{
        package local::try;
        use Full::Class qw(:v1);
        try { die 'test' } catch { 'ok' }
    }), 'ok', 'try/catch supported') or diag $@;
};

subtest 'helper methods from Scalar::Util' => sub {
    is(eval(q{
        package local::HelperMethods;
        use Full::Class qw(:v1);
        blessed(bless {}, "Nothing") eq "Nothing" or die 'blessed not found';
        'ok'
    }), 'ok', 'try/catch supported') or diag $@;
};
subtest 'dynamically available' => sub {
    is(eval(q{
        package local::dynamically;
        use Full::Class qw(:v1);
        my $x = "ok";
        {
         dynamically $x = "fail";
        }
        $x
    }), 'ok', 'dynamically supported') or diag $@;
};

subtest 'async/await available' => sub {
    isa_ok(eval(q{
        package local::asyncawait;
        use Full::Class qw(:v1);
        async sub example {
         await Future->new;
        }
        example();
    }), 'Future') or diag $@;
};

subtest 'utf8 enabled' => sub {
    local $TODO = 'probably not a valid test, fixme';
    is(eval(qq{
        package local::unicode;
        use Full::Class qw(:v1);
        "\x{2084}"
    }), "\x{2084}", 'utf8 enabled') or diag $@;
};

subtest 'Log::Any imported' => sub {
    is(eval(q{
        package local::logging;
        use Full::Class qw(:v1);
        $log->tracef("test");
        1;
    }), 1, '$log is available') or diag $@;
};

subtest 'Object::Pad' => sub {
    ok(eval(q{
        package local::pad;
        use Full::Class qw(:v1);
        method test { $self->can('test') ? 'ok' : 'not ok' }
        async method test_async { $self->can('test_async') ? 'ok' : 'not ok' }
        __PACKAGE__
    })) or diag $@;
    my $obj = new_ok('local::pad' => [name => 'test']);
    can_ok($obj, 'test');
    is($obj->test, 'ok', 'we find our own methods');
    isa_ok($obj->test_async, 'Future', 'async method returns a Future');
};

subtest 'Full::Class extras' => sub {
    is(eval(q{
        package local::v1;
        use Full::Class qw(:v1);
        field $suspended;
        field $resumed;
        method suspended { $suspended }
        method resumed { $resumed }
        async method example ($f) {
            suspend { ++$suspended }
            resume { ++$resumed }
            await $f;
            return;
        }
        extended method checked ($v : Checked(NumGE(5))) { 'ok' }
        __PACKAGE__
    }), 'local::v1') or diag $@;
    my $obj = local::v1->new;
    my $f = $obj->example(my $pending = Future->new);
    is($obj->suspended // 0, 1, 'have suspended once');
    is($obj->resumed // 0, 0, 'and not yet resumed');
    $pending->done;
    is($obj->suspended // 0, 1, 'have still suspended once');
    is($obj->resumed // 0, 1, 'and resumed once now');
    is(exception {
        $obj->checked(5)
    }, undef, 'can check numeric >= 5');
    like(exception {
        $obj->checked(-3)
    }, qr/\Qsatisfying NumGE(5)/, 'numeric check fails on number out of range');
    like(exception {
        $obj->checked('xx')
    }, qr/\Qsatisfying NumGE(5)/, 'numeric check fails on invalid number');
    done_testing;
};
done_testing;

