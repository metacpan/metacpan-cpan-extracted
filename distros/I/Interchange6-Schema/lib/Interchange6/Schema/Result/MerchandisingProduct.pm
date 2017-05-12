use utf8;

package Interchange6::Schema::Result::MerchandisingProduct;

=head1 NAME

Interchange6::Schema::Result::MerchandisingProduct

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 merchandising_products_id

Primary key.

=cut

primary_column merchandising_products_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "merchandising_products_merchandising_products_id_seq",
};

=head2 sku

FK on L<Interchange6::Schema::Result::Product/sku>

=cut

column sku =>
  { data_type => "varchar", size => 64 };

=head2 sku_related

FK on L<Interchange6::Schema::Result::Product/sku>

Is nullable.

=cut

column sku_related =>
  { data_type => "varchar", is_nullable => 1, size => 64 };

=head2 type

Type, e.g.: related, also_viewed, also_bought.

=cut

column type =>
  { data_type => "varchar", default_value => "", size => 32 };

=head1 UNIQUE CONSTRAINT

=head2 merchandising_products_sku_sku_related_type

=over 4

=item * L</sku>

=item * L</sku_related>

=item * L</type>

=back

=cut

unique_constraint merchandising_products_sku_sku_related_type =>
  [qw/sku sku_related type/];

=head1 RELATIONS

=head2 merchandising_attributes

Type: has_many

Related object: L<Interchange6::Schema::Result::MerchandisingAttribute>

=cut

has_many
  merchandising_attributes =>
  "Interchange6::Schema::Result::MerchandisingAttribute",
  "merchandising_products_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 product

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Product>

=cut

belongs_to
  product => "Interchange6::Schema::Result::Product",
  "sku",
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  };

=head2 product_related

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Product>

=cut

belongs_to
  product_related => "Interchange6::Schema::Result::Product",
  { sku => "sku_related" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  };

1;
