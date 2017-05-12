use utf8;
package Dwimmer::DB::Result::MailingList;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dwimmer::DB::Result::MailingList

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mailing_list>

=cut

__PACKAGE__->table("mailing_list");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 owner

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 from_address

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 response_page

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 validation_page

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 validation_response_page

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 validate_template

  data_type: 'blob'
  is_nullable: 1

=head2 confirm_template

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "owner",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "from_address",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "response_page",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "validation_page",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "validation_response_page",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "validate_template",
  { data_type => "blob", is_nullable => 1 },
  "confirm_template",
  { data_type => "blob", is_nullable => 1 },
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

=head2 owner

Type: belongs_to

Related object: L<Dwimmer::DB::Result::User>

=cut

__PACKAGE__->belongs_to(
  "owner",
  "Dwimmer::DB::Result::User",
  { id => "owner" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-15 11:13:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O3eO+tX90yadBcw36p61OQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
our $VERSION = '0.32';
1;
