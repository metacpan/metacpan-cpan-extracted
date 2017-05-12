use utf8;
package ExpenseTracker::Models::Result::OperationsCategory;
{
  $ExpenseTracker::Models::Result::OperationsCategory::VERSION = '0.008';
}
{
  $ExpenseTracker::Models::Result::OperationsCategory::VERSION = '0.008';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ExpenseTracker::Models::Result::OperationsCategory

=head1 VERSION

version 0.008

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<operations_categories>

=cut

__PACKAGE__->table("operations_categories");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 operation_id

  data_type: 'integer'
  is_nullable: 0

=head2 category_id

  data_type: 'integer'
  is_nullable: 0

=head2 created_at

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "operation_id",
  { data_type => "integer", is_nullable => 0 },
  "category_id",
  { data_type => "integer", is_nullable => 0 },
  "created_at",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-07-08 11:25:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G7xX9T5P0eIsnJYBw+9tUQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->belongs_to(operation => 'ExpenseTracker::Models::Result::Operation', 'operation_id');
__PACKAGE__->belongs_to(category => 'ExpenseTracker::Models::Result::Operation', 'category_id');
1;
