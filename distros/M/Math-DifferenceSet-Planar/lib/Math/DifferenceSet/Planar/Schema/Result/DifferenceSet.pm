package Math::DifferenceSet::Planar::Schema::Result::DifferenceSet;

=head1 NAME

Math::DifferenceSet::Planar::Schema::Result::DifferenceSet -
planar difference set database backend result class definition.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 VERSION

This documentation refers to version 0.007 of
Math::DifferenceSet::Planar::Schema::Result::DifferenceSet.

=cut

our $VERSION = '0.007';

=head1 TABLE: C<difference_set>

=cut

__PACKAGE__->table("difference_set");

=head1 ACCESSORS

=head2 order

  data_type: 'integer'
  is_nullable: 0

=head2 base

  data_type: 'integer'
  is_nullable: 0

=head2 exponent

  data_type: 'integer'
  is_nullable: 0

=head2 modulus

  data_type: 'integer'
  is_nullable: 0

=head2 n_planes

  data_type: 'integer'
  is_nullable: 0

=head2 deltas

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "order_",
  { accessor => "order", data_type => "integer", is_nullable => 0 },
  "base",
  { data_type => "integer", is_nullable => 0 },
  "exponent",
  { data_type => "integer", is_nullable => 0 },
  "modulus",
  { data_type => "integer", is_nullable => 0 },
  "n_planes",
  { data_type => "integer", is_nullable => 0 },
  "deltas",
  { data_type => "text", is_nullable => 0 },
);

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

Copyright (c) 2019 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
