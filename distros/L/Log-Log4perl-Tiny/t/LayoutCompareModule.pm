package LayoutCompareModule;
use strict;
use warnings;

BEGIN {
   *INFO = *main::INFO;
}

sub talk {
   INFO "talk";
   Some::Other::ever();
}

sub complain {
   $_[0]->();
}

1;
