#!perl -w
use strict;
use warnings;
use List::OrderBy;

# prints lines ordered by length
print order_cmp_by { length } <>;
