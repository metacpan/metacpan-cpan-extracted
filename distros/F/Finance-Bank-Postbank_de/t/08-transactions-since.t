#!/usr/bin/perl -w
use strict;
use FindBin;
use Data::Dumper;

use vars qw($statement);
use Test::More;

my %days = (
  20120304 => [{
            'tradedate' => '20120304',
            'receiver' => 'Stadtwerke Musterstadt',
            'comment' => 'Stromkosten Kd.Nr.1462347 Jahresabrechnung',
            'running_total' => '2427.76',
            'amount' => '-580.06',
            'type' => 'Lastschrift',
            'valuedate' => '20120304',
            'sender' => 'Petra Pfiffig'
          },
          {
            'tradedate' => '20120304',
            'receiver' => 'Petra Pfiffig',
            'comment' => 'Kindergeld Kindergeld-Nr. 1462347',
            'running_total' => '3007.82',
            'amount' => '154.00',
            'type' => 'Gutschrift',
            'valuedate' => '20120304',
            'sender' => 'Arbeitsamt Bonn'
          }
  ],
  20120306 => [
          {
            'tradedate' => '20120306',
            'receiver' => 'Telefon AG Köln',
            'comment' => 'Rechnung 03121999',
            'running_total' => '2301.96',
            'amount' => '-125.80',
            'type' => 'Lastschrift',
            'valuedate' => '20120306',
            'sender' => 'Petra Pfiffig'
          },
  ],
  20120308 => [
          {
            'tradedate' => '20120308',
            'receiver' => 'GEZ',
            'comment' => 'Teilnehmernr 1234567 Rundfunk 0103-1203',
            'running_total' => '2217.21',
            'amount' => '-84.75',
            'type' => 'Lastschrift',
            'valuedate' => '20120308',
            'sender' => 'Petra Pfiffig'
          },
  ],
  20120310 => [
          {
            'tradedate' => '20120310',
            'receiver' => 'Eigenheim KG',
            'comment' => 'Miete 600+250 EUR Obj22/328 Schulstr.7, 12345 Meinheim',
            'running_total' => '1292.21',
            'amount' => '-850.00',
            'type' => 'Lastschrift',
            'valuedate' => '20120310',
            'sender' => 'Petra Pfiffig'
          },
          {
            'tradedate' => '20120310',
            'receiver' => '2000123456789',
            'comment' => '',
            'running_total' => '2142.21',
            'amount' => '-75.00',
            'type' => 'Inh. Scheck',
            'valuedate' => '20120310',
            'sender' => 'Petra Pfiffig'
          },
  ],
  20120311 => [
          {
            'tradedate' => '20120311',
            'receiver' => 'Finanzkasse Köln-Süd',
            'comment' => '111111/DE05370501981000000000 Finanzkasse 3991234 Steuernummer 00703434',
            'running_total' => '5314.05',
            'amount' => '-328.75',
            'type' => 'Überweisung',
            'valuedate' => '20120311',
            'sender' => 'Petra Pfiffig'
          },
          {
            'tradedate' => '20120311',
            'receiver' => 'Petra Pfiffig',
            'comment' => "111111/DE90200100203299999999 \N{U+00DC}bertrag auf SparCard \N{U+00DC}berschuss was ich diesmal gespart hab",
            'running_total' => '5642.80',
            'amount' => '-228.61',
            'type' => 'Überweisung',
            'valuedate' => '20120311',
            'sender' => 'Petra Pfiffig'
          },
          {
            'tradedate' => '20120311',
            'receiver' => 'Petra Pfiffig',
            'comment' => "Bez\N{U+00FC}ge Pers.Nr. 70600170/01 Arbeitgeber u. Co",
            'running_total' => '5871.41',
            'amount' => '2780.70',
            'type' => 'Gutschrift',
            'valuedate' => '20120311',
            'sender' => 'Petra Pfiffig'
          },
          {
            'tradedate' => '20120311',
            'receiver' => 'Verlagshaus Scribere GmbH',
            'comment' => 'DA 1000001',
            'running_total' => '3090.71',
            'amount' => '-31.50',
            'type' => 'Überweisung',
            'valuedate' => '20120311',
            'sender' => 'Petra Pfiffig'
          },
          {
            'tradedate' => '20120311',
            'receiver' => 'Petra Pfiffig',
            'comment' => 'Eingang vorbehalten Gutbuchung 12345',
            'running_total' => '3122.21',
            'amount' => '1830.00',
            'type' => 'Scheckeinreichung',
            'valuedate' => '20120311',
            'sender' => 'Ein Fremder'
          },
  ],
);

my @test_dates = qw{ 1.1.1999 01/01/1999 1/01/1999 1999011 foo foo1 19990101foo };
Test::More->import( tests => 
  + 16
  + scalar @test_dates * 2
  + 17 * 4
);

use_ok("Finance::Bank::Postbank_de::Account");
my $account = Finance::Bank::Postbank_de::Account->new(
                number => '9999999999',
              );

my $acctname = "$FindBin::Bin/accountstatement.txt";
my $canned_statement = do {local $/ = undef;
                           open my $fh, "< $acctname"
                             or die "Couldn't read $acctname : $!";
                           binmode $fh, ':encoding(CP-1252)';
                           <$fh>};


my @all_transactions = map { @{ $days{$_} }} (reverse sort keys %days);

my @transactions;                     
my @expected_transactions;

$account->parse_statement(content => $canned_statement);

my @dates = $account->value_dates;
is_deeply(\@dates,[ "20120304", "20120306", "20120308", "20120310", "20120311" ],"Extracting account value dates" );
is_deeply(\@dates,[ sort keys %days ],"Test is consistent with canned data" );

@dates = $account->trade_dates;
is_deeply(\@dates,[ "20120304", "20120306", "20120308", "20120310", "20120311" ],"Extracting account trade dates");

@transactions = $account->transactions();
is_deeply(\@transactions,\@all_transactions, "All transactions");

my $last_count = 0;
my $last_date = '99999999';
for my $date (reverse (20120304 .. 20120320)) {
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

