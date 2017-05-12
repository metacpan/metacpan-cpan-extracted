use strict;
use warnings;
use Test::More tests => 1;
use File::Listing::Ftpcopy qw( ftpparse );

is ftpparse(''), undef, 'not found';
