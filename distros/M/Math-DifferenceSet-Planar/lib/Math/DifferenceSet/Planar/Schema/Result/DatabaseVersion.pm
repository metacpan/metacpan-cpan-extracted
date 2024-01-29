package Math::DifferenceSet::Planar::Schema::Result::DatabaseVersion;

=head1 NAME

Math::DifferenceSet::Planar::Schema::Result::DatabaseVersion -
planar difference set space database backend result class definition.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 VERSION

This documentation refers to version 1.001 of
Math::DifferenceSet::Planar::Schema::Result::DatabaseVersion.

=cut

our $VERSION = '1.001';

=head1 TABLE: C<database_version>

=cut

__PACKAGE__->table("database_version");

=head1 ACCESSORS

=head2 table_name

  data_type: 'varchar'
  is_nullable: 0

=head2 major

  data_type: 'integer'
  is_nullable: 0

=head2 minor

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "table_name",
  { data_type => "varchar", is_nullable => 0 },
  "major",
  { data_type => "integer", is_nullable => 0 },
  "minor",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</table_name>

=back

=cut

__PACKAGE__->set_primary_key("table_name");

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

Copyright (c) 2022-2023 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
