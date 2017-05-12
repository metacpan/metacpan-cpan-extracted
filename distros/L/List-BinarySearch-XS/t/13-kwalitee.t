#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;


# To enable this suite one must set $ENV{RELEASE_TESTING} to a true value.
# This prevents author tests from running on a user install.

if ( not $ENV{RELEASE_TESTING} ) {
    my $msg =
        'Author Test: Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
    done_testing();
}


unless(
  eval {
    require Test::Kwalitee;
    Test::Kwalitee->import();
    # Clean up. I don't know why this persists, but we certainly don't need to
    # leave clutter behind.
    unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';
    1;
  }
) {
  plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
  done_testing();
}
