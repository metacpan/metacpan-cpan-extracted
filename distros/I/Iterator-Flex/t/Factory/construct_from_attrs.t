#! perl

use Test2::V0;
use Iterator::Flex::Factory;

use v5.10;

use Test::Lib;
use MyTest::Utils qw( drain );

sub construct {

    my @array = ( 0 .. 9 );

    # initialize lexical variables here
    my $next    = 0;
    my $prev    = undef;
    my $current = undef;
    my $arr     = \@array;
    my $len     = @array;
    my $self;

    {
        _self => \$self,
        next  => sub {
            if ( $next == $len ) {
                # if first time through, set current
                $prev = $current
                  if !$self->is_exhausted;
                return $current = $self->signal_exhaustion;
            }
            $prev    = $current;
            $current = $next++;

            return $arr->[$current];
        },

        reset  => sub { $prev = $current = undef; $next = 0; },
        rewind => sub { $next = 0; },
        prev    => sub { return defined $prev    ? $arr->[$prev]    : undef; },
        current => sub { return defined $current ? $arr->[$current] : undef; },
    };
}

subtest 'return' => sub {
    subtest 'default' => sub {
        my $iter = Iterator::Flex::Factory->construct_from_attr( construct() );
        DOES_ok( $iter, 'Iterator::Flex::Role::Exhaustion::Return' );
        drain( $iter, 10 );
    };

    subtest 'explicit' => sub {
        my $iter = Iterator::Flex::Factory->construct_from_attr( construct(),
            { exhaustion => [ return => undef ] } );
        DOES_ok( $iter, 'Iterator::Flex::Role::Exhaustion::Return' );
        drain( $iter, 10 );
    };
};

subtest 'throw' => sub {

    my $iter = Iterator::Flex::Factory->construct_from_attr( construct(), { exhaustion => 'throw' } );
    DOES_ok( $iter, 'Iterator::Flex::Role::Exhaustion::Throw' );
    my $err = dies { drain( $iter, 10 ) };
    isa_ok( $err, 'Iterator::Flex::Failure::Exhausted' );
};


done_testing;
