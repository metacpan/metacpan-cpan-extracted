#!/usr/bin/perl -w

use strict;
use warnings;

use Gin::Calibrate::Serial;
use Gin::Calibrate::GcodeGenerator;

use Time::HiRes qw(gettimeofday tv_interval);

sub send_gcode {
  my ($serial, @gcode) = @_;

  my $inflight = 0;

  # Add a "wait until everthing's finished"
  # to the end of any Gcode we're sending
  push @gcode, 'M400';

  while(1) {
    if($#gcode >= 0) {
      my $line = shift(@gcode);
      #print "Sending >$line< inflight=$inflight\n";
      $serial->write_fd($line);
      $inflight++;
      next if($inflight < 2);
    } else {
      last if($inflight == 0);
    }

    # Now wait for acks
    while($inflight > 0) {
      my $rx = $serial->read_fd();
      if($rx eq 'ok') {
        #print "Ack received inflight=$inflight\n";
        $inflight--;
        last;
      } else {
        print "RX: $rx\n";
      }
    }
  }
}

MAIN: {
  my $serial = Gin::Calibrate::Serial->new();

  my $port = undef;
  if(-c '/dev/ttyACM0') {
    $port = '/dev/ttyACM0';
  } elsif(-c '/dev/ttyUSB0') {
    $port = '/dev/ttyUSB0';
  } else {
    die "Could not find a suitable serial port to use\n";
  }

  $serial->open_serial($port, 250000);

  my $generator = Gin::Calibrate::GcodeGenerator->new();

  my @waggle_parameters = (
    { 'distance' => 0.1, 'iterations' => 100 },
    { 'distance' => 0.5, 'iterations' => 100 },
    { 'distance' => 1, 'iterations' => 100 },
    { 'distance' => 2, 'iterations' => 100 },
    { 'distance' => 3, 'iterations' => 100 },
    { 'distance' => 4, 'iterations' => 100 },
    { 'distance' => 5, 'iterations' => 50 },
    { 'distance' => 10, 'iterations' => 10 },
    { 'distance' => 50, 'iterations' => 5 },
    { 'distance' => 100, 'iterations' => 2 },
  );

  my @tests = ();

  foreach my $params (@waggle_parameters) {
    push @tests, {
      'name' => 'x',
      'distance' => $params->{'distance'},
      'gcode' => $generator->waggle(['X'], $params->{'distance'}, $params->{'iterations'}),
      'iterations' => $params->{'iterations'},
    };
    push @tests, {
      'name' => 'y',
      'distance' => $params->{'distance'},
      'gcode' => $generator->waggle(['Y'], $params->{'distance'}, $params->{'iterations'}),
      'iterations' => $params->{'iterations'},
    };
  }

  @waggle_parameters = (
    {'distance' => 0.1, 'iterations' => 50 },
    {'distance' => 0.5, 'iterations' => 50 },
    {'distance' => 1, 'iterations' => 10 },
    {'distance' => 2, 'iterations' => 5 },
    {'distance' => 5, 'iterations' => 2 },
    {'distance' => 10, 'iterations' => 1 },
    {'distance' => 50, 'iterations' => 1 },
  );

  foreach my $params (@waggle_parameters) {
    push @tests, {
      'name' => 'z',
      'distance' => $params->{'distance'},
      'gcode' => $generator->waggle(['Z'], $params->{'distance'}, $params->{'iterations'}),
      'iterations' => $params->{'iterations'},
    };
  }

  print "Waiting for printer...\n";
  sleep(2);

  print "Starting...\n";
  my $start_gcode = $generator->start_gcode();
  &send_gcode($serial, (@$start_gcode)); 

  print "Running tests...\n";

  my $totals = {};

  foreach my $test (@tests) {
    my @gcode = @{$test->{'gcode'}};
    my $start = [gettimeofday];
    &send_gcode($serial, @gcode);
    my $end = [gettimeofday];

    my $diff = tv_interval($start, $end);
    # When we test, we go there and back, so distance * 2
    my $speed = ($test->{'distance'} * 2 * $test->{'iterations'}) / $diff;
    printf("Test '%s(%.1f)' executed %d iterations in %.4f seconds -> %.4fmm/s\n",
      $test->{'name'},
      $test->{'distance'},
      $test->{'iterations'},
      $diff,
      $speed);
    $test->{'time'} = $diff;

    my $test_type = 'z';
    if($test->{'name'} eq 'x' || $test->{'name'} eq 'y' || $test->{'name'} eq 'xy') {
      $test_type = 'xy';
    }
    if(!exists($totals->{$test_type})) {
      $totals->{$test_type} = {};
    }
    if(!exists($totals->{$test_type}->{$test->{'distance'}})) {
      $totals->{$test_type}->{$test->{'distance'}} = [];
    }
    # Append to the end of the list
    push @{$totals->{$test_type}->{$test->{'distance'}}}, $speed;
  }

  # Now work out the actual calibration values
  # These are in milliseconds per millimeter
  print "Calibration settings follow:\n";
  foreach my $test_type ('xy', 'z') {
    my @speeds = ();
    my @distances = ();
    my $my_results = $totals->{$test_type};
    foreach my $distance (sort { $a <=> $b } keys %{$my_results}) {
      push @distances, $distance;
      my $count = 0;
      my $total = 0;
      foreach my $value (@{$my_results->{$distance}}) {
        $count++;
        $total = $total + $value;
      }
      push @speeds, sprintf("%.4f",($total / $count));
    }
    print "\@Gcode::Interpreter::Ultimaker::${test_type}_speeds = (" . join(',', @speeds) . ");\n";
    print "\@Gcode::Interpreter::Ultimaker::${test_type}_distances = (" . join(',', @distances) . ");\n";
  }

}

# This is for Vim users - please don't delete it
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
