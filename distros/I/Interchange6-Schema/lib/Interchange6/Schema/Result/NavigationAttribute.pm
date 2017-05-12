use utf8;

package Interchange6::Schema::Result::NavigationAttribute;

=head1 NAME

Interchange6::Schema::Result::NavigationAttribute

=cut

use Interchange6::Schema::Candy;

=head1 DESCRIPTION

Linker table for connecting the L<Interchange6::Schema::Result::Navigation> class
to the <Interchange6::Schema::Result::Attribute> class records.

=head1 ACCESSORS

=head2 navigation_attributes_id

Primary key.

=cut

primary_column navigation_attributes_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "navigation_attributes_navigation_attributes_id_seq",
};

=head2 navigation_id

Foreign key constraint on L<Interchange6::Schema::Result::Navigation/navigation_id>
via L</navigation> relationship.

=cut

column navigation_id => {
    data_type         => "integer",
};

=head2 attributes_id

Foreign key constraint on L<Interchange6::Schema::Result::Attribute/attribute_id>
via L</attribute> relationship.

=cut

column attributes_id => {
    data_type         => "integer",
};

=head1 UNIQUE CONSTRAINT

=head2 navigation_id_attributes_id

=over 4

=item * L</navigation_id>

=item * L</attributes_id>

=back

=cut

unique_constraint navigation_id_attributes_id =>
  [qw/navigation_id attributes_id/];

=head1 RELATIONS

=head2 navigation

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Navigation>

=cut

belongs_to
  navigation => "Interchange6::Schema::Result::Navigation",
  "navigation_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 attribute

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Attribute>

=cut

belongs_to
  attribute => "Interchange6::Schema::Result::Attribute",
  "attributes_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 navigation_attribute_values

Type: has_many

Related object: L<Interchange6::Schema::Result::NavigationAttributeValue>

=cut

has_many
  navigation_attribute_values =>
  "Interchange6::Schema::Result::NavigationAttributeValue",
  "navigation_attributes_id",
  { cascade_copy => 0, cascade_delete => 0 };

1;
