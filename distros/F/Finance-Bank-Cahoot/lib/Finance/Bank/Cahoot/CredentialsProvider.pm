# Copyright (c) 2007 Jon Connell.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Finance::Bank::Cahoot::CredentialsProvider;

use strict;
use warnings 'all';
use vars qw($VERSION);

$VERSION = '1.07';

use Carp qw(croak);
use English '-no_match_vars';

sub new
{
  my ($class, %args) = @_;

  croak 'Calling abstract base class constructor for '.__PACKAGE__.' is forbidden'
    if $class eq __PACKAGE__;

  croak 'Must provide a list of credentials'
    if not exists $args{credentials};

  croak 'credentials is not an array ref'
    if ref $args{credentials} ne 'ARRAY';

  if (exists $args{options}) {
    croak 'options must be a hash ref'
      if ref $args{options} ne 'HASH';
    my @o = keys %{$args{options}};
    croak 'Empty list of options'
      if $#o < 0;
  }

  my $self = { };
  bless $self, $class;
  $self->{_credentials} = $args{credentials};
  foreach my $credential (@{$args{credentials}}) {
    no strict 'refs'; ## no critic
    *{"${class}::$credential"} = sub { my ($self, $offset) = @_;
				       return $self->get($credential, $offset);
				     };
  }
  $self->_init($args{options});
  return $self;
}

sub get
{
  my ($self) = @_;
  my $class = ref $self;
  croak 'Calling abstract base class get method for '.$class.' is forbidden';
}

1;

__END__

=for stopwords Connell Belka

=head1 NAME

 Finance::Bank::Cahoot::CredentialsProvider - Abstract base class for credentials providers

=head1 SYNOPSIS

  my $credentials = Finance::Bank::Cahoot::CredentialsProvider::Acme->new(
     credentials => [qw(account password)],
     options => {account => 'acmeuser'});

=head1 DESCRIPTION

Provides an abstract base class for deriving new credentials providers with a
defined interface. Derived classes B<MUST> implement C<_init> and C<get>
methods.

=head1 METHODS

=over 4

=item B<new>

Create a new instance of a credentials provider. Each credential is available
with its own access method of the same name. All methods may be optionally supplied a
character offset in the credentials value (first character is 0).

=item B<credentials> is an array ref of all the credentials types available via the
credentials provider.

=item B<options> is a hash ref of options for each credential. These are
used by the credentials provider in an implementation-defined manner.

=back

=head1 ABSTRACT METHODS

=over 4

=item B<_init>

Initialization routine for the derived class to implement. Called by C<new>
with the credentials options as a hash reference. In the following example,
taken from the the C<Constant> credentials provider, C<_init> simply stores
each option value in the class:

  sub _init
  {
    my ($self, $options) = @_;
    while (my ($credential, $value) = each %{$options}) {
      croak 'Invalid credential '.$credential.' supplied with callback'
        if not $self->can($credential);
      $self->{$credential} = $value;
    }
  }

=item B<get>

Public access method for the derived class to implement. Called with the
name of the credential to supply and an optional character offset (0 is
the first character). In the following example, taken from the the
C<Constant> credentials provider, the credential is simply returned from
class members created by the previous C<_init> method:

  sub get
  {
    my ($self, $credential, $offset) = @_;
    return substr ($self->{$credential}, $offset, 1)
      if defined $offset;
    return $self->{$credential};
  }

=back

=head1 AUTHOR

Jon Connell <jon@figsandfudge.com>

=head1 LICENSE AND COPYRIGHT

This module takes its inspiration from Finance::Bank::Natwest by Jody Belka.

Copyright 2007 by Jon Connell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
