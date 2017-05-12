package My::Tests;

use base qw[ Test::Builder::Module Exporter ];

our @EXPORT = qw[ test_attr run_methods ];


use Carp;

use Test::Exception;
use Test::Deep;

use strict;
use warnings;

sub test_attr {

    my $tb = __PACKAGE__->builder;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $new = shift;

    for my $test ( @_ ) {


        if ( 'ARRAY' eq ref( $test ) ) {

            test_attr( $new, $_ ) foreach @$test;
        }

        elsif ( 'HASH' eq ref( $test ) ) {


            lives_and {

		my @new_args = 'CODE' eq ref( $test->{new}  )
		             ? $test->{new}->() 
			     : @{$test->{new}};

                my $obj = $new->( @new_args );

                run_methods( $obj, @{ $test->{methods} // [] } );

                cmp_deeply( $obj, methods( %{ $test->{expected} } ) )
                  if exists $test->{expected};

                if ( exists $test->{compare} ) {

	                for my $stest ( @{ $test->{compare} } ) {

		                my ( $eval, $expected ) = @{ $stest } ;

		                my $got = eval "\$obj->$eval";
		                die( "error evaling $eval: $@\n" )
		                  if $@;
		                cmp_deeply( $got, methods( %{ $expected } ), "$test->{desc}:  $eval" );

	                }

                }

            }
            $test->{desc};

        }

        else {

            croak( "test must be a hash ref\n" );
        }

    }

    return;

}

sub run_methods {

    my $obj = shift;

    while ( 1 ) {

        my ( $method, $args ) = ( shift, shift );
        last unless defined $method;

        my @args = 'CODE' eq ref $args ? $args->() : @$args;

        $obj->$method( @args );
    }

    return;
}



1;
