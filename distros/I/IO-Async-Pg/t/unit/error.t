use strict;
use warnings;
use Test2::V0;

use IO::Async::Pg::Error;

subtest 'base error class' => sub {
    my $err = IO::Async::Pg::Error->new(
        message => 'Something went wrong',
    );

    isa_ok $err, 'IO::Async::Pg::Error';
    is $err->message, 'Something went wrong', 'message accessor';
    like "$err", qr/Something went wrong/, 'stringifies to message';
};

subtest 'query error' => sub {
    my $err = IO::Async::Pg::Error::Query->new(
        message    => 'duplicate key value violates unique constraint',
        code       => '23505',
        constraint => 'users_email_key',
        detail     => 'Key (email)=(test@example.com) already exists.',
        hint       => undef,
        position   => 42,
    );

    isa_ok $err, 'IO::Async::Pg::Error';
    isa_ok $err, 'IO::Async::Pg::Error::Query';

    is $err->code, '23505', 'SQLSTATE code';
    is $err->constraint, 'users_email_key', 'constraint name';
    is $err->detail, 'Key (email)=(test@example.com) already exists.', 'detail';
    is $err->hint, undef, 'hint can be undef';
    is $err->position, 42, 'position';
    is $err->state, 'unique_violation', 'human-readable state from code';
};

subtest 'connection error' => sub {
    my $err = IO::Async::Pg::Error::Connection->new(
        message => 'Connection refused',
        dsn     => 'postgresql://localhost/test',
    );

    isa_ok $err, 'IO::Async::Pg::Error';
    isa_ok $err, 'IO::Async::Pg::Error::Connection';

    is $err->dsn, 'postgresql://localhost/test', 'dsn accessor';
};

subtest 'pool exhausted error' => sub {
    my $err = IO::Async::Pg::Error::PoolExhausted->new(
        message   => 'Connection pool exhausted (waited 5s)',
        pool_size => 10,
    );

    isa_ok $err, 'IO::Async::Pg::Error';
    isa_ok $err, 'IO::Async::Pg::Error::PoolExhausted';

    is $err->pool_size, 10, 'pool_size accessor';
};

subtest 'timeout error' => sub {
    my $err = IO::Async::Pg::Error::Timeout->new(
        message => 'Query timeout after 30s',
        timeout => 30,
    );

    isa_ok $err, 'IO::Async::Pg::Error';
    isa_ok $err, 'IO::Async::Pg::Error::Timeout';

    is $err->timeout, 30, 'timeout accessor';
};

subtest 'errors can be thrown and caught' => sub {
    my $caught;
    eval {
        die IO::Async::Pg::Error::Query->new(
            message => 'syntax error',
            code    => '42601',
        );
    };
    $caught = $@;

    ok $caught, 'error was thrown';
    isa_ok $caught, 'IO::Async::Pg::Error::Query';
    is $caught->code, '42601', 'caught error has correct code';
};

done_testing;
