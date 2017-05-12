#!perl

use strict;
use warnings;
use Test::More tests => 5;
use Finance::Bank::DE::NetBank;
use Data::Dumper;

my %config = (
        CUSTOMER_ID => "demo",        # Demo Login
        PASSWORD    => "",            # Demo does not require a password
        ACCOUNT     => "1234567",     # Demo Account Number (Kontonummer)
);

my $account = Finance::Bank::DE::NetBank->new(%config);
ok($account->login(), 'login');
ok(my $statement = $account->statement, 'retrieve statement');

SKIP:
{
    eval 'use DateTime';
    skip('because DateTime is required for statement() structure validation', 1) if $@;
}

SKIP:
{
    eval 'use Test::Differences';
    skip('because Test::Differences is required for statement() structure validation', 1) if $@;
}

my $dt = DateTime->now();
$dt->set_time_zone("Europe/Berlin");
my $today = $dt;

my $month_back = $dt->clone()->subtract( DateTime::Duration->new( months => 1) );

    
eq_or_diff($statement->{ACCOUNT}, { 'KUNDENNUMMER' => 'demo', 
                                    'KONTOINHABER' => 'Muster, Martha' 
                                    }, "account holder data");

eq_or_diff($statement->{STATEMENT}, {
                                        'SALDO' => '552,73',
                                        'START_DATE' => $month_back->dmy('.'),
                                        'ACCOUNT_ID' => '1234567',
                                        'WAEHRUNG' => 'EUR',
                                        'END_DATE' => $today->dmy('.'),
                                    }, "saldo, date");

eq_or_diff($statement->{TRANSACTION}, [
                             {

                               'NOT_YET_FINISHED' => '*',
                               'BUCHUNGSTAG' => $today->dmy('.'),
                               'UMSATZ' => '-245.21',
                               'VERWENDUNGSZWECK' => 'VERSANDHAUS FIX RECHNUNG 4523, KUNDE 543239  ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->dmy('.'),
                             },
                             {
                               'BUCHUNGSTAG' => $today->dmy('.'),
                               'UMSATZ' => '-5.00',
                               'VERWENDUNGSZWECK' => 'Leihgebühr   ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->dmy('.'),
                             },
                             {
                               'BUCHUNGSTAG' => $today->clone->subtract( days => 1 )->dmy('.'),
                               'UMSATZ' => '-15.50',
                               'VERWENDUNGSZWECK' => 'Buchhaus LESEZEICHENdotCOM Kunde 321357, Rchng: 6493  ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->clone->subtract( days => 1 )->dmy('.'),
                             },
                             {
                               'BUCHUNGSTAG' => $today->clone->subtract( days => 1 )->dmy('.'),
                               'UMSATZ' => '-10.00',
                               'VERWENDUNGSZWECK' => 'Geschenke für Hans Danke für das Organisieren ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->clone->subtract( days => 1 )->dmy('.'),
                             },
                             {
                               'BUCHUNGSTAG' => $today->clone->subtract( days => 2 )->dmy('.'),
                               'UMSATZ' => '56.78',
                               'VERWENDUNGSZWECK' => 'Umbuchung   ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->clone->subtract( days => 2 )->dmy('.'), 
                             },
                             {
                               'BUCHUNGSTAG' => $today->clone->subtract( days => 2 )->dmy('.'),
                               'UMSATZ' => '-820.00',
                               'VERWENDUNGSZWECK' => 'FRIEDER VERMIETER MIETE INCL. NEBENKOSTEN ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->clone->subtract( days => 2 )->dmy('.'),
                             },
                             {
                               'BUCHUNGSTAG' => $today->clone->subtract( days => 3 )->dmy('.'),
                               'UMSATZ' => '20.00',
                               'VERWENDUNGSZWECK' => 'Spende   ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->clone->subtract( days => 3 )->dmy('.'), 
                             },
                             {
                               'BUCHUNGSTAG' => $today->clone->subtract( days => 4 )->dmy('.'),
                               'UMSATZ' => '-100.00',
                               'VERWENDUNGSZWECK' => 'Bausparkasse Monatsbeitrag  ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->clone->subtract( days => 4 )->dmy('.'),
                             },
                             {
                               'BUCHUNGSTAG' => $today->clone->subtract( days => 7)->dmy('.'),
                               'UMSATZ' => '-12.34',
                               'VERWENDUNGSZWECK' => 'Versicherungsbeitrag   ',
                               'WAEHRUNG' => 'EUR',
                               'WERTSTELLUNGSTAG' => $today->clone->subtract( days => 7)->dmy('.'),
                             }], "list of transactions");


