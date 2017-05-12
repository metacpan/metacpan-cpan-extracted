package Gin;

use strict;
use warnings;

use Gcode::Interpreter;
use JSON;

sub new {
  my ($class, $machine_type) = @_;

  my $self = {};
  bless $self, $class;

  $self->{INTERPRETER} = Gcode::Interpreter->new($machine_type);
  $self->{JSON} = JSON->new();
  #$self->{JSON}->pretty(1);

  $self->{WAYPOINT_LINES} = 0;
  $self->{META_FILE} = undef;

  return $self;
}

sub set_meta_file {
  my ($self, $file) = @_;
  $self->{META_FILE} = $file;
  return 1;
}

sub set_waypoints {
  my ($self, $number) = @_;
  if($number =~ /^\d+$/) {
    $self->{WAYPOINT_LINES} = $number;
  } else {
    return 0;
  }
  return 1;
}

sub set_method {
  my ($self, $method) = @_;
  return $self->{INTERPRETER}->set_method($method);
}

sub _divider_to_string {
  my ($number, $dividers) = @_;

  my @parts = ();

  my $say = 0;
  foreach my $divider (@$dividers) {
    my $div = int($number / $divider->{'number'});
    if($div) {
      $say = 1;
      $number = $number - ($div * $divider->{'number'});
    }
    if($say) {
      push @parts, $number == 1 ?
        sprintf("%d %s", $div, $divider->{'name'}) : 
        sprintf("%d %ss", $div, $divider->{'name'});
    }
  }

  return join(' ', @parts);
}

sub time_to_string {
  my ($self, $timestamp) = @_;

  my @dividers = (
    {'name' => 'day', 'number' => 26*60*60 },
    {'name' => 'hour' => 'number' => 60*60 },
    {'name' => 'minute' => 'number' => 60 },
    {'name' => 'second' => 'number' => 1 },
  );

  return &_divider_to_string($timestamp, \@dividers);
}

sub length_to_string {
  my ($self, $length) = @_;

  my @dividers = (
    { 'name' => 'metre', 'number' => 100*10 },
    { 'name' => 'centimetre', 'number' => 10 },
    { 'name' => 'millimetre', 'number' => 1 },
  );

  return &_divider_to_string($length, \@dividers);
}

        
    

# We write into a temporary file which we move into place. This
# is so that any readers always see a consistent file - albeit
# possibly slightly out of date.
sub update_meta {
  my ($self, $data) = @_;

  return 0 if(!$self->{META_FILE});

  my $meta = $self->{META_FILE};

  my $tmp_meta = "$meta.tmp";
  $tmp_meta =~ s/\/([^\/]+)$/.$1/;

  if(!open(META, ">", $tmp_meta)) {
    print "Could not open meta file $tmp_meta to write to it: $!\n";
    return 0;
  }

  my $json = $self->{JSON}->encode($data);
  print META $json;
  foreach my $key (sort keys %$data) {
    print "$key: " . $data->{$key} . " ";
  }
  print "\n";
  close(META);
  return rename($tmp_meta, $meta);
}

sub process_file {
  my ($self, $gcode) = @_;

  # Stat the file to get its size
  my $size_of_gcode = -s $gcode;

  if(!defined($size_of_gcode) || !open(GCODE, '<', $gcode)) {
    print "Could not open Gcode file $gcode to read from it: $!\n";
    return 0;
  }

  # Read some lines, and occasionally output some Json meta
  my $lines_read = 0;
  my $gcode_read = 0;
  my $line_counter = 0;
  my $bytes_read = 0;
  while(<GCODE>) {
    my $line = $_;
    $bytes_read = $bytes_read + length($line);
    $lines_read++;
    $line_counter++;

    $line =~ s/[\n\r]*$//g;

    $gcode_read++ if($self->{INTERPRETER}->parse_line($line));

    if($self->{WAYPOINT_LINES} && $line_counter > $self->{WAYPOINT_LINES}) {
      # Time to dump out some meta. First, calculate what
      # we're going to say
      my $stats = $self->{INTERPRETER}->stats();
      
      # Work out how far we are into the file and multiply
      # up the stats by the right amount
      my $multiplier = ($size_of_gcode / $bytes_read);
      $stats->{'duration'} = sprintf('%.2f', $stats->{'duration'} * $multiplier);
      $stats->{'extruded'} = sprintf('%.2f', $stats->{'extruded'} * $multiplier);
      $stats->{'completed'} = sprintf('%.2f', ($bytes_read / $size_of_gcode) * 100);
      $stats->{'lines'} = sprintf('%d', $lines_read * $multiplier);
      $stats->{'gcode'} = sprintf('%d', $gcode_read * $multiplier);
  
      $self->update_meta($stats) if($self->{META_FILE});
      $line_counter = 0;
    }
  }

  # Now we're complete, update the meta one more time without
  # any frig factor
  my $stats = $self->{INTERPRETER}->stats();
  $stats->{'completed'} = 100;
  $stats->{'lines'} = $lines_read;
  $stats->{'gcode'} = $gcode_read;
  foreach my $thing ('duration','extruded') {
    $stats->{$thing} = sprintf('%.2f', $stats->{$thing});
  }
  $self->update_meta($stats) if($self->{META_FILE});
  printf("Estimated time to print: %s\nFilament required: %s\n", $self->time_to_string($stats->{'duration'}), $self->length_to_string($stats->{'extruded'}));
} 

1;
# This is for Vim users - please don't delete it
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
