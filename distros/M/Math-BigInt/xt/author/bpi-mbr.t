# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 106;

use Math::BigRat;

subtest "Called as class method without argument.", sub {

    # With no argument, the default div_scale of 40 is used.

    my $x = Math::BigRat -> bpi();
    isa_ok($x, 'Math::BigRat');

    # Compute reference value with Math::BigFloat and compare.

    my $mbf_ref  = Math::BigFloat -> bpi(50);
    my $rel_err = $x -> as_float(50) -> bsub($mbf_ref) -> bdiv($mbf_ref);
    $rel_err -> babs() -> bround(5);
    my $rel_tol = Math::BigFloat -> new("1e-40");

    my $rel_err_num = $rel_err -> numify();
    my $rel_tol_num = $rel_tol -> numify();

    ok(abs($rel_err) < $rel_tol);
    note(sprintf(<<"EOF", $rel_err_num, $rel_tol_num));

        relative error: %+.5e
    relative tolerance: %+.5e
EOF
};

subtest "Called as class method with scalar argument.", sub {

    my $x = Math::BigRat -> bpi(16);
    isa_ok($x, 'Math::BigRat');

    # Compute reference value with Math::BigFloat and compare.

    my $mbf_ref  = Math::BigFloat -> bpi(26);
    my $rel_err = $x -> as_float(26) -> bsub($mbf_ref) -> bdiv($mbf_ref);
    $rel_err -> babs() -> bround(5);
    my $rel_tol = Math::BigFloat -> new("1e-16");

    my $rel_err_num = $rel_err -> numify();
    my $rel_tol_num = $rel_tol -> numify();

    ok(abs($rel_err) < $rel_tol);
    note(sprintf(<<"EOF", $rel_err_num, $rel_tol_num));

        relative error: %+.5e
    relative tolerance: %+.5e
EOF
};

subtest "Called as class method with instance argument.", sub {

    my $n = Math::BigRat -> new("16");

    my $x = Math::BigRat -> bpi($n);
    isa_ok($x, 'Math::BigRat');

    # Compute reference value with Math::BigFloat and compare.

    my $mbf_ref  = Math::BigFloat -> bpi(26);
    my $rel_err = $x -> as_float(26) -> bsub($mbf_ref) -> bdiv($mbf_ref);
    my $rel_tol = Math::BigFloat -> new("1e-16");
    $rel_err -> babs() -> bround(5);

    my $rel_err_num = $rel_err -> numify();
    my $rel_tol_num = $rel_tol -> numify();

    ok(abs($rel_err) < $rel_tol);
    note(sprintf(<<"EOF", $rel_err_num, $rel_tol_num));

        relative error: %+.5e
    relative tolerance: %+.5e
EOF
};

subtest "Called as instance method without argument.", sub {

    # With no argument, the default div_scale of 40 is used.

    my $x = Math::BigRat -> bnan();
    $x -> bpi();
    isa_ok($x, 'Math::BigRat');

    # Compute reference value with Math::BigFloat and compare.

    my $mbf_ref  = Math::BigFloat -> bpi(50);
    my $rel_err = $x -> as_float(50) -> bsub($mbf_ref) -> bdiv($mbf_ref);
    $rel_err -> babs() -> bround(5);
    my $rel_tol = Math::BigFloat -> new("1e-40");

    my $rel_err_num = $rel_err -> numify();
    my $rel_tol_num = $rel_tol -> numify();

    ok(abs($rel_err) < $rel_tol);
    note(sprintf(<<"EOF", $rel_err_num, $rel_tol_num));

        relative error: %+.5e
    relative tolerance: %+.5e
EOF
};

subtest "Called as instance method with scalar argument.", sub {

    my $x = Math::BigRat -> bnan();
    $x -> bpi(16);
    isa_ok($x, 'Math::BigRat');

    # Compute reference value with Math::BigFloat and compare.

    my $mbf_ref  = Math::BigFloat -> bpi(26);
    my $rel_err = $x -> as_float(26) -> bsub($mbf_ref) -> bdiv($mbf_ref);
    $rel_err -> babs() -> bround(5);
    my $rel_tol = Math::BigFloat -> new("1e-16");

    my $rel_err_num = $rel_err -> numify();
    my $rel_tol_num = $rel_tol -> numify();

    ok(abs($rel_err) < $rel_tol);
    note(sprintf(<<"EOF", $rel_err_num, $rel_tol_num));

        relative error: %+.5e
    relative tolerance: %+.5e
EOF
};

subtest "Called as instance method with instance argument.", sub {

    my $n = Math::BigRat -> new("16");

    my $x = Math::BigRat -> bnan();
    $x -> bpi($n);
    isa_ok($x, 'Math::BigRat');

    # Compute reference value with Math::BigFloat and compare.

    my $mbf_ref  = Math::BigFloat -> bpi(26);
    my $rel_err = $x -> as_float(26) -> bsub($mbf_ref) -> bdiv($mbf_ref);
    $rel_err -> babs() -> bround(5);
    my $rel_tol = Math::BigFloat -> new("1e-16");

    my $rel_err_num = $rel_err -> numify();
    my $rel_tol_num = $rel_tol -> numify();

    ok(abs($rel_err) < $rel_tol);
    note(sprintf(<<"EOF", $rel_err_num, $rel_tol_num));

        relative error: %+.5e
    relative tolerance: %+.5e
EOF
};

for my $n (1 .. 100) {

    note "\nMath::BigRat -> bpi($n);\n\n";

    # Compute rational approximation of PI.

    my $mbr = Math::BigRat -> bpi($n);

    # Convert rational approximation to a floating point number using some
    # extra digits.

    my $mbf = $mbr -> as_float($n + 10);

    # Compute reference value, again using some extra digits.

    my $mbf_ref = Math::BigFloat -> bpi($n + 10);

    # Compute the absolute error.

    my $abs_err = $mbf - $mbf_ref;

    # Compute the relative error.

    my $rel_err = $abs_err / $mbf_ref;

    my $rel_tol = Math::BigFloat -> new("0.1") -> bpow($n);

    my $rel_err_num = $rel_err -> numify();
    my $rel_tol_num = $rel_tol -> numify();

    ok(abs($rel_err) < $rel_tol);
    note(sprintf(<<"EOF", $rel_err_num, $rel_tol_num));

        relative error: %+.5e
    relative tolerance: %+.5e
EOF
};
