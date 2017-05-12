use utf8;
package Dwimmer::DB::Result::MailingListMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dwimmer::DB::Result::MailingListMember

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mailing_list_member>

=cut

__PACKAGE__->table("mailing_list_member");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 listid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 validation_code

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 approved

  data_type: 'bool'
  is_nullable: 1

=head2 register_ts

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "listid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "validation_code",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "approved",
  { data_type => "bool", is_nullable => 1 },
  "register_ts",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<validation_code_unique>

=over 4

=item * L</validation_code>

=back

=cut

__PACKAGE__->add_unique_constraint("validation_code_unique", ["validation_code"]);

=head1 RELATIONS

=head2 listid

Type: belongs_to

Related object: L<Dwimmer::DB::Result::User>

=cut

__PACKAGE__->belongs_to(
  "listid",
  "Dwimmer::DB::Result::User",
  { id => "listid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-15 11:14:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BA80gCbw2dnSgjjrxrjqLg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
our $VERSION = '0.32';
1;
