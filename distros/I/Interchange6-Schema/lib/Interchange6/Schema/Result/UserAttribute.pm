use utf8;

package Interchange6::Schema::Result::UserAttribute;

=head1 NAME

Interchange6::Schema::Result::UserAttribute

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 user_attributes_id

Primary key.

=cut

primary_column user_attributes_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "user_attributes_user_attributes_id_seq",
};

=head2 users_id

FK on L<Interchange6::Schema::Result::User/users_id>.

=cut

column users_id =>
  { data_type => "integer" };

=head2 attributes_id

FK on L<Interchange6::Schema::Result::Attribute/attributes_id>.

=cut

column attributes_id =>
  { data_type => "integer" };

=head1 UNIQUE CONSTRAINT

=head2 users_id_attributes_id

=over 4

=item * L</users_id>

=item * L</attributes_id>

=back

=cut

unique_constraint users_id_attributes_id => [qw/users_id attributes_id/];

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to
  user => "Interchange6::Schema::Result::User",
  "users_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 attribute

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Attribute>

=cut

belongs_to
  attribute => "Interchange6::Schema::Result::Attribute",
  "attributes_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 user_attribute_values

Type: has_many

Related object: L<Interchange6::Schema::Result::UserAttributeValue>

=cut

has_many
  user_attribute_values => "Interchange6::Schema::Result::UserAttributeValue",
  "user_attributes_id",
  { cascade_copy => 0, cascade_delete => 0 };

1;
