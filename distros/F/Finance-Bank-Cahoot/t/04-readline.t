#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 22;
use Test::Exception;
use Test::MockObject;
use Carp;

my $term = new Test::MockObject;
$term->fake_module('Term::ReadLine');
$term->fake_new('Term::ReadLine');
$term->mock('readline', sub { return $_[1].'bogus data' });

use_ok('Finance::Bank::Cahoot::CredentialsProvider::ReadLine');

my %invalid_details = ('Must provide a list of credentials'
		       => { },

		       'credentials is not an array ref'
		       => { credentials => { } },

		       'Empty list of options'
		       => { credentials => [qw(account password username)],
			    options => { } },

		       'options must be a hash ref'
		       => { credentials => [qw(account password username)],
			    options => '' },

		       'Invalid credential bogus supplied with callback'
		       => { credentials => [qw(account password username)],
			    options => { bogus => '' } },

		       'Prompt for unknown credential bogus'
		       => { credentials => [qw(account password username)],
			    options => { bogus_prompt => '' } }
		      );

while (my ($message, $credentials) = each %invalid_details) {
  dies_ok {
    my $provider =
      Finance::Bank::Cahoot::CredentialsProvider::ReadLine->new(%{$credentials});
  } 'invalid credentials: expected to fail';
  like($@, qr/$message at/, 'exception: '.$message);
  foreach (qw(account password username)) {
    no strict 'refs';
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::ReadLine::$_"};
  }
}

{
  my $provider =
    Finance::Bank::Cahoot::CredentialsProvider::ReadLine->new(
		credentials => [qw(account username password maiden date)],
		options => { date => '10/01/70',
			     account_prompt  => '::account::',
			     password_prompt => '::password::',
			     maiden_prompt   => '::maiden::' });
  is($provider->date, '10/01/70', 'constant value');
  is($provider->account, '::account::bogus data', 'account method');
  is($provider->username, 'Enter username: bogus data', 'username method');
  is($provider->password, '::password::bogus data', 'password method');
  is($provider->maiden, '::maiden::bogus data', 'maiden method');

  is($provider->account(12), 'b', 'account method');
  is($provider->username(14), 'e', 'username method');
  is($provider->password(15), 'g', 'password method');
  is($provider->maiden(-1), 't', 'maiden method');
}
