#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Finance::Card::Citibank;

my $userid = $ENV{F_C_CITIBANK_USERID};
my $passwd = $ENV{F_C_CITIBANK_PASSWD};

plan skip_all => "- Need password to fully test. To enable tests set F_C_CITIBANK_USERID F_C_CITIBANK_PASSWD environment variables."
		unless $userid && $passwd;
plan tests => 3;

# Can we load the library?

# Create client with ordered list of arguements
my @accounts = Finance::Card::Citibank->check_balance(
    			'username'	=> $userid,
    			'password'	=> $passwd,
                # 'log'       => 'tmp/out.html',        ## debugging: where to save the page
                 'content'   => 'tmp/out.html',        ## debugging: file to use rather than using their website
                # 'log2'      => 'tmp/out2.html',       ## debugging: where to save the page
                 'content2'  => 'tmp/out2.html',       ## debugging: file to use rather than using their website
		 );

ok @accounts, "check_balance returned a non-empty array";
isa_ok $accounts[0], 'Finance::Card::Citibank::Account', "check_balance returned a new Finance::Card::Citibank::Account object";
ok $accounts[0]->account_no, 'Returned a non-false value for the account number';

for (@accounts){
	printf "# %18s (%d): %8s / %8s : \$ %9.2f\n",
	    $_->name, $_->position, $_->sort_code, $_->account_no, $_->balance;
}

