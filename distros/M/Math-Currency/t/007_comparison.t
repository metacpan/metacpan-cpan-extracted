#!/usr/bin/env perl

use Test::More tests => 4;

use_ok 'Math::Currency';

# For subsequent testing, we need to make sure that format is default US
Math::Currency->format('USD');

subtest '==' => sub {
    plan tests => 4;

    my $object = Math::Currency->new('19.95');
    my $scalar = 19.95;

    cmp_ok( $object, '==', $object, 'Object == Object' );
    cmp_ok( $scalar, '==', $object, 'Scalar == Object' );
    cmp_ok( $object, '==', $scalar, 'Object == Scalar' );

    ok( !( Math::Currency->new('19.95') == Math::Currency->new('15.00') ), 'Object != Object' );
};

subtest '<=' => sub {
    plan tests => 2;

    subtest '==' => sub {
        plan tests => 4;

        my $object = Math::Currency->new('19.95');
        my $scalar = 19.95;

        cmp_ok( $object, '<=', $object, 'Object == Object' );
        cmp_ok( $scalar, '<=', $object, 'Scalar == Object' );
        cmp_ok( $object, '<=', $scalar, 'Object == Scalar' );

        ok( !( Math::Currency->new('19.95') <= Math::Currency->new('15.00') ), 'Object (!)<= Object' );
    };

    subtest '<=' => sub {
        plan tests => 4;

        my $lesser_object  = Math::Currency->new('15.00');
        my $lesser_scalar  = 15.00;
        my $greater_object = Math::Currency->new('19.95');
        my $greater_scalar = 19.95;

        cmp_ok( $lesser_object, '<=', $greater_object, 'Object <= Object' );
        cmp_ok( $lesser_scalar, '<=', $greater_object, 'Scalar <= Object' );
        cmp_ok( $lesser_object, '<=', $greater_scalar, 'Object <= Scalar' );

        ok( !( $greater_object <= $lesser_object ), 'Object (!)<= Object' );
    };
};

subtest '>=' => sub {
    plan tests => 2;

    subtest '==' => sub {
        plan tests => 4;

        my $object = Math::Currency->new('19.95');
        my $scalar = 19.95;

        cmp_ok( $object, '>=', $object, 'Object == Object' );
        cmp_ok( $scalar, '>=', $object, 'Scalar == Object' );
        cmp_ok( $object, '>=', $scalar, 'Object == Scalar' );

        ok( !( Math::Currency->new('15.00') >= Math::Currency->new('19.95') ), 'Object (!)>= Object' );
    };

    subtest '>=' => sub {
        plan tests => 4;

        my $lesser_object  = Math::Currency->new('15.00');
        my $lesser_scalar  = 15.00;
        my $greater_object = Math::Currency->new('19.95');
        my $greater_scalar = 19.95;

        cmp_ok( $lesser_object, '>=', $lesser_object, 'Object >= Object' );
        cmp_ok( $lesser_scalar, '>=', $lesser_object, 'Scalar >= Object' );
        cmp_ok( $lesser_object, '>=', $lesser_scalar, 'Object >= Scalar' );


        ok( !( $lesser_object >= $greater_object ), 'Object (!)>= Object' );
    };
};
