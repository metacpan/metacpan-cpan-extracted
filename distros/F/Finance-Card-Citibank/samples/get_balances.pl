#!/usr/bin/perl -w

use strict;
use warnings;
use Finance::Card::Citibank;

my $userid = $ARGV[0];
my $passwd = $ARGV[1];

die "Usage: $0 <userid> <passwd>\n"
		unless $userid && $passwd;

print "Retrieving account balances from Citibank\n";
my @accounts = Finance::Card::Citibank->check_balance(
    			'username'	=> $userid,
    			'password'	=> $passwd,
		 );

print "Account balances:\n";
for (@accounts){
	printf "%18s : %8s / %8s : \$ %9.2f\n",
	    $_->name, $_->sort_code, $_->account_no, $_->balance;
}

