#!perl
use 5.008001;
use strict;
use warnings;

use Test::More;

use Capture::Tiny 'capture';
use Log::Log4cplus;

my @enabled_log_levels  = (qw(emergency panic fatal critical error warning notice basic info debug));
my @disabled_log_levels = (qw(trace));

my $logger = Log::Log4cplus->new(config_basic => 1);
foreach my $log_level (@enabled_log_levels)
{
    my $is = "is_$log_level";
    ok($logger->$is(), "Testing for log-level $log_level is available");
    my ($stdout, $stderr, $exit) = capture { $logger->$log_level("Logging in level $log_level"); };
    is($exit, 0, "Logged in log-level $log_level");
  TODO:
    {
        local $TODO = "Broken since 5.9" if $] >= 5.009;
        like($stdout, qr/Logging in level $log_level$/, "Got logged text in log-level $log_level");
        is($stderr, "", "No error logging in log-level $log_level");
    }
}

foreach my $log_level (@disabled_log_levels)
{
    my $is = "is_$log_level";
    ok(!$logger->$is(), "Testing for log-level $log_level isn't available");
    my ($stdout, $stderr, $exit) = capture { $logger->$log_level("Logging in level $log_level"); };
    is($exit, 0, "Logged in log-level $log_level");
  TODO:
    {
        local $TODO = "Broken since 5.9" if $] >= 5.009;
        is($stdout, "", "Nothing logged in log-level $log_level");
        is($stderr, "", "No error logging in log-level $log_level");
    }
}

done_testing();
