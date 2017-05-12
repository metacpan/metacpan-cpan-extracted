use utf8;
package Interchange6::Schema::Result::Attribute;

=head1 NAME

Interchange6::Schema::Result::Attribute

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 attributes_id

Primary key.

=cut

primary_column attributes_id => {
    data_type         => "integer",
    is_auto_increment => 1,
};

=head2 name

Attribute name, e.g. color or size.

Required.

=cut

column name => {
    data_type   => "varchar",
    size        => 255,
};

=head2 type

Attribute type, e.g. variant.

Defaults to empty string.

=cut

column type => {
    data_type     => "varchar",
    default_value => "",
    size          => 255,
};

=head2 title

Displayed title for attribute name, e.g. Color or Size.

Defaults to same value as L</name> via L</new> method.

=cut

column title => {
    data_type     => "varchar",
    size          => 255,
};

=head2 dynamic

Boolean flag to designate the attribute as being dynamic.

Defaults to false.

=cut

column dynamic => {
    data_type     => "boolean",
    default_value => 0,
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

=head2 attributes_name_type

=over 4

=item * L</name>

=item * L</type>

=back

=cut

unique_constraint attributes_name_type => [qw/name type/];

=head1 RELATIONS

=head2 attribute_values

Type: has_many

Related object: L<Interchange6::Schema::Result::AttributeValue>

=cut

has_many
  attribute_values => "Interchange6::Schema::Result::AttributeValue",
  { "foreign.attributes_id" => "self.attributes_id" },
  { cascade_copy            => 0, cascade_delete => 0 };

=head2 product_attributes

Type: has_many

Related object: L<Interchange6::Schema::Result::ProductAttribute>

=cut

has_many
  product_attributes => "Interchange6::Schema::Result::ProductAttribute",
  { "foreign.attributes_id" => "self.attributes_id" },
  { cascade_copy            => 0, cascade_delete => 0 };

=head2 navigation_attributes

Type: has_many

Related object: L<Interchange6::Schema::Result::NavigationAttribute>

=cut

has_many
  navigation_attributes => "Interchange6::Schema::Result::NavigationAttribute",
  { "foreign.attributes_id" => "self.attributes_id" },
  { cascade_copy            => 0, cascade_delete => 0 };

=head1 METHODS

=head2 new

Set default value of L</title> to L</name>.

=cut

sub new {
    my ( $class, $attrs ) = @_;

    $attrs->{title} = $attrs->{name} unless defined $attrs->{title};

    my $new = $class->next::method($attrs);

    return $new;
}

1;
