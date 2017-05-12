# Feed::PhaseCheck

[![Build Status](https://travis-ci.org/binary-com/perl-feed-phasecheck.svg?branch=master)](https://travis-ci.org/binary-com/perl-feed-phasecheck)
[![codecov](https://codecov.io/gh/binary-com/perl-feed-phasecheck/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-feed-phasecheck)

Module that finds the relative time delay between two feed segments.  

Accomplished by shifting one feed relative to the other and then computing the error (absolute difference).  

The shift that yields the lowest error corresponds to the relative delay between he two input feeds.  

The output consists of the delay found, and the error in delayed point.

Module has only one function **compare_feeds**.

### Usage:
```perl
use Feed::PhaseCheck qw(compare_feeds);
my $sample = {
    "1451276654" => "1.097655",
    "1451276655" => "1.09765",
    ...
    "1451276763" => "1.0976",
    "1451276764" => "1.097595"
};
my $compare_to = {
    "1451276629" => "1.09765",
    "1451276630" => "1.09764916666667",
    ...
    "1451276791" => "1.097595",
    "1451276792" => "1.097595"
}
my $max_delay_check = 30;    # seconds
my ($errors,$delay_with_min_err) = compare_feeds($sample,$compare_to,$max_delay_check);
```
