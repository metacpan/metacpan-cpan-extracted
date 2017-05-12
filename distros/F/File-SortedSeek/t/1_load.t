use strict;
use Test;
use vars qw($loaded);

BEGIN { plan tests => 1 }
END   { print "not ok 1\n" unless $loaded }

use lib '../lib';
use File::SortedSeek;

ok($loaded = 1);