package Gcode::Interpreter::Ultimaker;

use strict;
use warnings;

use Exporter;
use vars qw($VERSION @ISA);

$VERSION     = 1.00;
@ISA         = qw(Exporter);

use constant CALC_METHOD_FAST => 0;
use constant CALC_METHOD_TABLE => 1;
use constant CALC_METHOD_CALC => 2;

$Gcode::Interpreter::Ultimaker::method = CALC_METHOD_FAST;

@Gcode::Interpreter::Ultimaker::xy_distances = (0.1,0.5,1,2,3,4,5,10,50,100,10000);
@Gcode::Interpreter::Ultimaker::xy_speeds = (3,16.2086,28.2828,35.8809,47.2937,55.3019,63.1498,68.9727,92.3058,132.9859,140.7281);

@Gcode::Interpreter::Ultimaker::z_distances = (0.1,0.5,1,2,5,10,50,10000);
@Gcode::Interpreter::Ultimaker::z_speeds = (1.5,3.4294,5.7529,7.2993,8.4196,9.2844,9.6132,9.9128);

sub new {
  my ($class) = @_;

  my $self = {
    'position' => [0, 0, 0, 0],
    'zero_adj' => [undef,undef,undef,undef],
    'temperature' => {
      'T0' => undef,
    },
    'feedrate' => 3600.0,
    'duration' => 0.0,
    'extruded' => 0.0,
    'current_extruder' => 0,
    'pos_abs' => 0,
    'ext_abs' => 1,
    'scale' => 1,
    'ext_scale' => 1,
  };
  $self->{LINE} = 0;
  $self->{OUTPUT} = [];

  bless $self, $class;

  return $self;
}

# return X,Y,Z,E
sub position {
  my ($self) = @_;
  return $self->{'position'};
}

# Return duration and amount extruded
sub stats {
  my ($self) = @_;
  return {
    'duration' => $self->{'duration'},
    'extruded' => $self->{'extruded'},
  };
}

# Confugure which method we're going to use to calculate print duration.
sub set_method {
  my ($self, $method) = @_;

  if($method eq 'fast') {
    $Gcode::Interpreter::Ultimaker::method = CALC_METHOD_FAST;
  } elsif($method eq 'table') {
    $Gcode::Interpreter::Ultimaker::method = CALC_METHOD_TABLE;
  } else {
    return 0;
  }
  return 1;
}

# Get a number from a string like "S220.2"
# This function gets called *a lot*. As such, it is performance
# optimised:
# - It's a function not a method
# - it doesn't use regexes, and instead uses substr to do the work. This
#   makes it faster, but less tolerant of minor gcode weirdness.
# - It's had a few shuffles about to make it profile better
sub num_from_code {
  my $code = shift(@_);
  my $string = shift(@_);

  my $index = index($string, $code);
  if($index == -1) {
    # Not found
    return undef;
  } 
  $index++;

  # Remove anything beyond the number in the string
  # Look for the first whitespace after the code and number
  my $end = index($string, ' ', $index);
  if($end > 0) {
    $string = substr($string, $index, $end - $index);
  } else {
    $string = substr($string, $index);
  }

  $string = eval { $string + 0.0; };
  if($@) {
    return undef;
  }
  return $string;
}

# Get 'everything' from a reference to a list of "words"
# these 'words' are something like:
# X1.0, Y2.23, Z45.2, E3.123
# This is performance optimised, and requires the words
# which are assumed to have been sought when parsing the line
# in the first place
sub xyze_from_words {
  my $words_ref = shift(@_);

  my @out = (undef, undef, undef, undef);

  foreach my $word (@$words_ref) {
    my $char = substr($word, 0, 1);
    if($char eq 'X') {
      $out[0] = substr($word, 1);
    } elsif($char eq 'Y') {
      $out[1] = substr($word, 1);
    } elsif($char eq 'Z') {
      $out[2] = substr($word, 1);
    } elsif($char eq 'E') {
      $out[3] = substr($word, 1);
    }
  }

  return \@out;
}

# Simulate a move. We first of all update out position based
# on whatever we've been told to do.
#
# We also update the object's total for duration and extruded
# amount. This can be done in a few different ways, depending
# on the method configured into the object.
sub _move {
  my $printer = shift(@_);
  my $adj_ref = shift(@_);

  my $position = $printer->{'position'};

  my @originals = @{$position};

  for(my $i = 0; $i < 4; $i++) {
    my $adj = shift(@$adj_ref);
    if(defined($adj)) {
      if($i == 3) {         # is E
        if($printer->{'ext_abs'}) {
          ${$position}[3] = $adj * $printer->{'ext_scale'};
        } else {
          ${$position}[3] = ${$position}[3] + ($adj * $printer->{'ext_scale'});
        }
      } else {              # is x,y or z
        if($printer->{'pos_abs'}) {
          ${$position}[$i] = $adj * $printer->{'scale'};
        } else {
          ${$position}[$i] = ${$position}[$i] + ($adj * $printer->{'scale'});
        }
      }
    }
  }

  # Now work out how far we've travelled, and so how long it took
  #math.sqrt(diffX * diffX + diffY * diffY) / feedRate
  my @diffs = (0,0,0,0);
  for(my $i = 0; $i < 4; $i++) {
    $diffs[$i] = ${$position}[$i] - $originals[$i];
  }

  my $duration = 0;
  if($Gcode::Interpreter::Ultimaker::method == CALC_METHOD_FAST) {
    # z^2 + b^2 = c^2
    my $distance = sqrt($diffs[0] * $diffs[0] + $diffs[1] * $diffs[1]);
    $duration = ($distance / $printer->{'feedrate'}) * 60;
  } elsif($Gcode::Interpreter::Ultimaker::method == CALC_METHOD_TABLE) {
    # This method involves the look up tables defined at the top of this file.
    # Essentially, we look along the distances to find the one that's closest
    # to the distance we're actually moving. We then look to see the speed
    # over that distance. We then work out the longest time of the X, Y or
    # Z move part of the movement and use that as the duration of the move.
    # This isn't strictly necessary with G1 moves because they should all
    # take the same time. We could optimise out some of the maths here to
    # get a speed increase...?
    for(my $i = 0; $i < 2; $i++) {
      next if($diffs[$i] == 0);
      my $diff = abs($diffs[$i]);
      for(my $j = 0; $j <= $#Gcode::Interpreter::Ultimaker::xy_distances; $j++) {
        #print "Checking axis $axis distance $distance for diff $diff (max=$max)\n";
        if($diff <= $Gcode::Interpreter::Ultimaker::xy_distances[$j]) {
          # We've found our entry in the table
          my $time = $diff / $Gcode::Interpreter::Ultimaker::xy_speeds[$j];
          if($time > $duration) {
            $duration = $time;
          }
          #print "Got time = $time, max = $max\n";
          last;
        }
      }
    }
    # Now do Z
    if($diffs[2] != 0) {
      my $diff = abs($diffs[2]);
      for(my $i = 0; $i <= $#Gcode::Interpreter::Ultimaker::z_distances; $i++) {
        if($diff <= $Gcode::Interpreter::Ultimaker::z_distances[$i]) {
          my $time = $diff / $Gcode::Interpreter::Ultimaker::z_speeds[$i];
          if($time > $duration) {
            $duration = $time;
          }
        }
      }
    }
  }
  $printer->{'duration'} = $printer->{'duration'} + $duration;

  # Also total up how much we extruded
  $printer->{'extruded'} = $printer->{'extruded'} + $diffs[3];
  return 1;
}
    
# Parse any G* command (Eg. G0, G1 etc)
# This gets called *lots* when parsing most Gcode,
# so it's performance optimised (and so not quite
# so readable).
sub _parse_g {
  # Don't reassign argument variables - it uses up a few
  # microseconds per call, so multiple seconds
  # on any reasonable length gcode file
  # $_[0] = $printer
  # $_[1] = $line (the preprocessed original gcode line)
  # $_[2] = $g (numeric value of the G command)
  # $_[3] = $words_ref (reference to a list of words in the original
  #         gcode line
  if($_[2] == 0 || $_[2] == 1) {
    # Move (0 = fast move, 1 = interpolated move)
    my $args = &xyze_from_words($_[3]);
    &_move($_[0], $args);
  } elsif($_[2] == 4) {
    # Delay
    if(my $s = &num_from_code('S', $_[1])) {
      $_[0]->{'duration'} = $_[0]->{'duration'} + $s;
    } elsif(my $p = &num_from_code('P', $_[1])) {
      $_[0]->{'duration'} = $_[0]->{'duration'} + ($p / 1000);
    }
  } elsif($_[2] == 10) {
    # Retract
    # What's wrong with a G1 E-<something>?
  } elsif($_[2] == 11) {
    # Push back after retract
  } elsif($_[2] == 20) {
    # Units -> inches
    $_[0]->{'scale'} = 25.4;
  } elsif($_[2] == 21) {
    # Units -> millimeters
    $_[0]->{'scale'} = 1;
  } elsif($_[2] == 28) {
    # Home all axies
    my $duration = 0;
    my $pos = &xyze_from_words($_[3]);
    my @pos = (@$pos);

    # First, do a move to the real home, if we know where that is.
    my @move = (undef,undef,undef,undef);
    my $printer_zero_adj = $_[0]->{'zero_adj'};
    for(my $i = 0; $i < 4; $i++) {
      if(defined($pos[$i])) {
        my $adj = defined(${$printer_zero_adj}[$i]) ? ${$printer_zero_adj}[$i] : 0;
        $move[$i] = $adj;
      }
    }
    # This move alters duration and so forth by the right amount
    &_move($_[0], \@move);

    # Now make the current position whatever we've been told to use,
    # and make a note of any adjustment so we know where we really are
    my $position = $_[0]->{'position'};
    for(my $i = 0; $i < 4; $i++) {
      if(defined($pos[$i])) {
        ${$position}[$i] = $pos[$i];
        ${$printer_zero_adj}[$i] = $pos[$i];
      }
    }
  } elsif($_[2] == 90) {
    $_[0]->{'pos_abs'} = 1;
    $_[0]->{'ext_abs'} = 1;
  } elsif($_[2] == 91) {
    $_[0]->{'pos_abs'} = 0;
    $_[0]->{'ext_abs'} = 0;
  } elsif($_[2] = 92) {
    # Set current position to co-ordinates given
    my $pos = &xyze_from_words($_[3]);
    my @pos = (@$pos);
    for(my $i = 0; $i < 4; $i++) {
      if(defined($pos[$i])) {
        my $adj = defined(${$_[0]->{'zero_adj'}}[$i]) ? ${$_[0]->{'zero_adj'}}[$i] : 0;
        ${$_[0]->{'zero_adj'}}[$i] = $pos[$i] - $adj;
        ${$_[0]->{'position'}}[$i] = $pos[$i];
      }
    }
  } else {
    print "Unsupported G command: ". $_[1] . "\n";
    return 0;
  }
  return 1;
}

# Parse any M command
# This doesn't get used very much in an average gcode file
# so doesn't need to be especially well optimised.
sub _parse_m {
  my ($printer, $line, $m) = @_;

  if($m == 0 || $m == 1 || $m == 80 || $m == 81) {
    # Ignore all of these:
    # 0
    # 1
    # 80 = Enable power supply
    # 81 = Suicide Pin
  } elsif($m == 82) {
    # Absolute E
    $printer->{'abs_ext'} = 1;
  } elsif($m == 83) {
    # Relative E
    $printer->{'abs_ext'} = 0;
  } elsif($m == 84 || $m == 92 || $m == 101 || $m == 103) {
    # Ignore all of these:
    # 84 = Disable steppers
    # 92 = Set steps per unit
    # 101 = Enable extruder
    # 103 = Disable extruder
  } elsif($m == 104 || $m == 109) {
    # Set current extruder temperature
    my $temp = &num_from_code('S', $line);
    if(defined($temp)) {
      # Set the temperature
      $printer->{'temperature'}->{'T' . $printer->{'current_extruder'}} = $temp;
    }
    if($m == 109) {
      # This now waits for the temperature to reach the required
      # value. It's not possible to know how long this will take on
      # a real machine, so we just add 5 seconds to the print
      $printer->{'duration'} = $printer->{'duration'} + 5;
    }
  } elsif($m == 105) {
    # Return the current temperatures
  } elsif($m == 106 || $m == 107 || $m == 108) {
    # 106 = turn on the fan
    # 107 = turn off the fan
    # 108 = Set Extruder RPM
  } elsif($m == 110 || $m == 113 || $m == 117) {
    # 110 = Reset Gcode N count
    # 113 = Set Extruder PWM
    # 117 = Set display message
  } elsif($m == 140 || $m == 190) {
    # Set bed temperature
    my $temp = &num_from_code('S', $line);
    if(defined($temp)) {
      # Set the temperature
      $printer->{'temperature'}->{'B0'} = $temp;
    }
    if($m == 190) {
      # Wait for bed to reach temperature - how long to wait?
      $printer->{'duration'} = $printer->{'duration'} + 5;
    }
  } elsif($m == 221) {
    # Set extruder amount multiplier
    my $new = &num_from_code('S', $line)
    # ???
  } else {
    print "Unsupported M command: $line\n";
    return 0;
  }
  return 1;
}

# parse_line(line_of_gcode)
# This method obviously gets called a great deal, but it necessarily
# has to be a method, and has to do some heavy lifting. It has had
# some performance optimisations though.
sub parse_line {
  my ($self, $line) = @_;

  $self->{LINE}++;
  
  # Others use the comments, we just strip them
  # This seems to be quicker than using substr/index to do this
  $line =~ s/\s*;.*$//;
  $line =~ s/\s*\(.*\)//;

  my ($cmd,@words) = split(/\s/, $line);

  # This is effectively a blank line check
  return 0 if(!defined($cmd));

  # Get the "code" from the command and the numeric
  # number too. Eg. M107 -> M and 107
  my $code = substr($cmd, 0, 1);
  my $num = substr($cmd, 1);

  # This shouldn't happen on generated gcode, but
  # messes us up quite a bit if it happens so we
  # have to check for it (easier here than in
  # the _parse_X() functions)
  if(!defined($num)) {
    print "Malformed Gcode line \"$line\", line " . $self->{LINE} ."\n";
    return 0;
  }
  if($code eq 'G') {
    return &_parse_g($self, $line, $num, \@words);
  } elsif($code eq 'M') {
    return &_parse_m($self, $line, $num);
  } elsif($code eq 'T') {
    $self->{'current_extruder'} = $num;
    return 1;
  }

  print "Unsupported Gcode \"$line\", line " . $self->{LINE} . "\n";
  return 0;
}

1;

__END__
=pod

=head1 NAME

Gcode::Interpreter::Ultimaker

=head1 SYNOPSIS

  use Gcode::Interpreter::Ultimaker;

  $interpreter = Gcode::Interpreter::Ultimaker->new();

  $interpreter->set_method('table');

  $interpreter->parse_line('G1 X1.0 Y1.0 Z1.0 E1.0');

  $position_ref = $interpreter->position();

  $stats_ref = $interpreter->stats();

=head1 DESCRIPTION

This module aims to simulate an Ultimaker 3D printer running the Marlin
firmware. It parses the Gcode that the Ultimaker uses and keeps track
of the printer's extruder head position. It also keeps track of the
time it would likely take to reach the current position based on the
various moves already processed. Likewise it keeps track of the length
of filament extruded.

The parser works on a line-by-line basis. This allows the caller to
inspect the state of the virtual printer throughout the simulated print.
Future developments may make this interface less interactive to increase
parsing speed.

The calculation of the estimated duration of a print is a relatively
difficult task as it can vary depending on specific settings of the printer.
However, there are three methods to perform this estimation with varying
degrees of accuracy (and speed).

The first method is known as the "infinite acceleration" method. It assumes
that the printer head instantly gets to maximum speed, and instantly stops
at its destination. Because of this, it usually makes very optimistic
estimates, but it has the advantage of being a simple and fast calculation.

The second method is to use a lookup table of speeds for various distances.
This again is a series of estimates, and inherently inaccurate. However,
it's again a fairly fast calculation and gives better results in most cases
than the "infinite acceleration" method.

The third method is to simulate the firmware of the actual printer. This
method understands the speed the head is moving throughout a movement,
and so can calculate the time the movement will take very accurately. Whilst
this method still misses some details and machine differences, it typically
gives excellent results. This method is complex, and so relatively slow. It's
also not implemented (yet) in this module.

This module is a specialised sub-module of the Gcode::Interpreter module. It
would normally not be instantiated directly, although definitely can be if required.

=head1 METHODS

=over 2

=item new
X<new>

The constructor takes no arguments and returns a blessed object.

=item position
X<position>

Takes no arguments and returns a reference to a four element list which denotes
the position of the printer. The list is X,Y,Z and E. Each value will be a float
denoting the distance from the origin in the measurement units of the printer
(which can be set dynamically between millimeters and inches).

=item stats
X<stats>

Takes no arguments and returns a reference to a hash containing two elements
('extruded' and 'duration'). These two elements denote the amount of filament
extruded (in the measurement units of the printer) and the fractional seconds
taken from the start of the print until the end of the last line of gcode
processed.

=item set_method
X<set_method>

Takes a string argument related to the calculation method used to work out the
print time duration. Currently supported values are 'fast' (for the 'infinite
acceleration' method) and 'table' for the calibrated lookup table method.

The method can be changed at any time, but don't take effect retrospectively
so may lead to inaccurate results.

=item parse_line
X<parse_line>

This method takes a string argument containing a line of Gcode instruction. It
returns true on succesful parsing and false if it fails.

=back

=head1 FUNCTIONS

These functions are primarily internal to the module and don't really have
'friendly' APIs for external use. They're highly performance optimised (which
is why they're functions instead of methods), and so somewhat specialised.

Their inputs and outputs may change from time to time. Caveat programmer ;-)

=over 2

=item num_from_code
X<num_from_code>

This function can retrieve the numeric value of a Gcode entity from a string
of Gcode. For example, it could be used to extract "220" from 'M104 S220'.

=item xyze_from_words
X<xyze_from_words>

This function returns a list of X,Y,Z and E values for a given gcode string.
For example, 'G1 E40 X10 Y20 Z30' would return 10,20,30,40.

=back

=head1 SEE ALSO

Marlin (Ultimaker firmware): https://github.com/ErikZalm/Marlin
Cura (slicer, Gcode generator and sender): https://github.com/daid/Cura
Printrun (Gcode sender): https://github.com/kliment/Printrun

A script is provided in the 'scripts' directory of the distibution that
can perform the calibration tests on a printer and outputs the results
in cut-and-paste format that can be put into this module.

Another script (called 'gin') is also provided which can use this module
to calculate the total time and filament required for a print. It can
also optionally write out some meta data as it works for use in other
Gcode-related applications.

=cut

# This is for Vim users - please don't delete it
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
