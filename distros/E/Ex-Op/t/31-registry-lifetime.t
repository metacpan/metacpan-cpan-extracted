#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Ex::Op ();

plan skip_all => 'threads: Devel::Cover does not work with them' if $INC{'Devel/Cover.pm'};

no strict 'refs';

{
    Ex::Op::make(redef => sub { my ($x) = @_; $x + 1 });
    my $old = \&redef;
    ok( Ex::Op::is_op($old), 'an op' );
    {
        no warnings 'redefine';
        eval q{ sub redef { my ($x) = @_; $x + 2 } 1 } or die $@;
    }
    ok( !Ex::Op::is_op(\&redef), 'redefined, the new body is not an op' );
    if ($old == \&redef) {
        is( Ex::Op::why_not(\&redef), 'it has been redefined or undefined since it was made an op',
            '... and why_not says the body changed under it' );
    }
    else {
        is( Ex::Op::why_not(\&redef), 'it was never made an op', '... a new sub, never made one' );
    }
    is( redef(1), 3, '... and the new body runs' );
}

{
    Ex::Op::make(gone => sub { my ($x) = @_; $x });
    my $ref = \&gone;
    undef &gone;
    ok( !Ex::Op::is_op($ref), 'undefined, it is not an op' );
    is( Ex::Op::why_not($ref), 'it has been redefined or undefined since it was made an op', '... and why_not says so' );
}

{
    my $code = sub { my ($x) = @_; $x };
    Ex::Op::make(twice => $code);
    ok( Ex::Op::make(twice2 => $code), 'the same sub made an op twice' );
    ok( Ex::Op::is_op($code), '... is still an op' );
}

{
    for my $i (1 .. 2000) {
        my $n = $i;
        my $code = sub { my ($x) = @_; $x + $n };
        Ex::Op::make("EO::Churn::f$i", $code);
        delete $EO::Churn::{"f$i"};
    }
    pass( '2000 closures made ops and freed' );
}

SKIP: {
    skip 'no threads', 5 unless $Config{useithreads};
    skip 'threads will not load', 5 unless eval { require threads; 1 };
    Ex::Op::make(threaded => sub { my ($x) = @_; $x * 3 });
    Ex::Op::make(threaded_none => sub { 7 });
    Ex::Op::make(threaded_bad => sub { shift });
    my ($is, $why, $val, $none, $bad) = @{ threads->create(sub {
        [ Ex::Op::is_op(\&threaded) ? 1 : 0, Ex::Op::why_not(\&threaded), threaded(2), Ex::Op::is_op(\&threaded_none) ? threaded_none() : 0, Ex::Op::why_not(\&threaded_bad) ];
    })->join };
    is( $is, 1, 'an op in a new thread is still an op' );
    is( $why, undef, '... with no reason not to be' );
    is( $val, 6, '... and runs' );
    is( $none, 7, '... and so does one with no parameters' );
    is( $bad, 'it reads @_ after its parameters', '... and a declined sub keeps its reason' );
}

done_testing;
