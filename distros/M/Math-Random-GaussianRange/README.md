Math::Random::GaussianRange
===========================

Given a range, returns a reference to an array of randomly generated numbers which are normally distributed i.e. clustered around the mean. The module uses a best approximation, values are distributed within 3 standard deviations from the perceived mean.

```perl

    my $rh = {
        min   => 0,    # minimum
        max   => 1000, # maximum
        n     => 100,  # number of numbers returned (default 100) 
        round => 0,    # return integers
    }
    
    my $ra = generate_normal_range( $rh );
```