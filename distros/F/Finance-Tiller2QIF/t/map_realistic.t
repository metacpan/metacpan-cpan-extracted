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

subtest rerun_is_idempotent => sub {
  my $dbfile  = uniqfile( 'map_rerun', 'sqlite3' );
  my $csvfile = uniqfile( 'map_rerun', 'csv' );
  my $mapfile = uniqfile( 'map_rerun', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,12,Checking,10.00,Coffee,Cafe,Food' );
  freshmap( $mapfile,
    'category | Food | Expenses:Food',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 12 } )->hash;
  is( $tx->{mapped_category}, 'Expenses:Food', 'Running map twice gives same result' );
  $db->disconnect;
};

subtest realistic_testcase => sub {
  my $dbfile  = uniqfile( 'map_real', 'sqlite3' );
  my $csvfile = 't/testcase/mapping1.csv';
  my $mapfile = 't/testcase/mapping1.map';
  my $db      = freshdb($dbfile);
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id payee mapped_category)] )->hashes->@*;
  is( $tx{TXN001}{mapped_category}, 'Expenses:Entertainment:Streaming Services',
    'Tidal.com matches payee pattern' );
  is( $tx{TXN002}{mapped_category}, 'Expenses:Medical Expenses',
    'Pharmacy matches category pattern' );
  is( $tx{TXN003}{mapped_category}, 'Expenses:Groceries',
    'Groceries category remapped to Expenses:Groceries' );
  is( $tx{TXN004}{mapped_category}, undef,
    'Kino Entertainment doesnt match and is defaulted' );
  $db->disconnect;
};

done_testing();
unlink glob "t/tmp/t2q_*" if test_pass();
