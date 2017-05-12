#!perl

use Test::Most;
use MAD::Loader qw{ load_module build_object };
use Carp;

use lib 't/lib';

my $method = 'bar';
my $module = load_module( module => 'Foo::Bar', inc => \@INC );
my $object = build_object(
    module   => $module,
    builder  => 'init',
    args     => [42],
    on_error => \&Carp::croak,
);

is( $object->$method(), 42, 'Object built' );

done_testing;
