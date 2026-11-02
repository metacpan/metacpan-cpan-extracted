use strict;
use warnings;
use Test2::V0;
use Test2::Bundle::More;
use Path::Tiny;
use Finance::Tiller2QIF::ReadCSV;
use Finance::Tiller2QIF::Map;
use Finance::Tiller2QIF::WriteQIF;
use Finance::Tiller2QIF::Util;
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

  my $db         = dbi_connect($dbfile);
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
  my $db = dbi_connect($dbfile);
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
    dbi_connect($dbfile)->query('UPDATE transactions SET exported = 0');
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
  like( $output, qr/A Very Long Payee Name Over Twenty/, 'Long payee is not truncated' );
  like( $output, qr/^ID: P1 \| Date: 2026-05-01 \| Account: Liabilities:CreditCard\n {4}Amount: +-42\.00\n {4}Payee: +Corner Market\n {4}Memo: +CORNER MARKET MEMO\n {4}Category: +\[Groceries\] Expenses:Groceries\n\n/m,
    'preview uses labeled, indented transaction blocks with amount and original category' );
  like( $output, qr/Unmapped/, 'Preview shows unmapped category when mapped_category is NULL' );

  $db->disconnect;
};

subtest preview_full_fields => sub {
  my $dbfile = uniqfile('wq_preview_full', 'sqlite3');
  my $db = freshdb($dbfile);
  my $account = 'Assets:Bank:A very long account name beyond thirty characters';
  my $payee = 'A full payee name beyond the old twenty character limit';
  my $memo = "A long first memo line beyond thirty characters\nID: this is memo content, not a transaction";
  my $category = 'Expenses:An unusually long category name beyond thirty characters';
  $db->query(q{INSERT INTO transactions (id, account, date, amount, payee, memo, category)
    VALUES (?, ?, ?, ?, ?, ?, ?)}, 'long-id-123456789', $account, '2026-09-27', -12.34,
    $payee, $memo, $category);
  my ($count, $text) = Finance::Tiller2QIF::WriteQIF::_preview_text($dbfile);
  is($count, 1, 'one transaction');
  like($text, qr/^ID: long-id-123456789 \| Date: 2026-09-27 \| Account: \Q$account\E$/m,
    'full ID, date and account on the first line');
  like($text, qr/^ {4}Payee: +\Q$payee\E$/m, 'full payee');
  like($text, qr/^ {4}Memo: +A long first memo line beyond thirty characters\n {14}ID: this is memo content, not a transaction$/m,
    'multiline memo stays indented within its transaction');
  like($text, qr/^ {4}Category: +\Q$category\E$/m, 'full category');
  $db->query('UPDATE transactions SET account = ?, payee = NULL, memo = NULL, category = NULL', "Bank\nSecond line");
  ($count, $text) = Finance::Tiller2QIF::WriteQIF::_preview_text($dbfile);
  like($text, qr/Account: Bank\\nSecond line\n/, 'header newline is escaped');
  like($text, qr/^ {4}Memo: +$/m, 'null memo renders an empty labeled line');
  $db->query('UPDATE transactions SET exported = 1');
  ($count, $text) = Finance::Tiller2QIF::WriteQIF::_preview_text($dbfile);
  is($count, 0, 'exported transaction excluded');
  like($text, qr/No transactions pending export/, 'empty preview explained');
  $db->disconnect;
};

subtest preview_viewer => sub {
  my $dbfile = uniqfile( 'wq_pvviewer', 'sqlite3' );
  my $db     = freshdb($dbfile);
  $db->query(q{
    INSERT INTO transactions
    (id, account, date, amount, payee, memo, category, mapped_category, check_number, skipped, exported)
    VALUES
    ('V1', 'Liabilities:CreditCard', '2026-05-01', -42.00, 'Corner Market', 'CORNER MARKET MEMO', 'Groceries', 'Expenses:Groceries', '', 0, 0),
    ('V2', 'Liabilities:CreditCard', '2026-05-02',  -9.99, 'Streaming Co',  'STREAMING CO MEMO',  'Entertainment', 'Entertainment',  '', 0, 0)
    ;
  });

  # stub viewer: copies the file it is given, and its path, to a marker file
  my $marker = uniqfile( 'wq_pvviewer_marker', 'txt' );
  my $script = uniqfile( 'wq_pvviewer_stub',   'pl' );
  path($script)->spew_utf8( <<"STUB" );
use v5.36;
open my \$in,  '<:encoding(UTF-8)', \$ARGV[0] or die "stub viewer: \$!";
open my \$out, '>:encoding(UTF-8)', '$marker' or die "stub viewer: \$!";
print {\$out} "\$ARGV[0]\\n", <\$in>;
STUB

  my $out = '';
  my $count;
  {
    open( my $fh, '>', \$out ) or die $!;
    my $old = select $fh;
    $count = Finance::Tiller2QIF::WriteQIF::Preview( $dbfile, 0, "$^X $script" );
    select $old;
  }

  is( $count, 2, 'Preview with a viewer still returns the transaction count' );
  like( $out, qr/Preview written to /, 'Preview reports the temporary file path' );
  ok( -e $marker, 'viewer was launched and read the preview file' );

  my @seen = path($marker)->lines_utf8( { chomp => 1 } );
  my $tempfile = shift @seen;
  like( $tempfile, qr/tiller2qif-preview-\w+\.t2qpv$/,
    'preview file is named with the t2qpv suffix' );
  like( join( "\n", @seen ), qr/^ID: .* \| Date: .* \| Account: /m,
    'viewer received the preview blocks' );
  like( join( "\n", @seen ), qr/Corner Market/, 'viewer received the transactions' );

  ok( -e $tempfile, 'preview file is left in place for the viewer' );
  # uncoverable branch true
  is( sprintf( '%04o', ( stat $tempfile )[2] & 07777 ),
    '0400', 'preview file is read only' )
    unless $^O eq 'MSWin32';
  unlink $tempfile;

  # An unset viewer is an invalid state, not a reason to fall back to STDOUT.
  like( dies { Finance::Tiller2QIF::WriteQIF::Preview( $dbfile, 0, undef ) },
    qr/viewer is not set/, 'undefined viewer is fatal' );
  like( dies { Finance::Tiller2QIF::WriteQIF::Preview( $dbfile, 0, '  ' ) },
    qr/viewer is not set/, 'blank viewer is fatal' );
  # Preview doesn't care *why* the viewer command failed — not found,
  # non-zero exit, killed by a signal — just that it didn't succeed.
  my $unknown = '';
  my $unknown_err = do {
    open( my $fh, '>', \$unknown ) or die $!;
    my $old = select $fh;
    my $e = dies { Finance::Tiller2QIF::WriteQIF::Preview( $dbfile, 0, 'nosuchprog-xyz' ) };
    select $old;
    $e;
  };
  like( $unknown_err, qr/preview viewer 'nosuchprog-xyz' failed/,
    'a failing viewer command is fatal' );
  unlink $1 if $unknown =~ /Preview written to (\S+)/;

  $db->disconnect;
};

done_testing();
unlink glob "t/tmp/*" if test_pass();
