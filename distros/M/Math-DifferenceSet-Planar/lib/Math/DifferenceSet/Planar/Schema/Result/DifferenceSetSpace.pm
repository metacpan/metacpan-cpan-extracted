package Math::DifferenceSet::Planar::Schema::Result::DifferenceSetSpace;

=head1 NAME

Math::DifferenceSet::Planar::Schema::Result::DifferenceSetSpace -
planar difference set space database backend result class definition.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 VERSION

This documentation refers to version 0.017 of
Math::DifferenceSet::Planar::Schema::Result::DifferenceSetSpace.

=cut

our $VERSION = '0.017';

=head1 TABLE: C<difference_set_space>

=cut

__PACKAGE__->table("difference_set_space");

=head1 ACCESSORS

=head2 order

  data_type: 'integer'
  is_nullable: 0

=head2 mul_radix

  data_type: 'integer'
  is_nullable: 0

=head2 mul_depth

  data_type: 'integer'
  is_nullable: 0

=head2 rot_radices

  data_type: 'blob'
  is_nullable: 0

=head2 rot_depths

  data_type: 'blob'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "order_",
  { accessor => "order", data_type => "integer", is_nullable => 0 },
  "mul_radix",
  { data_type => "integer", is_nullable => 0 },
  "mul_depth",
  { data_type => "integer", is_nullable => 0 },
  "rot_radices",
  { data_type => "blob", is_nullable => 0 },
  "rot_depths",
  { data_type => "blob", is_nullable => 0 },
);

=head2 rotator_space

I<rotator_space> is a wrapper for I<rot_radices> and I<rot_depths>,
unpacking those and generating two arrayrefs of radices and corresponding
depths.

=cut

sub rotator_space {
    my ($this) = @_;
    my @radices = unpack 'w*', $this->rot_radices;
    my @depths  = unpack 'w*', $this->rot_depths;
    return (\@radices, \@depths);
}

=head1 PRIMARY KEY

=over 4

=item * L</order>

=back

=cut

__PACKAGE__->set_primary_key("order_");

1;

=head1 SEE ALSO

=over 4

=item *

L<Math::DifferenceSet::Planar::Schema> - schema class.

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021-2022 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
