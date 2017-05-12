use utf8;
package Dwimmer::DB::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dwimmer::DB::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 sha1

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 fname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 lname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 country

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 state

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 validation_key

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 verified

  data_type: 'bool'
  default_value: 0
  is_nullable: 1

=head2 register_ts

  data_type: 'integer'
  default_value: NOW
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "sha1",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "fname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "lname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "country",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "state",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "validation_key",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "verified",
  { data_type => "bool", default_value => 0, is_nullable => 1 },
  "register_ts",
  { data_type => "integer", default_value => \"NOW", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<email_unique>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("email_unique", ["email"]);

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 feed_collectors

Type: has_many

Related object: L<Dwimmer::DB::Result::FeedCollector>

=cut

__PACKAGE__->has_many(
  "feed_collectors",
  "Dwimmer::DB::Result::FeedCollector",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mailing_list_members

Type: has_many

Related object: L<Dwimmer::DB::Result::MailingListMember>

=cut

__PACKAGE__->has_many(
  "mailing_list_members",
  "Dwimmer::DB::Result::MailingListMember",
  { "foreign.listid" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mailing_lists

Type: has_many

Related object: L<Dwimmer::DB::Result::MailingList>

=cut

__PACKAGE__->has_many(
  "mailing_lists",
  "Dwimmer::DB::Result::MailingList",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 page_histories

Type: has_many

Related object: L<Dwimmer::DB::Result::PageHistory>

=cut

__PACKAGE__->has_many(
  "page_histories",
  "Dwimmer::DB::Result::PageHistory",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sites

Type: has_many

Related object: L<Dwimmer::DB::Result::Site>

=cut

__PACKAGE__->has_many(
  "sites",
  "Dwimmer::DB::Result::Site",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-15 11:13:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I+uSHIDCzdIcBAKD9j/weQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
our $VERSION = '0.32';
1;
