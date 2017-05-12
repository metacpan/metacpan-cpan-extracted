use utf8;
package Dwimmer::DB::Result::Host;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dwimmer::DB::Result::Host

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<host>

=cut

__PACKAGE__->table("host");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 main

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "main",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 main

Type: belongs_to

Related object: L<Dwimmer::DB::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "main",
  "Dwimmer::DB::Result::Site",
  { id => "main" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-15 12:13:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Dyqv7/m0Kw2YqbPT4qZUqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
our $VERSION = '0.32';
1;
