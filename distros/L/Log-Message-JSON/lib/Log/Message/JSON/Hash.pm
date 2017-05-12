#!/usr/bin/perl

=head1 NAME

Log::Message::JSON::Hash - L<Tie::IxHash(3)> wrapper supporting storing cache

=head1 SYNOPSIS

  use Log::Message::JSON::Hash;
  use JSON;

  tie my %hash, "Log::Message::JSON::Hash";
  # fill %hash...
  tied(%hash)->cache = encode_json(\%hash);

  # ...

  print tied(%hash)->cache;

=head1 DESCRIPTION

This class is a proxy to L<Tie::IxHash(3)>. It's a valid class to tie hash to,
and above this the class adds possibility of storing a cache.

The cache is cleared on every destructive operation (storing an element,
deleting an element and clearing whole hash).

=cut

#-----------------------------------------------------------------------------

package Log::Message::JSON::Hash;

use warnings;
use strict;

use Tie::IxHash;
use Carp;

#-----------------------------------------------------------------------------

=head1 API

=head2 Own Methods

=over

=cut

#-----------------------------------------------------------------------------

=item C<< new() >>

Constructor.

=cut

sub new {
  my ($class, @args) = @_;

  my $tied = tie my %val, "Tie::IxHash";

  my $self = bless {
    tied_object => $tied,
    cache => undef,
  }, $class;

  return $self;
}

=item C<cache()>

=item C<cache($data)>

Get or set cache for this object.

Cache will be cleared on any destructive operation performed on this object.

=cut

sub cache {
  my ($self, $cache) = @_;

  if (defined $cache) {
    $self->{cache} = $cache;
  }

  return $self->{cache};
}

=back

=cut

#-----------------------------------------------------------------------------

=head2 Methods Satisfying C<tie()> API

All the rest of methods are defined to satisfy API for C<tie()> function. They
call appropriate methods of underlying L<Tie::IxHash(3)> object.

=cut

#-----------------------------------------------------------------------------

=begin InternalDocs

=head3 Creating and destroying objects

=over

=cut

#-----------------------------------------------------------------------------

sub TIEHASH {
  my ($class, @args) = @_;

  return $class->new(@args);
}

sub UNTIE {
  my ($self, @args) = @_;

  $self->{tied_object}->UNTIE(@args);
  $self->{cache} = undef;
}

=back

=cut

#-----------------------------------------------------------------------------

=head3 Altering object's data

=over

=cut

#-----------------------------------------------------------------------------

sub STORE {
  my ($self, @args) = @_;

  $self->{cache} = undef if defined $self->{cache};

  $self->{tied_object}->STORE(@args);
}

sub DELETE {
  my ($self, @args) = @_;

  $self->{cache} = undef if defined $self->{cache};

  $self->{tied_object}->DELETE(@args);
}

sub CLEAR {
  my ($self, @args) = @_;

  $self->{cache} = undef if defined $self->{cache};

  $self->{tied_object}->CLEAR(@args);
}

=back

=cut

#-----------------------------------------------------------------------------

=head3 Reading object's data

=over

=cut

#-----------------------------------------------------------------------------

sub FETCH {
  my ($self, @args) = @_;

  $self->{tied_object}->FETCH(@args);
}

sub EXISTS {
  my ($self, @args) = @_;

  $self->{tied_object}->EXISTS(@args);
}

sub FIRSTKEY {
  my ($self, @args) = @_;

  $self->{tied_object}->FIRSTKEY(@args);
}

sub NEXTKEY {
  my ($self, @args) = @_;

  $self->{tied_object}->NEXTKEY(@args);
}

sub SCALAR {
  my ($self, @args) = @_;

  $self->{tied_object}->SCALAR(@args);
}

=back

=end InternalDocs

=cut

#-----------------------------------------------------------------------------

=head1 AUTHOR

Stanislaw Klekot, C<< <cpan at jarowit.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Stanislaw Klekot.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Tie::IxHash(3)>, L<Tie::Hash(3)>, C<tie()> in L<perlfunc(1)>

=cut

#-----------------------------------------------------------------------------
1;
# vim:ft=perl
