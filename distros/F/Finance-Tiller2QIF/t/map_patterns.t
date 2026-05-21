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

subtest payee_match => sub {
  my $dbfile  = uniqfile( 'map_payee', 'sqlite3' );
  my $csvfile = uniqfile( 'map_payee', 'csv' );
  my $mapfile = uniqfile( 'map_payee', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,8,Checking,50.00,,Amazon,Shopping' );
  freshmap( $mapfile,
    'payee | Amazon | blank',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 8 } )->hash;
  is( $tx->{mapped_category}, '', 'payee match with blank destination works' );
  $db->disconnect;
};

subtest regex_alternation => sub {
  my $dbfile  = uniqfile( 'map_alt', 'sqlite3' );
  my $csvfile = uniqfile( 'map_alt', 'csv' );
  my $mapfile = uniqfile( 'map_alt', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,,Cafe Alpha,Food',
    '04/25/2026,2,Checking,20.00,,Cafe Beta,Food',
    '04/25/2026,3,Checking,5.00,Gas,Shell,Auto',
  );
  freshmap( $mapfile,
    'payee | /Cafe Alpha|Cafe Beta/ | Expenses:Dining',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my @rows = $db->select( 'transactions', [qw(id mapped_category)],
    {}, { order_by => 'id' } )->hashes->@*;
  is( $rows[0]{mapped_category}, 'Expenses:Dining', 'First alternation matched' );
  is( $rows[1]{mapped_category}, 'Expenses:Dining', 'Second alternation matched' );
  is( $rows[2]{mapped_category}, undef,             'Non-matching stays NULL' );
  $db->disconnect;
};

subtest case_insensitive_field => sub {
  my $dbfile  = uniqfile( 'map_cifield', 'sqlite3' );
  my $csvfile = uniqfile( 'map_cifield', 'csv' );
  my $mapfile = uniqfile( 'map_cifield', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food' );
  freshmap( $mapfile,
    'Category | Food | Expenses:Food',
    'Default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 1 } )->hash;
  is( $tx->{mapped_category}, 'Expenses:Food', 'Field name in mapping file is case-insensitive' );
  $db->disconnect;
};

subtest case_insensitive_pattern => sub {
  my $dbfile  = uniqfile( 'map_cipat', 'sqlite3' );
  my $csvfile = uniqfile( 'map_cipat', 'csv' );
  my $mapfile = uniqfile( 'map_cipat', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,10.00,Coffee,Cafe,FOOD',
    '04/25/2026,2,Checking,20.00,Coffee,Cafe,food',
    '04/25/2026,3,Checking,30.00,Coffee,Cafe,Food',
  );
  freshmap( $mapfile,
    'category | ^food$ | Expenses:Food',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my @rows = $db->select( 'transactions', [qw(id mapped_category)],
    {}, { order_by => 'id' } )->hashes->@*;
  is( $rows[0]{mapped_category}, 'Expenses:Food', 'Uppercase value matched by lowercase pattern' );
  is( $rows[1]{mapped_category}, 'Expenses:Food', 'Lowercase value matched by lowercase pattern' );
  is( $rows[2]{mapped_category}, 'Expenses:Food', 'Mixed-case value matched by lowercase pattern' );
  $db->disconnect;
};

subtest destination_preserves_case => sub {
  my $dbfile  = uniqfile( 'map_destcase', 'sqlite3' );
  my $csvfile = uniqfile( 'map_destcase', 'csv' );
  my $mapfile = uniqfile( 'map_destcase', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Coffee,Cafe,food' );
  freshmap( $mapfile,
    'category | food | Expenses:Food:CafeAndDining',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $tx = $db->select( 'transactions', ['mapped_category'], { id => 1 } )->hash;
  is( $tx->{mapped_category}, 'Expenses:Food:CafeAndDining',
    'Destination category case is preserved exactly' );
  $db->disconnect;
};

subtest escaped_pipe => sub {
  my $dbfile  = uniqfile( 'map_escape', 'sqlite3' );
  my $csvfile = uniqfile( 'map_escape', 'csv' );
  my $mapfile = uniqfile( 'map_escape', 'map' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,5.00,Cash|App Payment,Cash App,Transfers',
    '04/25/2026,2,Checking,5.00,Cash,Corner Store,Food',
    '04/25/2026,3,Checking,5.00,App Payment,App Store,Tech',
  );
  freshmap( $mapfile,
    'payee | Cash\|App Payment | Expenses:Transfers',
    'default | source',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx{1}{mapped_category}, 'Expenses:Transfers',
    'Literal pipe in data matched by \| in pattern' );
  is( $tx{2}{mapped_category}, undef,
    '"Cash" alone does not match escaped-pipe pattern' );
  is( $tx{3}{mapped_category}, undef,
    '"App Payment" alone does not match escaped-pipe pattern' );
  $db->disconnect;
};

my $wildcarddb = q{
  INSERT INTO transactions
  (id, account, date, amount, payee, memo, category, mapped_category, check_number, skipped, exported)
  VALUES
  ('X2343', 'DINERS CLUB', '2024-11-14', 88.22, 'Pennsylvania Wine and Spirits Store 752', '', 'Groceries', '', '', 0, 0),
  ('EERWOWWS71Y', 'AMERICAN EXPRESS - 9377', '2024-11-14', 414.85, 'Toodles Stationary', '', 'Incorrect', '', '', 0, 0),
  ('78344FIOD', 'BANK OF GOTHAM - 4499', '2024-11-14', 88.22, 'Pennsylvania Wine and Spirits Store 752', '', 'Groceries', '', '', 0, 0),
  ('1654', 'TOTALLUSH STORE CARD', '2024-11-14', 79.16, 'TL Outlet Wilmington, DE', 'Jack Daniels Sale', 'Restaurants', '', '', 0, 0),
  ('1965', 'TOTALLUSH STORE CARD', '2024-11-14', 62.18, 'TL Concord Pike Wilmington, DE', 'Best Single Malt Selection in Delaware', 'Groceries', '', '', 0, 0),
  ('78267FIOD', 'BANK OF GOTHAM - 4499', '2024-11-14', 4265.21, 'Gotham Mortgage & Usury', '', 'XFER', '', '', 0, 0)
  ;
};

my $wildcardmap = q{
  [totallush] payee | * | Expenses:Alcohol
  payee | toodles | Expenses:Office Supply
  [DINERS CLUB] category | /*/ | Expenses:Restaurants
  default | uncategorized
};

subtest wildcard_on_field => sub {
  my $dbfile  = uniqfile( 'wildcard_on_field', 'sqlite3' );
  my $mapfile = uniqfile( 'wildcard_on_field', 'map' );
  my $db      = freshdb($dbfile);
  $db->query($wildcarddb);
  freshmap( $mapfile, $wildcardmap );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id account payee category mapped_category)],
      {}, { order_by => 'id' } )->hashes->@*;

  is( $tx{'X2343'}{mapped_category}, 'Expenses:Restaurants',
    'DINERS CLUB wildcard on category matches any category value' );
  is( $tx{'EERWOWWS71Y'}{mapped_category}, 'Expenses:Office Supply',
    'toodles payee matches case-insensitive' );
  is( $tx{'78344FIOD'}{mapped_category}, 'uncategorized',
    'BANK OF GOTHAM transaction does not match any rules' );
  is( $tx{'1654'}{mapped_category}, 'Expenses:Alcohol',
    'TOTALLUSH account wildcard on payee matches' );
  is( $tx{'1965'}{mapped_category}, 'Expenses:Alcohol',
    'TOTALLUSH account wildcard on payee matches again' );
  is( $tx{'78267FIOD'}{mapped_category}, 'uncategorized',
    'BANK OF GOTHAM XFER transaction does not match any rules' );
  $db->disconnect;
};

subtest rule_ordering_specific_before_broad => sub {
  my $insert = q{
    INSERT INTO transactions
    (id, account, date, amount, payee, memo, category, mapped_category, check_number, skipped, exported)
    VALUES
    ('TX001', 'Liabilities:CreditCard1', '2026-05-03', -9.24,  'Wawa x 1234 Anytown PA', 'WAWA XXXX 1234 ANYTOWN PA',  'Groceries', '', '', 0, 0),
    ('TX002', 'Liabilities:CreditCard2', '2026-05-02', -24.08, 'Wawa x x-x-5678 PA',     'WAWA XXXX XXX-XXX-5678 PA',  'Groceries', '', '', 0, 0),
    ('TX003', 'Liabilities:CreditCard1', '2026-05-01', -15.00, 'Corner Market',           'CORNER MARKET 999',          'Groceries', '', '', 0, 0)
    ;
  };

  my $dbfile1  = uniqfile( 'map_order_correct', 'sqlite3' );
  my $mapfile1 = uniqfile( 'map_order_correct', 'map' );
  my $db1      = freshdb($dbfile1);
  $db1->query($insert);
  freshmap( $mapfile1,
    'payee    | Wawa      | blank',
    'category | Groceries | Expenses:Groceries',
    'default  | source',
  );
  Finance::Tiller2QIF::Map::Map({ db_path => $dbfile1, mapfile => $mapfile1 });
  my %tx1 = map { $_->{id} => $_ }
    $db1->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx1{TX001}{mapped_category}, '',                  'correct order: Wawa payee rule fires before broad category rule' );
  is( $tx1{TX002}{mapped_category}, '',                  'correct order: second Wawa transaction also blanked' );
  is( $tx1{TX003}{mapped_category}, 'Expenses:Groceries','correct order: non-Wawa grocery maps to Expenses:Groceries' );
  $db1->disconnect;

  my $dbfile2  = uniqfile( 'map_order_wrong', 'sqlite3' );
  my $mapfile2 = uniqfile( 'map_order_wrong', 'map' );
  my $db2      = freshdb($dbfile2);
  $db2->query($insert);
  freshmap( $mapfile2,
    'category | Groceries | Expenses:Groceries',
    'payee    | Wawa      | blank',
    'default  | source',
  );
  Finance::Tiller2QIF::Map::Map({ db_path => $dbfile2, mapfile => $mapfile2 });
  my %tx2 = map { $_->{id} => $_ }
    $db2->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx2{TX001}{mapped_category}, 'Expenses:Groceries', 'wrong order: broad category rule shadows specific payee rule' );
  is( $tx2{TX002}{mapped_category}, 'Expenses:Groceries', 'wrong order: second Wawa also captured by category rule' );
  is( $tx2{TX003}{mapped_category}, 'Expenses:Groceries', 'wrong order: non-Wawa grocery still maps correctly' );
  $db2->disconnect;
};

subtest payee_case_insensitive_substring => sub {
  my $dbfile  = uniqfile( 'map_payee_ci', 'sqlite3' );
  my $mapfile = uniqfile( 'map_payee_ci', 'map' );
  my $db      = freshdb($dbfile);
  $db->query(q{
    INSERT INTO transactions
    (id, account, date, amount, payee, memo, category, mapped_category, check_number, skipped, exported)
    VALUES
    ('TX001', 'Liabilities:CreditCard1', '2026-05-03', -9.24,  'Wawa x 1234 Anytown PA',    'WAWA XXXX 1234 ANYTOWN PA',       'Groceries', '', '', 0, 0),
    ('TX002', 'Liabilities:CreditCard2', '2026-05-02', -24.08, 'Wawa x x-x-5678 PA',        'WAWA XXXX XXX-XXX-5678 PA',       'Groceries', '', '', 0, 0)
    ;
  });
  freshmap( $mapfile,
    'payee | Wawa          | blank',
    'default | source',
  );
  Finance::Tiller2QIF::Map::Map({ db_path => $dbfile, mapfile => $mapfile });
  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id mapped_category)] )->hashes->@*;
  is( $tx{TX001}{mapped_category}, '', 'payee "Wawa x 1234 Anytown PA" matched by bare pattern Wawa (case-insensitive)' );
  is( $tx{TX002}{mapped_category}, '', 'payee "Wawa x x-x-5678 PA" matched by bare pattern Wawa (case-insensitive)' );
  $db->disconnect;
};

done_testing();
unlink glob "t/tmp/t2q_*" if test_pass();
