use strict;
use warnings;

use Test::More;

use Log::Any qw($log);
use Log::Any::Adapter;

use Log::Any::Adapter::Util qw(logging_methods);

my @levels = logging_methods();
for my $level (@levels){
    Log::Any::Adapter->import('DERIV', log_level => $level);
    is($log->adapter->level, $level, "current level is $level");
}

done_testing;