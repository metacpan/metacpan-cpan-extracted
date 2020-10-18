use 5.014;
use warnings;
use Test::More 0.98;

sub new {
    my $curve;

    $curve = Math::BSpline::Curve->new(
        degree => 2,
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
}

sub moo_behavior {
    my $curve;

    $curve = Math::BSpline::Curve->new(
        {
            degree      => 2,
            knot_vector => [0, 0, 0, 0.5, 1, 1, 1],
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, 2, 'degree is 2');
    is_deeply(
        $curve->knot_vector,
        [0, 0, 0, 0.5, 1, 1, 1],
        'knot vector as specified',
    );

    $curve = Math::BSpline::Curve->new(
        {
            degree => 2,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, 2, 'degree is 2');
    is_deeply(
        $curve->knot_vector,
        [0, 0, 0, 1, 1, 1],
        'default Bezier knot vector',
    );
}

sub munge_knot_vector {
    my $curve;
    my $U;
    my $Um;
    my $Ut;
    my $p;

    $p  = 2;
    $U  = undef;
    $Um = [0, 0, 0, 1, 1, 1];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [];
    $Ut = [];
    $Um = [0, 0, 0, 1, 1, 1];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 1];
    $Ut = [0, 1];
    $Um = [0, 0, 0, 1, 1, 1];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [1, 0];
    $Ut = [1, 0];
    $Um = [0, 0, 0, 1, 1, 1];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0];
    $Ut = [0];
    $Um = [0, 0, 0, 1, 1, 1];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [1];
    $Ut = [1];
    $Um = [1, 1, 1, 2, 2, 2];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 1, 2];
    $Ut = [0, 1, 2];
    $Um = [0, 0, 0, 1, 2, 2, 2];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 0, 1, 1, 1];
    $Ut = [0, 0, 0, 0, 1, 1, 1];
    $Um = [0, 0, 0, 1, 1, 1];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 1, 1, 1, 1];
    $Ut = [0, 0, 0, 1, 1, 1, 1];
    $Um = [0, 0, 0, 1, 1, 1];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 0, 1, 1, 1, 1];
    $Ut = [0, 0, 0, 0, 1, 1, 1, 1];
    $Um = [0, 0, 0, 1, 1, 1];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 1, 1, 2];
    $Ut = [0, 1, 1, 2];
    $Um = [0, 0, 0, 1, 1, 2, 2, 2];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 1, 1, 1, 2];
    $Ut = [0, 1, 1, 1, 2];
    $Um = [0, 0, 0, 1, 1, 2, 2, 2];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 0, 1, 1, 1, 2, 3, 3, 3, 3];
    $Ut = [0, 0, 0, 0, 1, 1, 1, 2, 3, 3, 3, 3];
    $Um = [0, 0, 0, 1, 1, 2, 3, 3, 3];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );

    $p  = 2;
    $U  = [0, 0, 0, 0, 1, 1, 1, 3, 3, 3, 3, 2];
    $Ut = [0, 0, 0, 0, 1, 1, 1, 3, 3, 3, 3, 2];
    $Um = [0, 0, 0, 1, 1, 2, 3, 3, 3];
    $curve = Math::BSpline::Curve->new(
        {
            degree      => $p,
            knot_vector => $U,
        },
    );

    ok(defined($curve), 'defined');
    isa_ok($curve, 'Math::BSpline::Curve');
    is($curve->degree, $p, "degree is $p");
    is_deeply(
        $U,
        $Ut,
        'parameter unchanged',
    );
    is_deeply(
        $curve->knot_vector,
        $Um,
        'knot vector as munged',
    );
}

use_ok('Math::BSpline::Curve');
new;
moo_behavior;
munge_knot_vector;
done_testing;
