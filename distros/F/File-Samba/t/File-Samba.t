# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Samba.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('File::Samba') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $smb = File::Samba->new("smb.conf");

$smb->version(3);
ok($smb->version == 3,"Testing version");

$smb->globalParameter('idmap uid','junk');
ok($smb->globalParameter('idmap uid') eq 'junk',"Testing globalParameter");

$smb->createShare('bogus');
$smb->sectionParameter('bogus','writeable','yes');
ok($smb->sectionParameter('bogus','writeable') eq 'yes',"Testing sectionParameter");
