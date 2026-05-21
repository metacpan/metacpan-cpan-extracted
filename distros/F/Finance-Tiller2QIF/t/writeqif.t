use strict;
use warnings;
use Test2::V0;
use Test2::Bundle::More;
use Path::Tiny;
use Finance::Tiller2QIF::ReadCSV;
use Finance::Tiller2QIF::Map;
use Finance::Tiller2QIF::WriteQIF;
use Finance::Tiller2QIF::Util;
use Mojo::SQLite;
use feature qw/signatures postderef/;

require './t/TestHelper.pm';

subtest single_account => sub {
  my $dbfile  = uniqfile( 'wq_single', 'sqlite3' );
  my $csvfile = uniqfile( 'wq_single', 'csv' );
  my $qiffile = uniqfile( 'wq_single', 'qif' );

  freshdb($dbfile);
  freshcsv( $csvfile,
    '04/24/2026,1,Checking,100.00,Deposit,Paycheck,Income',
    '04/25/2026,2,Checking,-50.00,Withdrawal,ATM,Expense',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );

  ok( -e $qiffile, 'QIF file created' );
  my $qif = path($qiffile)->slurp_utf8;

  like( $qif, qr/!Account\nNChecking\n\^\n!Type:Bank/,
    'Checking account header has correct structure' );
  like( $qif, qr/D2026-04-24\nT100\.00\nPDeposit/,
    'Deposit amount formatted to two decimal places' );
  like( $qif, qr/D2026-04-25\nT-50\.00\nPWithdrawal/,
    'Negative amount formatted to two decimal places' );
  like( $qif, qr/LIncome/,  'Category written for Deposit' );
  like( $qif, qr/LExpense/, 'Category written for Withdrawal' );

  unlink $dbfile, $csvfile, $qiffile;
};

subtest multi_account => sub {
  my $dbfile  = uniqfile( 'wq_multi', 'sqlite3' );
  my $csvfile = uniqfile( 'wq_multi', 'csv' );
  my $qiffile = uniqfile( 'wq_multi', 'qif' );

  freshdb($dbfile);
  freshcsv( $csvfile,
    '04/24/2026,1,Checking,100.00,Deposit,Paycheck,Income',
    '04/25/2026,2,Checking,-50.00,Withdrawal,ATM,Expense',
    '04/24/2026,3,Savings,500.00,Transfer,FromChecking,Income',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );

  ok( -e $qiffile, 'QIF file created' );
  my $qif = path($qiffile)->slurp_utf8;

  like( $qif, qr/!Account\nNChecking\n\^\n!Type:Bank/,
    'Checking account header has correct structure' );
  like( $qif, qr/!Account\nNSavings\n\^\n!Type:Bank/,
    'Savings account header has correct structure' );

  my @sections = grep { /\S/ } split /!Account\n/, $qif;
  is( scalar @sections, 2, 'QIF contains exactly two account sections' );

  my ($checking) = grep { /^NChecking/ } @sections;
  my ($savings)  = grep { /^NSavings/  } @sections;

  ok( $checking, 'Checking section found' );
  ok( $savings,  'Savings section found' );

  like(   $checking, qr/PDeposit/,    'Deposit in Checking section' );
  like(   $checking, qr/PWithdrawal/, 'Withdrawal in Checking section' );
  unlike( $checking, qr/PTransfer/,   'Transfer not in Checking section' );

  like(   $savings, qr/PTransfer/,   'Transfer in Savings section' );
  unlike( $savings, qr/PDeposit/,    'Deposit not in Savings section' );
  unlike( $savings, qr/PWithdrawal/, 'Withdrawal not in Savings section' );

  # unlink $dbfile, $csvfile, $qiffile;
};

subtest marks_exported => sub {
  my $dbfile  = uniqfile( 'wq_exported', 'sqlite3' );
  my $csvfile = uniqfile( 'wq_exported', 'csv' );
  my $qiffile = uniqfile( 'wq_exported', 'qif' );

  freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,80,Checking,100.00,Deposit,Paycheck,Income',
    '04/25/2026,81,Checking,-50.00,Withdrawal,ATM,Expense',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );

  my $db         = Mojo::SQLite->new($dbfile)->options({ sqlite_unicode => 1 })->db;
  my $unexported = $db->select( 'transactions', ['id'], { exported => 0 } )->arrays;
  my $exported   = $db->select( 'transactions', ['id'], { exported => 1 } )->arrays;
  is( scalar @$unexported, 0, 'No transactions remain unexported after Emit' );
  is( scalar @$exported,   2, 'All transactions marked exported = 1' );

  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  unlike( path($qiffile)->slurp_utf8, qr/!Account/, 'Second emit skips already-exported transactions' );

  $db->disconnect;
  unlink $dbfile, $csvfile, $qiffile;
};

subtest no_memo_no_category => sub {
  my $dbfile  = uniqfile( 'wq_sparse', 'sqlite3' );
  my $csvfile = uniqfile( 'wq_sparse', 'csv' );
  my $qiffile = uniqfile( 'wq_sparse', 'qif' );

  freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,70,Checking,42.00,SparsePayee,,',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );

  ok( -e $qiffile, 'QIF file created' );
  my $qif = path($qiffile)->slurp_utf8;
  like(   $qif, qr/PSparsePayee\n\^/, 'No M or L fields emitted when memo and category are empty' );
  unlike( $qif, qr/^M/m,             'No memo line in QIF' );
  unlike( $qif, qr/^L/m,             'No category line in QIF' );

  unlink $dbfile, $csvfile, $qiffile;
};

subtest skipped_excluded => sub {
  my $dbfile  = uniqfile( 'wq_skipped', 'sqlite3' );
  my $csvfile = uniqfile( 'wq_skipped', 'csv' );
  my $mapfile = uniqfile( 'wq_skipped', 'map' );
  my $qiffile = uniqfile( 'wq_skipped', 'qif' );

  freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,90,Checking,100.00,Deposit,Paycheck,Income',
    '04/25/2026,91,Checking,-250.00,CardPymt,Target Card Payment,Credit Card Payments',
  );
  path($mapfile)->spew_utf8( join( "\n",
    'category | Credit Card Payments | skip',
    'default | source',
    '',
  ));
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});
  my $updated = Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  is ( $updated, 1, "1 rows changed");

  my $qif = path($qiffile)->slurp_utf8;
  like(   $qif, qr/PDeposit/,   'Non-skipped transaction present in QIF' );
  unlike( $qif, qr/PCardPymt/,  'Skipped transaction absent from QIF' );

  # Skipped transactions are still marked exported so they don't reappear
  my $db = Mojo::SQLite->new($dbfile)->options({ sqlite_unicode => 1 })->db;
  is( $db->select( 'transactions', ['exported'], { id => 91 } )->hash->{exported},
    1, 'Skipped transaction is marked exported after Emit' );
  $db->disconnect;

  unlink $dbfile, $csvfile, $mapfile, $qiffile;
};

subtest qifdate_formats => sub {
  my $dbfile  = uniqfile( 'wq_datefmt', 'sqlite3' );
  my $csvfile = uniqfile( 'wq_datefmt', 'csv' );

  freshdb($dbfile);
  freshcsv( $csvfile,
    '04/24/2026,1,Checking,100.00,Deposit,Paycheck,Income',
  );
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );

  for my $case (
    [ ymd => 'D2026-04-24' ],
    [ mdy => 'D04/24/2026' ],
    [ dmy => 'D24/04/2026' ],
  ) {
    my ( $fmt, $expected ) = @$case;
    my $qiffile = uniqfile( "wq_datefmt_$fmt", 'qif' );
    Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile, 0, $fmt );
    like( path($qiffile)->slurp_utf8, qr/\Q$expected\E/,
      "date format '$fmt' produces '$expected'" );
    # reset exported flag so next iteration can re-emit
    Mojo::SQLite->new($dbfile)->options({ sqlite_unicode => 1 })
      ->db->query('UPDATE transactions SET exported = 0');
    unlink $qiffile;
  }

  unlink $dbfile, $csvfile;
};

subtest preview => sub {
  my $dbfile = uniqfile( 'wq_preview', 'sqlite3' );
  my $db     = freshdb($dbfile);
  $db->query(q{
    INSERT INTO transactions
    (id, account, date, amount, payee, memo, category, mapped_category, check_number, skipped, exported)
    VALUES
    ('P1', 'Liabilities:CreditCard', '2026-05-01', -42.00, 'Corner Market',                    'CORNER MARKET MEMO', 'Groceries',    'Expenses:Groceries', '', 0, 0),
    ('P2', 'Liabilities:CreditCard', '2026-05-02',  -9.99, 'A Very Long Payee Name Over Twenty', 'STREAMING CO MEMO',  'Entertainment','Entertainment',      '', 0, 0),
    ('P3', 'Liabilities:CreditCard', '2026-05-03', -10.00, 'Test Unmapped',                    'MEMO',               'Unmapped',     NULL,                  '', 0, 0)
    ;
  });

  my $output = '';
  open( my $fh, '>', \$output ) or die $!;
  my $old   = select $fh;
  my $count = Finance::Tiller2QIF::WriteQIF::Preview($dbfile);
  select $old;

  is( $count, 3, 'Preview returns correct transaction count' );
  ok( length($output) > 0, 'Preview produces output' );
  unlike( $output, qr/A Very Long Payee Name Over Twenty/, 'Long payee truncated in output' );
  like( $output, qr/Unmapped/, 'Preview shows unmapped category when mapped_category is NULL' );

  $db->disconnect;
};

done_testing();
unlink glob "t/tmp/*" if test_pass();