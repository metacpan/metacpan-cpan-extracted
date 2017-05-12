# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FTN-Pkt.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 1;
#BEGIN { use_ok('FTN::Pkt') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use FTN::Pkt;

my $pkt = new FTN::Pkt (
   fromaddr => '2:9999/999.128',
   toaddr   => '2:9999/999',
   password => 'password',
   inbound  => '/var/spool/fido/inbound'
   );
   
ok(defined($pkt) && ref $pkt eq 'FTN::Pkt',     'new() works');


            