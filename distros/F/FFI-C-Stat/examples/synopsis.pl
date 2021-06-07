use strict;
use warnings;
use FFI::C::Stat;

my $stat = FFI::C::Stat->new("foo.txt");
print "size = ", $stat->size;
