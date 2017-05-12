use utf8;

package Interchange6::Schema::Result::Order;

=head1 NAME

Interchange6::Schema::Result::Order

=cut

use Interchange6::Schema::Candy -components => [qw(InflateColumn::DateTime)];

=head1 ACCESSORS

=head2 orders_id

Primary key.

=cut

primary_column orders_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "orders_orders_id_seq",
};

=head2 order_number

Unique representation of the order.

=cut

unique_column order_number => {
    data_type         => "varchar",
    size              => 24
};

=head2 order_date

Timestamp of when the order was placed. Is nullable.

=cut

column order_date => {
    data_type         => "timestamp",
    is_nullable       => 1
};

=head2 users_id

Foreign key constraint on L<Interchange6::Schema::Result::User/users_id>
via L</user> relationship.

=cut

column users_id => {
    data_type         => "integer",
};

=head2 email

Email address used for the order.  Default is empty string

=cut

column email => {
    data_type         => "varchar",
    default_value     => "",
    size              => 255
};

=head2 shipping_addresses_id

Foreign key constraint on L<Interchange6::Schema::Result::Address/addresses_id>
via L</shipping_address> relationship.

=cut

column shipping_addresses_id => {
    data_type         => "integer",
};

=head2 billing_addresses_id

Foreign key constraint on L<Interchange6::Schema::Result::Address/addresses_id>
via L</billing_address> relationship.

=cut

column billing_addresses_id => {
    data_type         => "integer",
};

=head2 weight

Total numeric weight of the order. Default is 0

=cut

column weight => {
    data_type         => "numeric",
    default_value     => 0,
    size              => [ 11, 3 ]
};

=head2 payment_method

This is the type of payment used for the order.

=cut

column payment_method => {
    data_type         => "varchar",
    default_value     => "",
    size              => 255
};

=head2 payment_number

A validation record for the payment.

=cut

column payment_number => {
    data_type         => "varchar",
    default_value     => "",
    size              => 255
};

=head2 payment_status

The status of the payment for the current order.

=cut

column payment_status => {
    data_type         => "varchar",
    default_value     => "",
    size              => 255
};

=head2 shipping_method

What shipping method was used for the order.

=cut

column shipping_method => {
    data_type         => "varchar",
    default_value     => "",
    size              => 255
};

=head2 subtotal

The sum of all items in the cart before tax and shipping costs.

Defaults to 0.

=cut

column subtotal => {
    data_type         => "numeric",
    default_value     => 0,
    size              => [ 21, 3 ],
};

=head2 shipping

The numeric cost associated with shipping the order. Default is 0

=cut

column shipping => {
    data_type         => "numeric",
    default_value     => 0,
    size              => [ 21, 3 ],
};

=head2 handling

The numeric cost associated with handling the order. Default is 0.

=cut

column handling => {
    data_type         => "numeric",
    default_value     => 0,
    size              => [ 21, 3 ],
};

=head2 salestax

The total tax applied to the order. Default is 0

=cut

column salestax => {
    data_type         => "numeric",
    default_value     => 0,
    size              => [ 21, 3 ],
};

=head2 total_cost

The total cost of all items shipping handling and tax for the order.
Default is 0.

=cut

column total_cost => {
    data_type         => "numeric",
    default_value     => 0,
    size              => [ 21, 3 ],
};

=head1 RELATIONS

=head2 shipping_address

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Address>

=cut

belongs_to
  shipping_address => "Interchange6::Schema::Result::Address",
  { addresses_id  => "shipping_addresses_id" };

=head2 billing_address

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Address>

=cut

belongs_to
  billing_address => "Interchange6::Schema::Result::Address",
  { addresses_id  => "billing_addresses_id" };

=head2 orderlines

Type: has_many

Related object: L<Interchange6::Schema::Result::Orderline>

=cut

has_many
  orderlines => "Interchange6::Schema::Result::Orderline",
  "orders_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 payment_orders

Type: has_many

Related object: L<Interchange6::Schema::Result::PaymentOrder>

=cut

has_many
  payment_orders => "Interchange6::Schema::Result::PaymentOrder",
  "orders_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 user

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to
  user => "Interchange6::Schema::Result::User",
  "users_id",
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

=head2 order_comments

Type: has_many

Related object: L<Interchange6::Schema::Result::OrderComment>

=cut

has_many
  order_comments => 'Interchange6::Schema::Result::OrderComment',
  'orders_id';

=head2 _comments

Type: many_to_many

This is considered a private method. Please see public L</comments> and L</add_to_comments> methods.

=cut

many_to_many _comments => "order_comments", "message";

=head2 statuses

Type: has_many

Related object: L<Interchange6::Schema::Result::OrderStatus>

=cut

has_many
  statuses => 'Interchange6::Schema::Result::OrderStatus',
  'orders_id';


=head1 METHODS

=head2 comments

=over 4
 
=item Arguments: none

=item Return Value: L<Interchange6::Schema::Result::Message> resultset.

=back
 
=cut

sub comments {
    return shift->_comments(@_);
}

=head2 add_to_comments

=over 4
 
=item Arguments: \%col_data
 
=item Return Value: L<Interchange6::Schema::Result::Message>
 
=back

See L<DBIx::Class::Relationship::Base/add_to_$rel> many_to_many for further details.

=cut

# much of this was cargo-culted from DBIx::Class::Relationship::ManyToMany

sub add_to_comments {
    my $self = shift;
    @_ > 0
      or $self->throw_exception("add_to_comments needs an object or hashref");
    my $rset_message = $self->result_source->schema->resultset("Message");
    my $obj;
    if ( ref $_[0] ) {
        if ( ref $_[0] eq 'HASH' ) {
            $_[0]->{type} = "order_comment";
            $obj = $rset_message->create( $_[0] );
        }
        else {
            $obj = $_[0];
            unless ( my $type = $obj->message_type->name eq "order_comment" ) {
                $self->throw_exception(
                    "cannot add message type $type to comments");
            }
        }
    }
    else {
        push @_, type => "order_comment";
        $obj = $rset_message->create( {@_} );
    }
    $self->create_related( 'order_comments', { messages_id => $obj->id } );
    return $obj;
}

=head2 set_comments

=over 4
 
=item Arguments: (\@hashrefs_of_col_data | \@result_objs)
 
=item Return Value: not defined
 
=back

Similar to L<DBIx::Class::Relationship::Base/set_$rel> except that this method D
OES delete objects in the table on the right side of the relation.

=cut

sub set_comments {
    my $self = shift;
    @_ > 0
      or $self->throw_exception(
        "set_comments needs a list of objects or hashrefs");
    my @to_set = ( ref( $_[0] ) eq 'ARRAY' ? @{ $_[0] } : @_ );
    $self->order_comments->delete_all;
    $self->add_to_comments( $_ ) for (@to_set);
}

=head2 delete

Overload delete to force removal of any order comments.

=cut

# FIXME: (SysPete) There ought to be a way to force this with cascade delete.

sub delete {
    my ( $self, @args ) = @_;
    my $guard = $self->result_source->schema->txn_scope_guard;
    $self->order_comments->delete_all;
    $self->next::method(@args);
    $guard->commit;
}

=head2 insert

Override insert so that if no L<Interchange6::Schema::Result::OrderStatus> has
been provided via multicreate then create a single status named C<new>.

=cut

sub insert {
    my ( $self, @args ) = @_;
    my $guard = $self->result_source->schema->txn_scope_guard;
    my $ret = $self->next::method(@args);
    if ( $self->statuses->count == 0 ) {
        $self->create_related('statuses', { status => 'new' });
    }
    $guard->commit;
    return $ret;
}

=head2 status

Option argument C<$status> will cause creation of a new related entry in
L<Interchange6::Schema::Result::OrderStatus>.

Returns the most recent L<Interchange6::Schema::Result::OrderStatus/status> or
undef if none are found.

If initial result set was created using
L<Interchange6::Schema::ResultSet::Order/with_status> then the status added
by that method will be returned so that a new query is not required.

=cut

sub status {
    my $self = shift;
    if ( @_ ) {
        return $self->statuses->create( { status => shift } )->status;
    }
    if ( $self->has_column_loaded('status')) {
        return $self->get_column('status');
    }
    else {
        my $status =
          $self->statuses->order_by('!created,!order_status_id')->rows(1)
          ->single;
        return $status ? $status->status : undef;
    }
}

1;
