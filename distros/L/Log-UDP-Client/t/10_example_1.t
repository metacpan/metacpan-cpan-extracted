use strict;
use warnings;
use Test::More tests => 1;

use Log::UDP::Client;
# Send the simple scalar to the server
is(Log::UDP::Client->new->send("Hi"), 1, "send scalar failed");
