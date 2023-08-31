#!/usr/bin/env perl

use strict;
use warnings;

use Finance::Random::Price;

# Object.
my $obj = Finance::Random::Price->new(
        'currencies' => ['USD', 'EUR'],
        'min' => 99,
        'max' => 101,
);

# Print random price.
print $obj->random."\n";

# Output like:
# EUR100,00

# Output like:
# $99.00

# Output like:
# $101.00