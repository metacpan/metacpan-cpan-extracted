#!perl

use strict;
use warnings;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for author testing');
  }
}

use Test::More;

eval "use Test::Pod 1.00";
if ( $@ ) {
  plan skip_all => 'Test::Pod 1.00 required for testing POD';
}

my @poddirs = qw( ../lib ../script );
all_pod_files_ok( all_pod_files( @poddirs ) );

