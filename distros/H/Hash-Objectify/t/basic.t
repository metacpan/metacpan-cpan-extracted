use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;
use Scalar::Util qw/blessed/;

# load and API test
use Hash::Objectify;

can_ok( "main", 'objectify' );

# objectify HASHREF and accessor test

my $obj = objectify { foo => 'bar', baz => 'bam' };

like( ref $obj, qr/Hash::Objectified/, "C<objectify HASHREF> returns object" );

is( $obj->foo, 'bar', "foo accessor reads" );
$obj->foo("wibble");
is( $obj->foo, 'wibble', "foo accessor writes" );

for my $key (qw/foo baz/) {
    can_ok( $obj, $key );
}

# bad accessor test

like(
    exception { $obj->badkey },
    qr/Can't locate.*badkey/,
    "unknown accessor throws exception"
);

# 'can' shouldn't be fatal

my @rv;
is( exception { @rv = $obj->can('badkeydoesntexist') },
    undef, "calling 'can' on bad key isn't fatal" );
is_deeply( \@rv, [undef], "non-existent can() returns undef even in list context" );

# objectify class name test

my $obj2 = objectify { foo => 'bar', baz => 'bam' };

like( ref $obj2, qr/Hash::Objectified/, "C<objectify HASHREF> returns object" );

isnt( ref $obj, ref $obj2,
    "objectified objects from different lines are different classes" );

for my $key (qw/foo baz/) {
    can_ok( $obj2, $key );
}

# confirm that same lines/keys gives same objectified class; different line/keys gives different classes

sub make_hash_obj {
    return objectify { @_ };
}

my $obj3 = make_hash_obj( foo => 'bar' );
my $obj4 = make_hash_obj( foo => 'bar' );
my $obj5 = make_hash_obj( baz => 'bam' );
is( ref $obj3, ref $obj4,
    "objectified objects from same line with same keys are same class" );
isnt( ref $obj3, ref $obj5,
    "objectified objects from same line with different keys are different classes" );

# confirm that requested package name is used and inherits correctly

sub make_named_obj {
    return objectify { @_ }, "Wibble";
}

my $obj6 = make_named_obj( foo => 'bar' );
my $obj7 = make_named_obj( baz => 'bam' );
is( ref $obj6, 'Wibble',
    "C<objectify HASHREF, PACKAGE> returns object blessed to PACKAGE" );
is( ref $obj7, 'Wibble',
    "C<objectify HASHREF, PACKAGE> with different keys is still in PACKAGE" );
ok( $obj6->isa("Hash::Objectified"), "PACKAGE inherits Hash::Objectified" );
is( $obj6->foo, 'bar', "PACKAGE accessor works" );

# reference is copied, not blessed

my $hash = { foo => 'bar' };
ok( my $obj8 = objectify($hash), "objectify HASHREF" );
ok( !blessed $hash, "original HASHREF is not blessed" );
is_deeply( $hash, $obj8, "original and object contents are same" );

# test 'lax' mode
{

    package with::laxity;
    use Test::More;
    use Hash::Objectify qw/objectify_lax/;

    my $obj = objectify_lax( { foo => 'bar' } );
    is( $obj->foo,  'bar', "existing key works" );
    is( $obj->quux, undef, "non-existing key returns undef" );
}

done_testing;
#
# This file is part of Hash-Objectify
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
