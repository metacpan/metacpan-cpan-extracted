#!/usr/bin/perl -w
use strict;
use FindBin;
use Data::Dumper;

use vars qw($statement);
use Test::More;

my %days = (
  20180122 => [{
            'tradedate' => '20180122',
            'receiver' => 'CCF KINDERHILFSWERK',
            'comment' => '',
            'running_total' => '451.99',
            'amount' => '-25.00',
            'type' => 'Dauerauftrag',
            'valuedate' => '20180122',
            'sender' => 'Petra Pfiffig'
          }
  ],
  20180119 => [{
            'tradedate' => '20180119',
            'receiver' => 'PETRA PFIFFIG',
            'comment' => 'VERMÖGENSAUFBAU',
            'running_total' => '476.99',
            'amount' => '-100.00',
            'type' => 'Dauerauftrag',
            'valuedate' => '20180119',
            'sender' => 'Petra Pfiffig'
          }
  ],
  20180118 => [
  { tradedate => '20180118', valuedate => '20180118', type => 'Gutschrift',                comment=>'Referenz ZV0205004716790200000002',             sender => 'PETRA PFIFFIG',receiver=>'Petra Pfiffig',amount=>'2.00', running_total => '576.99',},
  { tradedate => '20180118', valuedate => '20180118', type => 'Überweisung',               comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'Petra Pfiffig',amount=>'-1.00', running_total => '574.99',},
  ],
  20180117 => [
  {tradedate => '20180117', valuedate => '20180117', type => 'Lastbuchung Komfort-Sparen',comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'PETRA PFIFFIG',amount=>'-12524.01', running_total => '575.99',},
  {tradedate => '20180117', valuedate => '20180117', type => 'Lastbuchung Komfort-Sparen',comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'PETRA PFIFFIG',amount=>'-50.00', running_total => '13100.00',},
  ],
  20180116 => [
  { tradedate => '20180116', valuedate => '20180116', type => 'Überweisung',               comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'unicef Schweiz',amount=>'-200.00', running_total => '13150.00',},
  { tradedate => '20180116', valuedate => '20180116', type => 'Spende',                    comment=>'Petra Pfiffig',                                 sender => 'Petra Pfiffig',receiver=>'CCF Kinderhilfswerk',amount=>'-50.00', running_total => '13350.00',},
  { tradedate => '20180116', valuedate => '20180116', type => 'Überweisung',               comment=>'Spareinlage',                                   sender => 'Petra Pfiffig',receiver=>'Petra Pfiffig',amount=>'-2500.00', running_total => '13400.00',},
  { tradedate => '20180116', valuedate => '20180116', type => 'Überweisung',               comment=>'',                                              sender => 'Petra Pfiffig',receiver=>'Petra Pfiffig',amount=>'-100.00', running_total => '15900.00',},
  ],
  20180110 => [
  { tradedate => '20180110', valuedate => '20180110', type => 'Gutschrift',                comment=>'Guthaben für Debitkarte',                       sender => 'Michael Mustermann',receiver=>'Petra Pfiffig',amount=>'1000.00', running_total => '16000.00',},
  ],
  20180109 => [
  { tradedate => '20180109', valuedate => '20180109', type => 'Gutschrift',                comment=>'Buchung -  (Haben Giro) Überweisungsgutschrift',sender => 'Michael Mustermann',receiver=>'Petra Pfiffig',amount=>'15000.00', running_total => '15000.00',},
  ],
);

my @test_dates = qw{ 1.1.1999 01/01/1999 1/01/1999 1999011 foo foo1 19990101foo };
Test::More->import( tests => 
  + 16
  + scalar @test_dates * 2
  + 28 * 4
);

use_ok("Finance::Bank::Postbank_de::Account");
my $account = Finance::Bank::Postbank_de::Account->new(
                number => '0565623128',
              );

my $acctname = "$FindBin::Bin/accountstatement.txt";
my $canned_statement = do {local $/ = undef;
                           open my $fh, "< $acctname"
                             or die "Couldn't read $acctname : $!";
                           binmode $fh, ':encoding(UTF-8)';
                           <$fh>};


my @all_transactions = map { @{ $days{$_} }} (reverse sort keys %days);

my @transactions;                     
my @expected_transactions;

$account->parse_statement(content => $canned_statement);

my @dates = $account->value_dates;
is_deeply(\@dates,[ '20180109', '20180110', '20180116', '20180117', '20180118', '20180119', '20180122' ],"Extracting account value dates" )
    or diag Dumper \@dates;
is_deeply(\@dates,[ sort keys %days ],"Test is consistent with canned data" )
    or diag Dumper \@dates;

@dates = $account->trade_dates;
is_deeply(\@dates,[ '20180109','20180110','20180116','20180117','20180118','20180119','20180122' ],"Extracting account trade dates")
    or diag Dumper \@dates;

@transactions = $account->transactions();
is_deeply(\@transactions,\@all_transactions, "All transactions");

my $last_count = 0;
my $last_date = '99999999';
for my $date (reverse (20180104 .. 20180131)) {
  # Test a single date:
  @transactions = $account->transactions(on => $date);
  @expected_transactions = map { @{ $days{$_} }} (grep { $_ eq $date} reverse sort keys %days);
  is_deeply(\@transactions,\@expected_transactions, "Selecting transactions on $date returns only transactions with that date");

  # Now test the cumulating account listing:
  @transactions = $account->transactions(since => $date);
  @expected_transactions = map { @{ $days{$_} }} (grep { $_ gt $date} reverse sort keys %days);

  ok($last_date>$date,"We select a previous day");
  ok($last_count<=scalar @transactions,"and the number of transactions doesn't get smaller");
  is_deeply(\@transactions,\@expected_transactions, "Selecting transactions after $date");

  $last_date = $date;
  $last_count = @transactions;
};

@transactions = $account->transactions(since => "");
is_deeply(\@transactions,\@all_transactions, "Capping transactions at empty string returns all transactions");
@transactions = $account->transactions(since => undef);
is_deeply(\@transactions,\@all_transactions, "Capping transactions at undef returns all transactions");
@transactions = $account->transactions(upto => "");
is_deeply(\@transactions,\@all_transactions, "Capping transactions at empty string returns all transactions");
@transactions = $account->transactions(upto => undef);
is_deeply(\@transactions,\@all_transactions, "Capping transactions at undef returns all transactions");

@transactions = $account->transactions(on => "20041111");
is_deeply(\@transactions,[], "Getting transactions for 20041111");

@transactions = $account->transactions(on => "today");
is_deeply(\@transactions,[], "Getting transactions for 'today'");

eval { @transactions =$account->transactions(since => "20030111", on => "20030111", upto => "20030111");};
like($@,qr/^Options 'since'\+'upto' and 'on' are incompatible/, "Options 'since'+'upto' and 'on' are incompatible");

eval { @transactions = $account->transactions(on => "20030111", upto => "20030111"); };
like($@,qr/^Options 'upto' and 'on' are incompatible/, "Options 'upto' and 'on' are incompatible");

eval { @transactions = $account->transactions(since => "20030111", on => "20030111" );};
like($@,qr/^Options 'since' and 'on' are incompatible/, "Options 'since' and 'on' are incompatible");

eval { @transactions = $account->transactions(since => "20030111", upto => "20030111" );};
like($@,qr/^The 'since' argument must be less than the 'upto' argument/, "Since < upto");

eval { @transactions = $account->transactions(since => "20030112", upto => "20030111" );};
like($@,qr/^The 'since' argument must be less than the 'upto' argument/, "Since < upto");


# Now check our error handling
my $date;
for $date (@test_dates) {
  eval { $account->transactions( since => $date )};
  like $@,"/^Argument \\{since => '$date'\\} dosen't look like a date to me\\./","Bogus start date ($date)";
  eval { $account->transactions( upto => $date )};
  like $@,"/^Argument \\{upto => '$date'\\} dosen't look like a date to me\\./","Bogus end date ($date)";
};

