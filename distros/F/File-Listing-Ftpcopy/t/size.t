use strict;
use warnings;
use Test::More tests => 1;
use File::Listing::Ftpcopy ();

pass("_size_of_UV = " . File::Listing::Ftpcopy::_size_of_UV());
