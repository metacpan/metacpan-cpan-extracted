#!/usr/bin/perl

use 5.010;
use Finance::Bitcoin;

my $creds   = shift @ARGV or die "Please provide username:password as a parameter.\n";
my $uri     = 'http://'.$creds.'@127.0.0.1:8332/';
my $wallet  = Finance::Bitcoin::Wallet->new( $uri );

foreach my $address ($wallet->addresses)
{
	say $address->address, ": ", $address->received;
}

say "--";
say "Balance: ", $wallet->balance;
