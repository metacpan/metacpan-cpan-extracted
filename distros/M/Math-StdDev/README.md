# NAME

Math::StdDev - Pure-perl mean and variance computation supporting running/online calculation (Welford's algorithm)

# SYNOPSIS

```perl
    #!/usr/bin/perl -w
      
    use Math::StdDev;

    my $d = new Math::StdDev();
    $d->Update(2);
    $d->Update(3);
    print $d->mean() . "\t" . $d->sampleVariance();     # or $d->variance()
```

or

```bash
    perl -MMath::StdDev -e '$d=new Math::StdDev; $d->Update(10**8+4, 10**8 + 7, 10**8 + 13, 10**8 + 16); print $d->mean() . "\n" . $d->sampleVariance() . "\n"'
```

# DESCRIPTION

This module impliments Welford's online algorithm (see https://en.wikipedia.org/wiki/Algorithms\_for\_calculating\_variance )
Maybe one day in future the two-pass algo could be included, along with Kahan compensated summation... so much math, so little time...

## EXPORT

None by default.

## Notes

## new

Usage is

```perl
    my $d = new Math::StdDev();
```
or
```perl
    my $d = new Math::StdDev(1,2,3,4);  # Add one or more samples, or a population, right from the start
```

## Update

Usage is

```perl
    my $d->Update(123);
```
or
```perl
    my $d->Update(@list_of_scalars);
```

## mean()

Usage is

```perl
    print $d->mean();
```

## variance

Usage is

```perl
    print $d->variance();
```

## sampleVariance

(same as variance, but uses n-1 divisor.)  Usage is:

```perl
    print $d->sampleVariance();
```

# AUTHOR

This module was written by Chris Drake `cdrake@cpan.org`. 

# COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
