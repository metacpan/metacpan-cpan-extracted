package CCstashCallee2;

use strict;
use warnings;

use Devel::Pragma qw(ccstash);

our $CCSTASH;

BEGIN { $CCSTASH = ccstash }

sub test {
    return $CCSTASH;
}

1;
