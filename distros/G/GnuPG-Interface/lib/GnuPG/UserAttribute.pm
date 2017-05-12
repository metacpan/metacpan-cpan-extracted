#  UserAttribute.pm
#    - providing an object-oriented approach to GnuPG user attributes
#
#  Copyright (C) 2010 Daniel Kahn Gillmor <dkg@fifthhorseman.net>
#  (derived from UserId.pm, Copyright (C) 2000 Frank J. Tobin <ftobin@cpan.org>)
#
#  This module is free software; you can redistribute it and/or modify it
#  under the same terms as Perl itself.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#  $Id: UserId.pm,v 1.7 2001/08/21 13:31:50 ftobin Exp $
#

package GnuPG::UserAttribute;
use Moo;
use MooX::late;

has [qw( validity subpacket_count subpacket_total_size )] => (
    isa => 'Any',
    is  => 'rw',
);

has signatures => (
    isa       => 'ArrayRef',
    is        => 'rw',
    default   => sub { [] },
);
has revocations => (
    isa       => 'ArrayRef',
    is        => 'rw',
    default   => sub { [] },
);

sub push_signatures {
    my $self = shift;
    push @{ $self->signatures }, @_;
}
sub push_revocations {
    my $self = shift;
    push @{ $self->revocations }, @_;
}

1;

__END__

=head1 NAME

GnuPG::UserAttribute - GnuPG User Attribute Objects

=head1 SYNOPSIS

  # assumes a GnuPG::PublicKey object in $publickey
  my $jpgs_size = $publickey->user_attributes->[0]->subpacket_total_size();

=head1 DESCRIPTION

GnuPG::UserAttribute objects are generally not instantiated on their
own, but rather as part of GnuPG::PublicKey or GnuPG::SecretKey
objects.

=head1 OBJECT METHODS

=over 4

=item new( I<%initialization_args> )

This methods creates a new object.  The optional arguments are
initialization of data members;

=back

=head1 OBJECT DATA MEMBERS

=over 4

=item validity

A scalar holding the value GnuPG reports for the calculated validity
of the binding between this User Attribute packet and its associated
primary key.  See GnuPG's DETAILS file for details.

=item subpacket_count

A scalar holding the number of attribute subpackets.  This is usually
1, as most UATs seen in the wild contain a single image in JPEG
format.

=item subpacket_total_size

A scalar holding the total byte count of all attribute subpackets.

=item signatures

A list of GnuPG::Signature objects embodying the signatures
on this user attribute.

=item revocations

A list of revocations associated with this User Attribute, stored as
GnuPG::Signature objects (since revocations are a type of
certification as well).

=back

=head1 BUGS

No useful information about the embedded attributes is provided yet.
It would be nice to be able to get ahold of the raw JPEG material.

=head1 SEE ALSO

L<GnuPG::Signature>,

=cut
