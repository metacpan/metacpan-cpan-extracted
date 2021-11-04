# t/10_foreign_currencies.t
# - Tests foreign currency transactions in lib/GnuCash::SQLite.pm
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw(. lib ../lib);

my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);
my $reader = GnuCash::SQLite->new(db => 't/sample2.db');

$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);

BEGIN {
    use_ok( 'GnuCash::SQLite' ) || print "Bail out!\n";
}

# For each function:
#   Look at the GIVEN defn and write tests
#   Look at the PROCEDURE defn and write tests
#   Look at the RETURNS defn and write tests

say "\n#---- GnuCash::SQLite::account_balance ----";
$msg = '/Current Assets -- ok';
$got = $reader->account_balance('Assets:Current Assets'),
$exp = 2980;
is($got, $exp, $msg);

$msg = '/Assets -- ok';
$got = $reader->account_balance('Assets'),
$exp = 17980;
is($got, $exp, $msg);

$msg = '/Foreign Assets -- ok';
$got = $reader->account_balance('Foreign Assets'),
$exp = 0;
is($got, $exp, $msg);


done_testing;


