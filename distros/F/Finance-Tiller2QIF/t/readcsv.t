use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Test2::Bundle::More;
# use Test2::Tools::Warnings  qw/warns warning warnings no_warnings/;
use Test2::Tools::Exception qw/dies lives/;
use Path::Tiny;
use Finance::Tiller2QIF::ReadCSV;
use Finance::Tiller2QIF::WriteQIF;
use Finance::Tiller2QIF::Util;
use Mojo::SQLite;
use Capture::Tiny qw( capture_stdout );
use DBI;
use feature qw/signatures postderef/;

require './t/TestHelper.pm';

# use Data::Printer;

subtest malformed_date => sub {
  my $dbfile  = uniqfile( 'malformed_date', 'sqlite3' );
  my $csvfile = uniqfile( 'malformed_date', 'csv' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, 'BADDATE,1,Checking,100.00,Deposit,Paycheck,Income' );

  my $count = Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  is($count, 0, 'No records added');
  my $out = capture_stdout { Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile ) };
  like( $out, qr/Could not parse date/, 'bad date prints expected message' );
  my $results = $db->select( 'transactions', ['id'], { id => 1 } )->arrays;
  is( scalar(@$results), 0, 'skipped record not in database' );
  $db->disconnect;
};

subtest missing_amount => sub {
  my $dbfile  = uniqfile( 'missing_amount', 'sqlite3' );
  my $csvfile = uniqfile( 'missing_amount', 'csv' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '4/25/2026,2,Checking,,Withdrawal,ATM,Expense' );
  ok( lives { Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile ) },
    'Missing amount does not crash' );
  my $count = Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  is($count, 0, 'No records added');
  $db->disconnect;
};

subtest missing_transaction_id => sub {
  my $dbfile  = uniqfile( 'missing_id', 'sqlite3' );
  my $csvfile = uniqfile( 'missing_id', 'csv' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile, '04/25/2026,,Checking,10.00,Withdrawal,ATM,Expense' );
  ok( lives { Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile ) },
    'Missing Transaction ID is not fatal' );
  my $count = Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  is($count, 0, 'No records added');
  my $results = $db->select( 'transactions', '*' )->arrays;
  is( scalar(@$results), 0, 'Missing Transaction ID is skipped' );
  $db->disconnect;
};

subtest extra_columns => sub {
  my $dbfile  = uniqfile( 'extra_columns', 'sqlite3' );
  my $csvfile = uniqfile( 'extra_columns', 'csv' );
  freshdb($dbfile);
  my @lines = (
    'Date,Transaction ID,Account,Amount,Description,Full Description,Category,Extra',
    '04/25/2026,3,Checking,10.00,Withdrawal,ATM,Expense,foo',
    '03/25/2026,4,Checking,10.00,Withdrawal,ATM,Expense,foo',
    ''
  );
  path($csvfile)->spew_utf8( join( "\n", @lines ) );
  is( Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile ), 2, 'Transaction written even with extra columns');
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  my $db      = Mojo::SQLite->new($dbfile)->options({ sqlite_unicode => 1 })->db;
  my $results = $db->select( 'transactions', '*' )->arrays;
  $db->disconnect;
};

subtest us_comma_thousands => sub {
  my $dbfile  = uniqfile( 'us_comma', 'sqlite3' );
  my $csvfile = uniqfile( 'us_comma', 'csv' );
  my $qiffile = uniqfile( 'us_comma', 'qif' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,20,Checking,"$1,234.56",Deposit,Paycheck,Income',
    '04/25/2026,21,Checking,"$1,000",Payment,Rent,Expense',
  );
  is(Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile ), 2, 'records added');
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  my $qif = path($qiffile)->slurp_utf8;
  like( $qif, qr/T1234\.56/, 'US comma-thousands with decimal correctly normalized' );
  like( $qif, qr/T1000\.00/, 'US comma-thousands without decimal correctly normalized' );
  $db->disconnect;
};

subtest missing_csv_file => sub {
  my $dbfile = uniqfile( 'missing', 'sqlite3' );
  freshdb($dbfile);
  ok( dies { Finance::Tiller2QIF::ReadCSV::Ingest( '/nonexistent/path/file.csv', $dbfile ) },
    'Nonexistent CSV file dies' );
};

subtest optional_fields => sub {
  my $dbfile  = uniqfile( 'optional', 'sqlite3' );
  my $csvfile = uniqfile( 'optional', 'csv' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,22,Checking,10.00,,Full Description Only,Income',
    '04/25/2026,23,Checking,20.00,HasDescription,Full Description,',
  );
  my $count = Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  is($count, 2, 'records added');
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  my @rows = $db->select( 'transactions', [qw(id payee memo category)],
    {}, { order_by => 'id' } )->hashes->@*;
  is( $rows[0]{payee},    'Full Description Only', 'Empty Description falls back to Full Description' );
  is( $rows[0]{category}, 'Income',                'Category stored when present' );
  is( $rows[1]{category}, '',                      'Empty Category stored as empty string' );
  $db->disconnect;
};

subtest british_pounds => sub {
  my $dbfile  = uniqfile( 'gbp', 'sqlite3' );
  my $csvfile = uniqfile( 'gbp', 'csv' );
  my $qiffile = uniqfile( 'gbp', 'qif' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '04/25/2026,30,Checking,£100.50,Deposit,Salary,Income',
    '04/25/2026,31,Checking,£1500.00,Payment,Rent,Expense',
  );
  my $count = Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  is($count, 2, 'records added');
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  my $qif = path($qiffile)->slurp_utf8;
  like( $qif, qr/T100\.50/,  'GBP amount with pence correctly normalized' );
  like( $qif, qr/T1500\.00/, 'GBP whole amount correctly normalized' );
  $db->disconnect;
};

subtest euro_amounts => sub {
  my $dbfile  = uniqfile( 'eur', 'sqlite3' );
  my $csvfile = uniqfile( 'eur', 'csv' );
  my $qiffile = uniqfile( 'eur', 'qif' );
  my $db      = freshdb($dbfile);
  path($csvfile)->spew_utf8( join( "\n",
    'Date,Transaction ID,Account,Amount,Description,Full Description,Category',
    '04/25/2026,40,Checking,"€1.234,56",Deposit,Salary,Income',
    '04/25/2026,41,Checking,"€100,50",Withdrawal,ATM,Expense',
    '',
  ));
  my $count = Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  is($count, 2, 'Records written');
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  my $qif = path($qiffile)->slurp_utf8;
  like( $qif, qr/T1234\.56/, 'EUR European thousands separator correctly normalized' );
  like( $qif, qr/T100\.50/,  'EUR European decimal comma correctly normalized' );
  $db->disconnect;
};

subtest check_number => sub {
  my $dbfile  = uniqfile( 'check_num', 'sqlite3' );
  my $csvfile = uniqfile( 'check_num', 'csv' );
  my $qiffile = uniqfile( 'check_num', 'qif' );
  my $db      = freshdb($dbfile);

  # Tiller emits 0 for electronic/card transactions and a real number for checks.
  # The leading-zero row intentionally shares the standard 7-column format;
  # check number is column 13 in the real export but freshcsv only writes 7 columns,
  # so we write this CSV manually to include the Check Number column.
  path($csvfile)->spew_utf8( join( "\n",
    'Date,Transaction ID,Account,Amount,Description,Full Description,Category,Check Number',
    '04/25/2026,50,Checking,-120.00,Electric Bill,City Power Co,Utilities,0',
    '04/25/2026,51,Checking,-85.00,Landlord,Rent Payment,Housing,201',
    '04/25/2026,52,Checking,-25.00,Groceries,Corner Market,Food,',
    '',
  ));


  is(Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile ), 3, 'Records added.');
  Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );

  my %tx = map { $_->{id} => $_ }
    $db->select( 'transactions', [qw(id check_number)] )->hashes->@*;

  is( $tx{50}{check_number}, undef, 'Check number 0 stored as NULL' );
  is( $tx{51}{check_number}, '201', 'Real check number stored correctly' );
  is( $tx{52}{check_number}, undef, 'Empty check number stored as NULL' );

  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  my $qif = path($qiffile)->slurp_utf8;
  unlike( $qif, qr/^N0$/m,   'Zero check number not emitted in QIF' );
  like(   $qif, qr/^N201$/m, 'Real check number emitted as N field' );

  $db->disconnect;
};

subtest empty_file => sub {
  my $dbfile  = uniqfile( 'empty_file', 'sqlite3' );
  my $csvfile = uniqfile( 'empty_file', 'csv' );
  freshdb($dbfile);
  path($csvfile)->spew("");
  ok( dies { Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile ) },
    'Empty file dies as expected' );
};

subtest bad_insert => sub {
  my $dbfile = uniqfile( 'bad_insert', 'sqlite3' );
  my $db     = freshdb($dbfile);
  $db->disconnect;

  my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, AutoCommit => 1, sqlite_unicode => 1 }
  );
  my $insert = Finance::Tiller2QIF::ReadCSV::_prepare_insert($dbh);
  $dbh->do('DROP TABLE transactions');

  my @columns = ( 'Date', 'Transaction ID', 'Account', 'Amount', 'Description', 'Full Description', 'Category' );
  my $row     = [ '04/25/2026', '99', 'Checking', '10.00', 'Test', 'Test', 'Food' ];

  my $out = capture_stdout {
    Finance::Tiller2QIF::ReadCSV::_insert_row( $insert, \@columns, $row, 0 );
  };
  like( $out, qr/Failed to import row/, 'catch block reports failed insert' );
  $dbh->disconnect;
};

subtest wrong_sheet => sub {
  my $dbfile = uniqfile( 'wrong_sheet', 'sqlite3' );
  freshdb($dbfile);
  my $err = dies { Finance::Tiller2QIF::ReadCSV::Ingest( 't/testcase/wrong_sheet.csv', $dbfile ) };
  like( $err, qr/missing required column/, 'wrong sheet CSV dies with missing column error' );
};

subtest missing_header => sub {
  my $dbfile = uniqfile( 'missing_header', 'sqlite3' );
  freshdb($dbfile);
  my $err = dies { Finance::Tiller2QIF::ReadCSV::Ingest( 't/testcase/missing_header.csv', $dbfile ) };
  like( $err, qr/missing required column.*Transaction ID/, 'CSV missing Transaction ID column dies with clear error' );
};

# us date format is tiller's only format as of 2026-04,
# tiller2qif also supports iso8601.
subtest date_format_iso8601 => sub {
  my $dbfile  = uniqfile( 'date_iso', 'sqlite3' );
  my $csvfile = uniqfile( 'date_iso', 'csv' );
  my $qiffile = uniqfile( 'date_iso', 'qif' );
  my $db      = freshdb($dbfile);
  freshcsv( $csvfile,
    '2026-04-25,60,Checking,100.00,Deposit,Paycheck,Income',
    '2026-03-15,61,Checking,50.00,Withdrawal,ATM,Expense',
  );
  is(Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile ), 2, 'ISO 8601 dates recorded');
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  my $qif = path($qiffile)->slurp_utf8;
  like( $qif, qr/D2026-04-25/, 'ISO 8601 date correctly normalized' );
  like( $qif, qr/D2026-03-15/, 'Second ISO date correctly normalized' );
  $db->disconnect;
};

done_testing();
unlink glob "t/tmp/*" if test_pass();