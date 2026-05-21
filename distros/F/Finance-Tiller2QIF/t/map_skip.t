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

subtest skip_rule => sub {
  my $dbfile  = uniqfile( 'map_skip', 'sqlite3' );
  my $csvfile = uniqfile( 'map_skip', 'csv' );
  my $mapfile = uniqfile( 'map_skip', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,100.00,Payment,Card Payment,Credit Card Payments',
    '04/25/2026,2,Checking,50.00,Coffee,Cafe,Food',
  );
  freshmap( $mapfile,
    'category | Credit Card Payments | skip',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id skipped mapped_category)] )->hashes->@*;
  is( $tx{1}{skipped},          1,     'Matched skip rule sets skipped = 1' );
  is( $tx{1}{mapped_category},  undef, 'Skipped transaction has no mapped_category' );
  is( $tx{2}{skipped},          0,     'Non-matching transaction is not skipped' );
  $db->disconnect;
};

subtest skip_default => sub {
  my $dbfile  = uniqfile( 'map_skipdef', 'sqlite3' );
  my $csvfile = uniqfile( 'map_skipdef', 'csv' );
  my $mapfile = uniqfile( 'map_skipdef', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,100.00,Pay,Payroll,Income',
    '04/25/2026,2,Checking,25.00,Misc,Unknown,Other',
  );
  freshmap( $mapfile,
    'category | Income | Revenues:Salary',
    'default | skip',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id skipped mapped_category)] )->hashes->@*;
  is( $tx{1}{skipped},         0,                'Matched rule overrides skip default' );
  is( $tx{1}{mapped_category}, 'Revenues:Salary', 'Matched rule sets mapped_category' );
  is( $tx{2}{skipped},         1,                'Unmatched transaction gets skip default' );
  $db->disconnect;
};

subtest skip_is_terminal => sub {
  my $dbfile  = uniqfile( 'map_skiprerun', 'sqlite3' );
  my $csvfile = uniqfile( 'map_skiprerun', 'csv' );
  my $mapfile = uniqfile( 'map_skiprerun', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,1,Checking,100.00,Payment,Card Payment,Credit Card Payments' );
  freshmap( $mapfile, 'category | Credit Card Payments | skip', 'default | source' );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', [qw(skipped exported)], { id => 1 } )->hash;
  is( $tx->{skipped},  1, 'Transaction skipped after map run' );
  is( $tx->{exported}, 1, 'Skipped transaction marked exported so it is excluded from future map runs' );

  # Re-running map without the skip rule does not reprocess the transaction
  path($mapfile)->spew_utf8( "default | source\n" );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  $tx = $db->select( 'transactions', [qw(skipped exported)], { id => 1 } )->hash;
  is( $tx->{skipped},  1, 'Skipped transaction not reprocessed on re-run (exported = 1 excludes it)' );

  $db->disconnect;
};

subtest account_filtered_skip => sub {
  my $dbfile  = uniqfile( 'map_acct_skip', 'sqlite3' );
  my $mapfile = uniqfile( 'map_acct_skip', 'map' );
  my $db      = freshdb($dbfile);
  $db->query(q{
    INSERT INTO transactions
    (id, account, date, amount, payee, memo, category, mapped_category, check_number, skipped, exported)
    VALUES
    ('TX001', 'FMFCU Home Equity',  '2026-05-01', -1216.20, 'Transfer From 7658', 'Transfer From 7658', 'Transfer', '', '', 0, 0),
    ('TX002', 'Liabilities:Amex',   '2026-05-01',  -842.00, 'Transfer From 1234', 'Transfer From 1234', 'Transfer', '', '', 0, 0),
    ('TX003', 'FMFCU Home Equity',  '2026-05-01',   -95.00, 'Corner Market',      'CORNER MARKET 999',  'Groceries','', '', 0, 0)
    ;
  });
  freshmap( $mapfile,
    '[CapitalOne|Amex|FMFCU Home Equity] category | Transfer | skip',
    'default | source',
  );
  Finance::Tiller2QIF::Map::Map({ db_path => $dbfile, mapfile => $mapfile });
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id skipped mapped_category exported)] )->hashes->@*;
  is( $tx{TX001}{skipped},         1,     'FMFCU Home Equity Transfer skipped by account-filtered rule' );
  is( $tx{TX001}{mapped_category}, undef, 'Skipped transaction has no mapped_category' );
  is( $tx{TX001}{exported},        1,     'Skipped transaction exported flag set to 1' );
  is( $tx{TX002}{skipped},         1,     'Amex Transfer also skipped by same account-filtered rule' );
  is( $tx{TX002}{exported},        1,     'Second skipped transaction exported flag set to 1' );
  is( $tx{TX003}{skipped},         0,     'FMFCU Home Equity non-Transfer transaction is not skipped' );
  is( $tx{TX003}{exported},        0,     'Non-skipped transaction exported flag remains 0' );
  $db->disconnect;
};

done_testing();
unlink glob "t/tmp/t2q_*" if test_pass();
