#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);
use Log::Any::For::Std;

#---

plan tests => 6;

# Capture STDERR
print STDERR 'стдерр';

# Capture WARN
warn 'варнинг';

# DIE (Parsing module, eval, or main program) - This message should not be captured
BEGIN {
    eval {
        die "бегинэвалдай";
    }
};

# DIE (Executing an eval) - This message should not be captured.
eval {
    die "эвалдай";
};

# Capture STDERR after DIE
print STDERR 'стдерр';

# Capture DIE
# TODO hmmm... need to think

my $msgs = $log->msgs;

like( $msgs->[0]->{message}, "/стдерр/", "Capture STDERR (message)" );
is( $msgs->[0]->{level}, 'notice', "Capture STDERR (level)" );

like( $msgs->[1]->{message}, "/варнинг/", "Capture WARN (message)" );
is( $msgs->[1]->{level}, 'warning', "Capture WARN (level)" );

like( $msgs->[2]->{message}, "/стдерр/", "Capture STDERR after DIE (message)" );
is( $msgs->[2]->{level}, 'notice', "Capture STDERR after DIE (level)" );
