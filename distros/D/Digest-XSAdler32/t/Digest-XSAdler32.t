# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Digest-XSAdler32.t'

use constant FILE_NAME => 'Adler_test_file';
#########################

use Test::More tests => 3;
BEGIN { use_ok('Digest::XSAdler32') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $file_name = "$ENV{PWD}/".FILE_NAME;
my $isFileExist = stat($file_name);
is($isFileExist, 1, 'Test File Found') or die('Test file not found. Cannot proceed');

open(FP, '<', $file_name) or diag($@);
my $cksum = Digest::XSAdler32::update_adler32(*FP,0,44);
is($cksum, '1900023812', 'Checksum successfully generated');

