#!/usr/bin/perl -w
#
#
#
# 02_reader.pl - k8055 logger
# A trivial example showing setting to and reading from 
# the analog ports of the k8055 interface board.
#
# See also 02_setter.pl
#
#
use strict;
use Device::Velleman::K8055::Fuse;
my $dev = Device::Velleman::K8055::Fuse->new('-pathToDevice' => '/tmp/8055');

print "Voltage:\n-------\n";
print "AN 1     AN 2\n";
for (0..100) {
	my $v1 = $dev->ReadAnalogChannel(1)/255*5;
	my $v2 = $dev->ReadAnalogChannel(2)/255*5;
	#perform some trivial formatting
        my $v1f = sprintf("%01.2f v in", $v1);
        my $v2f = sprintf("%01.2f v in", $v2);
	print "$v1f     $v2f\n";
	sleep 1;
}

