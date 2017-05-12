package Interchange6::Cart::Cost;

use Interchange6::Types -types;

use Moo;
use namespace::clean;

=head1 NAME 

Interchange6::Cart::Cost - Cart cost class for Interchange6 Shop Machine

=head1 DESCRIPTION

Cart cost class for L<Interchange6>.

=head1 ATTRIBUTES

=head2 id

Cart id can be used for subclasses, e.g. primary key value for cart or product costs in the database.

=cut

has id => (
    is => 'ro',
    isa => Int,
);

=head2 name

Unique name is required.

=cut

has name => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

=head2 label

Label for display. Default is same value as label.

=cut

has label => (
    is  => 'lazy',
    isa => NonEmptyStr,
);

sub _build_label {
    my $self = shift;
    return $self->name;
};

=head2 relative

Boolean defaults to 0. If true then L<amount> is relative to L<object subtotal|Intechange6::Role::Cost/subtotal>. If false then L<amount> is an absolute cost.

=cut

has relative => (
    is      => 'ro',
    isa     => Defined & Bool,
    default => 0,
);

=head2 inclusive

Boolean defaults to 0. If true signifies that the cost is already included in the price for example to calculate the tax component for gross prices.

=cut

has inclusive => (
    is      => 'ro',
    isa     => Defined & Bool,
    default => 0,
);

=head2 compound

Boolean defaults to 0. If true signifies that any following costs should be applied to the modified price B<after> this cost has been applied. This might be used for such things as discounts which are applied before taxes are applied to the modified price.

Using L</compound> along with L</inclusive> makes no sense and no guarantee is
given as to what the result might be.

=cut

has compound => (
    is      => 'ro',
    isa     => Defined & Bool,
    default => 0,
);

=head2 amount

Required amount of the cost. This is the absolute cost unless L</relative> is true in which case it is relative to the L<object subtotal|Interchange6::Role::Cost/subtotal>. For example for a tax of 8% amount should be set to 0.08

=cut

has amount => (
    is      => 'ro',
    isa     =>  Defined & Num,
    required => 1,
);

=head2 current_amount

Calculated current amount of cost. Unless L</relative> is true this will be the same as L</amount>. If L</relative> is true then this is value is recalulated whenever C<total> is called on the object.

=over

=item Writer: C<set_current_amount>

=back

=cut

has current_amount => (
    is     => 'ro',
    isa    => Num,
    coerce => sub { defined $_[0] && sprintf( "%.2f", $_[0] ) },
    writer => 'set_current_amount',
);

1;
