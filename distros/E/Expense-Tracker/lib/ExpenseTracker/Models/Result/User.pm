use utf8;
package ExpenseTracker::Models::Result::User;
{
  $ExpenseTracker::Models::Result::User::VERSION = '0.008';
}
{
  $ExpenseTracker::Models::Result::User::VERSION = '0.008';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ExpenseTracker::Models::Result::User

=head1 VERSION

version 0.008

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0

=head2 password

  data_type: 'char'
  is_nullable: 0

=head2 email

  data_type: 'varchar'
  is_nullable: 0

=head2 first_name

  data_type: 'varchar'
  is_nullable: 1

=head2 last_name

  data_type: 'varchar'
  is_nullable: 1

=head2 birth_date

  data_type: 'datetime'
  is_nullable: 1

=head2 created_at

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0 },
  "password",
  { data_type => "char", is_nullable => 0 },
  "email",
  { data_type => "varchar", is_nullable => 0 },
  "first_name",
  { data_type => "varchar", is_nullable => 1 },
  "last_name",
  { data_type => "varchar", is_nullable => 1 },
  "birth_date",
  { data_type => "datetime", is_nullable => 1 },
  "created_at",
  { data_type => "datetime", is_nullable => 1 },
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

=head2 C<username_unique>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_unique", ["username"]);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-07-08 11:25:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JewiMTxAfKfxnGlQAXq/AA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->has_many(categories => 'ExpenseTracker::Models::Result::Category', 'user_id');
__PACKAGE__->has_many(operations => 'ExpenseTracker::Models::Result::Operation', 'user_id');

1;
