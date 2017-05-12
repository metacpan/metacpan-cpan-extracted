#!/usr/bin/perl -w

use strict;
use Test::More tests => 20;
use Test::Exception;
use Carp;

use_ok('Finance::Bank::Cahoot::CredentialsProvider::Callback');

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
			    options => { bogus => sub {} } },

		       'Callback for account is not a code ref'
		       => { credentials => [qw(account password username)],
			    options => { account => '', 'password' => sub {}, username => sub {} } }
		      );

while (my ($message, $credentials) = each %invalid_details) {
  dies_ok {
    my $provider =
      Finance::Bank::Cahoot::CredentialsProvider::Callback->new(%{$credentials});
  } 'invalid credentials: expected to fail';
  like($@, qr/$message at/, 'exception: '.$message);
  foreach (qw(account password username)) {
    no strict 'refs';
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::Callback::$_"};
  }
}

{
  my $provider =
    Finance::Bank::Cahoot::CredentialsProvider::Callback->new(
		credentials => [qw(account username password maiden)],
		options => { account => sub { return '12345678' },
			     username => sub { return 'username' },
			     password => sub { return defined $_[0]
						 ? substr('secret', $_[0]-1, 1) : 'secret' },
			     maiden => sub { return 'Smith' } });

  is($provider->account, '12345678', 'account name');
  is($provider->username, 'username', 'user name');
  is($provider->password(1), 's', 'password character 1');
  is($provider->password(2), 'e', 'password character 2');
  is($provider->password(3), 'c', 'password character 3');
  is($provider->password(4), 'r', 'password character 4');
  is($provider->maiden, 'Smith', 'mother\'s maiden name');
  undef $provider;
}
