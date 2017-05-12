use strict;
use warnings;
use Test::More tests => 1;

use IO::Capture::Stdout;

my $capture = IO::Capture::Stdout->new();
$capture->start(); 

printf "Hello World";

$capture->stop(); 
is($capture->read, "Hello World");
