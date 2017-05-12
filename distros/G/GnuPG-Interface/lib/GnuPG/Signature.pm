#  Signature.pm
#    - providing an object-oriented approach to GnuPG key signatures
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
#  $Id: Signature.pm,v 1.4 2001/08/21 13:31:50 ftobin Exp $
#

package GnuPG::Signature;
use Moo;
use MooX::late;

has [qw(
         validity
         algo_num
         hex_id
         user_id_string
         date
         date_string
         expiration_date
         expiration_date_string
         sig_class
         is_exportable
      )] => (
    isa => 'Any',
    is  => 'rw',
);

sub is_valid {
    my $self = shift;
    return $self->validity eq '!';
}

sub compare {
  my ($self, $other) = @_;

  my @compared_fields = qw(
                            validity
                            algo_num
                            hex_id
                            date
                            date_string
                            sig_class
                            is_exportable
                         );

  foreach my $field ( @compared_fields ) {
    return 0 unless $self->$field eq $other->$field;
  }
  # check for expiration if present?
  return 0 unless (defined $self->expiration_date) == (defined $other->expiration_date);
  if (defined $self->expiration_date) {
    return 0 unless (($self->expiration_date == $other->expiration_date) ||
      ($self->expiration_date_string eq $other->expiration_date_string));
  }
  return 1;
}

1;

__END__

=head1 NAME

GnuPG::Signature - GnuPG Key Signature Objects

=head1 SYNOPSIS

  # assumes a GnuPG::Key or GnuPG::UserID or GnuPG::UserAttribute object in $signed
  my $signing_id = $signed->signatures->[0]->hex_id();

=head1 DESCRIPTION

GnuPG::Signature objects are generally not instantiated
on their own, but rather as part of GnuPG::Key objects.
They embody various aspects of a GnuPG signature on a key.

=head1 OBJECT METHODS

=over 4

=item new( I<%initialization_args> )

This methods creates a new object.  The optional arguments are
initialization of data members.

=item is_valid()

Returns 1 if GnuPG was able to cryptographically verify the signature,
otherwise 0.

=item compare( I<$other> )

Returns non-zero only when this Signature is identical to the other
GnuPG::Signature.

=back

=head1 OBJECT DATA MEMBERS

=over 4

=item validity

A character indicating the cryptographic validity of the key.  GnuPG
uses at least the following characters: "!" means valid, "-" means not
valid, "?" means unknown (e.g. if the supposed signing key is not
present in the local keyring), and "%" means an error occurred (e.g. a
non-supported algorithm).  See the documentation for --check-sigs in
gpg(1).

=item algo_num

The number of the algorithm used for the signature.

=item hex_id

The hex id of the signing key.

=item user_id_string

The first user id string on the key that made the signature.
This may not be defined if the signing key is not on the local keyring.

=item sig_class

Signature class.  This is the numeric value of the class of signature.

A table of possible classes of signatures and their numeric types can
be found at http://tools.ietf.org/html/rfc4880#section-5.2.1

=item is_exportable

returns 0 for local-only signatures, non-zero for exportable
signatures.

=item date_string

The formatted date the signature was performed on.

=item date

The date the signature was performed, represented as the number of
seconds since midnight 1970-01-01 UTC.

=item expiration_date_string

The formatted date the signature will expire (signatures without
expiration return undef).

=item expiration_date

The date the signature will expire, represented as the number of
seconds since midnight 1970-01-01 UTC (signatures without expiration
return undef)

=back

=head1 SEE ALSO


=cut
