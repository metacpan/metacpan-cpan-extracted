# NAME

Math::LiveStats - Pure perl module to make mean, standard deviation, vwap, and p-values available for one or more window sizes in streaming data

# SYNOPSIS

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

# CLI one-liner example

    cat data | perl -MMath::LiveStats -ne 'BEGIN{$s=Math::LiveStats->new(20);} chomp;($t,$p,$v)=split(/,/); $s->add($t,$p,$v); print "$t,$p,$v,",$s->n(20),",",$s->mean(20),",",$s->stddev(20),",",$s->vwap(20),",",$s->vwapdev(20),"\n"'

# DESCRIPTION

Math::LiveStats provides live statistical calculations (mean, standard deviation, p-value,
volume-weighted-average-price and stddev vwap) over multiple window sizes for streaming 
data. It uses West's algorithm for efficient updates and supports synthetic boundary 
entries to maintain consistent results.

Stats are computed based on data that exists inside the given window size, plus possibly
one (at most) synthetic entry: when old data shuffles out of the window, if there's no
data exactly on the oldest boundary of the window, one synthetic value is assumed to be
there, which is linearly-interpolated from the entries that appeared logically either side.

# METHODS

## new(@window\_sizes)

Creates a new Math::LiveStats object with the specified window sizes.

## add($timestamp, $value \[,$volume\])

Adds a new data point to the time-series and updates statistics.

## mean($window\_size)

Returns the mean for the specified window size.

## stddev($window\_size)

Returns the standard deviation of the values for the specified window size.

## pvalue($window\_size)

Calculates the p-value based on the standard deviation for the specified window size.

## n($window\_size)

Returns the number of entries in the specified window size.

## vwap($window\_size)

Returns the volume-weighted average price for the specified window size.

## vwapdev($window\_size)

Returns the standard deviation of the vwap for the specified window size.

## recalc($window\_size)

Recalculates the running statistics for the given window to reduce accumulated numerical errors.

## EXPORT

None by default.

## Source/Bug-Reports

Please report any bugs or feature requests on the GitHub repository at:

[https://github.com/gitcnd/Math-LiveStats](https://github.com/gitcnd/Math-LiveStats)

# AUTHORS

This module was written by Chris Drake `cdrake@cpan.org`.

# COPYRIGHT AND LICENSE

Copyright (c) 2024 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
