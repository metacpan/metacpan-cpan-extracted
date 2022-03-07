use warnings;
use strict;

use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

my @command = ('date');
my $rc = system( @command );

is $rc, 0, "system() returns success ok after moving CHLD handler";

done_testing();
