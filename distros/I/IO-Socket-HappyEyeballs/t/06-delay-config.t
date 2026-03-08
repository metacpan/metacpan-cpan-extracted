use strict;
use warnings;
use Test::More;

use IO::Socket::HappyEyeballs;

# Test connection_attempt_delay accessor
my $default = IO::Socket::HappyEyeballs->connection_attempt_delay;
is($default, 0.250, 'default delay is 250ms');

IO::Socket::HappyEyeballs->connection_attempt_delay(0.100);
is(IO::Socket::HappyEyeballs->connection_attempt_delay, 0.100, 'delay changed to 100ms');

# Restore
IO::Socket::HappyEyeballs->connection_attempt_delay(0.250);

done_testing;
