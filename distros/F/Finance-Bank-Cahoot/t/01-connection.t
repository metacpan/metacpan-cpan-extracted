#!/usr/bin/perl -w

use strict;

use lib 't/lib';

use Carp;
use Test::More tests => 31;
use Test::Exception;

use Mock::WWW::Mechanize;
my $cs = Mock::WWW::Mechanize->new('t/pages');

use_ok( 'Finance::Bank::Cahoot' );

dies_ok {
  my $c = Finance::Bank::Cahoot->new()
} 'no credentials supplied: expected to fail';

my %invalid_details = ('Must provide a credentials handler'
		       => {},

		       'Must provide credential options unless suppying a premade credentials object (1)'
		       => { credentials => 'Constant' },

		       'Must provide credential options unless suppying a premade credentials object (2)'
		       => { credentials => 'UnknownCP' },

		       'Not a valid credentials class - not found (1)'
		       => { credentials => 'UnknownCP', credentials_options => {} },

		       'Not a valid credentials object (1)'
		       => { credentials => bless {}, 'YetAnotherUnknownCP' },

		       'Not a valid credentials object (2)'
		       => { credentials => {} },

		       'Not a valid credentials object (3)'
		       => { credentials => {}, credentials_options => {} },

		       'Invalid class name'
		       => { credentials => ':bogus:', credentials_options =>{} },

		       'Must provide a credentials handler'
		       => { credentials_options => {} }
		      );
while (my ($message, $options) = each %invalid_details) {
  dies_ok {
    my $c = Finance::Bank::Cahoot->new(%{$options});
  } 'invalid credential parameters: expected to fail';
  my $re = $message;
  $re =~ s/\s*\(\d+\)$//;
  like($@, qr/$re at /, 'exception: '.$message);
}

dies_ok {
  my $provider = {};
  $INC{'Finance/Bank/Cahoot/CredentialsProvider/Bogus.pm'} = 1;
  bless $provider, 'Finance::Bank::Cahoot::CredentialsProvider::Bogus';
  package Finance::Bank::Cahoot::CredentialsProvider::Bogus;
  sub new {};
  package main;
  my $c = Finance::Bank::Cahoot->new(credentials => 'Bogus', credentials_options => {});
} 'incomplete pre-made credentials class: expected to fail';
like($@, qr/Not a valid credentials class - incomplete at /, 'exception: invalid credentials');

{
  my $cahoot;

  ok($cahoot = Finance::Bank::Cahoot->new(credentials => 'Constant',
					  credentials_options => { account => '12345678',
								   password => 'verysecret',
								   place => 'London',
								   date => '01/01/1906',
								   username => 'dummy',
								   maiden => 'Smith'
								 },
					 ),
     'valid credentials - getting ::Cahoot to create credentials object'
    );

  isa_ok($cahoot, 'Finance::Bank::Cahoot' );

  foreach my $method (qw(login set_account statement statements
			 set_statement snapshot accounts)) {
    can_ok($cahoot, $method);
  }
  foreach my $method (qw(password place date username maiden)) {
    no strict 'refs';
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::Constant::$method"};
  }
}

{
  my $creds = Finance::Bank::Cahoot::CredentialsProvider::Constant->new(credentials => [qw(password place date username maiden)],
									options => { account => '12345678',
										     password => 'verysecret',
										     place => 'London',
										     date => '01/01/1906',
										     username => 'dummy',
										     maiden => 'Smith' });

  ok(my $cahoot = Finance::Bank::Cahoot->new(credentials => $creds),
     'valid credentials - providing premade credentials object');

  $cahoot->login();
  ok($cahoot->{_connected}, 'Logged in successfully');
}
