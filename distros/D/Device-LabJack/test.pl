# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Device::LabJack;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$idnum=-1;
$demo=0;
$stateIO=0;
$updateIO=0;
$ledOn=1;
@channels=(0,1,2,3);
@gains=(0,0,0,0);
$disableCal=0;

print "Warning: we're about to read and write stuff to your LabJack,
so remove your hamster from your guilotine (or unplug your LabJack
from your guilotine solenoid and whatever else it drives), then hit
enter to continue...\n";

print "If you can see your firmware, then 4 status values followed by your current 8 AI voltages below, then this test has passed:-\n";

print "\nYour firmware version is: ";
print Device::LabJack::GetFirmwareVersion($idnum);
# print " on labjack ID# $idnum";

print "\n\nAISample(channels 0,1,2,3):-\n";

my(@results)=Device::LabJack::AISample($idnum,$demo,$stateIO,$updateIO,$ledOn,\@channels,\@gains,$disableCal);
print join("\n",@results);

print "\n\nAISample(channels 4,5,6,7):-";

@channels=(4,5,6,7);
my(undef,undef,undef,undef,@results)=Device::LabJack::AISample($idnum,$demo,$stateIO,$updateIO,$ledOn,\@channels,\@gains,$disableCal);
print join("\n",("",@results));


print "\n\nAOUpdate(write):-\n";

$trisD=1;
$trisIO=2;
$stateD=1;
$stateIO=2;
$updateDigital=1;
$resetCounter=1;
$analogOut0=2.1;
$analogOut1=4.2;

my(@results)=Device::LabJack::AOUpdate($idnum,$demo,$trisD,$trisIO,$stateD,$stateIO,$updateDigital,$resetCounter,$analogOut0,$analogOut1);

print join("\n",@results);



print "\n\nAOUpdate (read):-\n";

$trisD=1;
$trisIO=2;
$stateD=4;
$stateIO=8;
$updateDigital=0;
$resetCounter=0;
$analogOut0=2.1;
$analogOut1=4.2;

my(@results)=Device::LabJack::AOUpdate($idnum,$demo,$trisD,$trisIO,$stateD,$stateIO,$updateDigital,$resetCounter,$analogOut0,$analogOut1);

print join("\n",@results);



print "\n\nAIBurst:-\n";

$scanRate=456;
$triggerIO=0;
$triggerState=0;
$numScans=20;
$timeout=2;
$transferMode=0;


my(@results)=Device::LabJack::AIBurst($idnum,$demo,$stateIO,$updateIO,$ledOn,\@channels,\@gains,$scanRate,$disableCal,$triggerIO,$triggerState,$numScans,$timeout,$transferMode);


print join(", ",@results);








my $errcode = 0;
my $id      = 0;

my $ch   = 0;
my $gain = 0;
my ($oV,$V);

($errcode, $id, $oV, $V) = Device::LabJack::EAnalogIn($idnum, $demo, $ch, $gain);

print "\n\nEAnalogIn\nResult: err=$errcode, id=$id, oV=$oV, V=$V\n";






my($analogOut0, $analogOut1)=(2.2,3.3);

($errcode,$id) = Device::LabJack::EAnalogOut($idnum, $demo, $analogOut0, $analogOut1);

print "\n\nEAnalogOut($idnum, $demo, $analogOut0, $analogOut1)=($errcode,$id)\n";



@results = Device::LabJack::ECount($idnum, $demo, 0);

print "\n\nECount($idnum, $demo, 0)=(". join(',',@results) . ")\n";


$channel=1;
$writeD=1;
$state=1;

@results = Device::LabJack::EDigitalOut($idnum, $demo, $channel, $writeD, $state);
print "\n\nEDigitalOut($idnum, $demo, $channel, $writeD, $state)=(". join(',',@results) . ")\n";




@results = Device::LabJack::EDigitalIn($idnum, 0, 0);print "\n\nEDigitalIn($idnum, 0, 0)=(". join(',',@results) . ")\n";
@results = Device::LabJack::EDigitalIn($idnum, 1, 0);print "EDigitalIn($idnum, 1, 0)=(". join(',',@results) . ")\n";
@results = Device::LabJack::EDigitalIn($idnum, 2, 0);print "EDigitalIn($idnum, 2, 0)=(". join(',',@results) . ")\n";
@results = Device::LabJack::EDigitalIn($idnum, 3, 0);print "EDigitalIn($idnum, 3, 0)=(". join(',',@results) . ")\n";



