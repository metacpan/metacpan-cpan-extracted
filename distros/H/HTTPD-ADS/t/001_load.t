# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'HTTPD::ADS' ); }

my $object = HTTPD::ADS->new ();
isa_ok ($object, 'HTTPD::ADS');


