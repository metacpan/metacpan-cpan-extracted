use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;

my $h = IPC::Shareable->new({key => 123456, create => 1, destroy => 1});

$h->{1} = 1;

sleep 5;

print "One:\n";
print Dumper $h;