use utf8;

package Interchange6::Schema::Result::PriceModifier;

=head1 NAME

Interchange6::Schema::Result::PriceModifier

=head1 DESCRIPTION

Use cases:

=over

=item * group pricing based on L<roles|Interchange6::Schema::Result::Role>

=item * tier pricing (volume discounts)

=item * promotion/action pricing using L</start_date> and L</end_date>

=back

=cut

use Interchange6::Schema::Candy
  -components => [qw(InflateColumn::DateTime Helper::Row::OnColumnChange)];

=head1 ACCESSORS

=head2 price_modifiers_id

Primary key.

=cut

primary_column price_modifiers_id => {
    data_type         => "integer",
    is_auto_increment => 1,
};

=head2 sku

FK on L<Interchange6::Schema::Result::Product/sku>.

=cut

column sku =>
  { data_type => "varchar", size => 64 };

=head2 quantity

Minimum quantity at which price modifier applies (tier pricing).

Defaults to 0.

=cut

column quantity =>
  { data_type => "integer", default_value => 0 };

=head2 roles_id

FK on L<Interchange6::Schema::Result::Role/roles_id>.

Can be used for role-based pricing.

Is nullable.

=cut

column roles_id =>
  { data_type => "integer", is_nullable => 1 };

=head2 price

Price.

=cut

column price => {
    data_type     => "numeric",
    size          => [ 21, 3 ],
};

=head2 discount

Percent rate of discount. This is an alternative to setting L</price> directly.

B<NOTE:> It is not possible to create a new C<PriceModifier> record with both
L</price> and </percent> set in new/insert.

When L</discount> is set or updated the value of L</price> will be updated
accordingly based on the related L<Interchange6::Schema::Result::Product/price>.This is done using the method C<discount_changed>.

If related L<Interchange6::Schema::Result::Product/price> changes then the
modified L</price> will be updated.

Is nullable.

=cut

column discount => {
    data_type          => "numeric",
    size               => [ 7, 4 ],
    is_nullable        => 1,
    keep_storage_value => 1
};

before_column_change discount => {
    method => 'discount_changed',
    txn_wrap => 1,
};

=head2 start_date

The first date from which this modified price is valid.
Automatic inflation/deflation to/from L<DateTime>.

Is nullable.

=cut

column start_date => {
    data_type     => "date",
    is_nullable   => 1,
};

=head2 end_date

The last date on which this modified price is valid.
Automatic inflation/deflation to/from L<DateTime>.

Is nullable.

=cut

column end_date => {
    data_type     => "date",
    is_nullable   => 1,
};

=head1 RELATIONS

=head2 role

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Role>

=cut

belongs_to
  role => "Interchange6::Schema::Result::Role",
  "roles_id", { join_type => 'left', is_deferrable => 1 };

=head2 product

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Product>

=cut

belongs_to
  product => "Interchange6::Schema::Result::Product",
  "sku", { is_deferrable => 1 };

=head1 METHODS

=head2 insert

Throw exception if both L</price> and L</discount> have been supplied.

If L</discount> has been supplied then set L</price> based on related
<Interchange6::Schema::Result::Product/price>.

=cut

sub insert {
    my ( $self, @args ) = @_;

    if ( defined $self->discount ) {
        $self->throw_exception("Cannot set both price and discount")
          if defined $self->price;

        $self->price(
            sprintf( "%.2f",
                $self->product->price -
                  ( $self->product->price * $self->discount / 100 ) )
        );
    }

    $self->next::method(@args);
}

=head2 discount_changed

Called when L</discount> is updated.

=cut

sub discount_changed {
    my ( $self, $old_value, $new_value ) = @_;

    $self->price(
        sprintf( "%.2f",
            $self->product->price -
              ( $self->product->price * $new_value / 100 ) )
    );
}

1;
