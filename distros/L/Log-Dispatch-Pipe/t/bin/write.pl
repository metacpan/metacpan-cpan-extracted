use strict;
use warnings;

my $file = shift @ARGV;
open my $fh, '>>', $file or die "Failed to open handle: $!";

while (<>) { print $fh $_ }

close $fh;
