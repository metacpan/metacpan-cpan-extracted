package InheritanceTest;

use strict;
use warnings;
use lib 't/test';
use base 'Test';

sub new {
    my $class = shift;
    bless {}, $class;
}

1;
