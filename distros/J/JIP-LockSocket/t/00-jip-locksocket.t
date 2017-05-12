#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use English qw(-no_match_vars);

plan tests => 9;

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'JIP::LockSocket', '0.01';
    require_ok 'JIP::LockSocket';

    diag(
        sprintf 'Testing JIP::LockSocket %s, Perl %s, %s',
            $JIP::LockSocket::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'new()' => sub {
    plan tests => 9;

    eval { JIP::LockSocket->new } or do {
        like $EVAL_ERROR, qr{Mandatory \s argument \s "port" \s is \s missing}x;
    };

    eval { JIP::LockSocket->new(port => undef) } or do {
        like $EVAL_ERROR, qr{Bad \s argument \s "port"}x;
    };

    eval { JIP::LockSocket->new(port => q{}) } or do {
        like $EVAL_ERROR, qr{Bad \s argument \s "port"}x;
    };

    my $obj = init_obj();
    ok $obj, 'got instance of JIP::LockSocket';

    isa_ok $obj, 'JIP::LockSocket';

    can_ok $obj, qw(new addr port lock try_lock unlock is_locked);

    is $obj->port, 4242;
    is $obj->addr, '127.0.0.1';

    is(JIP::LockSocket->new(port => 4242, addr => 'localhost')->addr, 'localhost');
};

subtest 'not is_locked at startup' => sub {
    plan tests => 1;

    cmp_ok init_obj()->is_locked, q{==}, 0;
};

subtest 'unlock on non-is_locked changes nothing' => sub {
    plan tests => 2;

    is ref(init_obj()->unlock), 'JIP::LockSocket';
    cmp_ok init_obj()->is_locked, q{==}, 0;
};

subtest 'lock()' => sub {
    plan tests => 4;

    my $obj = init_obj();

    is ref($obj->lock), 'JIP::LockSocket';
    cmp_ok $obj->is_locked, q{==}, 1;

    # Re-locking changes nothing
    is ref($obj->lock), 'JIP::LockSocket';
    cmp_ok $obj->is_locked, q{==}, 1;
};

subtest 'unlock()' => sub {
    plan tests => 1;

    my $obj = init_obj()->lock;

    $obj->unlock;

    cmp_ok $obj->is_locked, q{==}, 0;
};

subtest 'unlocking on scope exit' => sub {
    plan tests => 1;

    {
        init_obj()->lock;
    }

    cmp_ok init_obj()->lock->is_locked, q{==}, 1;
};

subtest 'Lock or raise an exception' => sub {
    plan tests => 1;

    my $obj = init_obj()->lock;

    eval { init_obj()->lock } or do {
        like $EVAL_ERROR, qr{^Can't \s lock \s port \s "4242":}x;
    };
};

subtest 'try_lock()' => sub {
    plan tests => 2;

    my $obj = init_obj()->try_lock;

    # Re-locking changes nothing
    cmp_ok $obj->try_lock->is_locked, q{==}, 1;

    # Or just return undef
    is(init_obj()->try_lock, undef);
};

sub init_obj {
    my $port = shift || 4242;
    return JIP::LockSocket->new(port => $port);
}

