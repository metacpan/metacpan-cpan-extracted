use strict;
use warnings;
use utf8;
use Test::More;

# re.pm clobbers $_ in 5.14.0 ~ 5.16.0
# ref. https://github.com/mirrors/perl/commit/48895a0d

$_ = "Do not edit this variable";
require Encode::JP::Mobile::Charnames;
is($_, "Do not edit this variable");

done_testing;

