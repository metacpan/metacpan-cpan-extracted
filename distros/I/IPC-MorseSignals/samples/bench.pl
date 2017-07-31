#!/usr/bin/env perl

use strict;
use warnings;

use POSIX qw<SIGINT SIGTERM SIGKILL SIGHUP EXIT_FAILURE>;

use lib qw<blib/lib t/lib>;

use IPC::MorseSignals::TestSuite qw<init bench cleanup>;

sub diag { print STDERR "@_\n" };
*IPC::MorseSignals::TestSuite::diag = *main::diag;
my @res;

init 100;

bench 4,    1,   \@res;
bench 4,    4,   \@res;
bench 4,    16,  \@res;
bench 4,    64,  \@res;
bench 4,    256, \@res;
bench 16,   1,   \@res;
bench 16,   4,   \@res;
bench 16,   16,  \@res;
bench 16,   64,  \@res;
bench 64,   1,   \@res;
bench 64,   4,   \@res;
bench 64,   16,  \@res;
bench 256,  1,   \@res;
bench 256,  4,   \@res;
bench 1024, 1,   \@res;

cleanup;

diag "\n=== Summary ===";
diag $_ for @res;
