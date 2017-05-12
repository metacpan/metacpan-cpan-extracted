#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Lingua::JA::FindDates;
my $outdate = Lingua::JA::FindDates::default_make_date ({
    year => 2012,
    month => 3,
    date => 19,
    wday => 1,
});
print "$outdate\n";
