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
use Finance::Tiller2QIF::WriteQIF;
use Finance::Tiller2QIF::Util;
use Mojo::SQLite;
use feature qw/signatures postderef/;

require './t/TestHelper.pm';

# ---------------------------------------------------------------------------
# Scenario: a household with four accounts. Tiller exports everything into
# one CSV. Several major retailers appear across multiple accounts and with
# varying payee strings depending on purchase channel (online vs in-store vs
# store card). Card payments from checking look superficially like purchases
# at the same retailers and must be separated by rule ordering.
# ---------------------------------------------------------------------------

my $dbfile  = uniqfile( 'complex', 'sqlite3' );
my $csvfile = uniqfile( 'complex', 'csv' );
my $mapfile = uniqfile( 'complex', 'map' );
my $qiffile = uniqfile( 'complex', 'qif' );
my $db      = freshdb($dbfile);

freshcsv( $csvfile,
  # --- Checking: Amazon purchases ---
  '04/01/2026,101,Checking,-52.47,AMZN MKTP US*1A2B3C,Amazon Marketplace,Shopping',
  '04/02/2026,102,Checking,-14.99,AMAZON PRIME*1234567,Amazon Prime Membership,Subscription',
  '04/03/2026,103,Checking,-8.50,AMAZON GO #42,Amazon Go Store,Shopping',

  # --- Checking: Target store purchase (debit) ---
  '04/04/2026,104,Checking,-67.23,TARGET 00123456,Target Store,Shopping',

  # --- Checking: Costco ---
  '04/05/2026,105,Checking,-143.72,COSTCO WHSE #0123,Costco Wholesale,Groceries',
  '04/06/2026,106,Checking,-48.30,COSTCO GAS #0123,Costco Gas Station,Gas & Fuel',

  # --- Checking: Walmart ---
  '04/07/2026,107,Checking,-34.18,WAL-MART #5678,Walmart Store,Shopping',
  '04/08/2026,108,Checking,-22.50,WALMART.COM 8009666546,Walmart Online,Shopping',

  # --- Checking: card payments (payees resemble retailers — rule order matters) ---
  '04/09/2026,109,Checking,-250.00,TARGET CREDIT PYMT,Target Credit Card Payment,Credit Card Payment',
  '04/10/2026,110,Checking,-189.45,COSTCO VISA PYMT,Costco Visa Payment,Credit Card Payment',

  # --- Target RedCard: in-store, online, and an unrelated charge ---
  '04/01/2026,201,Target RedCard,-45.67,TARGET 00123456,Target Store,Shopping',
  '04/02/2026,202,Target RedCard,-23.99,TARGET.COM *,Target Online,Shopping',
  '04/03/2026,203,Target RedCard,-5.75,STARBUCKS #12345,Starbucks Coffee,Coffee',

  # --- Costco Visa: warehouse, third-party gas, and a non-Costco grocery ---
  '04/01/2026,301,Costco Visa,-156.23,COSTCO WHSE #0123,Costco Wholesale,Groceries',
  '04/02/2026,302,Costco Visa,-41.20,SHELL OIL 12345678,Shell Gas Station,Gas & Fuel',
  '04/03/2026,303,Costco Visa,-78.50,WHOLEFDS #10234,Whole Foods Market,Groceries',

  # --- Walmart Mastercard: store, supercenter, and online ---
  '04/01/2026,401,Walmart Mastercard,-29.47,WAL-MART #5678,Walmart Store,Shopping',
  '04/02/2026,402,Walmart Mastercard,-15.99,WM SUPERCENTER #9876,Walmart Supercenter,Shopping',
  '04/03/2026,403,Walmart Mastercard,-67.80,WALMART.COM,Walmart Online,Online Shopping',

  # --- Payment credits on card accounts (other side of the checking debit) ---
  # These should be suppressed — they are the mirror image of txns 109 and 110.
  '04/09/2026,209,Target RedCard,250.00,Payment Received,Target Card Payment,Credit Card Payment',
  '04/10/2026,309,Costco Visa,189.45,Payment Received,Costco Visa Payment,Credit Card Payment',
);

freshmap( $mapfile,
  '# Subscriptions must come before the general Amazon rule',
  'payee | AMAZON PRIME | Expenses:Subscriptions',
  '',
  '# Amazon — marketplace prefix varies (AMZN vs AMAZON)',
  'payee | AMZN | Expenses:Shopping:Amazon',
  'payee | AMAZON GO | Expenses:Shopping:Amazon',
  '',
  '# Card payments from checking — must precede general TARGET / COSTCO rules',
  'payee | TARGET.*PYMT   | Liabilities:CreditCards:Target',
  'payee | TARGET.*CREDIT | Liabilities:CreditCards:Target',
  'payee | COSTCO.*VISA   | Liabilities:CreditCards:Costco',
  '',
  '# Target purchases — in-store numbers and .com both match TARGET',
  'payee | TARGET | Expenses:Shopping:Target',
  '',
  '# Costco — gas before general warehouse rule',
  'payee | COSTCO GAS | Expenses:Gas',
  'payee | COSTCO     | Expenses:Groceries:Costco',
  '',
  '# Walmart — three different payee formats',
  'payee | WAL-MART       | Expenses:Shopping:Walmart',
  'payee | WALMART        | Expenses:Shopping:Walmart',
  'payee | WM SUPERCENTER | Expenses:Shopping:Walmart',
  '',
  '# Payment credits on card accounts — scoped to the specific card account so',
  '# checking-side debits with the same category are never accidentally suppressed',
  '[Target RedCard] category | Credit Card Payment | skip',
  '[Costco Visa]    category | Credit Card Payment | skip',
  '',
  '# Anything not matched keeps its Tiller category via COALESCE',
  'default | source',
);

Finance::Tiller2QIF::ReadCSV::Ingest( $csvfile, $dbfile );
Finance::Tiller2QIF::Map::Map({db_path => $dbfile, mapfile => $mapfile});

my %tx = map { $_->{id} => $_ }
  $db->select( 'transactions', '*' )->hashes->@*;

subtest amazon => sub {
  is( $tx{101}{mapped_category}, 'Expenses:Shopping:Amazon',
    'AMZN MKTP prefix maps to Amazon shopping' );
  is( $tx{102}{mapped_category}, 'Expenses:Subscriptions',
    'AMAZON PRIME maps to Subscriptions before general Amazon rule fires' );
  is( $tx{103}{mapped_category}, 'Expenses:Shopping:Amazon',
    'AMAZON GO maps to Amazon shopping' );
};

subtest target => sub {
  is( $tx{104}{mapped_category}, 'Expenses:Shopping:Target',
    'TARGET store number on checking maps to Target shopping' );
  is( $tx{201}{mapped_category}, 'Expenses:Shopping:Target',
    'TARGET store number on RedCard maps to Target shopping' );
  is( $tx{202}{mapped_category}, 'Expenses:Shopping:Target',
    'TARGET.COM on RedCard maps to Target shopping' );
  is( $tx{109}{mapped_category}, 'Liabilities:CreditCards:Target',
    'TARGET CREDIT PYMT distinguished from purchase by rule order' );
};

subtest costco => sub {
  is( $tx{105}{mapped_category}, 'Expenses:Groceries:Costco',
    'COSTCO WHSE on checking maps to Costco groceries' );
  is( $tx{106}{mapped_category}, 'Expenses:Gas',
    'COSTCO GAS distinguished from warehouse by rule order' );
  is( $tx{301}{mapped_category}, 'Expenses:Groceries:Costco',
    'COSTCO WHSE on Visa maps to Costco groceries' );
  is( $tx{110}{mapped_category}, 'Liabilities:CreditCards:Costco',
    'COSTCO VISA PYMT distinguished from purchase by rule order' );
};

subtest walmart => sub {
  is( $tx{107}{mapped_category}, 'Expenses:Shopping:Walmart',
    'WAL-MART format on checking' );
  is( $tx{108}{mapped_category}, 'Expenses:Shopping:Walmart',
    'WALMART.COM format on checking' );
  is( $tx{401}{mapped_category}, 'Expenses:Shopping:Walmart',
    'WAL-MART format on Mastercard' );
  is( $tx{402}{mapped_category}, 'Expenses:Shopping:Walmart',
    'WM SUPERCENTER format on Mastercard' );
  is( $tx{403}{mapped_category}, 'Expenses:Shopping:Walmart',
    'WALMART.COM format on Mastercard' );
};

subtest unmapped_fallthrough => sub {
  is( $tx{203}{mapped_category}, undef,
    'Starbucks on RedCard: no rule matches, mapped_category stays NULL' );
  is( $tx{302}{mapped_category}, undef,
    'Shell gas on Costco Visa: no rule matches, falls through to source' );
  is( $tx{303}{mapped_category}, undef,
    'Whole Foods on Costco Visa: no rule matches, falls through to source' );
};

subtest skip_payment_credits => sub {
  is( $tx{209}{skipped}, 1,
    'Target RedCard payment credit is skipped' );
  is( $tx{309}{skipped}, 1,
    'Costco Visa payment credit is skipped' );
  is( $tx{109}{skipped}, 0,
    'Checking-side Target payment is NOT skipped (caught by payee rule first)' );
  is( $tx{110}{skipped}, 0,
    'Checking-side Costco payment is NOT skipped (caught by payee rule first)' );
};

subtest qif_uses_mapped_categories => sub {
  Finance::Tiller2QIF::WriteQIF::Emit( $dbfile, $qiffile );
  my $qif = path($qiffile)->slurp_utf8;

  like( $qif, qr/LExpenses:Subscriptions/,
    'Amazon Prime emits mapped Subscriptions category' );
  like( $qif, qr/LLiabilities:CreditCards:Target/,
    'Target card payment emits liability category' );
  like( $qif, qr/LExpenses:Gas/,
    'Costco gas emits Gas category' );
  like( $qif, qr/LExpenses:Groceries:Costco/,
    'Costco warehouse emits Groceries:Costco category' );

  # Unmapped transactions fall back to their original Tiller category
  like( $qif, qr/LCoffee/,
    'Starbucks (unmapped) emits original Tiller category via COALESCE' );
  like( $qif, qr/LGas & Fuel/,
    'Shell (unmapped) emits original Tiller Gas & Fuel category via COALESCE' );

  # Skipped payment credits must not appear in the QIF
  unlike( $qif, qr/PPayment Received/,
    'Payment credit transactions absent from QIF output' );

  unlink $qiffile;
};

$db->disconnect;
unlink $dbfile, $csvfile, $mapfile;


done_testing();
unlink glob "t/tmp/*" if test_pass();