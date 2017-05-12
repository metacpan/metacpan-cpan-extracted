#!/usr/bin/perl -w
#  Copyright (C) 2011 jerry geiger
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  If you don't have received a copy of the GNU General Public License
#  along with this program see <http://www.gnu.org/licenses/>.
#
use strict;
use Device::Cdio;
use Device::Cdio::Device;
use Device::Cdio::Track;
use Device::Cdio::ISO9660::FS;
use perlmmc;
use File::Basename;
use Encode;
use vars qw($0 $program $VERSION);
my $VERSION = "0.0";
my $program = basename $0;
my $device_name; # = '/dev/cdrom';
my $drc; # Device::Cdio:: return value
my $dev; # Device::Cdio::Device

if ($ARGV[0]) {
    $device_name = shift;
}
print $program,"-$VERSION", ' Device::Cdio::VERSION ',$Device::Cdio::VERSION,
    "\n  using libcdio vers $perlcdio::VERSION_NUM: ",
    perlcdio::cdio_version,"\n";

if (not $device_name) {
    $device_name = '';
    my @devices = find_devices();
    print scalar @devices, " device(s) found:\n";
    foreach my $d (@devices) {
        print "  $d\n";
        if(! $dev) { #try to open
            $device_name = $d;
            $dev = Device::Cdio::Device->new($d);
            warn "$program: Can't open device $device_name \n" if not $dev;
        }
    }
    if(not $dev) {
        #libcdio's Device::Cdio::get_devices routines don't work
        #on mounted drives, so we need to try default as well.
        #try default device: set with Build ??
        print "  try default device\n";
        $device_name = "/dev/cdrom";
    }
}
if(not $dev) {
    $dev = Device::Cdio::Device->new($device_name);
}
if(not $dev) {
    die "$program: Can't open device $device_name \n";
}
my @hwinfo = $dev->get_hwinfo;
if (!$hwinfo[3]) {
    print "$program: ",perlcdio::driver_errmsg($hwinfo[3]),"\n";
} else {
    printf("$program: device %s %s (rev %s) %s (%s)\n",
	   $hwinfo[0], $hwinfo[1], $hwinfo[2], $device_name, 
	   $dev->get_driver_name());
}
if($dev->is_tray_open) {
    print "  tray is open?\n";
    # missing tray is open? -> close tray
    perlmmcc::mmc_close_tray($dev->{cd});
    #Device::Cdio::close_tray($device_name);
}
#
my $dmode = $dev->get_disc_mode();
if(!$dmode) {
    warn "no medium in drive?\n";
    #perlmmcc::mmc_eject_media($dev->{cd});
    perlmmcc::stop_media($dev->{cd});
    ##$dev->eject_media;
    exit 0;
}
my $mcn =  $dev->get_mcn;
printf "disk %s mcn %s\n", $dmode?$dmode:'?', $mcn?$mcn:'not availabale';

my $ntracks = $dev->get_num_tracks;
if($ntracks == $perlcdio::INVALID_TRACK) {
    if(!$dmode) {
        print 'No medium found?', "\n";
    }
    exit 0;
}
my ($rc, $last_session) = $dev->get_last_session();
print perlcdio::driver_errmsg($rc),"\n" if $rc;
printf "  %d track(s), %s-session\n", $ntracks, $last_session?'multi':'single';

my $start_lsn = $dev->get_first_track()->get_lsn();
my $end_lsn = $dev->get_disc_last_lsn();
my $fst_track = $dev->get_first_track;
my $fst_audio_trackno = undef;
my %tracks;
for (my $i =1; $i<=$ntracks; $i++) {
    $tracks{$fst_track->set_track($i)->get_format}++;
    if(not defined $fst_audio_trackno) { 
        $fst_audio_trackno = $i if 
                $fst_track->set_track($i)->get_format eq 'audio';
    }
}
foreach my $m (keys %tracks) {
    printf "  %d %s track(s)\n",$tracks{$m}, $m;
}
if(! $tracks{'audio'}) {
    warn "no audio tracks found - maybe not playable\n";
}
my $hasisopvd;
print "guess cd type: (time duration values are guessed approx.)\n";
for (my $i =1; $i<=$ntracks; $i++) {
    my $lsn = $fst_track->set_track($i)->get_lsn;
    printf "track %2d lsn: %6d msf: %s %s",$i, $lsn,
            $fst_track->set_track($i)->get_msf,
            $fst_track->set_track($i)->get_format;
    my $hash = $dev->guess_cd_type($lsn,$i);
    #while(my($k,$v) = each(%$hash)) {
    #    print "  $k=>$v\n";
    #}
    if($hash->{cdio_fs_t}==1) {  # CDIO_FS_AUDIO
        #time, ISRC flags
        my $secs = $fst_track->set_track($i+1)->get_lba - 
                        $fst_track->set_track($i)->get_lba;
        $secs = int($secs/75);
        my $ctrack = $fst_track->set_track($i);
        printf " (%d:%02d)\n    %d channels, %s, copy: %s, ISRC: %s\n",
            int($secs/60),$secs%60,
            $ctrack->get_audio_channels,
            $ctrack->get_preemphasis,
            $ctrack->get_copy_permit?'yes':'no',
            $ctrack->get_track_isrc;
    }
    next if $hash->{cdio_fs_t}==1;

    printf " %s ISRC: %s\n", $fst_track->set_track($i)->is_track_green,
            $fst_track->set_track($i)->get_track_isrc;

    foreach my $k ('cdio_fs_t','isofs_size', 'iso_label','UDFVerMajor',
            'UDFVerMinor') {
        print "  $i $k=>", $hash->{$k},"\n";
    }
    foreach my $k ('cdio_fs_cap_t','joliet_level') {
        printf "  %d %s %0x\n",$i,$k, $hash->{$k};
    }
    $hasisopvd = 1 if $hash->{'cdio_fs_t'} == 3;
    $hasisopvd = 1 if $hash->{'cdio_fs_t'} == 8;
    $hasisopvd = 1 if $hash->{'cdio_fs_t'} == 9;
    $hasisopvd = 1 if $hash->{'cdio_fs_t'} == 14;
}
if($hasisopvd && (my $pvd = $dev->read_pvd) ) {
    print "ISO-9660 Primary Volume Descriptor:\n";
    print 'type: ',perliso9660::get_pvd_type($pvd), "\n";
    print 'id: ', perliso9660::get_pvd_id($pvd), "\n";
    print 'version: ', perliso9660::get_pvd_version($pvd), "\n";
    print 'system_id: ', perliso9660::get_system_id($pvd), "\n";
    print 'volume_id: ', perliso9660::get_volume_id($pvd), "\n";
    print ' volume_space_size? ', perliso9660::get_pvd_space_size($pvd), "\n";
    print ' logical_block_size? ', perliso9660::get_pvd_block_size($pvd), "\n";
    print ' root_lsn? ', perliso9660::get_root_lsn($pvd), "\n";
    print 'volume_set_id: ', perliso9660::get_volumeset_id($pvd), "\n";
    print 'publisher_id: ', perliso9660::get_publisher_id($pvd), "\n";
    print 'preparer_id: ', perliso9660::get_preparer_id($pvd), "\n";
    print 'application_id: ', perliso9660::get_application_id($pvd), "\n";
    print "\n";
}
# disk size:
# lsn for Leadout (total time) perlcdio::LEADOUT_TRACK
# play time : find last audio track - audio tracks are mostly in first session
# (except  CD-i and mixed mode) and usually there is only one audio session.
# on mixed mode cds there might be an undetectable session gap between
# last audio sample and begin of next data track.
my $natracks = $tracks{'audio'};
if($natracks) {
    my $start_audio_lsn =  $fst_track->set_track($fst_audio_trackno)->get_lsn;
    my $track = $fst_track->set_track($natracks+1);
    my $end_audio_lsn = $track->get_lsn;
    my $diskmsf = $track->get_msf;
    my $asecs = ($end_audio_lsn-$start_audio_lsn)/75;
    printf "CD has %d audio tracks approx: %d:%02d (%s?) total play time)\n",
        $natracks, int($asecs/60),$asecs%60, $diskmsf;
} else {
    my $diskmsf = $fst_track->set_track($ntracks+1)->get_msf;
    printf "data disk %d tracks, %s (%d SECs)\n", $ntracks, $diskmsf,
            $dev->get_disc_last_lsn;
}
my $cdtext = $dev->get_disk_cdtext;
my $cddbid = undef;

if($tracks{'audio'}) {
    if(!$cdtext) {
	$cddbid = $dev->get_cddb_discid;
	printf "no cdtext, try cddb: %08x\n", $cddbid;
	#$cdtext = cddb2cdtext($cddbid);
    }
    if($cdtext) {
	print "disk: ";
	print_cdtext($cdtext, ' ');
	print "\n";
    }
    my ($state, $rcs) = $dev->audio_get_status;
#print int($state->{disk_s}/60),':',$state->{disk_s}%60,,' ', $state->{track_s},"\n";
#foreach my $y ($state) {
#    while(my ($k,$v) = each (%$y)) {
#        print "  $k -> $v\n";
#    }
#}
# $state->{audio_status} 0x11 0x12 0x13
    printf "player: %s track %d (%d) %d:%02d (%d:%02d)\n",
    $state->{status_text}, $state->{track}, $state->{index},
    $state->{rel_m},$state->{rel_s},$state->{abs_m},$state->{abs_s};
    
    if($state->{audio_status} == 0x11) {
	printf "\nsome information not available cause cd is playing: %0x\n", 
        $state->{audio_status};
	print "stop player to get full disc info\n"
    }
}
$dev->close;
exit 0;


sub print_cdtext {
    my $text = shift;
    my $nl = shift;
    return if !$text;
    foreach my $k (keys %$text) {
        my $t = $text->{$k};
        Encode::from_to($t,"iso-8859-1", "utf8");
        print $k,': ',$t, $nl if defined $t;
    }
}

sub cddb2cdtext {
    return undef;
}

# find devices (if device_name is undefined)
sub find_devices {
    # $cap = shift
    my $drives = Device::Cdio::get_devices_with_cap(
        -capabilities => $perlcdio::FS_AUDIO,
        -any=>0);
    unless ($drives && @$drives > 0) {
	warn("Could not find a CD-ROM device\n");
	return ();
    }
    return @$drives;
}
