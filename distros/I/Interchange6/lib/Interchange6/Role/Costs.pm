package Interchange6::Role::Costs;

use Carp;
use Interchange6::Cart::Cost;
use Interchange6::Types -types;

use Moo::Role;
use MooX::HandlesVia;
use MooseX::CoverableModifiers;

=head1 ATTRIBUTES

=head2 costs

Holds an array reference of L<Interchange::Cart::Cost> items.

When called without arguments returns an array reference of all costs associated with the object. Costs are ordered according to the order they were applied.

=cut

has costs => (
    is          => 'ro',
    isa         => ArrayRef[CartCost],
    coerce      => 1,
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        apply_cost  => 'push',
        clear_costs => 'clear',
        cost_get    => 'get',
        cost_set    => 'set',
        cost_count  => 'count',
        get_costs   => 'elements',
    },
    init_arg => undef,
);

after 'clear_costs', 'cost_set', 'apply_cost' => sub {
    shift->clear_total;
};

=head2 total

Returns the sum of the objects L</costs> added to its C<subtotal>.

=cut

has total => (
    is        => 'lazy',
    isa       => Num,
    clearer   => 1,
    predicate => 1,
);

sub _build_total {
    my $self = shift;

    my @costs    = $self->get_costs;
    my $subtotal = $self->subtotal;

    my $sum      = 0;
    foreach my $i ( 0 .. $#costs ) {

        if ( $costs[$i]->relative ) {
            $costs[$i]->set_current_amount( $subtotal * $costs[$i]->amount );
        }
        else {
            $costs[$i]->set_current_amount( $costs[$i]->amount );
        }

        if ( $costs[$i]->compound ) {
            $subtotal += $costs[$i]->current_amount;
        }
        elsif ( !$costs[$i]->inclusive ) {
            $sum += $costs[$i]->current_amount;
        }
    }

    return sprintf( "%.2f", $subtotal + $sum );
}

=head1 METHODS

=head2 clear_costs

Removes all the costs previously applied (using apply_cost). Used typically if you have free shipping or something similar, you can clear the costs.

This method also calls L</clear_total>.

=head2 clear_total

Clears L</total>.

=head2 cost_get($index)

Returns an element of the array of costs for the object by its index. You can also use negative index numbers, just as with Perl's core array handling.

=head2 cost_count

Returns the number of cost elements for the object.

=head2 get_costs

Returns all of the cost elements for the object as an array (not an arrayref).

=head2 cost_set($index, $cost)

Sets the cost at C<$index> to <$cost>.

This method also calls L</clear_total>.

=head2 has_total

predicate on L</total>.

=head2 apply_cost

Apply cost to object. L</apply_cost> is a generic method typicaly used for taxes, discounts, coupons, gift certificates, etc.

B<NOTE:> This method also calls L</clear_total>.

B<Example:> Absolute cost

Uses absolute value for amount. Amount 5 is 5 units of currency used (i.e. $5).

    $cart->apply_cost(amount => 5, name => 'shipping', label => 'Shipping');

B<Example:> Relative cost

Uses percentage instead of value for amount. Relative is a boolean value (0/1).

    Add 19% German VAT:

    $cart->apply_cost(
        amount => 0.19, name => 'tax', label => 'VAT', relative => 1
    );

    Add 10% discount (negative amount):

    $cart->apply_cost(
        amount => -0.1, name => 'discount', label => 'Discount', relative => 1
    );


B<Example:> Inclusive cost

Same as relative cost, but it assumes that tax was included in the subtotal already, and only displays it (19% of subtotal value in example). Inclusive is a boolean value (0/1).

        $cart->apply_cost(amount => 0.19, name => 'tax', label => 'Sales Tax', relative => 1, inclusive => 1);

=cut

around apply_cost => sub {
    my ( $orig, $self, @args ) = @_;

    croak "argument to apply_cost undefined" unless defined $args[0];

    my $cost = CartCost->check( $args[0] ) ? $args[0] : CartCost->coerce(@args);

    $orig->($self, $cost);
};

=head2 cost

Returns particular cost by position or by name.

B<Example:> Return tax value by name

  $cart->cost('tax');

Returns value of the tax (absolute value in your currency, not percentage)

B<Example:> Return tax value by position

  $cart->cost(0);

Returns the cost that was first applied to subtotal. By increasing the number you can retrieve other costs applied.

=cut

sub cost {
    my ( $self, $loc ) = @_;
    my ( $cost, $ret );

    if ( defined $loc ) {
        if ( $loc =~ /^\d+$/ ) {

            # cost by position
            $cost = $self->cost_get($loc);
        }
        elsif ( $loc =~ /\S/ ) {

            # cost by name
            for my $c ( $self->get_costs ) {
                if ( $c->name eq $loc ) {
                    $cost = $c;
                }
            }
        }
    }
    else {
        croak "Either position or name required as argument to cost";
    }

    if ( defined $cost ) {
        # calculate total in order to reset all costs
        $self->total;
    }
    else {
        croak "Bad argument to cost: " . $loc;
    }

    return $cost->current_amount;
}

1;
