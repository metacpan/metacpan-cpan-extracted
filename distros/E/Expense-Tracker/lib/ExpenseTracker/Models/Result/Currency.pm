use utf8;
package ExpenseTracker::Models::Result::Currency;
{
  $ExpenseTracker::Models::Result::Currency::VERSION = '0.008';
}
{
  $ExpenseTracker::Models::Result::Currency::VERSION = '0.008';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ExpenseTracker::Models::Result::Currency

=head1 VERSION

version 0.008

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<currencies>

=cut

__PACKAGE__->table("currencies");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0

=head2 created_at

  data_type: 'datetime'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0 },
  "created_at",
  { data_type => "datetime", is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-07-08 11:25:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qgVf69rpVeN01oZaokn4Sw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->has_many(operations => 'ExpenseTracker::Models::Result::Operation', 'currency_id');
1;
