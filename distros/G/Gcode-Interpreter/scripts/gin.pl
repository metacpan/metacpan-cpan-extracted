#!/usr/bin/perl -w

use strict;
use warnings;

use lib '../lib';

use Gin;
use Getopt::Std;
use Time::HiRes qw(gettimeofday tv_interval);

sub usage {
  print "Usage:\n";
  print "erm...\n";
}

MAIN: {
  my $options = {};
  getopts('ho:w:m:', $options);

  if($options->{'h'}) {
    usage();
    exit 0;
  }

  my $gin = Gin->new();

  $gin->set_output_file($options->{'o'}) if($options->{'o'});
  $gin->set_waypoints($options->{'w'}) if($options->{'w'} && $options->{'w'} =~ /^\d+$/);
  if($options->{'m'}) {
    if(!$gin->set_method($options->{'m'})) {
      die "gin: Unsupported method '" . $options->{'m'} . "'\n";
    }
  }

  if(!$ARGV[0] || !-f $ARGV[0]) {
    &usage();
    exit 1;
  }

  my $start = [gettimeofday];
  $gin->process_file($ARGV[0]);
  my $end = [gettimeofday];
  my $diff = tv_interval($start, $end);

  print "Time to execute: $diff seconds\n";
}


# This is for Vim users - please don't delete it
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
