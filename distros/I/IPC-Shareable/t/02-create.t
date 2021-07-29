use warnings;
use strict;

use IPC::Shareable;
use Test::More;

my $ok = eval {
    tie my $sv, 'IPC::Shareable', {key => 'test02', destroy => 1};
    1;
};

is $ok, undef, "We croak ok if create is not set and segment doesn't yet exist";
like $@, qr/Could not acquire/, "...and error is sane.";

done_testing;

