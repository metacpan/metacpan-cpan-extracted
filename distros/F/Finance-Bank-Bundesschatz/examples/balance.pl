#!/usr/bin/perl

# $Id: balance.pl,v 1.1.1.1 2003/10/08 19:07:06 florian Exp $

use Finance::Bank::Bundesschatz;

use strict;
use warnings;

my $agent = Finance::Bank::Bundesschatz->new(
        account       => 'XXX',
        pass          => 'XXX',
        return_floats => 1,
);

my $balance  = $agent->check_balance;
my $details  = $agent->get_details;

printf("%11s: %25s\n", 'Kontonummer', $agent->account);
printf("%11s: %25s\n", $_->[0], $balance->{$_->[1]})
	for(( [ qw/ Kontostand balance / ],
	      [ qw/ Verzinsung interest / ],
));
print "\n";

foreach my $detail (@$details) {
	printf("%11s: %25s\n", $_->[0], $detail->{$_->[1]})
		for(( [ qw/ Produkt product / ],
		      [ qw/ Von from / ],
		      [ qw/ Bis to / ],
		      [ qw/ Verzinsung interest / ],
		      [ qw/ Betrag amount / ],
		      [ qw/ Zinsen interest_amount / ],
		      [ qw/ KESt tax / ],
		      [ qw/ Gesamt amount_after_tax / ],
	));
	print "\n";
}
