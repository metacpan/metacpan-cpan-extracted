#!perl -w
use strict;

use Devel::Optrace -all;

print STDOUT 42, "\n";
BEGIN{
	print $^H, "\n";
}
