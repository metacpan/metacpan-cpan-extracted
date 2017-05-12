#! /usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 17;
use Test::Exception;
use Test::Deep;

use Mock::WWW::Mechanize;
my $cs = Mock::WWW::Mechanize->new('t/pages');

use_ok('Finance::Bank::Cahoot');
use_ok('Finance::Bank::Cahoot::CredentialsProvider::Constant');

{
  my $creds = Finance::Bank::Cahoot::CredentialsProvider::Constant->new(
	credentials => [qw(account password place date username maiden)],
	options => { account => '12345678',
		     password => 'verysecret',
		     place => 'London',
		     date => '01/01/1906',
		     username => 'dummy',
		     maiden => 'Smith' });

  ok(my $c = Finance::Bank::Cahoot->new(credentials => $creds),
     'valid credentials - providing premade credentials object');

  $c->login();
  my $accounts = $c->accounts();
  is_deeply($accounts,
	    [ { name => 'current account', account => '12345678',
                account_index => 0,
		balance => '847.83', available => '1847.83' },
	      { name => 'flexible loan', account => '87654321',
                account_index => 1,
		balance => '0.00', available => '1000.00' },
	    ],
	    'Got expected account summary (list)' );

  dies_ok {
    $c->set_account();
  } 'set_account called with no account number';

  dies_ok {
    $c->set_account('bogus');
  } 'set_account called with invalid account details';

  ok($c->set_account($accounts->[0]->{account}),
     'set account for account 0');

  {
    my $statement = $c->snapshot();
    isa_ok($statement, 'Finance::Bank::Cahoot::Statement');
    my $row = $statement->rows->[0];
    foreach my $method (qw(time date details debit credit balance)) {
      can_ok($row, $method);
    }
    cmp_deeply($statement->rows,
	       array_each(isa('Finance::Bank::Cahoot::Statement::Entry')),
	       'got an array of statement rows');
    cmp_deeply($statement->rows,
	       array_each(methods(balance => undef)),
	       'no balance in a snapshot');
    cmp_deeply($statement->rows,
	       [ methods('debit' => '',
			 'credit' => '15.00',
			 'date' => '15 Dec 2007',
			 'time' => 1197676800,
			 'details' => 'JON DOE'),
		 methods('debit' => '',
			 'credit' => '14.45',
			 'date' => '15 Dec 2007',
			 'time' => 1197676800,
			 'details' => 'MARK SMITH'),
		 methods('debit' => '18.72',
			 'credit' => '',
			 'date' => '11 Dec 2007',
			 'time' => 1197331200,
			 'details' => 'ACME PHONE CORP BILLING'),
		 methods('debit' => '50.00',
			 'credit' => '',
			 'date' => '10 Dec 2007',
			 'time' => 1197244800,
			 'details' => 'MAIN STREET ATM'),
		 methods('debit' => '34.12',
			 'credit' => '',
			 'date' => '08 Dec 2007',
			 'time' => 1197072000,
			 'details' => 'LEC CO ELECTRICITY'),
		 methods('debit' => '37.11',
			 'credit' => '',
			 'date' => '08 Dec 2007',
			 'time' => 1197072000,
			 'details' => 'GASCO LIMITED'),
		 methods('debit' => '2.25',
			 'credit' => '',
			 'date' => '01 Dec 2007',
			 'time' => 1196467200,
			 'details' => 'TAX ON CR INTEREST'),
		 methods('debit' => '',
			 'credit' => '11.23',
			 'date' => '01 Dec 2007',
			 'time' => 1196467200,
			 'details' => 'INTEREST PAID'),
		 methods('debit' => '938.65',
			 'credit' => '',
			 'date' => '23 Nov 2007',
			 'time' => 1195776000,
			 'details' => 'GIVESALOT CHARITY CREDIT CARD'),
		 methods('debit' => '1827.26',
			 'credit' => '',
			 'date' => '22 Nov 2007',
			 'time' => 1195689600,
			 'details' => 'BIGGINS IT CONSULTANTS')
	       ],
	       'got expected statement');
  }
}
