#  SubKey.pm
#    - providing an object-oriented approach to GnuPG sub keys
#
#  Copyright (C) 2000 Frank J. Tobin <ftobin@cpan.org>
#
#  This module is free software; you can redistribute it and/or modify it
#  under the same terms as Perl itself.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#  $Id: SubKey.pm,v 1.9 2001/09/14 12:34:36 ftobin Exp $
#

package GnuPG::SubKey;
use Carp;
use Moo;
use MooX::late;
BEGIN { extends qw( GnuPG::Key ) }

has [qw( validity   owner_trust  local_id  )] => (
    isa => 'Any',
    is  => 'rw',
);

# DEPRECATED!
# return the last signature, if present.  Or push in a new signature,
# if one is supplied.
sub signature {
  my $self = shift;
  my $argcount = @_;

  if ($argcount) {
    @{$self->signatures} = ();
    $self->push_signatures(@_);
  } else {
    my $sigcount = @{$self->signatures};
    if ($sigcount) {
      return $self->signatures->[$sigcount-1];
    } else {
      return undef;
    }
  }
}

1;

__END__

=head1 NAME

GnuPG::SubKey - GnuPG Sub Key objects

=head1 SYNOPSIS

  # assumes a GnuPG::PublicKey object in $key
  my @subkeys = $key->subkeys();

  # now GnuPG::SubKey objects are in @subkeys

=head1 DESCRIPTION

GnuPG::SubKey objects are generally instantiated
through various methods of GnuPG::Interface.
They embody various aspects of a GnuPG sub key.

This package inherits data members and object methods
from GnuPG::Key, which are not described here, but rather
in L<GnuPG::Key>.

=head1 OBJECT DATA MEMBERS

=over 4

=item validity

A scalar holding the value GnuPG reports for the trust of authenticity
(a.k.a.) validity of a key.
See GnuPG's DETAILS file for details.

=item local_id

GnuPG's local id for the key.

=item owner_trust

The scalar value GnuPG reports as the ownertrust for this key.
See GnuPG's DETAILS file for details.

=item signature

* DEPRECATED*

A GnuPG::Signature object holding the representation of the signature
on this key.  Please use signatures (see L<GnuPG::Key>) instead of
signature.  Using signature, you will get an arbitrary signature from
the set of available signatures.

=back

=head1 SEE ALSO

L<GnuPG::Key>,
L<GnuPG::Signature>,

=cut
