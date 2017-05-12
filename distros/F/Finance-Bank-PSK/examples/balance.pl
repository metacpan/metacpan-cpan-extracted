#!/usr/bin/perl

# $Id: balance.pl,v 1.4 2003/08/14 21:42:29 florian Exp $

use Finance::Bank::PSK;

use strict;
use warnings;

my $agent = Finance::Bank::PSK->new(
	account       => 'xxx',
	user          => 'xxx',
	pass          => 'xxx',
	return_floats => 1,
);

my $result  = $agent->check_balance;
my $entries = $agent->get_entries;

foreach my $account (@{$result->{accounts}}) {
        printf("%11s: %25s\n", $_->[0], $account->{$_->[1]})
                for(( [ qw/ Kontonummer account / ],
                      [ qw/ Bezeichnung name / ],
                      [ qw/ Waehrung currency / ]
                ));
        printf("%11s: %25.2f\n", $_->[0], $account->{$_->[1]})
		for(( [ qw/ Saldo balance / ],
                      [ qw/ Dispo final / ]
                ));
        print "\n";
}

foreach my $fund (@{$result->{funds}}) {
        printf("%11s: %25s\n", $_->[0], $fund->{$_->[1]})
                for(( [ qw/ Depotnummer fund / ],
                      [ qw/ Bezeichnung name / ],
                      [ qw/ Waehrung currency / ]
                ));
        printf("%11s: %25.2f\n", 'Saldo', $fund->{balance});
        print "\n";
}

if(scalar @$entries) {
        printf("Buchungszeilen:\n\n");
        foreach my $row (@$entries) {
                $row->{text} =~ s/(.{50}).*/$1.../;

                printf("%7s %5s %53s %9.2f\n",
                        @{$row}{qw/nr value text amount/}
                );
        }
}
