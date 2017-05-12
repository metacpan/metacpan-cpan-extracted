# Copyright (C) 2007 Randall Hansen
# This program is free software; you can redistribute it and/or modify it under the terms as Perl itself.
package main;
use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 98;
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
# empty package
package Test1;
# END of package
package main;

    @Test1::ISA = ( 'Loompa' );

        $one = Test1->new;
    ok( defined( $one ));
    ok( $one->isa( 'Test1' ));
    ok( $one->isa( 'Loompa' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# failures
    can_ok( $one, 'make_methods' );
    is( $one->make_methods, undef );

        $tmp = 'API error:  please read the documentation for check_methods\(\) \(invalid method name\)';
    throws_ok{ $one->make_methods([ '' ])} qr/$tmp/;
    throws_ok{ $one->make_methods([ '*' ])} qr/$tmp/;
    throws_ok{ $one->make_methods([ '123' ])} qr/$tmp/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# object methods
    ok( ! $one->can( 'name' ));
    ok( ! $one->can( 'rank' ));
    ok( ! $one->can( 'serial_number' ));
    ok( $one->make_methods([ qw/ name rank serial_number /]));

    ok( $one->can( 'name' ));
    ok( $one->can( 'rank' ));
    ok( $one->can( 'serial_number' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# class methods
    ok( ! Test1->can( 'solid' ));
    ok( ! Test1->can( 'liquid' ));
    ok( ! Test1->can( 'gas' ));
    ok( Test1->make_methods([ qw/ solid liquid gas /]));

    ok( Test1->can( 'solid' ));
    ok( Test1->can( 'liquid' ));
    ok( Test1->can( 'gas' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# verify they do what we want
    is( $one->name, undef );

    # scalars
    is( $one->name( 'Boris' ), 'Boris' );
    is( $one->name, 'Boris' );
    is( $one->name( 'the cat' ), 'the cat' );
    is( $one->name, 'the cat' );

    # reset
    is( $one->name( undef ), undef );
    is( $one->name, undef );

    # refs
    is_deeply( $one->name([]), [] );
    is_deeply( $one->name, [] );
    is_deeply( $one->name([ 1, 2, 3, 5, 7 ]), [ 1, 2, 3, 5, 7 ] );
    is_deeply( $one->name, [ 1, 2, 3, 5, 7 ] );

    # multiple values
    throws_ok{ $one->name( 42, 47 )} qr/Please pass only one value/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# custom methods
   ok( $one->make_methods([ qw/ red green /], sub { 'i am a color' })); 
   is( $one->red, 'i am a color' );
   is( $one->green, 'i am a color' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test constructor
    throws_ok{ Test1->new( 1 )} qr/Argument to constructor must be hash reference/;
    throws_ok{ Test1->new({ cat => 'Boris' })} qr/Method "cat" not defined for object/;
    ok( $one = Test1->new({
        name            => 'Boris',
        rank            => 'Cat',
        serial_number   => 666,
    }));
    is( $one->name, 'Boris' );
    is( $one->rank, 'Cat' );
    is( $one->serial_number, 666 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test caching
    ok( ! Test1->can( 'cached' ));
    ok( $one->make_methods([ 'cached' ]));
    ok( Test1->can( 'cached' ));

    # if 'make_methods' recreates the method, this test will fail
    # thus we prove that we cache constructed methods
    {
        no strict qw/ refs /;
        my $ref1 = \&{ "Test1::cached" };

        ok( $one->make_methods([ 'cached' ]));
        my $ref2 = \&{ "Test1::cached" };
        is_deeply( $ref1, $ref2 );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# empty package
package Test2;
sub methods {[ qw/ one two three /]}
sub init {
    my $self = shift;
    my( $properties ) = @_;

    $self->one( 'default' )
        unless defined $self->one;
    $self->{ _properties } = $properties;
    $self;
}
# END of package
package main;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# no methods yet, since we're not a Loompa
    ok( ! Test2->can( 'new' ));
    ok( Test2->can( 'init' ));
    ok( Test2->can( 'methods' ));

    require Loompa;
    @Test2::ISA = ( 'Loompa' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# here we also check that "init" gets passed the same arguments that the
# constructor does

    ok( $one = Test2->new );
    ok( defined( $one ));
    ok( $one->isa( 'Test2' ));
    ok( $one->isa( 'Loompa' ));

    ok( Test2->can( 'one' ));
    ok( Test2->can( 'two' ));
    ok( Test2->can( 'three' ));

    ok( $one = Test2->new({
        one     => 111,
        two     => 222,
        three   => 333,
    }));
    is( $one->one, 111 );
    is( $one->two, 222 );
    is( $one->three, 333 );
    is_deeply( $one->{ _properties }, {
        one     => 111,
        two     => 222,
        three   => 333,
    });

    ok( $one = Test2->new({
        two     => 222,
        three   => 333,
    }));
    is_deeply( $one->{ _properties }, {
        two     => 222,
        three   => 333,
    });
    is( $one->one, 'default' );
    is( $one->two, 222 );
    is( $one->three, 333 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# custom methods, POD code test
package Test3;
use base qw/ Loompa /;

sub color_method {
    my $self = shift;
    my( $name, $emotion ) = @_;
    return "My name is '$name' and I am '$emotion.'";
}
Test3->make_methods([ qw/ orange brown /], \&color_method );

# END of package
package main;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ok( Test3->can( 'orange' ));
    is( Test3->orange( 'happy' ), "My name is 'orange' and I am 'happy.'" );
    is( Test3->brown( 'sad' ), "My name is 'brown' and I am 'sad.'" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# methods() as hash reference
package Test4;
use base qw/ Loompa /;

my $ai_method = sub {
    my $self = shift;
    my( $name, $emotion ) = @_;
    return "My name is '$name' and I may go insane and kill you.";
};
my $cat_method = sub {
    return 'I am a cat.';
};

sub methods {
    {
        hal     => $ai_method,
        mother  => $ai_method,
        sasha   => $cat_method,
        name    => 'Boris',
        color   => undef,
    }
}

# END of package
package main;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $one = Test4->new;
    ok( $one->set_method_defaults );

    ok( $one->can( 'hal' ));
    ok( $one->can( 'mother' ));
    ok( $one->can( 'sasha' ));
    ok( $one->can( 'name' ));
    ok( $one->can( 'color' ));

    is( $one->hal, "My name is 'hal' and I may go insane and kill you." );
    is( $one->mother, "My name is 'mother' and I may go insane and kill you." );
    is( $one->sasha, 'I am a cat.' );
    is( $one->name, 'Boris' );
    is( $one->color, undef );

    ok( $one->name( 'Sasha' ));
    is( $one->name, 'Sasha' );
    ok( defined $one->name( 0 ));
    is( $one->name, 0 );
    is( $one->name( undef ), undef );
    is( $one->name, undef );

    ok( $one->color( 'black' ));
    is( $one->color, 'black' );
    is( $one->color( undef ), undef );
    is( $one->color, undef );
    ok( defined $one->color( 0 ));
    is( $one->color, 0 );
