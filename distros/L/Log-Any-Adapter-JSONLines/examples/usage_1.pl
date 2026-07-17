#!/usr/bin/env perl
use strict;
use warnings;
use 5.008_006;
our $VERSION = 0.001;

use Log::Any qw( $log );
use Log::Any::Adapter( 'JSONLines' );

# ###################################################################
# main
sub main {
    $log->tracef('Logging TRACE, level: %d', Log::Any::Adapter::Util::numeric_level( 'trace' ));
    $log->debugf('Logging DEBUG, level: %d', Log::Any::Adapter::Util::numeric_level( 'debug') );
    $log->infof('Logging INFO, level: %d', Log::Any::Adapter::Util::numeric_level( 'info') );
    $log->noticef('Logging NOTICE, level: %d', Log::Any::Adapter::Util::numeric_level( 'notice') );
    $log->warningf('Logging WARNING, level: %d', Log::Any::Adapter::Util::numeric_level( 'warning') );
    $log->errorf('Logging ERROR, level: %d', Log::Any::Adapter::Util::numeric_level( 'error') );
    $log->fatalf('Logging FATAL, level: %d', Log::Any::Adapter::Util::numeric_level( 'fatal') );
    $log->criticalf('Logging CRITICAL, level: %d', Log::Any::Adapter::Util::numeric_level( 'critical') );
    $log->alertf('Logging ALERT, level: %d', Log::Any::Adapter::Util::numeric_level( 'alert') );
    $log->emergencyf('Logging EMERGENCY, level: %d', Log::Any::Adapter::Util::numeric_level( 'emergency') );
    return 0;
}

exit main(@ARGV);
