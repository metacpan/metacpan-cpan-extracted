#!/usr/bin/env perl
use strict;
use warnings;
use 5.008_006;
our $VERSION = 0.001;

use Log::Any qw( $log );
use Log::Any::Adapter( 'JSONLines',
    file => \*STDERR,
    log_level => 'trace',
    canonical => 0,
    hooks => {
        before => [ \&prepare_json, ]
    },
);
sub prepare_json {
    my ($level, $category, $log_entry) = @_;
    $log_entry->{epoch}  = time;
    $log_entry->{lvl} = $level;
    $log_entry->{cat} = $category;
    $log_entry->{msg} = delete $log_entry->{message};
    return;
}

# ###################################################################
# main
sub main {
    $log->trace('Logging TRACE');
    $log->debug('Logging DEBUG');
    $log->info('Logging INFO');
    $log->warning('Logging WARNING');
    $log->error('Logging ERROR');
    $log->fatal('Logging FATAL');
    return 0;
}

exit main(@ARGV);
