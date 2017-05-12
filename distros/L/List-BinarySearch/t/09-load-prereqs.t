#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

sub prereq_message {
    return "*** YOU MUST INSTALL $_[0] BEFORE PROCEEDING ***\n";
}

# If Parse::RecDescent or Inline::C aren't cleanly installed there's no point
# continuing the test suite.

BEGIN {
    use_ok( 'Scalar::Util' )                                        # 1.
        or BAIL_OUT( prereq_message( 'Scalar::Util' ) );
}

done_testing();
