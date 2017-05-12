package Foo;

use strict;
use warnings;

my $foo;

sub init {
    my $class = shift;
    $Foo::foo = shift || 1;
    
    return 42;
}

sub foo {
    return $Foo::foo;
}

1;
