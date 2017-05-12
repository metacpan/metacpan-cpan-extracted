#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 23;
use Test::Exception;

use_ok('Finance::Bank::Cahoot::CredentialsProvider');

dies_ok {
  my $provider = Finance::Bank::Cahoot::CredentialsProviderProvider->new;
} 'invalid base constructor: expected to fail';

{
  package Finance::Bank::Cahoot::CredentialsProvider::Broken;
  use base qw(Finance::Bank::Cahoot::CredentialsProvider);
  sub _init {};
  package main;

  my $provider = Finance::Bank::Cahoot::CredentialsProvider::Broken->new(credentials => []);
  dies_ok {
    $provider->get;
  } 'get method not overridden: expected to fail';
  like($@, qr/Calling abstract base class get method for Finance::Bank::Cahoot::CredentialsProvider::Broken is forbidden at/,
     'exception: Calling abstract base class get method');
}

use_ok('Finance::Bank::Cahoot::CredentialsProvider::Constant');

dies_ok {
  my $provider = new Finance::Bank::Cahoot::CredentialsProvider;
} 'construct abstract base: expected to fail';

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
		      );

while (my ($message, $credentials) = each %invalid_details) {
  dies_ok {
    my $provider =
      Finance::Bank::Cahoot::CredentialsProvider::Constant->new(%{$credentials});
  } 'invalid credentials: expected to fail';
  like($@, qr/$message at/, 'exception: '.$message);
  foreach (qw(account password username)) {
    no strict 'refs';
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::Constant::$_"};
  }
}

{
  my $provider =
    Finance::Bank::Cahoot::CredentialsProvider::Constant->new(credentials => [qw(account username password maiden)],
							      options => { account => '12345678',
									   username => 'acmeuser',
									   password => 'secret',
									   maiden => 'Smith' });

  isa_ok($provider, 'Finance::Bank::Cahoot::CredentialsProvider::Constant');

  is($provider->account, '12345678', 'account name');
  is($provider->username, 'acmeuser', 'user name');
  is($provider->password(1), 's', 'password character 1');
  is($provider->password(2), 'e', 'password character 2');
  is($provider->password(3), 'c', 'password character 3');
  is($provider->maiden, 'Smith', 'maiden name');
}
