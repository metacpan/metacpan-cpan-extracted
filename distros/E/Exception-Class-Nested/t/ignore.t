#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

package Foo;

sub foo
{
    my $class = shift;

    TestException->throw(@_) unless $class eq 'Foo';

    Bar->bar(@_);
}

package Bar;

sub bar
{
    shift;
    Baz->baz(@_);
}

package Baz;

use vars qw(@ISA);
@ISA = qw(Foo);

sub baz
{
    shift->foo(@_);
}

package main;

use strict;

use Exception::Class qw(TestException);


sub check_trace
{
    my ( $trace, $unwanted_pkg, $unwanted_class ) = @_;

    my($bad_frame);
    while ( my $frame = $trace->next_frame )
    {
        if ( (grep { $frame->package eq $_ } @$unwanted_pkg)
             || (grep { UNIVERSAL::isa( $frame->package, $_ ) } @$unwanted_class))
        {
            $bad_frame = $frame;
            last;
        }
    }

    ok( ! $bad_frame, "Check for unwanted frames" );
    diag( "Unwanted frame found: $bad_frame" )
        if $bad_frame;
}

eval { Foo->foo() };
my $e = $@;

check_trace( $e->trace, [], [] );

eval { Foo->foo( ignore_package => [ 'Baz' ] ) };
$e = $@;

check_trace( $e->trace, [ 'Baz' ], [] );

eval { Foo->foo( ignore_class => [ 'Foo' ] ) };
$e = $@;

check_trace( $e->trace, [], [ 'Foo' ] );

eval { Foo->foo( ignore_package => [ 'Foo', 'Baz' ] ) };
$e = $@;

check_trace($e->trace, [ 'Foo', 'Baz' ], []);

