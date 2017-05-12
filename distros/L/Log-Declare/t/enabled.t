#!/usr/bin/env perl

# the whole premise of Log::Declare is that a) arguments should not be evaluated and
# b) Log::Declare->log(...) should not be called unless c) the log level is enabled e.g.:
#
#     info "foo: %s", Dumper($foo);
#
# is translated to:
#
#     Log::Declare->log('info', ['GENERAL'], sprintf('foo: %s', Dumper($foo))) if info();
#
# confirm that the log-level functions behave as expected i.e. return true if the
# log level is enabled, and false otherwise

use strict;
use warnings;

use Test::More tests => 72;

# keep our own record of the levels and their expected relations. this allows the
# test to be run on older versions of the module, and prevents tight (i.e. redundant)
# coupling between the testing and tested fixtures
my @LEVELS = qw(trace debug info warn error audit);
my %LEVEL = map { $LEVELS[$_] => $_ + 1 } (0 .. $#LEVELS);

$LEVEL{off} = $LEVEL{disable} = @LEVELS + 1;
$LEVEL{all} = $LEVEL{any} = $LEVEL{invalid} = $LEVEL{mistyped} = -1;

{
    package Log::Declare::t;

    use Log::Declare;

    sub get_enabled {
        Log::Declare->startup_level(shift);
        return { map { $_ => __PACKAGE__->can($_)->() || 0 } @LEVELS };
    }
}

for my $level (keys %LEVEL) {
    my $enabled = Log::Declare::t::get_enabled($level);

    for my $key (keys %$enabled) {
        my $value = $enabled->{$key};

        if ($LEVEL{$key} >= $LEVEL{$level}) { # message level >= (global) log level/threshold: enabled
            ok($value, "threshold: $level, message: $key: enabled: 1");
        } else { # message level < (global) log level/threshold: disabled
            ok(!$value, "threshold: $level, message: $key: enabled: 0");
        }
    }
}
