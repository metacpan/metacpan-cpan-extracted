package Math::LiveStats;

use strict;
use warnings;

# perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/Math/LiveStats.pm  > README.md

=head1 NAME

Math::LiveStats - Pure perl module to make mean, standard deviation, and p-values available for given window sizes in streaming data

=head1 SYNOPSIS


    #!/usr/bin/perl -w
  
    use Math::LiveStats;
  
    # Create a new Math::LiveStats object with window sizes of 60 and 300 seconds
    my $stats = Math::LiveStats->new(60, 300); # doesn't have to be "time" or "seconds" - could be any series base you want
  
    # Add time-series data points (timestamp, value)
    $stats->add(1000, 50);
    $stats->add(1060, 55);
    $stats->add(1120, 53);
  
    # Get mean and standard deviation for a window size
    my $mean_60 = $stats->mean(60);
    my $stddev_60 = $stats->stddev(60);
  
    # Get the p-value for a window size
    my $pvalue_60 = $stats->pvalue(60);
  
    # Get the number of entries in a window
    my $n_60 = $stats->n(60);
  
    # Recalculate statistics to reduce accumulated errors
    $stats->recalc(60);


=head1 DESCRIPTION

Math::LiveStats provides live statistical calculations (mean, standard deviation, p-value)
over multiple window sizes for streaming data. It uses West's algorithm for efficient
updates and supports synthetic boundary entries to maintain consistent results.


=head1 METHODS


=cut

require Exporter;

our @ISA = qw(Exporter);
our($VERSION)='1.00';
our($UntarError) = '';

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );



=head2 new(@window_sizes)

Creates a new Math::LiveStats object with the specified window sizes.

=cut

sub new {
  my ($class, @window_sizes) = @_;
  die "At least one window size must be provided" unless @window_sizes;

  # Ensure window sizes are positive integers and sort them
  @window_sizes = sort { $a <=> $b } grep { $_ > 0 } @window_sizes;

  my $self = {
    window_sizes => \@window_sizes,
    data         => [],
    stats        => {},
  };

  # Initialize stats for each window size
  foreach my $window (@window_sizes) {
    $self->{stats}{$window} = {
      n         => 0,
      mean      => 0,
      M2        => 0,
      synthetic => undef,  # To store synthetic entry if needed
      start_index => 0,
    };
  }

  return bless $self, $class;
} # new


=head2 add($timestamp, $value)

Adds a new data point to the time-series and updates statistics.

=cut

sub add {
  my ($self, $timestamp, $value) = @_;

  die "series key (e.g. timestamp) and value must be defined" unless defined $timestamp && defined $value;
  die "duplicated $timestamp" if @{ $self->{data} } && $self->{data}[-1]==$timestamp;

  my $largest_window = $self->{window_sizes}[-1];
  my $window_start   = $timestamp - $largest_window;
  my $inserted_synthetic=0;


  # Actually append the new data point to the end of our array
  push @{ $self->{data} }, { timestamp => $timestamp, value => $value };

  # Update stats for our largest_window with the new data point
  $self->_add_point({ timestamp => $timestamp, value => $value }, $largest_window);

  # de-accumulate now-old data from non-largest window sizes
  foreach my $window (@{ $self->{window_sizes} }[0 .. $#{ $self->{window_sizes} } - 1]) { # do all, except the last (i.e. not the $largest_window)
    my $stats = $self->{stats}{$window};

    # Remove previous synthetic point if it exists (adding new data always means that any synthetic must be removed)
    if ($stats->{synthetic}) {
      my $synthetic_point = $stats->{synthetic};
      $self->_remove_point($synthetic_point, $window);
      $stats->{synthetic} = undef;
    }

    my $window_start = $timestamp - $window; # Caution; this "$window_start" is for the smaller window, not the outer-scope $window_start which is for the $largest_window
    while (@{ $self->{data} } && $self->{data}[$stats->{start_index}]{timestamp} < $window_start) {
      $self->_remove_point($self->{data}[$stats->{start_index}], $window); # de-accumulate this old data
      $stats->{start_index}++;
    }
  }


  # Remove (both de-accumulate, as well as physically remove from the start of the array) data points outside the largest window size
  my $last_removed_point;
  my $removed_count = 0;  # Keep track of the number of removed points
  while (@{ $self->{data} } && $self->{data}[0]{timestamp} < $window_start) {
    $last_removed_point = shift @{ $self->{data} };
    $self->_remove_point($last_removed_point, $largest_window);
    $removed_count++;
  }



  # Check if a synthetic entry is needed to be physically inserted into the data as the start of the largest window
  my $oldest_point = $self->{data}[0];
  if ($oldest_point->{timestamp} > $window_start) {

    # Need to insert synthetic entry at window_start
    my $synthetic_timestamp = $window_start;

    # Determine value for synthetic point
    my $synthetic_value;

    if ($last_removed_point) {
      # Interpolate between last_removed_point and oldest_point
      $synthetic_value = $self->_interpolate( $last_removed_point, $oldest_point, $synthetic_timestamp );
    } else {
      # Initial add, use value of the oldest_point
      $synthetic_value = $oldest_point->{value};
    }

    # Create synthetic point
    my $synthetic_point = {
      timestamp => $synthetic_timestamp,
      value   => $synthetic_value,
      # is this needed? synthetic => 1,  # Mark as synthetic
    };

    # Insert synthetic point at the beginning of data list
    unshift @{ $self->{data} }, $synthetic_point;
    $removed_count--;

    # Update stats with the synthetic point
    $self->_add_point({ timestamp => $synthetic_timestamp, value => $synthetic_value }, $largest_window);
  }


  # Now accumulate the new point for the other window sizes, and work out their synthetic entries as well if required
  foreach my $window (@{ $self->{window_sizes} }[0 .. $#{ $self->{window_sizes} } - 1]) { # all except largest_window
    my $window_start = $timestamp - $window;
    my $stats = $self->{stats}{$window};

    # Update stats with the new data point for this window
    $self->_add_point({ timestamp => $timestamp, value => $value }, $window);

    if($removed_count!=0) { # might be negative if we already physically inserted a synthetic point
      # Decrement start_index by the number of removed elements
      $stats->{start_index} -= $removed_count;
      # Ensure start_index doesn't go below zero
      $stats->{start_index} = 0 if $stats->{start_index} < 0;
    }

    # clear dust if our window has only 1 entry now
    $self->recalc($window) if($stats->{n}==1);


    # Check if a synthetic entry is needed at the start of this window
    my $oldest_in_window = $self->{data}[ $stats->{start_index} ] || undef;

    if (!$oldest_in_window || $oldest_in_window->{timestamp} > $window_start) { # needs synthetic
      # Need to insert synthetic point
      my $synthetic_timestamp = $window_start;
      my $synthetic_value;

      my $before_index = $stats->{start_index} - 1;
      my $before = $before_index >= 0 ? $self->{data}[ $before_index ] : undef;
      my $after  = $oldest_in_window;

      if ($before && $after) {
        # Interpolate between before and after
        $synthetic_value = $self->_interpolate($before, $after, $synthetic_timestamp);
      } elsif ($after) {
        # Use the value of the after point
        $synthetic_value = $after->{value};
      } else {
        # Use the current value (since there's no data in window)
        $synthetic_value = $value;
      }

      # Create synthetic point
      my $synthetic_point = {
        timestamp => $synthetic_timestamp,
        value     => $synthetic_value,
        # not used: synthetic => 1,
      };

      # Update stats with the synthetic point
      $self->_add_point($synthetic_point, $window);

      # Store synthetic point in stats
      $stats->{synthetic} = $synthetic_point;
    }

  }

} # add


=head2 mean($window_size)

Returns the mean for the specified window size.

=cut

sub mean {
  my ($self, $window) = @_;
  die "Window size must be specified" unless defined $window;
  die "Invalid window size" unless exists $self->{stats}{$window};

  return $self->{stats}{$window}{mean};
}

=head2 stddev($window_size)

Returns the standard deviation for the specified window size.

=cut

sub stddev {
  my ($self, $window) = @_;
  die "Window size must be specified" unless defined $window;
  die "Invalid window size" unless exists $self->{stats}{$window};

  my $n  = $self->{stats}{$window}{n};
  my $M2   = $self->{stats}{$window}{M2};
  my $variance = $n > 1 ? $M2 / ($n - 1) : 0;
  return $variance<0? 0: sqrt($variance);
}

=head2 pvalue($window_size)

Calculates the p-value based on the standard deviation for the specified window size.

=cut

sub pvalue {
  my ($self, $window) = @_;
  my $stddev = $self->stddev($window);

  # Ensure standard deviation is defined
  return undef unless defined $stddev;

  # Absolute value of z-score
  my $z = abs($stddev);

  # Constants for the approximation
  my $b1 =  0.319381530;
  my $b2 = -0.356563782;
  my $b3 =  1.781477937;
  my $b4 = -1.821255978;
  my $b5 =  1.330274429;
  my $p  =  0.2316419;
  my $c  =  0.39894228;

  # Compute t
  my $t = 1 / (1 + $p * $z);

  # Compute the standard normal probability density function (PDF)
  my $pdf = $c * exp(-0.5 * $z * $z);

  # Compute the cumulative distribution function (CDF) approximation
  my $cdf = 1 - $pdf * (
    $b1 * $t +
    $b2 * $t**2 +
    $b3 * $t**3 +
    $b4 * $t**4 +
    $b5 * $t**5
  );

  # Two-tailed p-value
  my $pvalue = 2 * (1 - $cdf);

  # Ensure p-value is between 0 and 1
  $pvalue = 1 if $pvalue > 1;
  $pvalue = 0 if $pvalue < 0;

  return $pvalue;
}


=head2 n($window_size)

Returns the number of entries in the specified window size.

=cut

sub n {
  my ($self, $window) = @_;
  die "Invalid window size" unless defined $window && exists $self->{stats}{$window};
  return $self->{stats}{$window}{n};
}

=head2 recalc($window_size)

Recalculates the running statistics for the given window to reduce accumulated numerical errors.

=cut

sub recalc {
  my ($self,$window) = @_;

  my $data = $self->{data};

  # Reset stats for given window size
  my $stats = $self->{stats}{$window};
  $stats->{n}           = 0;
  $stats->{mean}        = 0;
  $stats->{M2}          = 0;
  # Retain existing synthetic entry if any
  # $stats->{synthetic} remains unchanged
  # Retain existing start_index so we can avoid having to search for the starting data
  # $stats->{start_index} = 0; # Note that $stats->{start_index} is always 0 for our largest window size.

  my $window_start = $data->[-1]{timestamp} - $window;

  # Add synthetic point to stats if it exists
  if ($stats->{synthetic}) {
    my $synthetic_point = $stats->{synthetic};
    $self->_add_point($synthetic_point, $window);
  }

  # Add data points within the window to stats
  for (my $i = $stats->{start_index}; $i < @$data; $i++) {
    my $point = $data->[$i];
    $self->_add_point($point, $window);
  }
} # recalc


# Internal method to add a data point to stats for a specific window
sub _add_point {
  my ($self, $point, $window) = @_;

  my $stats = $self->{stats}{$window};

  $stats->{n}++;
  my $delta = $point->{value} - $stats->{mean};
  $stats->{mean} += $delta / $stats->{n};
  my $delta2 = $point->{value} - $stats->{mean};
  $stats->{M2} += $delta * $delta2;
  #print("added w$window ($point->{timestamp},$point->{value}) n=$stats->{n}\n");
} # _add_point


# Internal method to remove a data point from stats for a specific window
sub _remove_point {
  my ($self, $point, $window) = @_;

  my $stats = $self->{stats}{$window};
  #return if $stats->{n} == 0;

  #print("removed w$window ($point->{timestamp},$point->{value})");
  $stats->{n}--;
  my $delta = $point->{value} - $stats->{mean};
  $stats->{mean} -= $delta / ($stats->{n} || 1);
  my $delta2 = $point->{value} - $stats->{mean};
  $stats->{M2} -= $delta * $delta2;

  # Ensure M2 is not negative due to floating-point errors
  #warn "hmm $stats->{M2}"  if $stats->{M2} < 0;
  $stats->{M2} = 0 if $stats->{M2} < 0;
  #print("new n=$stats->{n}\n");
}


# Internal method to interpolate synthetic value
sub _interpolate {
  my ($self, $before, $after, $time) = @_;

  my $t0 = $before->{timestamp};
  my $t1 = $after->{timestamp};
  my $v0 = $before->{value};
  my $v1 = $after->{value};

  my $slope = ($v1 - $v0) / ($t1 - $t0);
  return $v0 + $slope * ($time - $t0);
}



1; # End of Math::LiveStats


__END__

=head2 EXPORT

None by default.


=head1 AUTHORS

This module was written by Chris Drake F<cdrake@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

