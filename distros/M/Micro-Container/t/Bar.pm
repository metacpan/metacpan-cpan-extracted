package t::Bar;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

1;
