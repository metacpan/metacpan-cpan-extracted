# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GnuCash-SQLite.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use DateTime;
use File::Copy qw/copy/;
use Try::Tiny;
use Time::Local;
use Test::Number::Delta;
use lib 'lib';

use Test::More tests => 24;
BEGIN { use_ok('GnuCash::SQLite') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my ($reader, $guid, $got, $exp, $msg);
$reader = GnuCash::SQLite->new(db => 't/sample.db');

try {
    my $book = GnuCash::SQLite->new();
} catch {
    tt('new() croaks if db parameter is undefined.',
        got => $_ =~ /No GnuCash file defined. at /,
        exp => 1 );
};

try {
    my $book = GnuCash::SQLite->new(db => 't/a-missing-file');
} catch {
    tt('new() croaks if db file is missing.',
        got => $_ =~ /File: t\/a-missing-file does not exist. at /,
        exp => 1 );
};

$guid = $reader->create_guid();
tt('create_guid() generates 32-characters',
    got => length($guid),
    exp => 32 );

tt('commodity_guid() found correct GUID.',
    got => $reader->commodity_guid('Assets:Cash'),
    exp => 'be2788c5c017bb63c859430612e64093');

my ($ss,$mm,$hh,$DD,$MM,$YY) = gmtime(timelocal(0,0,0,1,0,114));
my $utc_dttm = sprintf('%04d%02d%02d%02d%02d%02d', $YY+1900,$MM+1,$DD,$hh,$mm,$ss);
tt('UTC_post_date() generated correct timestamp.',
    got => $reader->UTC_post_date('20140101'),
    exp => $utc_dttm);

my $dt = DateTime->now();
tt('UTC_enter_date() generated correct timestamp.',
    got => $reader->UTC_enter_date(),
    exp => $dt->ymd('').$dt->hms(''));

tt('account_guid() found correct GUID.',
    got => $reader->account_guid('Assets:Cash'),
    exp => '6a86047e3b12a6c4748fbf8fde76c0c0');

tt('account_guid_sql() returns correct SQL.',
    got => $reader->account_guid_sql('Assets:Cash'),
    exp =>'SELECT guid FROM accounts WHERE name = "Cash" AND parent_guid = (SELECT guid FROM accounts WHERE name = "Assets" AND parent_guid = (SELECT guid FROM accounts WHERE name = "Root Account"))');

$guid = $reader->account_guid('Assets');
tt('child_guid() returns correct list of child guids.',
    got => join('--',sort @{$reader->child_guid($guid)}),
    exp => join('--',('6a86047e3b12a6c4748fbf8fde76c0c0',
                      '6b870a6ef2c3fbbff0ec6df32108ac34')));

tt('child_guid() returns empty list for leaf accounts.',
    got => join('--',sort @{$reader->child_guid('Assets:Cash')}),
    exp => '');

$guid = $reader->account_guid('Assets:Cash');
tt('_node_bal() returns correct balance.',
    got => $reader->_node_bal($guid)+0,
    exp => 10000);

$guid = $reader->account_guid('Assets:Cash');
tt('_guid_bal() returns correct balance for leaf accounts.',
    got => $reader->_guid_bal($guid),
    exp => 10000);

$guid = $reader->account_guid('Assets');
tt('_guid_bal() returns correct balance for parent accounts.',
    got => $reader->_guid_bal($guid),
    exp => 15000);

tt('account_balance() returns correct balance for leaf accounts.',
    got => $reader->account_balance('Assets:Cash'),
    exp => 10000);

tt('account_balance() returns correct parent accounts balances.',
    got => $reader->account_balance('Assets'),
    exp => 15000 );

tt('account_balance() returns undef for invalid account names.',
    got => $reader->account_balance('No:Such:Account'),
    exp => undef );


#------------------------------------------------------------------
# Test the writer
#------------------------------------------------------------------

copy "t/sample.db", "t/scratch.db";
my $book = GnuCash::SQLite->new(db => 't/scratch.db');

my $cash_bal  = 10000;
my $bank_bal  =  5000;
my $asset_bal = 15000;

my $txn = {
    date         => '20140102',
    description  => 'Deposit monthly savings',
    from_account => 'Assets:Cash',
    to_account   => 'Assets:aBank',
    amount       => 2540.15,
    number       => ''
};

# Create a string that can be used in a regex match
$exp = hashref2str({
        date         => '20140102',
        description  => 'Deposit monthly savings',
        from_account => 'Assets:Cash',
        to_account   => 'Assets:aBank',
        amount       => 2540.15,
        number       => '',
        tx_guid         => '.' x 32,    # some 32-char string
        tx_ccy_guid     => 'be2788c5c017bb63c859430612e64093',
        tx_post_date    => $book->UTC_post_date('20140102'),
        tx_enter_date   => '\d' x 14,    # some 14-char numeric string
        tx_from_guid    => '6a86047e3b12a6c4748fbf8fde76c0c0',
        tx_to_guid      => '6b870a6ef2c3fbbff0ec6df32108ac34',
        tx_from_numer   => -254015,
        tx_to_numer     =>  254015,
        splt_guid_1     => '.' x 32,    # some 32-char string
        splt_guid_2     => '.' x 32     # some 32-char string 
    });
tt('_augment() adds correct set of data.',
    got => (hashref2str($book->_augment($txn)) =~ /$exp/) || '0',
    exp => 1);

$book->add_transaction($txn);

delta_ok($book->account_balance('Assets:Cash'),
         $cash_bal - $txn->{amount},
         'add_transaction() deducted from source account correctly.');

delta_ok($book->account_balance('Assets:aBank'),
         $bank_bal + $txn->{amount},
         'add_transaction() added to target account correctly.');

tt('add_transaction() kept parent account (Assets) unchanged.',
    got => $book->account_balance('Assets'),
    exp => $asset_bal );

tt('add_transaction() does not clutter its input',
    got => join('|', sort keys %{$txn}),
    exp => 'amount|date|description|from_account|number|to_account');

tt('is_locked() returns 0 if unlocked.',
    got => $book->is_locked,
    exp => 0);

$book->_runsql('INSERT INTO gnclock VALUES ("i3","12345")');
tt('is_locked() returns 1 if another db is access by another app.',
    got => $book->is_locked,
    exp => 1);
$book->_runsql('DELETE FROM gnclock');

#------------------------------------------------------------------
# A test utility
#------------------------------------------------------------------
# A function to allow rewriting the test to show the message first
# but when there are errors, the line number reported is not useful
sub tt {
    my $msg = shift;
    my %hash = @_;

    is($hash{got},$hash{exp},$msg);
}

# Given a hashref
# Return a string representation that's the same everytime
sub hashref2str {
    my $href = shift;
    my $result = '';

    foreach my $k (sort keys %{$href}) {
        $result .= "  $k - $href->{$k} \n"; 
    }
    return $result;
} 
