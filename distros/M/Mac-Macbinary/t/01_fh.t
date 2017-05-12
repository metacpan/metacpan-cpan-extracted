use strict;
use Test;
BEGIN { plan tests => 1 }
use Mac::Macbinary;

open FH, "t/test.mb";
my $mb = new Mac::Macbinary \*FH;
ok($mb->data, "testdata");
close FH;

