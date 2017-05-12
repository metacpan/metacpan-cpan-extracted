# Copyright (c) 2007 Jon Connell.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Finance::Bank::Cahoot::CredentialsProvider::CryptFile;
use base qw(Finance::Bank::Cahoot::CredentialsProvider);

use strict;
use warnings 'all';
use vars qw($VERSION);

$VERSION = '1.07';

use Carp qw(croak);
use Crypt::CBC;
use English '-no_match_vars';
use File::Slurp qw(slurp);
use IO::File;

sub _init
{
  my ($self, $options) = @_;

  croak 'No key provided' if not defined $options->{key};
  my $cipher = Crypt::CBC->new(-key    => $options->{key},
			       -cipher => 'DES_PP');
  my $keyfile = $options->{keyfile};
  $keyfile = $ENV{HOME}.'/.cahoot' if not defined $keyfile;

  if (-e $keyfile) {
    my $fh = new IO::File $keyfile, 'r'
      or croak "Can't open $keyfile for reading: $OS_ERROR";
    my $data = slurp $fh;
    my $plaintext = $cipher->decrypt($data);
    for (split /\n/, $plaintext) {
      my ($k, $v) = split /\t/;
      $self->{$k} = $v;
    }
    $fh->close;
  }

  if (defined $options->{fallback}) {
    my $fallback_class = 'Finance::Bank::Cahoot::CredentialsProvider::'.$options->{fallback};
    eval "use $fallback_class"; ## no critic
    croak 'Invalid fallback provider '.$options->{fallback} if $EVAL_ERROR;

    my $fallback_args = { credentials => $self->{_credentials},
			  options => $options->{fallback_options} };
    eval "\$self->{_fallback} = $fallback_class->new(\%{\$fallback_args})"; ## no critic
    croak 'Fallback provider '.$options->{fallback}.' failed to initialise' if $EVAL_ERROR;
  }

  my $do_update = 0;
  foreach my $credential (@{$self->{_credentials}}) {
    if (not defined $self->{$credential}) {
      croak 'No fallback provider given and '.$credential.' is not in keyfile'
	if not defined $self->{_fallback};
      $self->{$credential} = $self->{_fallback}->$credential;
      $do_update = 1;
    }
  }

  if ($do_update) {
    my $fh = new IO::File $keyfile, 'w'
      or croak "Can't open $keyfile for writing: $OS_ERROR";

    my @ciphers;
    foreach my $credential (@{$self->{_credentials}}) {
      push @ciphers, $credential."\t".$self->{$credential};
    }
    my $ciphertext = $cipher->encrypt(join "\n", @ciphers);
    $fh->print($ciphertext);
    $fh->close;
  }
  return $self;
}

sub get
{
  my ($self, $credential, $offset) = @_;
  return substr $self->{$credential}, $offset, 1
    if defined $offset;
  return $self->{$credential};
}

1;

__END__

=for stopwords Connell Belka Gariv passphrase keyfile crypto

=head1 NAME

 Finance::Bank::Cahoot::CredentialsProvider::CryptFile - Credentials provider for encrypted stored data

=head1 SYNOPSIS

  my $credentials = Finance::Bank::Cahoot::CredentialsProvider::CrpytFile->new(
     credentials => [qw(account password)],
     options => {key => 'verysecret', keyfile => '/etc/cahoot'});

=head1 DESCRIPTION

Provides a credentials provider that uses credentials stored in an encrypted file.
Each credential is available with its own access method of the same name. All methods
may be optionally supplied a character offset in the credentials value (first
character is 0).

=head1 METHODS

=over 4

=item B<new>

Create a new instance of a static data credentials provider.

=item B<credentials> is an array ref of all the credentials types available via the
credentials provider.

=item B<options> a hash ref of options for the credentials provider.

=over 4

=item B<key> Is the text passphrase for encrypting/decrypting the credentials store.

=item B<keyfile> is an optional path to the credentials store. The default store
is C<$HOME/.cahoot>.

=item B<fallback> is the name of a C<Finance::Bank::Cahoot::CredentialsProvider>
credentials provider to use for any credentials that are not present in
the encrypted store. Newly discovered credentials and encrypted and written
back to the store.

=item B<fallback_options> is a hash ref that is passed to the fallback credentials
provider's constructor as C<options>.

  my $provider =
    Finance::Bank::Cahoot::CredentialsProvider::CryptFile->new(
      credentials => [qw(account username password)],
      options => { key => 'verysecret',
		   keyfile => '/etc/cahoot,
		   fallback => 'Constant',
		   fallback_options => { account => '12345678',
			 		 username => 'acmeuser',
				 	 password => 'secret' } });

=back

=item B<get>

Returns a credential value whose name is passed as the first parameter. An
optional  character offset (0 is the first character) may also be provided.

  my $password_char = $provider->password(5);

=back

=head1 AUTHOR

Jon Connell <jon@figsandfudge.com>

=head1 LICENSE AND COPYRIGHT

This module takes its inspiration from C<Finance::Bank::Natwest> by Jody Belka.
The crypto access routes are heavily borrowed from C<Finance::Bank::Wachovia>
by Jim Gariv.

Copyright 2004 Jim Garvin
Copyright 2007 by Jon Connell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
