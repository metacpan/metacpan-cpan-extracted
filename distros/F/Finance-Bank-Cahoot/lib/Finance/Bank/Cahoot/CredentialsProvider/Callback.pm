# Copyright (c) 2007 Jon Connell.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Finance::Bank::Cahoot::CredentialsProvider::Callback;
use base qw(Finance::Bank::Cahoot::CredentialsProvider);

use strict;
use warnings 'all';
use vars qw($VERSION);

$VERSION = '1.07';

use Carp qw(croak);

sub _init
{
  my ($self, $options) = @_;
  while (my ($credential, $callback) = each %{$options}) {
    croak 'Invalid credential '.$credential.' supplied with callback'
      if not $self->can($credential);
    croak 'Callback for '.$credential.' is not a code ref'
      if ref $callback ne 'CODE';
    $self->{$credential} = $callback;
  }
  return $self;
}

sub get
{
  my ($self, $credential, $offset) = @_;
  return $self->{$credential}($offset);
}

1;
__END__

=for stopwords Connell Belka

=head1 NAME

 Finance::Bank::Cahoot::CredentialsProvider::Callback - Credentials provider that uses callbacks

=head1 SYNOPSIS

  my $credentials =  Finance::Bank::Cahoot::CredentialsProvider::Callback->new(
     credentials => [qw(account password)],
     options => { account => sub { return '12345678' },
                  username => sub { return 'username' },
                  password => sub { return substr('verysecret', $_[0]-1, 1) } });

=head1 DESCRIPTION

This module provides an implementation of a credentials provider where each of
the credentials is provided by a user-supplied callback. All callbacks return a
text string. Any callback may be optionally supplied a character offset in the
credentials value (first character is 0).

=head1 METHODS

=over 4

=item B<new>

Create a new instance of the credentials provider. All parameters are mandatory.

=item B<credentials> is an array ref of all the credentials types available via the
credentials provider.

=item B<options> is a hash ref of callback routines for each credential.

=item B<get>

Returns a credential value whose name is passed as the first parameter. An
optional  character offset (0 is the first character) may also be provided.

  my $password_char = $provider->password(5);

=back

=head1 AUTHOR

Jon Connell <jon@figsandfudge.com>

=head1 LICENSE AND COPYRIGHT

This module borrows heavily from Finance::Bank::Natwest by Jody Belka.

Copyright 2007 by Jon Connell
Copyright 2003 by Jody Belka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
