#!/usr/bin/env perl
# Test device operations
# No assumption about the CD-ROM drives is made, so
# we're just going to run operations and see that they
# don't crash.

use strict;
use warnings;
use lib '../lib';
use blib;

use Device::Cdio;
use Device::Cdio::Device;
use Test::More;

#should be imported from Build.PL or ...
my $device = '/dev/cdrom';

note 'Test running audio device operations';

my $dev = Device::Cdio::Device->new(-driver_id=>$perlcdio::DRIVER_DEVICE);
ok ( defined $dev , 'Device::Cdio::Device->new(-driver_id=>$perlcdio::DRIVER_DEVICE)');
my $drive_name = $dev->get_device();
note('Device->new(DRIVER_DEVICE)((i.e.:',$perlcdio::DRIVER_DEVICE,')) found: ',$drive_name);

if ($ENV{'CI'}) {
    done_testing();
} else {

    #my @drives = Device::Cdio::get_devices_with_cap(
    #       -capabilities => $perlcdio::FS_AUDIO,
    #       -any=>0);
    my @drives = Device::Cdio::get_devices($perlcdio::DRIVER_DEVICE);
    SKIP : {
	my @hwinfo = $dev->get_hwinfo;
	ok ( $hwinfo[3] , 'Device::Cdio::Device->get_hwinfo');
	note("Testing ", $device, ' ', $hwinfo[0],' ',$hwinfo[1]);

	my ($vols,$rcv) =$dev->audio_get_volume;
	ok ( $rcv == 0 , 'Device::Cdio::Device->audio_get_volume');
	note('Volume was set to ',join(', ',@$vols));

	$dev->audio_set_volume(-1,-1,-1,-1);
	my ($nvols, $mvols);
	($nvols,$rcv) =$dev->audio_get_volume;
	is_deeply($vols, $nvols, "audio_set_volume keep values");
	$dev->audio_set_volume(255,255);
	($mvols,$rcv) =$dev->audio_get_volume;
	@$nvols[0] = 255; @$nvols[1] = 255;
	is_deeply($mvols, $nvols, "audio_set_volume 2 channels");

	$dev->audio_set_volume(100,100,-1,255);
	($mvols,$rcv) =$dev->audio_get_volume;
	@$nvols[0] = 100; @$nvols[1] = 100; @$nvols[3] = 255;
	my $c4 = eq_array ($mvols, $nvols) || note('4 channels are not supported: ',join(', ',@$mvols));
	$dev->audio_set_volume(@$vols[0], @$vols[1], @$vols[2], @$vols[3]);
	($mvols,$rcv) =$dev->audio_get_volume;
	is_deeply($mvols, $vols, "audio_set_volume reset");

      SKIP2: {
	  skip '4 volume channels are not supported', 1, unless $c4 ;
	  is_deeply($mvols, $nvols, "audio_set_volume 4 channels");
	}
    }
    done_testing();
}
