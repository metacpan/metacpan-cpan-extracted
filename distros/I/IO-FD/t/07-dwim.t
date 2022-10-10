use Test::More;
use IO::FD::DWIM;

use Fcntl;

#Create a pipe with core
die "Could not use CORE::pipe" unless CORE::pipe my $read, my $write;

#Do IO With IO::FD
syswrite $write, "Hello";
sysread $read, my $buf, 5;
ok $buf eq "Hello", "Read/Write ok";

CORE::close $read;
CORE::close $write;


#Create a pipe with core
die "Could not use CORE::pipe" unless pipe $read, $write;

#Do IO With IO::FD
syswrite $write, "Hello";
sysread $read, my $buf, 5;
ok $buf eq "Hello", "Read/Write ok";

close $read;
close $write;

done_testing;
