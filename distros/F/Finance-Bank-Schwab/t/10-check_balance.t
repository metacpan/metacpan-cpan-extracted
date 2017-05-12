use strict;
use warnings;

use Test::More;
use Finance::Bank::Schwab;

my $userid = $ENV{F_C_SCHWAB_USERID};
my $passwd = $ENV{F_C_SCHWAB_PASSWD};

plan skip_all => "- Need password to fully test. To enable tests set "
  . "F_C_SCHWAB_USERID F_C_SCHWAB_PASSWD environment variables."
  unless $userid && $passwd;
plan tests => 4;

# Test set 2 -- create client with ordered list of arguements
my @accounts = Finance::Bank::Schwab->check_balance(
    username => $userid,
    password => $passwd,
    ## log => 'log/tmp.log',
    content       => 'log/tmp.log',
    get_positions => 1,
);

ok @accounts, "check_balance returned a non-empty array";
isa_ok $accounts[0], 'Finance::Bank::Schwab::Account', "check_balance()";
ok $accounts[0]->account_no, 'Returned a true value for the account number';
ok $accounts[0]->positions,  'Returned a non-empty list of positions';

for (@accounts) {
    printf "# %18s : %8s / %8s : \$ %9.2f\n",
      $_->name, $_->sort_code, $_->account_no, $_->balance;

    for my $position ( @{ $_->positions } ) {
        printf "# \t%-10s %-10s %10s Shares \@ \$%-15s\n",
          $position->type,
          $position->symbol,
          $position->quantity,
          $position->price;
    }
    print "# \n";
}

