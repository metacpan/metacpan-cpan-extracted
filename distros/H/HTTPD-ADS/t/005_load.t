# -*- perl -*-

# t/005_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'HTTPD::ADS::AbuseNotify' ); }

my $object = HTTPD::ADS::AbuseNotify->new ();
isa_ok ($object, 'HTTPD::ADS::AbuseNotify');


