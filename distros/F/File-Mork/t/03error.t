use strict;
use Test::More tests => 3;
use File::Mork;

my $filename = "examples/does_not_exist";
my $mork;
ok(!defined $File::Mork::ERROR, "No error message");
ok(!($mork = File::Mork->new($filename)), "Couldn't instantiate file");
ok(defined $File::Mork::ERROR,"Got error message");
