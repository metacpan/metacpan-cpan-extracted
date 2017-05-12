package t::Foo;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

1;
