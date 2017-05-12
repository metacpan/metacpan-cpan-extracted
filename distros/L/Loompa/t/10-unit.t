# Copyright (C) 2007 Randall Hansen
# This program is free software; you can redistribute it and/or modify it under the terms as Perl itself.
package Loompa::Test::Unit;
use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 69;
use Test::Exception;

use vars qw/ $CLASS $one $tmp /;

BEGIN {
    *CLASS = \'Loompa';
    use_ok( $CLASS );
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ok( $one = Loompa->new );
    ok( defined( $one ));
    ok( $one->isa( 'Loompa' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# custom methods, simple
    can_ok( $one, '_make_method' );
    throws_ok{ $one->_make_method( 'foo', \'bar' )} qr/Second argument, if supplied, must be scalar value or subroutine reference/;
    throws_ok{ $one->_make_method( 'foo', { foo => 'bar' })} qr/Second argument, if supplied, must be scalar value or subroutine reference/;

    ok( $one->_make_method( 'foo', sub { 'i am foo!' }));
    can_ok( $one, 'foo' );
    is( $one->foo, 'i am foo!' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# custom methods, self-knowing
    ok( $one->_make_method( 'bar', sub { 
        my $self = shift;
        my $name = shift;

        my $parent = ref $self;
        return "My name is '$name' and my parent is '$parent'";
    }));
    is( $one->bar, "My name is 'bar' and my parent is 'Loompa'" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# default value
    ok( $one->_make_method( 'zork', 'Nemesis' ));
    is( $one->zork, undef ); # default values only set by constructor or 'set_defaults'

    ok( defined $one->zork( 0 ));
    is( $one->zork, 0 );

    is( $one->zork( undef ), undef );
    is( $one->zork, undef );

    ok( $one->zork( 'Zardoz!' ));
    is( $one->zork, 'Zardoz!' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# override existing method, first appearance of %options
    ok( $one->_make_method( 'foo', sub { 'i am not foo!' }, { override_existing => 1 }));
    can_ok( $one, 'foo' );
    is( $one->foo, 'i am not foo!' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set_method_defaults
        $one = $CLASS->new;
    can_ok( $one, 'set_method_defaults' );
    is( $one->set_method_defaults, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check_methods
    can_ok( $one, 'check_methods' );
    throws_ok{ $one->check_methods } qr/\$methods is required/;
    is( $one->check_methods( undef, { undef_ok => 1 }), undef );

        $tmp = 'API error:  please read the documentation for check_methods\(\) \(invalid data type: argument to make_methods\(\) must be arrayref or hashref\)';
    throws_ok{ $one->check_methods( 'foo' )} qr/$tmp/;
    throws_ok{ $one->check_methods( \'foo' )} qr/$tmp/;

    # arrays, failure
        $tmp = 'API error:  please read the documentation for check_methods\(\) \(invalid method name\)';
    throws_ok{ $one->check_methods([ '' ])} qr/$tmp/;
    throws_ok{ $one->check_methods([ '', 'one' ])} qr/$tmp/;
    throws_ok{ $one->check_methods([ 'one two' ])} qr/$tmp/;
    throws_ok{ $one->check_methods([ 'one', 'foo-two' ])} qr/$tmp/;

    #array, success
    is( $one->check_methods([ 'one', 'two' ]), 2 );
    is( $one->check_methods([ qw/ one two buckle my shoe /]), 5 );

    # hashref, failure
        $tmp = 'API error:  please read the documentation for check_methods\(\) \(invalid hash reference\)';
    throws_ok{ $one->check_methods( {} )} qr/$tmp/;
    throws_ok{ $one->check_methods( { 'one' => \'foo' } )} qr/$tmp/;
    throws_ok{ $one->check_methods( { 'one' => \{} } )} qr/$tmp/;
    throws_ok{ $one->check_methods( { 'one' => \[] } )} qr/$tmp/;

        $tmp = 'API error:  please read the documentation for check_methods\(\) \(invalid method name\)';
    throws_ok{ $one->check_methods( { 'one two' => undef } )} qr/$tmp/;
    throws_ok{ $one->check_methods( { 'one-two' => undef } )} qr/$tmp/;
    throws_ok{ $one->check_methods( { '6onetwo' => undef } )} qr/$tmp/;

    # hashref, success
    is( $one->check_methods({ one => undef, two => undef }), 2 );
    is( $one->check_methods({ one => undef, two => 2, three => 'three', four => sub {} }), 4 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make_methods
    can_ok( $one, 'make_methods' );
    is( $one->make_methods, undef );

        $tmp = 'API error:  please read the documentation for check_methods\(\) \(invalid data type: argument to make_methods\(\) must be arrayref or hashref\)';
    throws_ok{ $one->make_methods( 'foo' )} qr/$tmp/;

        $tmp = 'API error:  please read the documentation for check_methods\(\) \(invalid method name\)';
    throws_ok{ $one->make_methods([ 'one two' ])} qr/$tmp/;
    throws_ok{ $one->make_methods( { 'one two' => undef } )} qr/$tmp/;

        $tmp = 'API error:  please read the documentation for check_methods\(\) \(invalid hash reference\)';
    throws_ok{ $one->make_methods( { 'one' => \'foo' } )} qr/$tmp/;

    ok( $one->make_methods([ 'one', 'two' ]));
    ok( $one->make_methods({ one => undef, two => 2, three => 'three', four => sub {} }));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make_methods part deux (object option)

    # we're doing some dirty stuff here. We define a package that inherits from
    # loompa to build methods in it. Then, we piss all over the namespace.
    #
    # I figured it was the only adequate way to test it.
   
    package TestLoompa;
    use base qw(Loompa);
    package Loompa::Test::Unit;

    # class methods
    ok(TestLoompa->make_methods(['one', 'two'], sub { die shift; }, { object => "TestLoompa" }));
    throws_ok { TestLoompa->one } qr/TestLoompa/;
    throws_ok { TestLoompa->two } qr/TestLoompa/;

    # object methods (via closure)
   
    $one = TestLoompa->new;

    ok(TestLoompa->make_methods(['three', 'four'], sub { return shift; }, { object => $one }));

    # these should still work the same.
    throws_ok { TestLoompa->one } qr/TestLoompa/;
    throws_ok { TestLoompa->two } qr/TestLoompa/;

    # these should return the object that was closed inside.
    is_deeply (TestLoompa->three, $one); 
    is_deeply (TestLoompa->four,  $one);

    # modify the object a bit and make sure this is the case.
    
    $one->{foo} = "bar"; 

    is_deeply (TestLoompa->three, $one); 
    is_deeply (TestLoompa->four,  $one);
  
    # make sure the object gets shifted off
    
    ok(TestLoompa->make_methods(['five', 'six'], sub { shift; shift; die shift; }, { object => $one }));

    throws_ok { TestLoompa->five('foo') } qr/foo/;
    throws_ok { TestLoompa->six('bar') } qr/bar/;
