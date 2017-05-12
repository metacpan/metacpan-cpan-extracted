#!/usr/bin/perl

# $Id: balance-gpg.pl,v 1.1.1.1 2003/10/08 19:07:06 florian Exp $

use Finance::Bank::Bundesschatz;
use GnuPG::Interface;
use IO::File;
use IO::Handle;
use YAML qw/Load/;

use strict;
use warnings;

my $agent    = Finance::Bank::Bundesschatz->new(&get_secrets);

my $balance  = $agent->check_balance;
my $details  = $agent->get_details;
my $interest = $agent->check_interest;

printf("%11s: %25s\n", 'Kontonummer', $agent->user);
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


sub get_secrets {
        my $secrets = '/Users/florian/bin/bundesschatz.gpg';
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
