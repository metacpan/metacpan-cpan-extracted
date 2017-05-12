use Test::More tests => 4;

use File::Spec;

BEGIN {
  use_ok( 'IRC::Indexer::Report::Server') ;
  use_ok( 'IRC::Indexer::Report::Network') ;
}
new_ok( 'IRC::Indexer::Report::Server' );
new_ok( 'IRC::Indexer::Report::Network' );
