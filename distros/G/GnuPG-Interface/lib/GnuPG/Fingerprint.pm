#  Fingerprint.pm
#    - providing an object-oriented approach to GnuPG key fingerprints
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
#  $Id: Fingerprint.pm,v 1.8 2001/08/21 13:31:50 ftobin Exp $
#

package GnuPG::Fingerprint;
use Moo;
use MooX::late;
with qw(GnuPG::HashInit);

has as_hex_string => (
    isa => 'Any',
    is  => 'rw',        
);

sub compare {
  my ($self, $other) = @_;
  return 0 unless $other->isa('GnuPG::Fingerprint');
  return $self->as_hex_string() eq $other->as_hex_string();
}

# DEPRECATED
sub hex_data
{
    my ( $self, $v ) = @_;
    $self->as_hex_string( $v ) if defined $v;
    return $self->as_hex_string();
}

1;

__END__

=head1 NAME

GnuPG::Fingerprint - GnuPG Fingerprint Objects

=head1 SYNOPSIS

  # assumes a GnuPG::Key in $key
  my $fingerprint = $key->fingerprint->as_hex_string();

=head1 DESCRIPTION

GnuPG::Fingerprint objects are generally part of GnuPG::Key
objects, and are not created on their own.

=head1 OBJECT METHODS

=head2 Initialization Methods

=over 4

=item new( I<%initialization_args> )

This methods creates a new object.  The optional arguments are
initialization of data members.

=item hash_init( I<%args> ).

=item compare( I<$other> )

Returns non-zero only when this fingerprint is identical to the other
GnuPG::Fingerprint.

=back

=head1 OBJECT DATA MEMBERS

=over 4

=item as_hex_string

This is the hex value of the fingerprint that the object embodies,
in string format.

=back

=head1 SEE ALSO

L<GnuPG::Key>,

=cut
