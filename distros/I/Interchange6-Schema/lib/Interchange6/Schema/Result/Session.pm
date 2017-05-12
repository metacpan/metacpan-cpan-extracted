use utf8;

package Interchange6::Schema::Result::Session;

=head1 NAME

Interchange6::Schema::Result::Session

=cut

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 ACCESSORS

=head2 sessions_id

Primary key.

=cut

primary_column sessions_id =>
  { data_type => "varchar", size => 255 };

=head2 session_data

Session data.

=cut

column session_data => { data_type => "text" };

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

=head2 carts

Type: has_many

Related object: L<Interchange6::Schema::Result::Cart>

=cut

has_many
  carts => "Interchange6::Schema::Result::Cart",
  "sessions_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 payment_orders

Type: has_many

Related object: L<Interchange6::Schema::Result::PaymentOrder>

=cut

has_many
  payment_orders => "Interchange6::Schema::Result::PaymentOrder",
  "sessions_id",
  { cascade_copy => 0, cascade_delete => 0 };

1;
