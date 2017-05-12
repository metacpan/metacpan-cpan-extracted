# -*- perl -*-

# t/004_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'HTTPD::ADS::OpenProxyDetector' ); }

my $object = HTTPD::ADS::OpenProxyDetector->new (ip =>'192.206.112.3');
isa_ok ($object, 'HTTPD::ADS::OpenProxyDetector');


