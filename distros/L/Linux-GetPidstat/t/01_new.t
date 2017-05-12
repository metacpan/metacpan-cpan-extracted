use strict;
use warnings;
use Test::More 0.98;
use Test::Fatal;

use Linux::GetPidstat;

is exception {
    my $instance = Linux::GetPidstat->new;
}, undef, "create ok";

done_testing;
