package Devel::ebug::Plugin::ActionPoints;
$Devel::ebug::Plugin::ActionPoints::VERSION = '0.59';
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(break_point break_point_delete break_point_subroutine break_points break_points_with_condition all_break_points_with_condition watch_point break_on_load);

# set a break point (by default in the current file)
sub break_point {
  my $self = shift;
  my($filename, $line, $condition);
  if ($_[0] =~ /^\d+$/) {
    $filename = $self->filename;
  } else {
    $filename = shift;
  }
  ($line, $condition) = @_;
  my $response = $self->talk({
    command   => "break_point",
    filename  => $filename,
    line      => $line,
    condition => $condition,
  });
  return $response->{line};
}

# delete a break point (by default in the current file)
sub break_point_delete {
  my $self = shift;
  my($filename, $line);
  my $first = shift;
  if ($first =~ /^\d+$/) {
    $line = $first;
    $filename = $self->filename;
  } else {
    $filename = $first;
    $line = shift;
  }

  my $response = $self->talk({
    command   => "break_point_delete",
    filename  => $filename,
    line      => $line,
  });
}

# set a break point
sub break_point_subroutine {
  my($self, $subroutine) = @_;
  my $response = $self->talk({
    command    => "break_point_subroutine",
    subroutine => $subroutine,
  });
  return $response->{line};
}

# list break points
sub break_points {
  my($self, $filename) = @_;
  my $response = $self->talk({
    command => "break_points",
    filename => $filename,
  });
  return @{$response->{break_points}};
}

# list break points with condition
sub break_points_with_condition {
  my($self, $filename) = @_;
  my $response = $self->talk({
    command => "break_points_with_condition",
    filename => $filename,
  });
  return @{$response->{break_points}};
}

# list break points with condition for the whole program
sub all_break_points_with_condition {
  my($self, $filename) = @_;
  my $response = $self->talk({
    command => "all_break_points_with_condition",
    filename => $filename,
  });
  return @{$response->{break_points}};
}


# set a watch point
sub watch_point {
  my($self, $watch_point) = @_;
  my $response = $self->talk({
    command => "watch_point",
    watch_point => $watch_point,
  });
}


# set a break point on file loading
sub break_on_load {
  my $self = shift;
  my($filename) = @_;
  
  my $response = $self->talk({
    command   => "break_on_load",
    filename  => $filename,
  });
  return $response->{line};
}

1;
