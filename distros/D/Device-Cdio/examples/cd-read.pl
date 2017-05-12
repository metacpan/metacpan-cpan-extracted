#!/usr/bin/perl -w
#
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

use vars qw($0 $program %opts $read_mode);

my %read_modes = (
    'audio'=> $perlcdio::READ_MODE_AUDIO,
    'm1f1' => $perlcdio::READ_MODE_M1F1,
    'm1f2' => $perlcdio::READ_MODE_M1F2,
    'm2f1' => $perlcdio::READ_MODE_M2F1,
    'm2f2' => $perlcdio::READ_MODE_M2F2,
    'data' => undef
		  );

sub init() {
  use File::Basename;
  $program     = basename($0); # Who am I today, anyway?
  $opts{start} = 1;
  $opts{number}= 1;
  $opts{mode}  = undef;
  $read_mode   = undef;
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

   $program --mode [mode] [other options] [device]
    Read blocks of a CD or CD image.

options:
    --help          -- print this help and exit
    --mode *name*   -- CD Reading mode: audio, m1f1, m1f2, m2f1 or m2f2
    --start *n*     -- starting block number. Default 1.
    --number *n*    -- Number fo block. Default 1.
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
     'mode=s'         => \$opts{mode},
     'start=n'        => \$opts{start},
     'number=n'       => \$opts{number},
    );
  show_version() if $show_version;

  usage(0) unless $result || @ARGV > 1;
  usage(1) if $help;

  if (!$opts{mode} ) {
      print "Read mode option must given.\n"; 
      exit 1
  } 
  $read_mode = $read_modes{$opts{mode}};
  if (!defined($read_mode)) {
      print "Read mode must be one of audio, m1f1, m1f2, m1f2 or m1f2.\n";
      exit 1;
  }
}

# Standard C library's isprint() in Ruby
sub isprint($) {
    return $_[0] =~ m{^[: -~]$} ;
}

# Print a hex dump and string interpretation of buffer.
# If just_hex is true, then show only the hex dump.
sub hexdump ($) {
    my $buffer = $_[0];
    foreach my $i (0 .. length($buffer) - 1) {
	printf "0x%04x: ", $i if $i % 16 == 0;
	printf "%02x", ord(substr($buffer, $i, 1));
	printf " " if $i % 2 == 1;
	if ($i % 16 == 15) {
	    printf "  ";
	    foreach my $j ($i-15 .. $i) {
		printf "%s", 
		isprint(substr($buffer, $j, 1)) ?
		    substr($buffer, $j, 1) : '.';
	    }
	    print "\n";
	}
    }
    print "\n";
}

init();
process_options();

my ($drive_name, $d);
if ($ARGV[0]) {
    $drive_name=$ARGV[0];
    $d = Device::Cdio::Device->new(-source=>$drive_name);
    if (!defined($drive_name)) {
	print "Problem opening CD-ROM: $drive_name\n";
	exit(1);
    }
} else {
    $d = Device::Cdio::Device->new(-driver_id=>$perlcdio::DRIVER_DEVICE);
    $drive_name = $d->get_device();
    if (!defined($drive_name)) {
        print "Problem finding a CD-ROM\n";
        exit(1);
    }
}

## All this setup just to issue this one of these commands.
my ($data, $size, $drc);
if (defined($read_mode)) {
    ($data, $size, $drc) =
	$d->read_sectors($opts{start}, $read_mode, $opts{number});
} else {
    ($data, $size, $drc) = 
	$d->read_data_blocks($opts{start}, $opts{number});
}
if ($perlcdio::DRIVER_OP_SUCCESS == $drc) {
    hexdump($data);
} else {
    print "Error reading block $opts{start} mode $opts{mode} on $drive_name\n";
    printf "Return code message: %s", Device::Cdio::driver_strerror($drc);
}

