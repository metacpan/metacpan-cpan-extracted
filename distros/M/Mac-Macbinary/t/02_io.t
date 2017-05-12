use strict;
use Test;
BEGIN { plan tests => 1 }
use Mac::Macbinary;

use IO::File;

my $io = new IO::File "t/test.mb";
my $mb = new Mac::Macbinary $io;
ok($mb->data, "testdata");

