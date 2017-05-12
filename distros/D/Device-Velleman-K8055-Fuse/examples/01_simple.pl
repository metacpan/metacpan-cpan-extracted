#!/usr/bin/perl -w
#
#
#
# 01_simple.pl - k8055 logger
# A trivial example showing setting to and reading from 
# the analog ports of the k8055 interface board.
#
#
#
#
use strict;
use Device::Velleman::K8055::Fuse;


my $dev = Device::Velleman::K8055::Fuse->new('-pathToDevice' => '/tmp/8055');


#first clear the analog outputs just to be sure.
$dev->ClearAllAnalog();


print "Voltage:\n-------\n";
print "AN 1     AN 2\n";
for (0..100) {
	sleep 1;
	$dev->SetAnalogChannel(1,rand(255));
	$dev->SetAnalogChannel(2,rand(255));
	
	my $v1 = $dev->ReadAnalogChannel(1)/255*5;
	my $v2 = $dev->ReadAnalogChannel(2)/255*5;
	#perform some trivial formatting
        my $v1f = sprintf("%01.2f", $v1);
        my $v2f = sprintf("%01.2f", $v2);
	print "$v1f     $v2f\n";

}

