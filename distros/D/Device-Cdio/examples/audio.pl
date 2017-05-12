#!/usr/bin/perl -w
#  Copyright (C) 2006, 2008, 2011 Rocky Bernstein <rocky@cpan.org>
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
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Program to read CD blocks. See read-cd from the libcdio distribution
# for a more complete program.

use strict;

BEGIN {
    chdir 'example' if -d 'example';
    use lib '../lib';
    eval "use blib";  # if we fail keep going - maybe we have installed Cdio
}

use Device::Cdio;
use Device::Cdio::Device;
use Device::Cdio::Track;

use vars qw($0 $program $pause %opts);

sub init() {
  use File::Basename;
  $program = basename($0); # Who am I today, anyway?
  $opts{close}=undef;
  $opts{eject}=0;
  $opts{pause}=0;
  $opts{play}=0;
  $opts{resume}=0;
  $opts{stop}=0;
  $opts{get_audio_volume}=0;
  $opts{set_audio_volume}='';
  $opts{set_audio}=0;
}

# Show the CVS version id string and quit.
sub show_version() {
    print "$program version $Device::Cdio::VERSION\n";
    exit 1;
}

sub usage {
  my($full_help) = @_;

  print "
usage:

   $program [options] [device]
    Issue analog audio CD controls - like playing

options:
    --help          -- print this help and exit
    --version       -- show a CVS version string and exit
    --eject DEVICE  -- eject disc from DEVICE
    --close DEVICE  -- close CD tray of DEVICE
    -P | --pause    -- pause playing
    --play          -- play entire CD
    --resume        -- resume playing
    --stop          -- stop playing
    --track=N       -- play track N
    --volume        -- get audio volume levels
    --set-volume=s  -- set audio volume levels
";
  exit 100;
}

# The bane of programming.
sub process_options() {
  use Getopt::Long;
  my(@opt_cf);
  $Getopt::Long::autoabbrev = 1;
  my($help, $long_help, $show_version);

  my $result = &GetOptions
    (
     'help'           => \$help,
     'close'          => \$opts{close},
     'eject'          => \$opts{eject},
     'version'        => \$opts{show_version},
     'P|pause'        => \$opts{pause},
     'play'           => \$opts{play},
     'resume'         => \$opts{resume},
     'stop'           => \$opts{stop},
     'volume'         => \$opts{get_audio_volume},
     'track=n'        => \$opts{track},
     'set-volume=s'   => \$opts{set_audio_volume},
    );
  show_version() if $show_version;

  usage(0) unless $result || @ARGV > 1;
  usage(1) if $help;
}

init();
process_options();

my ($drc, $device_name);

# Handle closing the CD-ROM tray if that was specified.
if ($opts{close}) {
    $device_name = $opts{close};
    $drc = Device::Cdio::close_tray(-drive=>$opts{close});
    if ($drc) {
	printf "Error closing: %s\n", perlcdio::driver_errmsg($drc) ;
	exit $drc;
    }
}

my $d;
if ($ARGV[0]) {
    $d = Device::Cdio::Device->new($ARGV[0]);
    exit(1) if !defined($d);
} else {
    # For audio any *has* to be set false.
    my @drives = Device::Cdio::get_devices_with_cap(-capabilities=>
						    $perlcdio::FS_AUDIO,
						    -any=>0);
    if (@drives >= 1) {
	$d = Device::Cdio::Device->new($drives[0]);
	if (!defined($d)) {
	    print "Sorry having trouble opening $drives[0]\n";
	    exit(1);
	}
    } else {
	print "Could not automatically find a CD-ROM with an audio CD in it\n";
	print "Please specify a device name\n";
	exit(1);
    }
}

$device_name = $d->get_device();

if ($opts{play}) {
    if ($d->get_disc_mode() ne 'CD-DA') {
        printf "The disc on %s I found was not CD-DA, but CD is %s\n",
	$device_name, $d->get_disc_mode();
        print "I have bad feeling about trying to play this...\n";
    }
    my $start_lsn = $d->get_first_track()->get_lsn();
    my $end_lsn=$d->get_disc_last_lsn();
    printf "Playing entire CD on %s\n", $device_name;
    $drc = $d->audio_play_lsn($start_lsn, $end_lsn);
    printf "Error playing CD: %s\n", perlcdio::driver_errmsg($drc) if ($drc);

} elsif ($opts{track}) {
    if ($d->get_disc_mode() ne 'CD-DA') {
        printf "The disc on %s I found was not CD-DA, but CD is %s\n",
	$device_name, $d->get_disc_mode();
        print "I have bad feeling about trying to play this...\n";
    }
    if ($opts{track} > $d->get_last_track()->{track}) {
	printf "Requested track %d but CD only has %d tracks\n", 
		$opts{track}, $d->get_last_track()->{track};
	exit(2);
    }
        
    if ($opts{track} < $d->get_first_track()->{track}) {
	printf "Requested track %d but first track on CD is %d\n",
	       $opts{track}, $d->get_first_track()->{track};
	exit(2);
    }
    printf("Playing track %d on %s\n", $opts{track}, $device_name);
    my $start_lsn = $d->get_track($opts{track})->get_lsn();
    my $end_lsn = $d->get_track($opts{track}+1)->get_lsn();
    $drc = $d->audio_play_lsn($start_lsn, $end_lsn);
    printf "Error closing: %s\n", perlcdio::driver_errmsg($drc) if ($drc);
} elsif ($opts{get_audio_volume}) {
    my($vol, $rc) = $d->audio_get_volume();
    printf "Audio volume levels: %s\n", join(', ', @$vol);
} elsif ($opts{set_audio_volume}) {
    my @levels=split(/,\s*/, $opts{set_audio_volume});
    # $d->audio_set_volume(@levels);
    $d->audio_set_volume($levels[0], $levels[1], $levels[2], $levels[3]);
     my($vol, $rc) = $d->audio_get_volume();
     printf "Audio volume levels are now: %s\n", join(', ', @$vol);
} elsif ($opts{pause}) {
    printf "Pausing playing in drive %s\n", $device_name;
    $drc = $d->audio_pause();
    printf "Error pausing: %s\n", perlcdio::driver_errmsg($drc) if ($drc);
} elsif ($opts{resume}) {
    printf "Resuming playing in drive %s\n", $device_name;
    $drc = $d->audio_resume();
    printf "Error resuming: %s\n", perlcdio::driver_errmsg($drc) if ($drc);
} elsif ($opts{stop}) {
    printf "Stopping playing in drive %s\n", $device_name;
    $drc = $d->audio_stop();
    printf("Stopping failed on drive %s: %s\n", 
	   $device_name, perlcdio::driver_errmsg($drc)) 
	if $drc;
} elsif ($opts{eject}) {
    print "Ejecting CD in CD-ROM drive $device_name\n";
    $drc = $d->eject_media();
    printf("Eject failed on drive %s: %s\n", 
	   $device_name, perlcdio::driver_errmsg($drc))
	if $drc;
    exit $drc;
}
        
$d->close();
