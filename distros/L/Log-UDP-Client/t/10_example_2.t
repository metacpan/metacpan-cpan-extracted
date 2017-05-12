use strict;
use warnings;
use Test::More tests => 1001;

use Time::HiRes ();
use Log::UDP::Client;

# Log lots of messages
my $logger = Log::UDP::Client->new(server_port => 15000);
isa_ok($logger,'Log::UDP::Client', 'logger is not a Log::UDP::Client instance');
my $counter=0;
while(++$counter) {
    is($logger->send($counter), 1, "send $counter failed");
    last if $counter >= 1000;
}

# Benchmark it a bit
my $count = 10000;
my $start = Time::HiRes::time;
for(my $i=0; $i < $count; $i++) {
    $logger->send($i);
}
my $stop = Time::HiRes::time;
my $interval = $stop - $start;
my $send_pr_sec = $count / $interval;
diag("$count tests took $interval seconds, $send_pr_sec messages per second (using Storable::nfreeze).");
