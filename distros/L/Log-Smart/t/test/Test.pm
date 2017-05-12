package Test;

use strict;
use warnings;
use Log::Smart -name => 'Test.debug', -timestamp;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub say {
    LOG('say hello');
    return "hello";
}

1;
