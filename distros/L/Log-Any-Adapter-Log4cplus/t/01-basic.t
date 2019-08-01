use 5.008003;
use strict;
use warnings;

use Test::More;
use Log::Any::Test;
use Log::Any qw($log);
use Log::Any::Adapter ();

Log::Any::Adapter->set(Log4cplus => [config_basic => 1]);
my $logger = Log::Any->get_logger;

foreach my $log_level (Log::Any->logging_methods())
{
    $logger->$log_level("Logging in level $log_level");
    $log->contains_ok(qr/Logging in level $log_level$/, "Got logged text in log-level $log_level");
}

done_testing;
