# NAME

Math::LiveStats - Pure perl module to make mean, standard deviation, and p-values available for given window sizes in streaming data

# SYNOPSIS

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

# DESCRIPTION

Math::LiveStats provides live statistical calculations (mean, standard deviation, p-value)
over multiple window sizes for streaming data. It uses West's algorithm for efficient
updates and supports synthetic boundary entries to maintain consistent results.

# METHODS

## new(@window\_sizes)

Creates a new Math::LiveStats object with the specified window sizes.

## add($timestamp, $value)

Adds a new data point to the time-series and updates statistics.

## mean($window\_size)

Returns the mean for the specified window size.

## stddev($window\_size)

Returns the standard deviation for the specified window size.

## pvalue($window\_size)

Calculates the p-value based on the standard deviation for the specified window size.

## n($window\_size)

Returns the number of entries in the specified window size.

## recalc($window\_size)

Recalculates the running statistics for the given window to reduce accumulated numerical errors.

## EXPORT

None by default.

# AUTHORS

This module was written by Chris Drake `cdrake@cpan.org`.

# COPYRIGHT AND LICENSE

Copyright (c) 2024 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
