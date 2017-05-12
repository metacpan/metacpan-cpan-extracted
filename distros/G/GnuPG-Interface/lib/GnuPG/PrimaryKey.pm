#  PrimaryKey.pm
#      - objectified GnuPG primary keys (can have subkeys)
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
#  $Id: PrimaryKey.pm,v 1.4 2001/09/14 12:34:36 ftobin Exp $
#

package GnuPG::PrimaryKey;
use Moo;
use MooX::late;
use MooX::HandlesVia;

BEGIN { extends qw( GnuPG::Key ) }

for my $list (qw(user_ids subkeys user_attributes)) {
    my $ref = $list . "_ref";
    has $ref => (
        handles_via => 'Array',
        is          => 'rw',
        default     => sub { [] },
        handles     => {
            "push_$list" => 'push',
        },
    );

    no strict 'refs';
    *{$list} = sub {
        my $self = shift;
        return wantarray ? @{$self->$ref(@_)} : $self->$ref(@_);
    };
}

has $_ => (
    isa     => 'Any',
    is      => 'rw',
    clearer => 'clear_' . $_,
) for qw( local_id owner_trust );


sub compare {
  my ($self, $other, $deep) = @_;

  # not comparing local_id because it is meaningless in modern
  # versions of GnuPG.
  my @comparison_fields = qw (
     owner_trust
  );

  foreach my $field (@comparison_fields) {
    return 0 unless $self->$field eq $other->$field;
  }

  if (defined $deep && $deep) {
    my @lists = qw(
      user_ids
      subkeys
      user_attributes
                 );

    foreach my $list (@lists) {
      return 0 unless @{$self->$list} == @{$other->$list};
      for ( my $i = 0; $i < scalar(@{$self->$list}); $i++ ) {
        return 0
          unless $self->$list->[$i]->compare($other->$list->[$i], 1);
      }
    }
  }

  return $self->SUPER::compare($other, $deep);
}

1;

__END__

=head1 NAME

GnuPG::PrimaryKey - GnuPG Primary Key Objects

=head1 SYNOPSIS

  # assumes a GnuPG::Interface object in $gnupg
  my @keys = $gnupg->get_public_keys( 'ftobin' );

  # or

  my @keys = $gnupg->get_secret_keys( 'ftobin' );

  # now GnuPG::PrimaryKey objects are in @keys

=head1 DESCRIPTION

GnuPG::PrimaryKey objects are generally instantiated
as GnuPG::PublicKey or GnuPG::SecretKey objects
through various methods of GnuPG::Interface.
They embody various aspects of a GnuPG primary key.

This package inherits data members and object methods
from GnuPG::Key, which is not described here, but rather
in L<GnuPG::Key>.

=head1 OBJECT DATA MEMBERS

=over 4

=item user_ids

A list of GnuPG::UserId objects associated with this key.

=item user_attributes

A list of GnuPG::UserAttribute objects associated with this key.

=item subkeys

A list of GnuPG::SubKey objects associated with this key.

=item local_id

WARNING: DO NOT USE.  This used to mean GnuPG's local id for the key,
but modern versions of GnuPG do not produce it.  Expect this to be the
empty string or undef.

=item owner_trust

The scalar value GnuPG reports as the ownertrust for this key.
See GnuPG's DETAILS file for details.

=back

=head1 SEE ALSO

L<GnuPG::Key>,
L<GnuPG::UserId>,
L<GnuPG::SubKey>,

=cut
