use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use Net::Amazon::Config;
use Metabase::Index::SimpleDB;
use Metabase::Test::Index;

use lib "t/lib";

with 'Metabase::Test::Index::SimpleDB';

# help us clean up our database
local $SIG{INT} = sub { warn "Got SIGINT"; exit 1 };

run_tests(
  "Run Index tests on Metabase::Index::SimpleDB",
  ["main", "Metabase::Test::Index"],
);

done_testing;
