
use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use lib './lib';
use File::Util;

# check object constructor
ok
(
   ref File::Util->new() eq 'File::Util',
   'New bare File::Util instantiation'
);

exit;
