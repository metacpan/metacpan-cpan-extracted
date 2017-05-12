#!/usr/bin/perl -w

use strict;
use Linux::Input::Joystick;
use Getopt::Long;

die (qq{Usage: $0 <device_file>...

Example:
  sudo $0 /dev/input/event*
}) if (!@ARGV);

my @dev = map { Linux::Input->new($_) } @ARGV;
my $selector = IO::Select->new( map { $_->fh } @dev );
my %dev_for_fh = map { $_->fh => $_ } @dev;

print "Press Ctrl-C to exit.\n";
my $i = 0;

while (1) {
  while (my @fh = $selector->can_read()) {
    foreach (@fh) {
      my $input_device = $dev_for_fh{$_};
      my @event = $input_device->poll(0.01);
      foreach my $ev (@event) {
	printf(
	  '%5d, %7d.%-7d, '.
	  'type => %4s, code => %4d, value => %d,'."\n",
	  $i++,
	  $ev->{tv_sec},
	  $ev->{tv_usec},
	  $ev->{type},
	  $ev->{code},
	  $ev->{value},
	);
      }
    }
  }
}

exit 0;

=head1 NAME

evtest.pl - Linux::Input event testing utility

=head1 SYNOPSIS

  sudo evtest.pl /dev/input/event*

=head1 DESCRIPTION

This utility will observe all the input devices that are passed on to the
command line, and print the event data as it comes in.

=head1 AUTHOR

John Beppu (beppu@cpan.org)

=cut

# vim:sw=2 sts=2
