#!perl -w
use strict;

use Devel::Optrace -all;

sub hello{
	print STDOUT "Hello, world!\n";
}

sub foo(){ 42 }

&hello;

print foo(), "\n";
