#!/usr/bin/env perl

use strict;
use warnings;
use Finance::Bank::Schwab;

my $userid = $ARGV[0];
my $passwd = $ARGV[1];

# die "Usage: $0 <userid> <passwd>\n"
# 		unless $userid && $passwd;

print "Retrieving account balances from Schwab\n";
my @accounts = Finance::Bank::Schwab->check_balance(
    username      => $userid,
    password      => $passwd,
    get_positions => 1,
);

print "Account balances:\n";
for (@accounts) {
    printf "%18s : %8s / %8s : \$ %9.2f\n",
      $_->name, $_->sort_code, $_->account_no, $_->balance;

    for my $position ( @{ $_->positions } ) {
        printf "\t%-10s %-10s %10s Shares \@ \$%-15s\n",
          $position->type,
          $position->symbol,
          $position->quantity,
          $position->price;
    }

    print "\n";
}

