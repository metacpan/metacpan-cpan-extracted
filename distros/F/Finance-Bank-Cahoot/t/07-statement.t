#!/usr/bin/perl -w

use strict;
use lib 't/lib';
use Test::More tests => 38;
use Test::Exception;
use Test::Deep;

use Mock::WWW::Mechanize;
my $cs = Mock::WWW::Mechanize->new('t/pages');
$cs->mock('get', sub { print STDERR "In mocked get()\n"; return WWW::Mechanize::get(@_)});

use_ok('Finance::Bank::Cahoot');
use_ok('Finance::Bank::Cahoot::Statement');
use_ok('Finance::Bank::Cahoot::Statement::Entry');
use_ok('Finance::Bank::Cahoot::CredentialsProvider::Constant');

{
  dies_ok {
    my $row = Finance::Bank::Cahoot::Statement::Entry->new;
  } 'no data row to constructor: expected to fail';
  like($@, qr/No row data passed to Finance::Bank::Cahoot::Statement::Entry constructor at /,
       'exception: no data row to constructor');

  dies_ok {
    my $row = Finance::Bank::Cahoot::Statement::Entry->new('bogus')
  } 'invalid data row to constructor: expected to fail';
  like($@, qr/row data is not an array ref at /,
       'exception: invalid data row to constructor');

    dies_ok {
    my $row = Finance::Bank::Cahoot::Statement->new;
  } 'no data row to constructor: expected to fail';
  like($@, qr/No statement table passed to Finance::Bank::Cahoot::Statement constructor at /,
       'exception: no statement table to constructor');

  dies_ok {
    my $row = Finance::Bank::Cahoot::Statement->new('bogus')
  } 'invalid data row to constructor: expected to fail';
  like($@, qr/statement is not an array ref at /,
       'exception: invalid statement to constructor');

}

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
		account_index => 0, balance => '847.83', available => '1847.83' },
	    { name => 'flexible loan', account => '87654321',
	      account_index => 1, balance => '0.00', available => '1000.00' },
	    ],
	    'got expected account summary (list)' );

  ok($c->set_account($accounts->[1]->{account}),
     'set account for account 1');
  $cs->clear;
  $c->set_account($accounts->[1]->{account});
  is($cs->called('get'), 0, 'set account for same acount ignored');

  $cs->clear;
  $c->set_account($accounts->[0]->{account});
  is($cs->called('get'), 1, 'set new account');

  {
    my $statement = $c->statement();
    isa_ok($statement, 'Finance::Bank::Cahoot::Statement');
    my $row = $statement->rows->[0];
    foreach my $method (qw(time date details debit credit balance)) {
      can_ok($row, $method);
    }
    cmp_deeply($statement->rows,
	       array_each(isa('Finance::Bank::Cahoot::Statement::Entry')),
	       'got an array of statement rows');
    cmp_deeply($statement->rows,
	       [ methods(balance => '672.19',
			 debit => '13.02',
			 credit => '',
			 date => '15 Oct 2007',
			 time => 1192406400,
			 details => 'ACME PHONE CORP BILLING'),
                 methods(balance => '656.64',
			 debit => '15.55',
			 credit => '',
			 date => '16 Oct 2007',
			 time => 1192492800,
			 details => 'LEC CO ELECTRICITY'),
                 methods(balance => '556.56',
			 debit => '100.08',
			 credit => '',
			 date => '22 Oct 2007',
			 time => 1193011200,
			 details => 'MAMMA ITALINA EUR 140.00'),
                 methods(balance => '555.16',
			 debit => '1.40',
			 credit => '',
			 date => '22 Oct 2007',
			 time => 1193011200,
			 details => 'SERVICE CHARGE DEBIT'),
                 methods(balance => '2382.42',
			 debit => '',
			 credit => '1827.26',
			 date => '31 Oct 2007',
			 time => 1193788800,
			 details => 'BIGGINS IT CONSULTANTS')
	       ],
	       'got correct statement');
  }
  foreach my $method (qw(account password place date username maiden)) {
    no strict 'refs';
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::Constant::$method"};
  }
}

{
  my $c = Finance::Bank::Cahoot->new(credentials => 'Constant',
				     credentials_options => { account => '12345678',
							      password => 'verysecret',
							      place => 'London',
							      date => '01/01/1906',
							      username => 'dummy',
							      maiden => 'Smith' });
  dies_ok {
    $c->set_statement()
  } 'select undef statement: expected to fail';
  like($@, qr/No statement selected for set_statement/, 'exception: no statement selected');
  dies_ok {
    $c->set_statement('16/03/07 - 15/04/07')
  } 'select statement with no account: expected to fail';
  like($@, qr/No account currently selected/, 'exception: no account selected');
  dies_ok {
    $c->statements()
  } 'get statement with no account: expected to fail';
  like($@, qr/No account currently selected/, 'exception: no account selected');
  foreach my $method (qw(account password place date username maiden)) {
    no strict 'refs';
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::Constant::$method"};
  }
}

{
  my $creds = Finance::Bank::Cahoot::CredentialsProvider::Constant->new(
	credentials => [qw(account password place date username maiden)],
	options => { account => '12345678',
		     password => 'verysecret',
		     place => 'London',
		     date => '01/01/1906',
		     username => 'dummy',
		     maiden => 'Smith' });

  my $c = Finance::Bank::Cahoot->new(credentials => $creds);
  my $accounts = $c->accounts();
  $c->set_account($accounts->[0]->{account});
  my $statements = $c->statements;
  is_deeply($statements,
            [ { 'description' => '16/01/08 - 15/02/08',
                'end' => 1203033600,
                'start' => 1200441600 },
              { 'description' => '16/12/07 - 15/01/08',
                'end' => 1200355200,
                'start' => 1197763200 },
              { 'description' => '16/11/07 - 15/12/07',
                'end' => 1197676800,
                'start' => 1195171200 },
              { 'description' => '16/10/07 - 15/11/07',
                'end' => 1195084800,
                'start' => 1192492800 },
              { 'description' => '16/09/07 - 15/10/07',
                'end' => 1192406400,
                'start' => 1189900800 },
              { 'description' => '16/08/07 - 15/09/07',
                'end' => 1189814400,
                'start' => 1187222400 },
              { 'description' => '16/07/07 - 15/08/07',
                'end' => 1187136000,
                'start' => 1184544000 },
              { 'description' => '16/06/07 - 15/07/07',
                'end' => 1184457600,
                'start' => 1181952000 },
              { 'description' => '16/05/07 - 15/06/07',
                'end' => 1181865600,
                'start' => 1179273600 },
              { 'description' => '16/04/07 - 15/05/07',
                'end' => 1179187200,
                'start' => 1176681600 },
              { 'description' => '16/03/07 - 15/04/07',
                'end' => 1176595200,
                'start' => 1174003200 },
              { 'description' => '16/02/07 - 15/03/07',
                'end' => 1173916800,
                'start' => 1171584000 }
	    ],
	    'got list of all statements');

  dies_ok {
    $c->set_statement('junk'),
  } 'invalid statement selected, expected to fail';
  like($@, qr/Invalid statement: junk/, 'exception: invalid statement');

  ok($c->set_statement($statements->[3]->{description}),
     'selected 4th statement in list');

  my $statement = $c->statement();
  isa_ok($statement, 'Finance::Bank::Cahoot::Statement');
  cmp_deeply($statement->rows,
             [ methods(balance => '672.19',
		       debit => '13.02',
		       credit => '',
		       date => '15 Oct 2007',
		       time => 1192406400,
		       details => 'ACME PHONE CORP BILLING'),
	       methods(balance => '656.64',
		       debit => '15.55',
		       credit => '',
		       date => '16 Oct 2007',
		       time => 1192492800,
		       details => 'LEC CO ELECTRICITY'),
	       methods(balance => '556.56',
		       debit => '100.08',
		       credit => '',
		       date => '22 Oct 2007',
		       time => 1193011200,
		       details => 'MAMMA ITALINA EUR 140.00'),
	       methods(balance => '555.16',
		       debit => '1.40',
		       credit => '',
		       date => '22 Oct 2007',
		       time => 1193011200,
		       details => 'SERVICE CHARGE DEBIT'),
	       methods(balance => '2382.42',
		       debit => '',
		       credit => '1827.26',
		       date => '31 Oct 2007',
		       time => 1193788800,
		       details => 'BIGGINS IT CONSULTANTS')
	     ],
	     'extracted another statement');
}
