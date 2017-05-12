package Gin::Calibrate::GcodeGenerator;

use strict;
use warnings;

sub new {
  my ($class) =@_;
  
  my $self = {};

  $self->{STARTX} = 50;
  $self->{STARTY} = 50;
  $self->{STARTZ} = 15.0;

  bless $self, $class;

  return $self;
}

sub start_gcode {
  my ($self) = @_;

  my $x = $self->{STARTX};
  my $y = $self->{STARTY};
  my $z = $self->{STARTZ};

  my @gcode = (
    'T0',
    'G21',              # metric
    'G90',              # Absolute positioning
    'G28 X0 Y0',        # Zero x/y
    'G28 Z',            # Zero z
    "G1 Z$z F9000",     # Move Z down a bit
    "G1 X$x Y$y",       # Move to a suitable playground
    "G92 X0 Y0 Z0 E0",  # Make the current position zero
    "G91",              # Relative positioning
  );

  return \@gcode;
}

sub waggle {
  my ($self, $directions, $distance, $iterations) = @_;

  my @gcode = ();

  for(my $i = 0; $i < $iterations; $i++) {
    foreach my $direction (1, -1) {
      my $moves = {
        'X' => 0,
        'Y' => 0,
        'Z' => 0,
      };

      foreach my $dir (@$directions) {
        $moves->{$dir} = $direction * $distance;
      }

      # Now make some gcode and add it to the list
      # G1 = interpolated move (G0 = fast move), although both
      # are the same on the Ultimaker
      my $line = 'G1';
      foreach my $temp (sort keys %$moves) {
        $line .= sprintf(" %s%.2f", $temp, $moves->{$temp});
      }
      push @gcode, $line;
    }
  }
  return \@gcode;
}
    
1;
# This is for Vim users - please don't delete it
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
