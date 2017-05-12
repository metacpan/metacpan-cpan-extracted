use utf8;
package ExpenseTracker::Models::Result::Category;
{
  $ExpenseTracker::Models::Result::Category::VERSION = '0.008';
}
{
  $ExpenseTracker::Models::Result::Category::VERSION = '0.008';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ExpenseTracker::Models::Result::Category

=head1 VERSION

version 0.008

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<categories>

=cut

__PACKAGE__->table("categories");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 parent_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 created_at

  data_type: 'datetime'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "parent_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  { data_type => "datetime", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-07-08 11:25:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q4inyXJmZPFAxtYf6421MA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->load_components(qw( Tree::AdjacencyList ));
 __PACKAGE__->parent_column('parent_id');
 __PACKAGE__->repair_tree( 1 );


__PACKAGE__->belongs_to(user => 'ExpenseTracker::Models::Result::User', 'user_id');
__PACKAGE__->has_many(operations_category => 'ExpenseTracker::Models::Result::OperationsCategory', 'category_id');
__PACKAGE__->many_to_many(operations => 'operations_category', 'operation');

1;
