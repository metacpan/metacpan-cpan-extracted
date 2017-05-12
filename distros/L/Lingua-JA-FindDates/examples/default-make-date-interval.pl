#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Lingua::JA::FindDates;
print Lingua::JA::FindDates::default_make_date_interval (
{
    # 19 February 2010
    year => 2010,
    month => 2,
    date => 19,
    wday => 5,
},
# Monday 19th March 2012.
{
    year => 2012,
    month => 3,
    date => 19,
    wday => 1,
},), "\n";

