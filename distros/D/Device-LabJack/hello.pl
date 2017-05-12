#!perl

# use ExtUtils::testlib;

use Device::LabJack;

$idnum=-1;
$demo=0;
$stateIO=0;
$updateIO=0;
$ledOn=1;
@channels=(0,1,2,3);
@gains=(0,0,0,0);
$disableCal=0;

$ledOn=$1 if($ARGV[0]=~/(\d+)/);

my(@results)=Device::LabJack::AISample($idnum,$demo,$stateIO,$updateIO,$ledOn,\@channels,\@gains,$disableCal);
print join("\n",@results);


