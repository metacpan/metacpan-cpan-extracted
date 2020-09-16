use 5.014;
use warnings;
use Test::More 0.98;

sub new {
    my $bspline;

    $bspline = Math::BSpline::Basis->new(
        degree      => 2,
        knot_vector => [0, 0, 0, 1, 1, 1],
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, 2, 'degree is 2');
    is_deeply(
        $bspline->knot_vector,
        [0, 0, 0, 1, 1, 1],
        'knot vector as specified',
    );

    $bspline = Math::BSpline::Basis->new(
        degree => 2,
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, 2, 'degree is 2');
    is_deeply(
        $bspline->knot_vector,
        [0, 0, 0, 1, 1, 1],
        'default Bezier knot vector',
    );
}

sub moo_behavior {
    my $bspline;

    $bspline = Math::BSpline::Basis->new(
        {
            degree      => 2,
            knot_vector => [0, 0, 0, 1, 1, 1],
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, 2, 'degree is 2');
    is_deeply(
        $bspline->knot_vector,
        [0, 0, 0, 1, 1, 1],
        'knot vector as specified',
    );

    $bspline = Math::BSpline::Basis->new(
        {
            degree => 2,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, 2, 'degree is 2');
    is_deeply(
        $bspline->knot_vector,
        [0, 0, 0, 1, 1, 1],
        'default Bezier knot vector',
    );
}

sub munge_knot_vector {
    my $bspline;
    my $U;
    my $Um;
    my $Ut;
    my $p;

    $p  = 2;
    $U  = undef;
    $Um = [0, 0, 0, 1, 1, 1];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [];
    $Ut = [];
    $Um = [0, 0, 0, 1, 1, 1];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 1];
    $Ut = [0, 1];
    $Um = [0, 0, 0, 1, 1, 1];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [1, 0];
    $Ut = [1, 0];
    $Um = [0, 0, 0, 1, 1, 1];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0];
    $Ut = [0];
    $Um = [0, 0, 0, 1, 1, 1];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [1];
    $Ut = [1];
    $Um = [1, 1, 1, 2, 2, 2];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 1, 2];
    $Ut = [0, 1, 2];
    $Um = [0, 0, 0, 1, 2, 2, 2];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 0, 1, 1, 1];
    $Ut = [0, 0, 0, 0, 1, 1, 1];
    $Um = [0, 0, 0, 1, 1, 1];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 1, 1, 1, 1];
    $Ut = [0, 0, 0, 1, 1, 1, 1];
    $Um = [0, 0, 0, 1, 1, 1];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 0, 1, 1, 1, 1];
    $Ut = [0, 0, 0, 0, 1, 1, 1, 1];
    $Um = [0, 0, 0, 1, 1, 1];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 1, 1, 2];
    $Ut = [0, 1, 1, 2];
    $Um = [0, 0, 0, 1, 1, 2, 2, 2];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 1, 1, 1, 2];
    $Ut = [0, 1, 1, 1, 2];
    $Um = [0, 0, 0, 1, 1, 2, 2, 2];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 0, 1, 1, 1, 2, 3, 3, 3, 3];
    $Ut = [0, 0, 0, 0, 1, 1, 1, 2, 3, 3, 3, 3];
    $Um = [0, 0, 0, 1, 1, 2, 3, 3, 3];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 0, 1, 1, 1, 3, 3, 3, 3, 2];
    $Ut = [0, 0, 0, 0, 1, 1, 1, 3, 3, 3, 3, 2];
    $Um = [0, 0, 0, 1, 1, 2, 3, 3, 3];
    $bspline = Math::BSpline::Basis->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($bspline), 'defined');
    isa_ok($bspline, 'Math::BSpline::Basis');
    is($bspline->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $bspline->knot_vector,
        $Um,
        'knot vector as munged',
    );
}

use_ok('Math::BSpline::Basis');
new;
moo_behavior;
munge_knot_vector;
done_testing;
