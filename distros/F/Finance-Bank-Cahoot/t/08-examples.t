#! /usr/bin/perl

use strict;
use warnings;

use Config;
use lib 't/lib';
use Test::More tests => 3;

use Mock::WWW::Mechanize;
my $cs = Mock::WWW::Mechanize->new('t/pages');

my $term = new Test::MockObject;
$term->fake_module('Term::ReadLine');
$term->fake_new('Term::ReadLine');
$term->mock('readline', sub { return $_[1].'bogus data' });

package PrintToString;
use Symbol;
our $result;
sub new {
  $result = '';
  my $sym = gensym;
  tie *$sym, $_[0];
  bless $sym, $_[0];
}
sub TIEHANDLE { bless {}, $_[0] }
sub PRINT { shift; my $str = join '', @_; $result .= $str; }

package main;

my $old_fh = select PrintToString->new;
do 'examples/snapshot';
select $old_fh;
ok($PrintToString::result
   eq '15 Dec 2007,JON DOE,15.00,0'."\n".
      '15 Dec 2007,MARK SMITH,14.45,0'."\n".
      '11 Dec 2007,ACME PHONE CORP BILLING,0,18.72'."\n".
      '10 Dec 2007,MAIN STREET ATM,0,50.00'."\n".
      '08 Dec 2007,LEC CO ELECTRICITY,0,34.12'."\n".
      '08 Dec 2007,GASCO LIMITED,0,37.11'."\n".
      '01 Dec 2007,TAX ON CR INTEREST,0,2.25'."\n".
      '01 Dec 2007,INTEREST PAID,11.23,0'."\n".
      '23 Nov 2007,GIVESALOT CHARITY CREDIT CARD,0,938.65'."\n".
      '22 Nov 2007,BIGGINS IT CONSULTANTS,0,1827.26'."\n",
   'snapshot example');

foreach (qw(place date maiden account username password)) {
  no strict 'refs';
  undef *{"Finance::Bank::Cahoot::CredentialsProvider::ReadLine::$_"};
}

$old_fh = select PrintToString->new;
do 'examples/statement';
select $old_fh;
ok($PrintToString::result
   eq '15 Oct 2007,ACME PHONE CORP BILLING,0,13.02,672.19'."\n".
      '16 Oct 2007,LEC CO ELECTRICITY,0,15.55,656.64'."\n".
      '22 Oct 2007,MAMMA ITALINA EUR 140.00,0,100.08,556.56'."\n".
      '22 Oct 2007,SERVICE CHARGE DEBIT,0,1.40,555.16'."\n".
      '31 Oct 2007,BIGGINS IT CONSULTANTS,1827.26,0,2382.42'."\n",
   'statement example');

foreach (qw(place date maiden account username password)) {
  no strict 'refs';
  undef *{"Finance::Bank::Cahoot::CredentialsProvider::ReadLine::$_"};
}

$old_fh = select PrintToString->new;
do 'examples/debits';
select $old_fh;
ok($PrintToString::result
   eq 'ACME WATER CO,07028928282'."\n".
      'HAPPYSHIRE COUNCIL,282726272'."\n".
      'TV LICENCE,06904826736'."\n".
      'LOOPY CAR INSURE,9762041'."\n".
      'LECCO GAS CO,337710'."\n".
      'BONGO.COM SUBSCRIPTION,7227REFVD'."\n".
      'LINUX FOOBARS MAGAZINE,SCAMMING101'."\n".
      'ROBBERS HOUSE INSURANCE,29272635647262'."\n".
      'NORWICH UNION,28272718HDUYST'."\n".
      'ACME DIRECT DEBITS,2928272762'."\n",
   'debits example');
