# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Db::GTM') };

#########################

my $db = new GTMDB('SPZ');
ok($db,  "Initialize Database Link"); 
ok(!$db->kill(),     "Clear Test Environment");

system("stty sane"); # gtm_init() screws up the terminal 

