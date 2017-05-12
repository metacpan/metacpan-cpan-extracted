use strict;
use warnings;
use utf8;
use Test::More;
use Log::Pony;

my $logger = Log::Pony->new(color => 1, log_level => 'debug');
isa_ok($logger, 'Log::Pony');
$logger->debug("OK DEBUG");
$logger->info("OK INFO");
$logger->warn("OK WARN");
$logger->error("OK ERROR");

done_testing;

