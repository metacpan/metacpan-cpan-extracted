#!/usr/bin/perl

# $Id: balance.pl,v 1.4 2003/10/06 20:36:44 florian Exp $

use Finance::Bank::easybank;

use strict;
use warnings;

my $agent = Finance::Bank::easybank->new(
        user          => 'xxx',
        pass          => 'xxx',
        return_floats => 1,

        accounts      => [ qw/
                2000xxxxxxx
                / ],

        entries       => [ qw/
                2000xxxxxxx
                / ],
);

my @accounts = $agent->check_balance;
my $entries  = $agent->get_entries;

foreach my $account (@accounts) {
        printf("%11s: %25s\n", $_->[0], $account->{$_->[1]})
                for(( [ qw/ Kontonummer account / ],
                      [ qw/ BLZ bc / ],
                      [ qw/ Bezeichnung name / ],
                      [ qw/ Datum date / ],
                      [ qw/ Waehrung currency / ]
                ));
        printf("%11s: %25.2f\n", $_->[0], $account->{$_->[1]})
                for(( [ qw/ Saldo balance / ],
                      [ qw/ Dispo final / ]
                ));

        print "\nBuchungzeilen:\n\n";

	if(exists($entries->{$account->{account}})) {
		foreach my $row (@{$entries->{$account->{account}}}) {
			$row->{text} =~ s/(.{39}).*/$1.../;

			printf("%2d %10s %42s %6s %3s %9.2f\n", 
				@{$row}{qw/nr date text value currency/},
				$row->{amount}
			);      
		}
	}

        print "\n";
}
