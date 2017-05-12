#!/usr/bin/env perl
use strict;
use warnings;
use Finance::Card::Discover;

my $card = Finance::Card::Discover->new(
    username => $ENV{DISCOVERCARD_USERNAME},
    password => $ENV{DISCOVERCARD_PASSWORD},
    debug    => $ENV{FINANCE_DISCOVER_CARD_DEBUG},
);

for my $account ($card->accounts) {
    my $number     = $account->number;
    my $expiration = $account->expiration;
    print "account: $number $expiration\n";

    my $balance = $account->balance;
    print "balance: $balance\n";
    my $profile = $account->profile;

    printf "soan transaction: %s %s %s\n", $_->date, $_->amount, $_->merchant
        for $account->soan_transactions;

    print "\n";

    printf "transaction: %s %s %s %s\n", $_->date, $_->type, $_->amount,
        $_->name
        for $account->transactions;
}

my $res = $card->response;
die $res->dump unless $res->is_success;
