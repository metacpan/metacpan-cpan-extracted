# Copyright (c) 2007 Jon Connell.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Finance::Bank::Cahoot::CredentialsProvider::Constant;
use base qw(Finance::Bank::Cahoot::CredentialsProvider);

use strict;
use warnings 'all';
use vars qw($VERSION);

$VERSION = '1.07';

use Carp qw(croak);

sub _init
{
  my ($self, $options) = @_;
  while (my ($credential, $value) = each %{$options}) {
    croak 'Invalid credential '.$credential.' supplied with callback'
      if not $self->can($credential);
    $self->{$credential} = $value;
  }
  return $self;
}

sub get
{
  my ($self, $credential, $offset) = @_;
  croak 'Undefined credential '.$credential
    if not exists $self->{$credential};
  return substr $self->{$credential}, $offset - 1, 1
    if defined $offset;
  return $self->{$credential};
}

1;

__END__

=for stopwords Connell Belka

=head1 NAME

 Finance::Bank::Cahoot::CredentialsProvider::Constant - Credentials provider for static data

=head1 SYNOPSIS

  my $credentials = Finance::Bank::Cahoot::CredentialsProvider::Constant->new(
     credentials => [qw(account password)],
     options => {account => 'acmeuser'});

=head1 DESCRIPTION

Provides a credentials provider that returns static data. Each credential is available
with its own access method of the same name. All methods may be optionally supplied a
character offset in the credentials value (first character is 1).

=head1 METHODS

=over 4

=item B<new>

Create a new instance of a static data credentials provider.

=item B<credentials> is an array ref of all the credentials types available via the
credentials provider.

=item B<options> is a hash ref of constant return values of credentials.

=item B<get>

Returns a credential value whose name is passed as the first parameter. An
optional  character offset (1 is the first character) may also be provided.

  my $password_char = $provider->password(5);

=back

=head1 AUTHOR

Jon Connell <jon@figsandfudge.com>

=head1 LICENSE AND COPYRIGHT

This module takes its inspiration from Finance::Bank::Natwest by Jody Belka.

Copyright 2007 by Jon Connell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
