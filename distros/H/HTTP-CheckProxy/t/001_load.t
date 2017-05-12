# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 4;

BEGIN { use_ok( 'HTTP::CheckProxy' ); }
my $ip ='192.206.112.3';
my $object = HTTP::CheckProxy->new ($ip);
isa_ok ($object, 'HTTP::CheckProxy');
ok($object->code > 400);
ok(!$object->guilty);



