use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Exception qw/dies lives/;
use Capture::Tiny qw/capture_stdout/;
use Path::Tiny;
use Finance::Tiller2QIF::Map;
use Finance::Tiller2QIF::ReadCSV;
use Finance::Tiller2QIF::Util;
use Mojo::SQLite;
use feature qw/signatures postderef/;

require './t/TestHelper.pm';

# beforemap.sql has two statements: renames 'Checking' -> 'Checking-VIP'
#                                   and 'Savings' -> 'Savings-VIP'
# Map rules fire only on the renamed accounts, proving beforemap ran before map
# and that both statements in the script executed.
# aftermap.sql has two statements: sets check_number on Expenses:Dining rows
#                                  and on Expenses:Food rows.

subtest beforemap => sub {
  my $db_path = uniqfile( 'beforemap', 'sqlite3' );
  my $csvfile = uniqfile( 'beforemap', 'csv' );
  my $mapfile = uniqfile( 'beforemap', 'map' );
  my $dbmojo  = freshdb($db_path);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Savings,20.00,Coffee,Cafe,Food',
    '04/25/2026,3,Brokerage,30.00,Stocks,Vanguard,Investment',
  );
  freshmap( $mapfile,
    '[Checking-VIP] category | Food | Expenses:Dining',
    '[Savings-VIP]  category | Food | Expenses:Dining',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $db_path );
  Finance::Tiller2QIF::Map::Map({
    db_path   => $db_path,
    mapfile   => $mapfile,
    beforemap => 't/testcase/beforemap.sql',
  });
  my @rows = $dbmojo->select( 'transactions', [qw(id account mapped_category)],
    {}, { order_by => 'id' } )->hashes->@*;
  is( $rows[0]{account},         'Checking-VIP',    'beforemap stmt 1: Checking renamed' );
  is( $rows[1]{account},         'Savings-VIP',     'beforemap stmt 2: Savings renamed' );
  is( $rows[2]{account},         'Brokerage',       'beforemap did not rename unmatched account' );
  is( $rows[0]{mapped_category}, 'Expenses:Dining', 'map rule fired on Checking-VIP' );
  is( $rows[1]{mapped_category}, 'Expenses:Dining', 'map rule fired on Savings-VIP' );
  is( $rows[2]{mapped_category}, undef,             'map rule did not fire on unmatched account' );
  $dbmojo->disconnect;
};

subtest aftermap => sub {
  my $db_path = uniqfile( 'aftermap', 'sqlite3' );
  my $csvfile = uniqfile( 'aftermap', 'csv' );
  my $mapfile = uniqfile( 'aftermap', 'map' );
  my $dbmojo  = freshdb($db_path);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Savings,20.00,Coffee,Cafe,Food',
    '04/25/2026,3,Brokerage,30.00,Stocks,Vanguard,Investment',
  );
  freshmap( $mapfile,
    '[Checking-VIP] category | Food | Expenses:Dining',
    '[Savings-VIP]  category | Food | Expenses:Dining',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $db_path );
  Finance::Tiller2QIF::Map::Map({
    db_path  => $db_path,
    mapfile  => $mapfile,
    aftermap => 't/testcase/aftermap.sql',
  });
  my @rows = $dbmojo->select( 'transactions', [qw(id mapped_category check_number)],
    {}, { order_by => 'id' } )->hashes->@*;
  # Without beforemap no rules fire, so aftermap finds nothing to update.
  is( $rows[0]{mapped_category}, undef, 'map rule did not fire without beforemap' );
  is( $rows[0]{check_number},    undef, 'aftermap stmt 1 found no matching rows' );
  is( $rows[1]{mapped_category}, undef, 'map rule did not fire without beforemap' );
  is( $rows[1]{check_number},    undef, 'aftermap stmt 2 found no matching rows' );
  is( $rows[2]{check_number},    undef, 'aftermap did not touch unmatched row' );
  $dbmojo->disconnect;
};

subtest beforemap_and_aftermap => sub {
  my $db_path = uniqfile( 'both', 'sqlite3' );
  my $csvfile = uniqfile( 'both', 'csv' );
  my $mapfile = uniqfile( 'both', 'map' );
  my $dbmojo  = freshdb($db_path);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Savings,20.00,Coffee,Cafe,Food',
    '04/25/2026,3,Brokerage,30.00,Stocks,Vanguard,Investment',
  );
  freshmap( $mapfile,
    '[Checking-VIP] category | Food | Expenses:Dining',
    '[Savings-VIP]  category | Food | Expenses:Dining',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $db_path );
  Finance::Tiller2QIF::Map::Map({
    db_path   => $db_path,
    mapfile   => $mapfile,
    beforemap => 't/testcase/beforemap.sql',
    aftermap  => 't/testcase/aftermap.sql',
  });
  my @rows = $dbmojo->select( 'transactions', [qw(id account mapped_category check_number)],
    {}, { order_by => 'id' } )->hashes->@*;
  is( $rows[0]{mapped_category}, 'Expenses:Dining', 'map rule fired on Checking-VIP' );
  is( $rows[1]{mapped_category}, 'Expenses:Dining', 'map rule fired on Savings-VIP' );
  is( $rows[0]{check_number},    'after_ran',       'aftermap stmt 1 ran after map' );
  is( $rows[1]{check_number},    'after_ran',       'aftermap stmt 1 ran after map' );
  is( $rows[2]{account},         'Brokerage',       'beforemap did not rename unmatched account' );
  is( $rows[2]{mapped_category}, undef,             'map rule did not fire on unmatched account' );
  is( $rows[2]{check_number},    undef,             'aftermap did not touch unmatched row' );
  $dbmojo->disconnect;
};

subtest sql_semicolon_edgecases => sub {
  my $db_path = uniqfile( 'edge', 'sqlite3' );
  my $csvfile = uniqfile( 'edge', 'csv' );
  my $mapfile = uniqfile( 'edge', 'map' );
  my $dbmojo  = freshdb($db_path);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Savings,20.00,Coffee,Cafe,Food',
    '04/25/2026,3,Brokerage,30.00,Stocks,Vanguard,Investment',
  );
  freshmap( $mapfile, 'default | source' );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $db_path );
  ok( lives {
    Finance::Tiller2QIF::Map::Map({
      db_path   => $db_path,
      mapfile   => $mapfile,
      beforemap => 't/testcase/edgecase.sql',
    })
  }, 'edgecase sql file executed without error' );
  my @rows = $dbmojo->select( 'transactions', [qw(id account memo)],
    {}, { order_by => 'id' } )->hashes->@*;
  is( $rows[0]{account}, 'Checking-VIP', 'stmt after -- comment with semicolon executed' );
  is( $rows[1]{account}, 'Savings-VIP',  'stmt after /* */ comment with semicolon executed' );
  is( $rows[2]{memo},    'foo; bar',     'semicolon inside string literal preserved correctly' );
  $dbmojo->disconnect;
};

subtest verbose_output => sub {
  my $db_path = uniqfile( 'verbose', 'sqlite3' );
  my $csvfile = uniqfile( 'verbose', 'csv' );
  my $mapfile = uniqfile( 'verbose', 'map' );
  my $dbmojo  = freshdb($db_path);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Brokerage,30.00,Stocks,Vanguard,Investment',
  );
  freshmap( $mapfile,
    '[Checking-VIP] category | Food | Expenses:Dining',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $db_path );
  my $out = capture_stdout {
    Finance::Tiller2QIF::Map::Map({
      db_path   => $db_path,
      mapfile   => $mapfile,
      beforemap => 't/testcase/beforemap.sql',
      aftermap  => 't/testcase/aftermap.sql',
      verbose   => 1,
    })
  };
  like( $out, qr/Running beforemap/,              'verbose reports beforemap start' );
  like( $out, qr/beforemap completed successfully/, 'verbose reports beforemap success' );
  like( $out, qr/Running aftermap/,               'verbose reports aftermap start' );
  like( $out, qr/aftermap completed successfully/,  'verbose reports aftermap success' );
  like( $out, qr/1 row\(s\) affected/,            'verbose reports positive rows affected' );
  like( $out, qr/0 row\(s\) affected/,            'verbose reports zero rows affected' );
  $dbmojo->disconnect;
};

done_testing();

unlink glob "t/tmp/t2q_*" if test_pass();
