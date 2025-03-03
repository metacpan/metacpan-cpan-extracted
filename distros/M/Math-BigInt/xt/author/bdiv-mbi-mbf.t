# -*- mode: perl; -*-

use strict;
use warnings;

use Scalar::Util 'refaddr';
use Test::More tests => 40;

use Math::BigFloat;

note "\nScalar context, no upgrading or downgrading\n\n";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade(undef);

subtest '$x = Math::BigInt -> new("9"); $q = $x -> bdiv("4");' => sub {
    # this must not upgrade

    my $x = Math::BigInt -> new("9");
    my $q = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("8"); $q = $x -> bdiv("4");' => sub {
    # this must not downgrade

    my $x = Math::BigFloat -> new("8");
    my $q = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

note "\nScalar context, upgrading, but no downgrading\n\n";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade(undef);

subtest '$x = Math::BigInt -> new("9"); $q = $x -> bdiv("4");' => sub {
    # this must upgrade

    my $x = Math::BigInt -> new("9");
    my $q = $x -> bdiv("4");

    is($x, "2.25", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigInt -> new("8"); $q = $x -> bdiv("4");' => sub {
    # this must not upgrade

    my $x = Math::BigInt -> new("8");
    my $q = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("8"); $q = $x -> bdiv("4");' => sub {
    # this must not downgrade

    my $x = Math::BigFloat -> new("8");
    my $q = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

note "\nScalar context, downgrading, but no upgrading\n\n";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade("Math::BigInt");

subtest '$x = Math::BigInt -> new("9"); $q = $x -> bdiv("4");' => sub {
    # this must not upgrade

    my $x = Math::BigInt -> new("9");
    my $q = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("8"); $q = $x -> bdiv("4");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my $q = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("7.5"); $q = $x -> bdiv("2.5");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("7.5");
    my $q = $x -> bdiv("2.5");

    is($x, "3", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("8"); $q = $x -> bdiv("1");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my $q = $x -> bdiv("1");

    is($x, "8", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("8"); $q = $x -> bdiv("0");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my $q = $x -> bdiv("0");

    is($x, "inf", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("0"); $q = $x -> bdiv("0");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("0");
    my $q = $x -> bdiv("0");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("NaN"); $q = $x -> bdiv("4");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("NaN");
    my $q = $x -> bdiv("4");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

note "\nScalar context, upgrading and downgrading\n\n";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

subtest '$x = Math::BigInt -> new("8"); $q = $x -> bdiv("4");' => sub {
    # this must not upgrade

    my $x = Math::BigInt -> new("8");
    my $q = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigInt -> new("9"); $q = $x -> bdiv("4");' => sub {
    # this must upgrade

    my $x = Math::BigInt -> new("9");
    my $q = $x -> bdiv("4");

    is($x, "2.25", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("8"); $q = $x -> bdiv("4");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my $q = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("7.5"); $q = $x -> bdiv("2.5");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("7.5");
    my $q = $x -> bdiv("2.5");

    is($x, "3", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("8"); $q = $x -> bdiv("1");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my $q = $x -> bdiv("1");

    is($x, "8", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("8"); $q = $x -> bdiv("0");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my $q = $x -> bdiv("0");

    is($x, "inf", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("0"); $q = $x -> bdiv("0");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("0");
    my $q = $x -> bdiv("0");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

subtest '$x = Math::BigFloat -> new("NaN"); $q = $x -> bdiv("4");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("NaN");
    my $q = $x -> bdiv("4");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
};

note "\nList context, no upgrading or downgrading\n\n";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade(undef);

subtest '$x = Math::BigInt -> new("9"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must not upgrade

    my $x = Math::BigInt -> new("9");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "1", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must not downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigFloat", "remainder class");
};

note "\nList context, upgrading, but no downgrading\n\n";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade(undef);

subtest '$x = Math::BigInt -> new("9"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must not upgrade, because in list context, we want both the
    # quotient and the remainder, and when dividing two integers, we know
    # in advance that the quotient and remainder are integers

    my $x = Math::BigInt -> new("9");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "1", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must not downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigFloat", "remainder class");
};

note "\nList context, downgrading, but no upgrading\n\n";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade("Math::BigInt");

subtest '$x = Math::BigInt -> new("9"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must not upgrade

    my $x = Math::BigInt -> new("9");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "1", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("7.5"); ($q, $r) = $x -> bdiv("2.5");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("7.5");
    my ($q, $r) = $x -> bdiv("2.5");

    is($x, "3", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("1");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("1");

    is($x, "8", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("0");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("0");

    is($x, "inf", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "8", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("0"); ($q, $r) = $x -> bdiv("0");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("0");
    my ($q, $r) = $x -> bdiv("0");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("NaN"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("NaN");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "NaN", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("2.5");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("2.5");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "NaN", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

note "\nList context, upgrading and downgrading\n\n";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

subtest '$x = Math::BigInt -> new("9"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must upgrade internally, then downgrade the results

    my $x = Math::BigInt -> new("9");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "1", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("7.5"); ($q, $r) = $x -> bdiv("2.5");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("7.5");
    my ($q, $r) = $x -> bdiv("2.5");

    is($x, "3", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("1");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("1");

    is($x, "8", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("0");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("0");

    is($x, "inf", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "8", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("0"); ($q, $r) = $x -> bdiv("0");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("0");
    my ($q, $r) = $x -> bdiv("0");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("NaN"); ($q, $r) = $x -> bdiv("4");' => sub {
    # this must downgrade

    my $x = Math::BigFloat -> new("NaN");
    my ($q, $r) = $x -> bdiv("4");

    is($x, "NaN", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "NaN", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
};

subtest '$x = Math::BigFloat -> new("8"); ($q, $r) = $x -> bdiv("2.5");' => sub {
    # this must downgrade, but only the quotient, not the remainder

    my $x = Math::BigFloat -> new("8");
    my ($q, $r) = $x -> bdiv("2.5");

    is($x, "3", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0.5", "remainder value");
    is(ref($r), "Math::BigFloat", "remainder class");
};
