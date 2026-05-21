use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Test2::Bundle::More;
use Path::Tiny;
use Finance::Tiller2QIF::Map;
use Finance::Tiller2QIF::ReadCSV;
use feature qw/signatures postderef/;

require './t/TestHelper.pm';

subtest no_map_file => sub {
  my $dbfile  = uniqfile( 'map_noop', 'sqlite3' );
  my $csvfile = uniqfile( 'map_noop', 'csv' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Coffee,Corner Cafe,Food' );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 1 } )->hash;
  is( $tx->{mapped_category}, undef, 'No mapping file leaves mapped_category NULL' );
  $db->disconnect;
};

subtest category_match => sub {
  my $dbfile  = uniqfile( 'map_cat', 'sqlite3' );
  my $csvfile = uniqfile( 'map_cat', 'csv' );
  my $mapfile = uniqfile( 'map_cat', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,2,Checking,10.00,Coffee,Corner Cafe,Food',
    '04/25/2026,3,Checking,50.00,Shoes,Shoe Shop,Shopping',
  );
  freshmap( $mapfile,
    'category | Food | Expenses:Food',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my @rows = $db->select( 'transactions', [qw(id mapped_category)],
    {}, { order_by => 'id' } )->hashes->@*;
  is( $rows[0]{mapped_category}, 'Expenses:Food', 'Matched category is mapped' );
  is( $rows[1]{mapped_category}, undef,           'source default leaves unmatched NULL' );
  $db->disconnect;
};

subtest blank_destination => sub {
  my $dbfile  = uniqfile( 'map_blank', 'sqlite3' );
  my $csvfile = uniqfile( 'map_blank', 'csv' );
  my $mapfile = uniqfile( 'map_blank', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,4,Checking,10.00,Fee,Bank Fee,Fees' );
  freshmap( $mapfile,
    'category | Fees | blank',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 4 } )->hash;
  is( $tx->{mapped_category}, '', 'blank keyword sets mapped_category to empty string' );
  $db->disconnect;
};

subtest default_blank => sub {
  my $dbfile  = uniqfile( 'map_defblank', 'sqlite3' );
  my $csvfile = uniqfile( 'map_defblank', 'csv' );
  my $mapfile = uniqfile( 'map_defblank', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,5,Checking,100.00,Pay,Payroll,Income',
    '04/25/2026,6,Checking,25.00,Misc,Unknown,Other',
  );
  freshmap( $mapfile,
    'category | Income | Revenues:Salary',
    'default | blank',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my @rows = $db->select( 'transactions', [qw(id mapped_category)],
    {}, { order_by => 'id' } )->hashes->@*;
  is( $rows[0]{mapped_category}, 'Revenues:Salary', 'Rule match overrides blank default' );
  is( $rows[1]{mapped_category}, '',                'blank default applied to unmatched' );
  $db->disconnect;
};

subtest first_match_wins => sub {
  my $dbfile  = uniqfile( 'map_first', 'sqlite3' );
  my $csvfile = uniqfile( 'map_first', 'csv' );
  my $mapfile = uniqfile( 'map_first', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,7,Checking,10.00,Coffee,Cafe,Food' );
  freshmap( $mapfile,
    'category | Food     | Expenses:Food',
    'category | ^Food$   | Expenses:Dining',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 7 } )->hash;
  is( $tx->{mapped_category}, 'Expenses:Food', 'First matching rule wins' );
  $db->disconnect;
};

subtest source_destination => sub {
  my $dbfile  = uniqfile( 'map_source', 'sqlite3' );
  my $csvfile = uniqfile( 'map_source', 'csv' );
  my $mapfile = uniqfile( 'map_source', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,8,Checking,10.00,Coffee,Cafe,Food' );
  freshmap( $mapfile,
    'category | Food | source',
    'default | blank',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 8 } )->hash;
  is( $tx->{mapped_category}, undef, 'source destination sets mapped_category to NULL' );
  $db->disconnect;
};

done_testing();
unlink glob "t/tmp/t2q_*" if test_pass();
