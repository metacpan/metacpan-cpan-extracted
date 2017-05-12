use utf8;

package Interchange6::Schema::Result::PaymentOrder;

=head1 NAME

Interchange6::Schema::Result::PaymentOrder

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 DESCRIPTION

The C<payment_sessions_id> is used to store the session id provided by the gateway.
For example, with L<Business::OnlinePayment::IPayment> you put the session id into
the HTML form for the silent CGI mode.

The C<sessions_id> is used here so we can track down payments without orders.
We usually turn a guest user into a real user after confirmation of a successful payment,
so we need the session information here in the case the payment is made but
the confirmation didn't reach the online shop.

=head1 ACCESSORS

=head2 payment_orders_id

Primary key.

=cut

primary_column payment_orders_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "payment_orders_payment_orders_id_seq",
};

=head2 payment_mode

Payment mode, e.g.: PayPal.

Defaults to empty string.

=cut

column payment_mode =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 payment_action

Payment action, e.g.: charge.

Defaults to empty string.

=cut

column payment_action =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 payment_id

Payment ID.

Defaults to empty string.

=cut

column payment_id =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 auth_code

Payment auth code.

Defaults to empty string.

=cut

column auth_code => {
    data_type     => "varchar",
    default_value => "",
    size          => 255
};

=head2 users_id

FK on L<Interchange6::Schema::Result::User/users_id>.

Is nullable.

=cut

column users_id =>
  { data_type => "integer", is_nullable => 1 };

=head2 sessions_id

FK on L<Interchange6::Schema::Result::Session/sessions_id>.

Is nullable.

=cut

column sessions_id => {
    data_type      => "varchar",
    is_nullable    => 1,
    size           => 255
};

=head2 orders_id

FK on L<Interchange6::Schema::Result::Order/orders_id>.

Is nullable.

=cut

column orders_id =>
  { data_type => "integer", is_nullable => 1 };

=head2 amount

Amount of payment.

Defaults to 0.

=cut

column amount => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 21, 3 ],
};

=head2 status

Status of this payment.

Defaults to empty string.

=cut

column status =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 payment_sessions_id

FK on L<Interchange::Schema::Result::Session/sessions_id>.

=cut

column payment_sessions_id => {
    data_type     => "varchar",
    default_value => "",
    size          => 255
};

=head2 payment_error_code

Error message returned from payment gateway.

Defaults to empty string.

=cut

column payment_error_code =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 payment_error_message

Error message returned from payment gateway.

Is nullable.

=cut

column payment_error_message => { data_type => "text", is_nullable => 1 };

=head2 payment_fee

Some gateways (notably PayPal) charge a fee for each transaction. This
column should be used to store the transaction fee (if any).

=cut

column payment_fee => {
    data_type     => "numeric",
    default_value => 0,
    size          => [ 12, 3 ],
};

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created =>
  { data_type => "datetime", set_on_create => 1 };

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type     => "datetime",
    set_on_create => 1,
    set_on_update => 1,
};

=head1 RELATIONS

=head2 order

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Order>

=cut

belongs_to
  order => "Interchange6::Schema::Result::Order",
  "orders_id",
  {
    is_deferrable => 1,
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
    join_type     => "left"
  };

=head2 user

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to
  user => "Interchange6::Schema::Result::User",
  "users_id",
  {
    is_deferrable => 1,
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
    join_type     => "left"
  };

=head2 session

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Session>

=cut

belongs_to
  session => "Interchange6::Schema::Result::Session",
  "sessions_id",
  { join_type => 'left', on_delete => 'SET NULL' };

1;
