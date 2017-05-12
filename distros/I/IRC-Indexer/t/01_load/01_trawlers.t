use Test::More tests => 5;

use File::Spec;

BEGIN {
  use_ok( 'IRC::Indexer' );
  use_ok( 'IRC::Indexer::Trawl::Bot' );
  use_ok( 'IRC::Indexer::Trawl::Forking') ;
}

new_ok( 'IRC::Indexer::Trawl::Bot'     => [ Server => 'localhost']);
new_ok( 'IRC::Indexer::Trawl::Forking' => [ Server => 'localhost']);
