#!perl

use Test::Most;
use MAD::Loader qw{ load_module build_object };
use Carp;

use lib 't/lib';

my $method = 'bar';
my $module = load_module( module => 'Foo::Bar', inc => \@INC );
my $object;

throws_ok {
    $object = build_object(
        module   => $module,
        builder  => 'new',
        args     => [42],
        on_error => \&Carp::croak,
    );
}
qr{Can.t locate object method "new" via package "Foo::Bar"},
  'build_object fail';

done_testing;
