use utf8;
package Interchange6::Schema::Result::AttributeValue;

=head1 NAME

Interchange6::Schema::Result::AttributeValue

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 attribute_values_id

Primary key.

=cut

primary_column attribute_values_id => {
    data_type         => "integer",
    is_auto_increment => 1,
};

=head2 attributes_id

Foreign key constraint on
L<Interchange6::Schema::Result::Attribute/attributes_id>
via L</attribute> relationship.

=cut

column attributes_id => {
    data_type      => "integer",
};

=head2 value

Value name, e.g. red or white.

Required.

=cut

column value => {
    data_type   => "varchar",
    size        => 255,
};

=head2 title

Displayed title for attribute value, e.g. Red or White.

Defaults to same value as L</value> via L</new> method.

=cut

column title => {
    data_type     => "varchar",
    size          => 255,
};

=head2 priority

Display order priority.

Defaults to 0.

=cut

column priority => {
    data_type     => "integer",
    default_value => 0,
};

=head1 UNIQUE CONSTRAINT

=head2 attribute_values_attributes_id_value

=over 4

=item * L</attributes_id>

=item * L</value>

=back

=cut

unique_constraint attribute_values_attributes_id_value =>
  [qw/attributes_id value/];

=head1 RELATIONS

=head2 attribute

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Attribute>

=cut

belongs_to
  attribute => "Interchange6::Schema::Result::Attribute",
  { attributes_id => "attributes_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 product_attribute_values

Type: has_many

Related object: L<Interchange6::Schema::Result::ProductAttributeValue>

=cut

has_many
  product_attribute_values =>
  "Interchange6::Schema::Result::ProductAttributeValue",
  { "foreign.attribute_values_id" => "self.attribute_values_id" },
  { cascade_copy                  => 0, cascade_delete => 0 };

=head2 user_attribute_values

Type: has_many

Related object: L<Interchange6::Schema::Result::UserAttributeValue>

=cut

has_many
  user_attribute_values => "Interchange6::Schema::Result::UserAttributeValue",
  { "foreign.attribute_values_id" => "self.attribute_values_id" },
  { cascade_copy                  => 0, cascade_delete => 0 };

=head2 navigation_attribute_values

Type: has_many

Related object: L<Interchange6::Schema::Result::NavigationAttributeValue>

=cut

has_many
  navigation_attribute_values =>
  "Interchange6::Schema::Result::NavigationAttributeValue",
  { "foreign.attribute_values_id" => "self.attribute_values_id" },
  { cascade_copy                  => 0, cascade_delete => 0 };

=head1 METHODS

=head2 new

Set default value of L</title> to L</name>.

=cut

sub new {
    my ( $class, $attrs ) = @_;

    $attrs->{title} = $attrs->{value} unless defined $attrs->{title};

    my $new = $class->next::method($attrs);

    return $new;
}

1;
