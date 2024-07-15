package Math::DifferenceSet::Planar::Schema::Result::DifferenceSet;

=head1 NAME

Math::DifferenceSet::Planar::Schema::Result::DifferenceSet -
planar difference set database backend result class definition.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 VERSION

This documentation refers to version 1.002 of
Math::DifferenceSet::Planar::Schema::Result::DifferenceSet.

=cut

our $VERSION = '1.002';

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

=head2 ref_std

  data_type: 'integer'
  is_nullable: 0

=head2 ref_lex

  data_type: 'integer'
  is_nullable: 0

=head2 ref_gap

  data_type: 'integer'
  is_nullable: 0

=head2 delta_main

  data_type: 'blob'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "order_",
  { accessor => "order", data_type => "integer", is_nullable => 0 },
  "base",
  { data_type => "integer", is_nullable => 0 },
  "ref_std",
  { data_type => "integer", is_nullable => 0 },
  "ref_lex",
  { data_type => "integer", is_nullable => 0 },
  "ref_gap",
  { data_type => "integer", is_nullable => 0 },
  "delta_main",
  { data_type => "blob", is_nullable => 0 },
);

=head2 main_elements

I<main_elements> is a wrapper for I<delta_main> generating an array of
elements values from the deltas raw data.  It returns an array reference
if deltas are defined, otherwise undef.

Unpacking delta_main raw data into element values is part of the resultset
API, as different implementations may employ different packing mechanisms.

=cut

sub main_elements {
    my ($this) = @_;
    my $delta_main = $this->delta_main;
    return undef if !defined $delta_main;
    my $sum = 0;
    my @elements = map { $sum += $_ } unpack 'w*', $delta_main;
    return \@elements;
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

=item *

L<Math::DifferenceSet::Planar::Data> - higher level data interface.

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2024 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

The licence grants freedom for related software development but does
not cover incorporating code or documentation into AI training material.
Please contact the copyright holder if you want to use the library whole
or in part for other purposes than stated in the licence.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
