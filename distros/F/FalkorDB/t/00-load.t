use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('FalkorDB')        || BAIL_OUT("FalkorDB failed to load");
    use_ok('FalkorDB::Graph') || BAIL_OUT("FalkorDB::Graph failed to load");
    use_ok('FalkorDB::QueryResult')
      || BAIL_OUT("FalkorDB::QueryResult failed to load");
    use_ok('FalkorDB::Node') || BAIL_OUT("FalkorDB::Node failed to load");
    use_ok('FalkorDB::Edge') || BAIL_OUT("FalkorDB::Edge failed to load");
    use_ok('FalkorDB::Path') || BAIL_OUT("FalkorDB::Path failed to load");
}

diag("Testing FalkorDB $FalkorDB::VERSION, Perl $], $^X");
