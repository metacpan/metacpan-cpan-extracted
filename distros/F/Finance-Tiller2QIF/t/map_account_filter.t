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

subtest account_filter => sub {
  my $dbfile  = uniqfile( 'map_acct', 'sqlite3' );
  my $csvfile = uniqfile( 'map_acct', 'csv' );
  my $mapfile = uniqfile( 'map_acct', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Savings,10.00,Coffee,Cafe,Food',
  );
  freshmap( $mapfile,
    '[Checking] category | Food | Expenses:Food',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx{1}{mapped_category}, 'Expenses:Food',
    'Account-filtered rule matches transaction on correct account' );
  is( $tx{2}{mapped_category}, undef,
    'Account-filtered rule does not match transaction on different account' );
  $db->disconnect;
};

subtest account_filter_alternation => sub {
  my $dbfile  = uniqfile( 'map_acctalt', 'sqlite3' );
  my $csvfile = uniqfile( 'map_acctalt', 'csv' );
  my $mapfile = uniqfile( 'map_acctalt', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food',
    '04/25/2026,2,Savings,10.00,Coffee,Cafe,Food',
    '04/25/2026,3,Brokerage,10.00,Coffee,Cafe,Food',
  );
  freshmap( $mapfile,
    '[Checking|Savings] category | Food | Expenses:Food',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx{1}{mapped_category}, 'Expenses:Food', 'Checking matches alternation filter' );
  is( $tx{2}{mapped_category}, 'Expenses:Food', 'Savings matches alternation filter' );
  is( $tx{3}{mapped_category}, undef,           'Brokerage not in filter, falls to default' );
  $db->disconnect;
};

subtest account_filter_skip => sub {
  my $dbfile  = uniqfile( 'map_acctskip', 'sqlite3' );
  my $csvfile = uniqfile( 'map_acctskip', 'csv' );
  my $mapfile = uniqfile( 'map_acctskip', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,-250.00,CardPymt,Target Payment,Credit Card Payment',
    '04/25/2026,2,Target RedCard,250.00,Payment Received,Target Payment,Credit Card Payment',
  );
  freshmap( $mapfile,
    'payee | CardPymt | Liabilities:CreditCards:Target',
    '[Target RedCard] category | Credit Card Payment | skip',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id skipped mapped_category)] )->hashes->@*;
  is( $tx{1}{skipped},         0,                          'Checking payment not skipped' );
  is( $tx{1}{mapped_category}, 'Liabilities:CreditCards:Target',
    'Checking payment mapped to liability' );
  is( $tx{2}{skipped},         1,                          'Card-side credit skipped by account filter' );
  $db->disconnect;
};

done_testing();
unlink glob "t/tmp/t2q_*" if test_pass();
