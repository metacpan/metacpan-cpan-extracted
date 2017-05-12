# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GRID-Cluster.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Test::More tests => 6;
use File::Temp qw/ tempfile /;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $executable = "../scripts/pki.pl";
if (-x $executable) {
}
else {
  chdir "t";
}
SKIP: {
  skip("Developer test", 6) unless ($ENV{DEVELOPER} && $ENV{GRID_REMOTE_MACHINES} && ($^O =~ /nux$|darwin/));
  
    my $output = `perl $executable -h 2>&1`;
    like($output, qr{Usage: \./pki\.pl.*}, "Script help");
    
    $output = `perl $executable -v 2>&1`;
    like($output, qr{Error: A set of hosts must be specified}, "Error: A set of hosts must be specified");

    $output = `perl $executable -v -g no_config -c my_host 2>&1`;
    like($output, qr{Error: Configuration file does not exist}, "Error: Configuration file does not exist");

    (undef, my $tmpfilename) = tempfile(OPEN => 0, DIR => "/tmp/");
    (undef, my $tmpkeyfilename) = tempfile(OPEN => 0, DIR => "/tmp/");
    
    system("$executable -v -k '-q' -g pki/config -c orion 2>&1 | tee $tmpfilename");
    $output = `cat $tmpfilename`;
    like($output, qr{Public key has been copied in the host orion}, "Authorized keys file does not exist in the remote machine. Successful copy of the public key");

    system("$executable -v -k '-q' -g pki/config -c orion 2>&1 | tee $tmpfilename");
    $output = `cat $tmpfilename`;
    like($output, qr{Public key is already installed in the host orion}, "Public key is already installed in the remote machine");
    
    system("$executable -v -k '-q' -g pki/config -f $tmpkeyfilename -c orion 2>&1 | tee $tmpfilename");
    $output = `cat $tmpfilename`;
    like($output, qr{Public key has been copied in the host orion}, "New public key installation in the remote machine.");
}
