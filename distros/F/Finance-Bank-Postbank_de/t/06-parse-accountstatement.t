#!/usr/bin/perl -w
use strict;
use Test::More tests => 12;
use FindBin;

use_ok("Finance::Bank::Postbank_de::Account");

my $account = Finance::Bank::Postbank_de::Account->new(
                number => '9999999999',
              );
my $account_2 = Finance::Bank::Postbank_de::Account->new(
                number => '666666',
              );
my $account_3 = Finance::Bank::Postbank_de::Account->new(
                number => undef,
              );

my @acctnames = ("$FindBin::Bin/accountstatement.txt","$FindBin::Bin/accountstatement-negative.txt");
my $canned_statement = do {local $/ = undef;
                           open my $fh, "< $acctnames[0]"
                             or die "Couldn't read $acctnames[0] : $!";
                           binmode $fh, ':encoding(UTF-8)';
                           <$fh>};

# Check that the parameter passing works :
{
  my ($get_called,$open_called);
  no warnings 'redefine';
  no warnings 'once';
  local *Finance::Bank::Postbank_de::Account::slurp_file = sub { die "slurp file called\n" };
  local *Finance::Bank::Postbank_de::Account::get_statement = sub { die "get called\n" };

  eval { $account->parse_statement( file => 'a/test/file') };
  is($@,"slurp file called\n","Passing file parameter");
};

# Check that the account number gets verified / set from the account data :
eval { $account_2->parse_statement( file => $acctnames[0] ) };
like( $@, "/^Wrong/mixed account kontonummer: Got '0565623128', expected '666666'/", "Existing account number gets verified");
$account_3->parse_statement( file => $acctnames[0] );
is($account_3->number, "0565623128", "Empty account number gets filled");

# Check error messages for invalid content :
eval { $account->parse_statement( content => '' ) };
like($@,"/^Don't know what to do with empty content/","Passing no parameter");
eval { $account->parse_statement( content => 'foo' ) };
like($@,"/^No valid account statement: 'foo'/","Passing bogus content");
eval { $account->parse_statement( content => "Umsatzauskunft;\n\nFOO, BAR BLZ;66666666 Kontonummer: 9999999999\n\nfoo" )};
like($@,"/^Field 'Name' not found in account statement/","Passing no Name in content");
eval { $account->parse_statement( content => "Umsatzauskunft;\nName;Test User\nfoo" )};
like($@,"/^Field 'BLZ' not found in account statement/","Passing no BLZ in content");
eval { $account->parse_statement( content => "Umsatzauskunft;\nName;Test User\nBLZ;666\nfoo" )};
like($@,"/^Field 'Kontonummer' not found in account statement/","Passing no Kontonummer in content");
eval { $account->parse_statement( content => "Umsatzauskunft;\nName;Test User\nBLZ;666\nKontonummer;9999999999\nfoo" )};
like($@,"/^Field 'IBAN' not found in account statement/","Passing no IBAN in content");

my @expected_statements = (
{ name => "Petra Pfiffig",
                       blz => "10010010",
                       number => "0565623128",
                       iban => "DE40100100100565623128",
                       #account_type => 'gebuchte Umsätze',
                       balance => ["????????","451.99"],
                       #balance_unavailable => ['????????','150.00'],
                       transactions_future => ['????????',-3110.99],
                       transactions => [
  {
            'tradedate' => '20180122',
            'receiver' => 'CCF KINDERHILFSWERK',
            'comment' => '',
            'running_total' => '451.99',
            'amount' => '-25.00',
            'type' => 'Dauerauftrag',
            'valuedate' => '20180122',
            'sender' => 'Petra Pfiffig'
          },
  {
            'tradedate' => '20180119',
            'receiver' => 'PETRA PFIFFIG',
            'comment' => 'VERMÖGENSAUFBAU',
            'running_total' => '476.99',
            'amount' => '-100.00',
            'type' => 'Dauerauftrag',
            'valuedate' => '20180119',
            'sender' => 'Petra Pfiffig'
          },
  { tradedate => '20180118', valuedate => '20180118', type => 'Gutschrift',                comment=>'Referenz ZV0205004716790200000002',             sender => 'PETRA PFIFFIG',receiver=>'Petra Pfiffig',amount=>'2.00', running_total => '576.99',},
  { tradedate => '20180118', valuedate => '20180118', type => 'Überweisung',               comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'Petra Pfiffig',amount=>'-1.00', running_total => '574.99',},
  {tradedate => '20180117', valuedate => '20180117', type => 'Lastbuchung Komfort-Sparen',comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'PETRA PFIFFIG',amount=>'-12524.01', running_total => '575.99',},
  {tradedate => '20180117', valuedate => '20180117', type => 'Lastbuchung Komfort-Sparen',comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'PETRA PFIFFIG',amount=>'-50.00', running_total => '13100.00',},
  { tradedate => '20180116', valuedate => '20180116', type => 'Überweisung',               comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'unicef Schweiz',amount=>'-200.00', running_total => '13150.00',},
  { tradedate => '20180116', valuedate => '20180116', type => 'Spende',                    comment=>'Petra Pfiffig',                                 sender => 'Petra Pfiffig',receiver=>'CCF Kinderhilfswerk',amount=>'-50.00', running_total => '13350.00',},
  { tradedate => '20180116', valuedate => '20180116', type => 'Überweisung',               comment=>'Spareinlage',                                   sender => 'Petra Pfiffig',receiver=>'Petra Pfiffig',amount=>'-2500.00', running_total => '13400.00',},
  { tradedate => '20180116', valuedate => '20180116', type => 'Überweisung',               comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'Petra Pfiffig',amount=>'-100.00', running_total => '15900.00',},
  { tradedate => '20180110', valuedate => '20180110', type => 'Gutschrift',                comment=>'Guthaben für Debitkarte',                       sender => 'Michael Mustermann',receiver=>'Petra Pfiffig',amount=>'1000.00', running_total => '16000.00',},
  { tradedate => '20180109', valuedate => '20180109', type => 'Gutschrift',                comment=>'Buchung -  (Haben Giro) Überweisungsgutschrift',sender => 'Michael Mustermann',receiver=>'Petra Pfiffig',amount=>'15000.00', running_total => '15000.00',},
                       ],
                     },
{ name => "Petra Pfiffig",
                       blz => "20010020",
                       number => "9999999999",
                       iban => "DE31200100209999999999",
		       account_type => 'Girokonto',
                       balance => ["????????","5314.05"],
                       balance_unavailable => ['????????',"150.00"],
                       transactions_future => ['????????',-11.33],
                       transactions => [
                         { tradedate => "20120311", valuedate => "20120311", type => "\xdcberweisung",
                           comment => "111111/DE05370501981000000000 Finanzkasse 3991234 Steuernummer 00703434",
                           receiver => "Finanzkasse K\xf6ln-S\xfcd", sender => 'Petra Pfiffig', amount => "-328.75",
			   running_total => '5314.05' },
                         { tradedate => "20120311", valuedate => "20120311", type => "\xdcberweisung",
                           comment => "111111/DE90200100203299999999 Übertrag auf SparCard 3299999999",
                           receiver => "Petra Pfiffig", sender => 'Petra Pfiffig', amount => "-228.61",
			   running_total => '5642.80' },
                         { tradedate => "20120311", valuedate => "20120311", type => "Gutschrift",
                           comment => "Bez\xfcge Pers.Nr. 70600170/01 Arbeitgeber u. Co",
                           receiver => "Petra Pfiffig", sender => 'Petra Pfiffig', amount => "2780.70", 
			   running_total => '5871.41' },
                         { tradedate => "20120311", valuedate => "20120311", type => "\xdcberweisung",
                           comment => "DA 1000001",
                           receiver => "Verlagshaus Scribere GmbH", sender => 'Petra Pfiffig', amount => "-31.50",
			   running_total => '3090.71' },
                         { tradedate => "20120311", valuedate => "20120311", type => "Scheckeinreichung",
                           comment => "Eingang vorbehalten Gutbuchung 12345",
                           receiver => "Petra Pfiffig", sender => 'Ein Fremder', amount => "1830.00",
			   running_total => '3122.21' },
                         { tradedate => "20120310", valuedate => "20120310", type => "Lastschrift",
                           comment => "Miete 600+250 EUR Obj22/328 Schulstr.7, 12345 Meinheim",
                           receiver => "Eigenheim KG", sender => 'Petra Pfiffig', amount => "-850.00", 
			   running_total => '1292.21' },
                         { tradedate => "20120310", valuedate => "20120310", type => "Inh. Scheck",
                           comment => "",
                           receiver => "2000123456789", sender => 'Petra Pfiffig', amount => "-75.00",
			   running_total => '2142.21' },
                         { tradedate => "20120308", valuedate => "20120308", type => "Lastschrift",
                           comment => "Teilnehmernr 1234567 Rundfunk 0103-1203",
                           receiver => "GEZ", sender => 'Petra Pfiffig', amount => -84.75,
			   running_total => '2217.21' },
                         { tradedate => "20120306", valuedate => "20120306", type => "Lastschrift",
                           comment => "Rechnung 03121999",
                           receiver => "Telefon AG K\xf6ln", sender => 'Petra Pfiffig', amount => "-125.80", 
			   running_total => '2301.96' },
                         { tradedate => "20120306", valuedate => "20120306", type => "Lastschrift",
                           comment => "Stromkosten Kd.Nr.1462347 Jahresabrechnung",
                           receiver => "Stadtwerke Musterstadt", sender => 'Petra Pfiffig', amount => -580.06,
			   running_total => '2427.76' },
                         { tradedate => "20120306", valuedate => "20120306", type => "Gutschrift",
                           comment => "Kindergeld Kindergeld-Nr. 1462347",
                           receiver => "Petra Pfiffig", sender => 'Arbeitsamt Bonn', amount => "154.00", 
			   running_total => '3007.82' },
                       ],
                     });

# Reinitialize the account
$account = Finance::Bank::Postbank_de::Account->new(
                number => '0565623128',
           );
my $statement = $account->parse_statement(content => $canned_statement);
is_deeply($statement,$expected_statements[0], "Parsing from memory works");

$account->parse_statement(file => $acctnames[0]);
is_deeply($statement,$expected_statements[0], "Parsing from file works");

#$account->parse_statement(file => $acctnames[1]);
#is_deeply($statement,$expected_statements[1], "Parsing from file works for negative accounts");
