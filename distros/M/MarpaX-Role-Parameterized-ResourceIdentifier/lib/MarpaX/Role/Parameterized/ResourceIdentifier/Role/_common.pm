use strict;
use warnings FATAL => 'all';

package MarpaX::Role::Parameterized::ResourceIdentifier::Role::_common;

# ABSTRACT: Resource Identifier: Common syntax semantics

our $VERSION = '0.003'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Moo::Role;
use Unicode::Normalize qw/normalize/;

sub can_scheme { my ($class, $scheme) = @_; $scheme =~ /\A[A-Za-z][A-Za-z0-9\+\-\.]*\z/ }

#
# Arguments of every callback:
# my ($self, $field, $value, $lhs) = @_;
#
around build_character_normalizer => sub {
  my ($orig, $self) = (shift, shift);

  my $rc = $self->$orig(@_);
  #
  # --------------------------------------------
  # http://tools.ietf.org/html/rfc3987
  # --------------------------------------------
  #
  # 5.3.2.2.  Character Normalization
  #
  # [The exceptions are] conversion
  # from a non-digital form, and conversion from a non-UCS-based
  # character encoding to a UCS-based character encoding. In these cases,
  # NFC or a normalizing transcoder using NFC MUST be used for
  # interoperability.
  #
  $rc->{''} = sub { normalize('NFC',  $_[2]) } if (! $self->is_character_normalized);
  $rc
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Role::Parameterized::ResourceIdentifier::Role::_common - Resource Identifier: Common syntax semantics

=head1 VERSION

version 0.003

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
