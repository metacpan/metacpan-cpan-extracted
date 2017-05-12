# Copyright (c) 2007 Jon Connell.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Finance::Bank::Cahoot::CredentialsProvider::ReadLine;
use base qw(Finance::Bank::Cahoot::CredentialsProvider);

use strict;
use warnings 'all';
use vars qw($VERSION);

$VERSION = '1.07';

use Carp qw(croak);
use Term::ReadLine;

sub _init
{
  my ($self, $options) = @_;
  while (my ($arg, $value) = each %{$options}) {
    if ($arg =~ m/(\w+)_prompt/) {
      croak 'Prompt for unknown credential '.$1
	if not $self->can($1);
      $self->{_prompts}->{$1} = $value;
    } else {
      croak 'Invalid credential '.$arg.' supplied with callback'
	if not $self->can($arg);
      $self->{$arg} = $value;
    }
  }
  $self->{_console} = new Term::ReadLine 'Cahoot Login Credentials';
  return $self;
}

sub get
{
  my ($self, $credential, $offset) = @_;

  my $prompt;
  if (defined $self->{_prompts}->{$credential}) {
    $prompt = sprintf $self->{_prompts}->{$credential}, $offset;
  } else {
    if (defined $offset) {
      $prompt = sprintf 'Enter character %d of '.$credential.': ', $offset;
    } else {
      $prompt = 'Enter '.$credential.': ';
    }
  }
  my $str;
  if (defined $self->{$credential}) {
    $str = $self->{$credential};
  } else {
    $str = $self->{_console}->readline($prompt);
  }
  return $str if length $str == 1;
  if (defined $offset) {
    return substr $str, $offset - 1, 1;
  } else {
    return $str;
  }
}

1;

__END__

=for stopwords Connell Belka username online

=head1 NAME

 Finance::Bank::Cahoot::CredentialsProvider::ReadLine - Console-based credentials provider

=head1 SYNOPSIS

  my $credentials =  Finance::Bank::Cahoot::CredentialsProvider::ReadLine->new(
     account => '12345678', username => 'acmeuser',
     password_prompt => 'Enter character %d of your password: '
  );

=head1 DESCRIPTION

This module provides a C<Term::ReadLine> implementation of a credentials provider
for console entry of credentials. Each credentials method can be overridden by
a constant parameter to reduce the amount of console interaction with the user in
the case of less security sensitive data such as a username. In addition to the
value overrides, the text prompt for each readline method can also be overridden.

=head1 METHODS

=over 4

=item B<new>

Create a new instance of the credentials provider.

=item B<credentials> is an array ref of all the credentials types available via the
credentials provider.

=item B<options> is a hash ref of optional default values and prompts for each
credential. Prompts are provided in C<options> using keys of the form
C<credential_prompt>.

  my $credentials =  Finance::Bank::Cahoot::CredentialsProvider::ReadLine->new(
     account => '12345678', username => 'acmeuser',
     password_prompt => 'Enter character %d of your password: '
  );

=item B<get>

Returns a credential value whose name is passed as the first parameter. An
optional  character offset (1 is the first character) may also be provided.

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
