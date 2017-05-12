#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 32;
use Test::Exception;
use Test::MockObject;
use Carp;

use_ok('Finance::Bank::Cahoot::CredentialsProvider::CryptFile');

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

		       'No key provided'
		       => { credentials => [qw(account password username)],
			    options => { bogus => '' } },

		       'Can\'t open .* for writing: .*'
		       => { credentials => [qw(account password username)],
			    options => { key => 'test', keyfile => '/W^%$#/@%W$S', fallback => 'Constant',
					 fallback_options => { account => '12345678',
							       username => 'acmeuser',
							       password => 'secret' } } },
		       'Can\'t open .* for reading: .*'
		       => { credentials => [qw(account password username)],
			    options => { key => 'test', keyfile => 'temp_keyfile' } },

		       'Invalid fallback provider bogus (1)'
		       => { credentials => [qw(account password username)],
			    options => { key => 'test', fallback => 'bogus' } },

		       'Invalid fallback provider bogus (2)'
		       => { credentials => [qw(account password username)],
			    options => { key => 'test', keyfile => 'temp_keyfile', fallback => 'bogus' } },

		       'No fallback provider given and account is not in keyfile'
		       => { credentials => [qw(account password username)],
			    options => { key => 'test', keyfile => 'temp_keyfile'} },

		       'Fallback provider Constant failed to initialise (1)'
		       => { credentials => [qw(account password username)],
			    options => { key => 'test', keyfile => 'temp_keyfile', fallback => 'Constant',
					 fallback_options => { bogus => 1 } } }
		      );

while (my ($message, $credentials) = each %invalid_details) {
  if ($message =~ /open.*reading/) {
    new IO::File $credentials->{options}->{keyfile}, 'w';
    chmod 000, $credentials->{options}->{keyfile};
  } else {
    unlink 'temp_keyfile';
  }
  dies_ok {
    local $^W = 0;  ## supress UNIVERSAL::can warning from Crypt::CBC
    my $provider =
      Finance::Bank::Cahoot::CredentialsProvider::CryptFile->new(%{$credentials});
  } $message.': expected to fail';
  my $re = $message;
  $re =~ s/\s*\(\d+\)$//;
  like($@, qr/$re at/, 'exception: '.$message);
  foreach (qw(account password username)) {
    no strict 'refs';
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::CryptFile::$_"};
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::Constant::$_"};
  }
}

{
  unlink 'temp_keyfile';
  my $provider =
    Finance::Bank::Cahoot::CredentialsProvider::CryptFile->new(
	credentials => [qw(account username password)],
	options => { key => 'verysecret',
		     keyfile => 'temp_keyfile',
		     fallback => 'Constant',
		     fallback_options => { account => '12345678',
					   username => 'acmeuser',
					   password => 'secret' } });
  is($provider->account, '12345678', 'account method via constant fallback');
  is($provider->username, 'acmeuser', 'username method via constant fallback');
  is($provider->password, 'secret', 'password method via constant fallback');

  foreach my $method (qw(account username password)) {
    no strict 'refs';
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::CryptFile::$method"};
    undef *{"Finance::Bank::Cahoot::CredentialsProvider::Constant::$method"};
  }
  undef $provider;

  my $provider2 =
    Finance::Bank::Cahoot::CredentialsProvider::CryptFile->new(
	credentials => [qw(account username password)],
	options => { key => 'verysecret', keyfile => 'temp_keyfile' });
  is($provider2->account, '12345678', 'account method via autosaved cryptfile');
  is($provider2->username, 'acmeuser', 'username method via autosaved cryptfile');
  is($provider2->password(0), 's', 'password character 0 method via autosaved cryptfile');
  is($provider2->password(1), 'e', 'password character 1 method via autosaved cryptfile');
  is($provider2->password(2), 'c', 'password character 2 method via autosaved cryptfile');
  is($provider2->password(3), 'r', 'password character 3 method via autosaved cryptfile');
}

unlink 'temp_keyfile';
