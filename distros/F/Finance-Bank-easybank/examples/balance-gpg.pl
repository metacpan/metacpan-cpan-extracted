#!/usr/bin/perl

# $Id: balance-gpg.pl,v 1.3 2003/10/06 20:36:43 florian Exp $

use Finance::Bank::easybank;
use GnuPG::Interface;
use IO::File;
use IO::Handle;
use YAML qw/Load/;

use strict;
use warnings;

my $agent    = Finance::Bank::easybank->new(&get_secrets);
my @accounts = $agent->check_balance;
my $entries  = $agent->get_entries;

foreach my $account (@accounts) {
	print '-' x 77, "\n\n";

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


sub get_secrets {
        my $secrets = '/Users/florian/bin/easybank.gpg';
        my $cipher  = IO::File->new;
        my $input   = IO::Handle->new;
        my $output  = IO::Handle->new;
        my $gnupg   = GnuPG::Interface->new;
        my $pid;
        my $plain;

        $cipher->open($secrets, 'r')
                or die sprintf("Couldn't open %s\n", $secrets);

        $pid = $gnupg->decrypt(handles => GnuPG::Handles->new(
                stdin  => $input,
                stdout => $output,
        ));

        print $input $_ while <$cipher>;

        close $cipher;
        close $input;

        $plain = Load(join('', <$output>));
	close $output;

        waitpid($pid, 0);

        $plain;
}
