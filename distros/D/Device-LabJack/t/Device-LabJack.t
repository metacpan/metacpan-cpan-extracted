# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Device-LabJack.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use Device::LabJack;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my($cdbg)=0;
my($rc)=333;    # Set the return code to an unlikley value
  

my $idnum=-1;
my $demo=0;
my $stateIO=0;
my $updateIO=0;
my $ledOn=1;
my @channels=(0,1,2,3);
my @gains=(0,0,0,0);
my $disableCal=0;

# Get the version!
$rc=Device::LabJack::GetFirmwareVersion(-1);
ok((($rc>=1.0)&&($rc<=5.0)),1,'GetFirmwareVersion');
if($cdbg) { open(OUT,'>','/tmp/res'); print OUT "GetFirmwareVersion(-1) returns '$rc'\n"; close(OUT); }

my(@results)=Device::LabJack::AISample($idnum,$demo,$stateIO,$updateIO,$ledOn,\@channels,\@gains,$disableCal);
ok(($results[0]!~/not found/i),1,"AISample reports:\033[33;1m $results[0]

 This usually means your LabJack instrument is not connected - or - if it
 *is* connected, you need to unplug it, then plug it back in, then wait a
 minute, then try running this test again.

\033[0m");
if($cdbg) { open(OUT,'>','/tmp/res'); print OUT "AISample($idnum,...) returns:-" . join("\n",@results); close(OUT); }

