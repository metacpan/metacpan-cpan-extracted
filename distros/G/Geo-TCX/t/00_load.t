# t/01_load.t - check module loading

use Test::More tests => 2;

BEGIN {
    use_ok( 'Geo::TCX' );
}

diag( "Testing Geo::TCX $Geo::TCX::VERSION" );

my $object = Geo::TCX->new('t/2014-08-11-10-25-15.tcx');
isa_ok ($object, 'Geo::TCX');

print "so debug doesn't exit\n";
