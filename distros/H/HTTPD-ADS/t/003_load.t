# -*- perl -*-

# t/003_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok( 'HTTPD::ADS::DBI' ); }

my $object = HTTPD::ADS::Hosts->create ({ip =>'1.2.3.4'});
isa_ok ($object, 'HTTPD::ADS::Hosts');
ok($object->delete);

