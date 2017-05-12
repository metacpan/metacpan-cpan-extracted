use strict;
use warnings;
use Test::More tests => 1;

use Log::UDP::Client;

# Send some debugging info
my $logger = Log::UDP::Client->new();
is($logger->send({
    pid     => $$,
    program => $0,
    args    => \@ARGV,
}), 1, 'send hashref failed');
