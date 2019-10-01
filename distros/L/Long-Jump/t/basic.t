use Test2::V0;

use Long::Jump qw/setjump longjump/;

BEGIN {
    my $got = setjump foo => sub {
        longjump foo => qw/x y z/;
        ok(0, "Should not get here");
    };

    is($got, [qw/x y z/], "Got the results of the long jump in a BEGIN");
}

my $got = setjump foo => sub {
    longjump foo => qw/x y z/;
    ok(0, "Should not get here");
};
is($got, [qw/x y z/], "Got the results of the long jump at runtime");

$got = setjump foo => sub { 1 };
is($got, undef, "Did not jump");

$got = setjump foo => sub { longjump 'foo' };
is($got, [], "Jump with no values");

$got = setjump foo => sub {
    setjump bar => sub {
        setjump baz => sub {
            longjump foo => qw/x y z/;
            ok(0, "Should not get here");
        };
        ok(0, "Should not get here");
    };
    ok(0, "Should not get here");
};
is($got, [qw/x y z/], "Got the results of the long jump within several jump points");

$got = setjump foo => sub {
    my $in = setjump bar => sub {
        setjump baz => sub {
            longjump bar => qw/x y z/;
            ok(0, "Should not get here");
        };
        ok(0, "Should not get here");
    };
    is($in, [qw/x y z/], "inner jump got args");
};
is($got, undef, "Outer jump did not get anything");

like(dies { setjump() }, qr/You must name your jump point/, "Need to label the jump" );
like(dies { setjump('foo') }, qr/You must provide a subroutine as a second argument/, "Need a sub" );
like(dies { setjump('foo', {}) }, qr/You must provide a subroutine as a second argument/, "Must be a coderef" );

like(
    dies {
        setjump(
            'foo',
            sub {
                setjump('foo', sub { });
            }
        )
    },
    qr/There is already a jump point named 'foo'/,
    "Cannot nest jump points with the same name"
);

like(
    dies { longjump 'foo' },
    qr/No such jump point: 'foo'/,
    "Must be a valid jump point"
);

{
    no warnings 'redefine';
    my $count = 1;

    # This lets us skip the first croak and test the second
    local *Long::Jump::croak = sub {
        return if $count--;
        Carp::croak(@_);
    };

    # Theoretically a user can never get here, but if they do we want to be
    # sure to see the full error message.
    like(
        dies { longjump 'foo' },
        qr/longjump\('foo'\) failed, error: Label not found for "last LONG_JUMP_SET"/,
        "Errors in the call to 'last' get passed on"
    );
}

done_testing;
