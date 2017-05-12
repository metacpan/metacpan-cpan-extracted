#  Revoker.pm
#    - providing an object-oriented approach to GnuPG key revokers
#
#  Copyright (C) 2010 Daniel Kahn Gillmor <dkg@fifthhorseman.net>
#  (derived from Signature.pm, Copyright (C) 2000 Frank J. Tobin <ftobin@cpan.org>)
#
#  This module is free software; you can redistribute it and/or modify it
#  under the same terms as Perl itself.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#  $Id: Signature.pm,v 1.4 2001/08/21 13:31:50 ftobin Exp $
#

package GnuPG::Revoker;
use Moo;
use MooX::late;

has [qw(
         algo_num
         class
      )] => (
    isa => 'Int',
    is  => 'rw',
);

has fingerprint => (
                    isa => 'GnuPG::Fingerprint',
                    is => 'rw',
                    );

has signatures => (
    isa       => 'ArrayRef',
    is        => 'rw',
    default   => sub { [] },
);

sub push_signatures {
    my $self = shift;
    push @{ $self->signatures }, @_;
}

sub is_sensitive {
    my $self = shift;
    return $self->class & 0x40;
}

sub compare {
  my ( $self, $other, $deep ) = @_;

  my @comparison_ints = qw( class algo_num );

  foreach my $field ( @comparison_ints ) {
    return 0 unless $self->$field() == $other->$field();
  }

  return 0 unless $self->fingerprint->compare($other->fingerprint);

  # FIXME: is it actually wrong if the associated signatures come out
  # in a different order on the two compared designated revokers?
  if (defined $deep && $deep) {
    return 0 unless @{$self->signatures} == @{$other->signatures};
    for ( my $i = 0; $i < scalar(@{$self->signatures}); $i++ ) {
      return 0
        unless $self->signatures->[$i]->compare($other->signatures->[$i], 1);
    }
  }

  return 1;
}

1;

__END__

=head1 NAME

GnuPG::Revoker - GnuPG Key Revoker Objects

=head1 SYNOPSIS

  # assumes a GnuPG::PrimaryKey object in $key
  my $revokerfpr = $key->revokers->[0]->fingerprint();

=head1 DESCRIPTION

GnuPG::Revoker objects are generally not instantiated on their own,
but rather as part of GnuPG::Key objects.  They represent a statement
that another key is designated to revoke certifications made by the
key in question.

=head1 OBJECT METHODS

=over 4

=item new( I<%initialization_args> )

This methods creates a new object.  The optional arguments are
initialization of data members.

=item is_sensitive()

Returns 0 if the revoker information can be freely distributed.
If this is non-zero, the information should be treated as "sensitive".

Please see http://tools.ietf.org/html/rfc4880#section-5.2.3.15 for
more explanation.

=item compare( I<$other>, I<$deep> )

Returns non-zero only when this designated revoker is identical to the
other GnuPG::Revoker.  If $deep is present and non-zero, the revokers'
signatures will also be compared.


=back

=head1 OBJECT DATA MEMBERS

=over 4

=item fingerprint

A GnuPG::Fingerprint object indicating the fingerprint of the
specified revoking key.  (Note that this is *not* the fingerprint of
the key whose signatures can be revoked by this revoker).

=item algo_num

The numeric identifier of the algorithm of the revoker's key.

=item signatures

A list of GnuPG::Signature objects which cryptographically bind the
designated revoker to the primary key.  If the material was
instantiated using the *_with_sigs() functions from GnuPG::Interface,
then a valid revoker designation should have a valid signature
associated with it from the relevant key doing the designation (not
from the revoker's key).

Note that designated revoker certifications are themselves
irrevocable, so there is no analogous list of revocations in a
GnuPG::Revoker object.

=back

=head1 SEE ALSO

L<GnuPG::Interface>,
L<GnuPG::Fingerprint>,
L<GnuPG::Key>,
L<GnuPG::Signature>,
L<http://tools.ietf.org/html/rfc4880#section-5.2.3.15>

=cut
