#!perl

use Test::Most;
use MAD::Loader;

use Carp;
use Scalar::Util qw{ refaddr };

my $loader = MAD::Loader->new;

isa_ok( $loader, 'MAD::Loader', '$loader' );
is( $loader->prefix,  '',    '$loader->prefix default' );
is( $loader->builder, 'new', '$loader->builder default' );
is( $loader->add_inc, undef, '$loader->add_inc default' );
is( $loader->set_inc, undef, '$loader->set_inc default' );

is_deeply( $loader->inc, \@INC, '$loader->inc default' );
is_deeply( $loader->args, [], '$loader->args default' );

is(
    refaddr( $loader->on_error ),
    refaddr( \&Carp::croak ),
    '$loader->on_error default'
);

done_testing;
