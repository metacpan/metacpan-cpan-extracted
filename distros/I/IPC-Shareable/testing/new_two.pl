use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;

my $h = IPC::Shareable->new({key => 123456, create => 1, destroy => 1});
$h->{2} = 2;

print "Two:\n";
print Dumper $h;