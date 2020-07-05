#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use LCS::BV;
use LCS;
use LCS::Tiny;

# export NYTPROF=addtimestamp=1:start=init;perl -d:NYTProf 10_profile.t
# nytprofhtml -f nytprof.out.1437103846 -o nytprof.1437103846
# or easiest: perl -d:NYTProf 10_profile.t; nytprofhtml

my @data = (
  [split(//,'Chrerrplzon')],
  [split(//,'Choerephon')]
);

my @data3 = ([qw/a b d/ x 50], [qw/b a d c/ x 50]);

if (1) {
    my $count = 1000;
    for (1..$count) {
      LCS::BV->LLCS(@data);
      LCS->LLCS(@data);
      LCS::Tiny->LCS(@data);
    }
}
