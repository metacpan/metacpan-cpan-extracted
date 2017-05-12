use strict;
use warnings;
use IO::Handle;

my $filename = shift @ARGV;
open my $file, ">", $filename or die "Cannot open $filename: $!";

local $| = 1;
$file->autoflush(1);

while(defined(my $line = <STDIN>)) {
    print $line;
    print $file $line;
    last if $line =~ /^exit/;
}
close $file;
