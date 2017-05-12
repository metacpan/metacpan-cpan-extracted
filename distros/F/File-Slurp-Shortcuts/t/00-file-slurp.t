#!perl -T

# tests to see that standard File::Slurp behaviour (e.g. default exports) is not
# changed

use 5.010;
use strict;
use warnings;

use Test::More tests => 1;

use File::Temp qw(tempfile);
use File::Slurp::Shortcuts;

my ($fh, $filename);
($fh, $filename) = tempfile();

write_file($filename, 'test');
is(read_file($filename), 'test',
   'read_file/write_file exported by default, just like with File::Slurp');


