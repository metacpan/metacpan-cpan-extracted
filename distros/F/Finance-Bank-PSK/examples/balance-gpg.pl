#!/usr/bin/perl

# $Id: balance-gpg.pl,v 1.1 2003/08/14 21:42:01 florian Exp $

use Finance::Bank::PSK;
use GnuPG::Interface;
use IO::File;
use IO::Handle;
use YAML qw/Load/;

use strict;
use warnings;

my $agent    = Finance::Bank::PSK->new(&get_secrets);
my $result   = $agent->check_balance;
my $entries  = $agent->get_entries;

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

sub get_secrets {
        my $secrets = '/Users/florian/bin/psk.gpg';
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
