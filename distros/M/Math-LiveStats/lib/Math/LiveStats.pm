package Math::LiveStats;

use strict;
use warnings;

# perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/Math/LiveStats.pm  > README.md

=head1 NAME

Math::LiveStats - Pure perl module to make mean, standard deviation, vwap, and p-values available for one or more window sizes in streaming data

=head1 SYNOPSIS


    #!/usr/bin/perl -w
  
    use Math::LiveStats;
  
    # Create a new Math::LiveStats object with window sizes of 60 and 300 seconds
    my $stats = Math::LiveStats->new(60, 300); # doesn't have to be "time" or "seconds" - could be any series base you want
  
    # Add time-series data points (timestamp, value, volume) # use volume=0 if you don't use/need vwap
    $stats->add(1000, 50, 5);
    $stats->add(1060, 55, 10);
    $stats->add(1120, 53, 5);
  
    # Get mean and standard deviation for a window size
    my $mean_60 = $stats->mean(60);
    my $stddev_60 = $stats->stddev(60); # of the mean
    my $vwap_60 = $stats->vwap(60);
    my $vwapdev_60 = $stats->vwapdev(60); # stddev of the vwap
  
    # Get the p-value for a window size
    my $pvalue_60 = $stats->pvalue(60);
  
    # Get the number of entries in a window
    my $n_60 = $stats->n(60);
  
    # Recalculate statistics to reduce accumulated errors
    $stats->recalc(60);

=head1 CLI one-liner example

    cat data | perl -MMath::LiveStats -ne 'BEGIN{$s=Math::LiveStats->new(20);} chomp;($t,$p,$v)=split(/,/); $s->add($t,$p,$v); print "$t,$p,$v,",$s->n(20),",",$s->mean(20),",",$s->stddev(20),",",$s->vwap(20),",",$s->vwapdev(20),"\n"'

=head1 DESCRIPTION

Math::LiveStats provides live statistical calculations (mean, standard deviation, p-value,
volume-weighted-average-price and stddev vwap) over multiple window sizes for streaming 
data. It uses West's algorithm for efficient updates and supports synthetic boundary 
entries to maintain consistent results.

Stats are computed based on data that exists inside the given window size, plus possibly
one (at most) synthetic entry: when old data shuffles out of the window, if there's no
data exactly on the oldest boundary of the window, one synthetic value is assumed to be
there, which is linearly-interpolated from the entries that appeared logically either side.

=head1 METHODS


=cut

require Exporter;

our @ISA = qw(Exporter);
our($VERSION)='1.02';
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
      cpv       => 0, # Cumulative_Price_Volume
      cv        => 0, # Cumulative_Volume
      vM2       => 0, # M2 of the vwap
      vmean	=> 0, # for vwapdev
      synthetic => undef,  # To store synthetic entry if needed
      start_index => 0,
    };
  }

  return bless $self, $class;
} # new


=head2 add($timestamp, $value [,$volume])

Adds a new data point to the time-series and updates statistics.

=cut

sub add {
  my ($self, $timestamp, $value, $volume) = @_;

  die "series key (e.g. timestamp) and value must be defined" unless defined $timestamp && defined $value;
  die "duplicated $timestamp" if @{ $self->{data} } && $self->{data}[-1]{timestamp}==$timestamp;

  my $largest_window = $self->{window_sizes}[-1];
  my $window_start   = $timestamp - $largest_window;
  my $inserted_synthetic=0;
  $volume=0 unless($volume);


  # Actually append the new data point to the end of our array
  push @{ $self->{data} }, { timestamp => $timestamp, value => $value, volume => $volume };

  # Update stats for our largest_window with the new data point
  $self->_add_point({ timestamp => $timestamp, value => $value, volume => $volume}, $largest_window);

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
    my($synthetic_value, $synthetic_volume);

    if ($last_removed_point) {
      # Interpolate between last_removed_point and oldest_point
      ($synthetic_value, $synthetic_volume) = $self->_interpolate( $last_removed_point, $oldest_point, $synthetic_timestamp );
    } else {
      # Initial add, use value of the oldest_point
      $synthetic_value = $oldest_point->{value};
      $synthetic_volume = $oldest_point->{volume};
    }

    # Create synthetic point
    my $synthetic_point = {
      timestamp => $synthetic_timestamp,
      value   => $synthetic_value,
      volume   => $synthetic_volume,
      # is this needed? synthetic => 1,  # Mark as synthetic
    };

    # Insert synthetic point at the beginning of data list
    unshift @{ $self->{data} }, $synthetic_point;
    $removed_count--;

    # Update stats with the synthetic point
    $self->_add_point($synthetic_point, $largest_window);
  }


  # Now accumulate the new point for the other window sizes, and work out their synthetic entries as well if required
  foreach my $window (@{ $self->{window_sizes} }[0 .. $#{ $self->{window_sizes} } - 1]) { # all except largest_window
    my $window_start = $timestamp - $window;
    my $stats = $self->{stats}{$window};

    # Update stats with the new data point for this window
    $self->_add_point({ timestamp => $timestamp, value => $value, volume => $volume }, $window);

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
      my($synthetic_value, $synthetic_volume);

      my $before_index = $stats->{start_index} - 1;
      my $before = $before_index >= 0 ? $self->{data}[ $before_index ] : undef;
      my $after  = $oldest_in_window;

      if ($before && $after) {
        # Interpolate between before and after
        ($synthetic_value, $synthetic_volume) = $self->_interpolate($before, $after, $synthetic_timestamp);
      } elsif ($after) {
        # Use the value of the after point
        $synthetic_value = $after->{value};
        $synthetic_volume = $after->{volume};
      } else {
        # Use the current value (since there's no data in window)
        $synthetic_value = $value;
        $synthetic_volume = $volume;
      }

      # Create synthetic point
      my $synthetic_point = {
        timestamp => $synthetic_timestamp,
        value     => $synthetic_value,
        volume   => $synthetic_volume,
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

Returns the standard deviation of the values for the specified window size.

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


=head2 vwap($window_size)

Returns the volume-weighted average price for the specified window size.

=cut

sub vwap {
  my ($self, $window) = @_;
  die "Window size must be specified" unless defined $window;
  die "Invalid window size" unless exists $self->{stats}{$window};

  return $self->{stats}{$window}{cv} ? $self->{stats}{$window}{cpv}/$self->{stats}{$window}{cv} : undef;
} # vwap


=head2 vwapdev($window_size)

Returns the standard deviation of the vwap for the specified window size.

=cut

sub vwapdev {
  my ($self, $window) = @_;
  die "Window size must be specified" unless defined $window;
  die "Invalid window size" unless exists $self->{stats}{$window};

  my $cv = $self->{stats}{$window}{cv};
  my $vM2 = $self->{stats}{$window}{vM2};
  my $variance = $cv > 0 ? $vM2 / $cv : 0;
  return $variance < 0 ? 0 : sqrt($variance);
} # vwapdev

=head2 recalc($window_size)

Recalculates the running statistics for the given window to reduce accumulated numerical errors.

=cut

sub recalc {
  my ($self,$window) = @_;

  my $data = $self->{data};

  # Reset stats for given window size
  my $stats = $self->{stats}{$window};
  $stats->{n}		= 0;
  $stats->{mean}	= 0;
  $stats->{M2}		= 0;
  $stats->{cpv}		= 0;
  $stats->{cv}		= 0;
  $stats->{vM2}		= 0;
  $stats->{vmean}	= 0;
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
  my $w = $point->{volume} ? $point->{volume} : ($stats->{n} ? $stats->{cv} / $stats->{n} : 0);
  $stats->{n}++;

  # Update mean and M2 as before
  my $delta = $point->{value} - $stats->{mean};
  $stats->{mean} += $delta / $stats->{n};
  my $delta2 = $point->{value} - $stats->{mean};
  $stats->{M2} += $delta * $delta2;

  # Update cumulative price*volume and cumulative volume
  $stats->{cpv} += $point->{value} * $w;
  $stats->{cv} += $w;

  # Update weighted mean (vmean) and weighted M2 (vM2)
  my $sumw_prev = $stats->{cv} - $w;
  if ($sumw_prev > 0) {
    my $delta_w = $point->{value} - $stats->{vmean};
    $stats->{vmean} += ($w / $stats->{cv}) * $delta_w;
    $stats->{vM2} += $w * $delta_w * ($point->{value} - $stats->{vmean});
  } else {
    # First data point
    $stats->{vmean} = $point->{value};
    $stats->{vM2} = 0;
  }
} # _add_point


# Internal method to remove a data point from stats for a specific window
sub _remove_point {
  my ($self, $point, $window) = @_;

  my $stats = $self->{stats}{$window};
  my $w = $point->{volume} ? $point->{volume} : ($stats->{n} ? $stats->{cv} / $stats->{n} : 0);
  $stats->{n}--;
  $stats->{n} = 0 if $stats->{n} < 0;

  # Update mean and M2
  my $delta = $point->{value} - $stats->{mean};
  $stats->{mean} -= $delta / ($stats->{n} || 1);
  my $delta2 = $point->{value} - $stats->{mean};
  $stats->{M2} -= $delta * $delta2;
  $stats->{M2} = 0 if $stats->{M2} < 0; # Ensure M2 is not negative due to floating-point errors

  # Update cumulative price*volume and cumulative volume
  $stats->{cpv} -= $point->{value} * $w;
  $stats->{cv} -= $w;
  $stats->{cv} = 0 if $stats->{cv} < 0;

  # Update weighted mean (vmean) and weighted M2 (vM2)
  my $sumw_prev = $stats->{cv} + $w;
  if ($stats->{cv} > 0) {
    my $delta_w = $point->{value} - $stats->{vmean};
    $stats->{vmean} -= ($w / $stats->{cv}) * $delta_w;
    $stats->{vM2} -= $w * $delta_w * ($point->{value} - $stats->{vmean});
    $stats->{vM2} = 0 if $stats->{vM2} < 0;
  } else {
    # No data points left
    $stats->{vmean} = 0;
    $stats->{vM2} = 0;
  }
} # _remove_point


# Internal method to interpolate synthetic value
sub _interpolate {
  my ($self, $before, $after, $time) = @_;

  my $t0 = $before->{timestamp};
  my $t1 = $after->{timestamp};
  my $p0 = $before->{value};
  my $p1 = $after->{value};
  my $v0 = $before->{volume};
  my $v1 = $after->{volume};

  my $slopep = ($p1 - $p0) / ($t1 - $t0);
  my $slopev = ($v1 - $v0) / ($t1 - $t0);
  return ($p0 + $slopep * ($time - $t0), $v0 + $slopev * ($time - $t0));
} # _interpolate



1; # End of Math::LiveStats


__END__

=head2 EXPORT

None by default.


=head2 Source/Bug-Reports

Please report any bugs or feature requests on the GitHub repository at:

L<https://github.com/gitcnd/Math-LiveStats>


=head1 AUTHORS

This module was written by Chris Drake F<cdrake@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

