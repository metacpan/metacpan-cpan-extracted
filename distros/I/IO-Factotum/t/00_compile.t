use strict;
use Test::More 0.98;

use_ok $_ for qw(
    IO::Factotum
    IO::Factotum::ARGV
    IO::Factotum::Highlight::skylighting
    IO::Factotum::Highlight::sourcehighlight
    IO::Factotum::Highlight::sky
    IO::Factotum::Highlight::gnu
    Getopt::EX::Factotum
);

done_testing;
