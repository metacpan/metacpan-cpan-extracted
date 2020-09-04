#!perl

use Test2::V0;
use IO::ReStoreFH;

use File::Temp qw[ tempfile ];

plan 'skip_all', 'only relevant to 5.10.x'
  if $^V lt v5.10.0 || $^V ge 5.11.0;

my ( $fh, $fname ) = tempfile;

ok( lives { $fh->getline },
    "use FileHandle::Fmode doesn't break under 5.10.1" );

done_testing;
