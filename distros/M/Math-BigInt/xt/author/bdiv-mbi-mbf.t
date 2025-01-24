#!/bin/perl

use strict;
use warnings;

use Scalar::Util 'refaddr';
use Test::More tests => 72;

use Math::BigFloat;

note "Scalar context, no upgrading or downgrading";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade(undef);

{
    # this must not upgrade

    my $x = Math::BigInt -> new(9);
    my $q = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

{
    # this must not downgrade

    my $x = Math::BigFloat -> new(8);
    my $q = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

note "Scalar context, upgrading, but no downgrading";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade(undef);

{
    # this must upgrade

    my $x = Math::BigInt -> new(9);
    my $q = $x -> bdiv(4);

    is($x, "2.25", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

{
    # this must not downgrade

    my $x = Math::BigFloat -> new(8);
    my $q = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

note "Scalar context, downgrading, but no upgrading";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade("Math::BigInt");

{
    # this must not upgrade

    my $x = Math::BigInt -> new(9);
    my $q = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

{
    # this must downgrade

    my $x = Math::BigFloat -> new(8);
    my $q = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

note "Scalar context, upgrading and downgrading";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

{
    # this must upgrade

    my $x = Math::BigInt -> new(9);
    my $q = $x -> bdiv(4);

    is($x, "2.25", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

{
    # this must downgrade

    my $x = Math::BigFloat -> new(8);
    my $q = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

{
    # this must upgrade internally, then downgrade the result

    my $x = Math::BigInt -> new(8);
    my $q = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");
}

note "List context, no upgrading or downgrading";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade(undef);

{
    # this must not upgrade

    my $x = Math::BigInt -> new(9);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "1", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
}

{
    # this must not downgrade

    my $x = Math::BigFloat -> new(8);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigFloat", "remainder class");
}

note "List context, upgrading, but no downgrading";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade(undef);

{
    # this must not upgrade, because in list context, we want both the
    # quotient and the remainder, and when dividing two integers, we know
    # in advance that the quotient and remainder are integers

    my $x = Math::BigInt -> new(9);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "1", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
}

{
    # this must not downgrade

    my $x = Math::BigFloat -> new(8);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigFloat", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigFloat", "remainder class");
}

note "List context, downgrading, but no upgrading";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade("Math::BigInt");

{
    # this must not upgrade

    my $x = Math::BigInt -> new(9);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "1", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
}

{
    # this must downgrade

    my $x = Math::BigFloat -> new(8);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
}

note "List context, upgrading and downgrading";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

{
    # this must upgrade internally, then downgrade the results

    my $x = Math::BigInt -> new(9);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "1", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
}

{
    # this must downgrade

    my $x = Math::BigFloat -> new(8);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
}

{
    # this must upgrade internally, then downgrade the results

    my $x = Math::BigInt -> new(8);
    my ($q, $r) = $x -> bdiv(4);

    is($x, "2", "quotient value");
    is(ref($x), "Math::BigInt", "quotient class");
    is(refaddr($x), refaddr($q), "quotient address");

    is($r, "0", "remainder value");
    is(ref($r), "Math::BigInt", "remainder class");
}
