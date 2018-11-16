package My::Tests;

use Test2::V0;
use Test2::API qw[ context ];

use Carp;

use Exporter 'import';

our @EXPORT = qw[ test_attr run_methods ];

sub test_attr {


    my $ctx = context;

    my $new = shift;

    try_ok {

        for my $test ( @_ ) {

            if ( 'ARRAY' eq ref( $test ) ) {

                test_attr( $new, $_ ) foreach @$test;
            }

            elsif ( 'HASH' eq ref( $test ) ) {

                try_ok {

                    my @new_args
                      = 'CODE' eq ref( $test->{new} )
                      ? $test->{new}->()
                      : @{ $test->{new} };

                    my $obj = $new->( @new_args );

                    run_methods( $obj, @{ $test->{methods} // [] } );

                    if ( exists $test->{expected} ) {
                        is(
                            $obj,
                            object {
                                map { call( $_, $test->{expected}{$_} ) }
                                  keys %{ $test->{expected} }
                            },
                        );
                    }

                    if ( exists $test->{compare} ) {

                        for my $stest ( @{ $test->{compare} } ) {

                            my ( $eval, $expected ) = @{$stest};

                            my $got = eval "\$obj->$eval";
                            die( "error evaling $eval: $@\n" )
                              if $@;
                            is(
                                $got,
                                object {
                                    map { call( $_, $expected->{$_} ) }
                                      keys %{$expected}
                                },
                                "$test->{desc}:  $eval"
                            );

                        }

                    }

                }
                $test->{desc};

            }

            else {

                croak( "test must be a hash ref\n" );
            }

        }

    };

    $ctx->release;

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
