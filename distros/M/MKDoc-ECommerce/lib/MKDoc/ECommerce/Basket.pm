# -------------------------------------------------------------------------------------
# MKDoc::ECommerce::Basket
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This object represents a collection of Item objects.
# -------------------------------------------------------------------------------------
package MKDoc::ECommerce::Basket;
use strict;
use warnings;


##
# $class->new();
# --------------
# Instanciates a new basket object.
##
sub new
{
    my $class = shift;
    return bless { items => [] }, $class;
}


##
# $self->clear();
# ---------------
# Completely clears the shopping basket.
##
sub clear
{
    my $self = shift;
    $self->{items} = [];
}


##
# $self->add ($item);
# -------------------
# Adds $item in quantity $qty. If not specified,
# $qty defaults to 1.
##
sub add
{
    my $self = shift;
    my $item_to_add   = shift;
    my $item_existing = $self->item ($item_to_add);
    if ($item_existing)
    {
        $item_existing->set_quantity ($item_existing->quantity() + $item_to_add->quantity());
    }
    else
    {
        push @{$self->{items}}, $item_to_add;
    } 
}


##
# $self->delete ($item);
# ----------------------
# Deletes item $item from basket.
##
sub delete
{
    my $self = shift;
    my $ref  = shift;
    $ref = $ref->reference() if (ref $ref);
     
    my @items = @{$self->{items}};
    @items = map { ($_->reference() eq $ref) ? () : $_ } @items;
    $self->{items} = \@items;
}


##
# $self->items();
# ---------------
# Returns a list of items from the basket.
##
sub items
{
    my $self = shift;
    my @items = @{$self->{items}};
    return wantarray ? @items : \@items;
}


##
# $self->item ($ref_id);
# ----------------------
# Returns a particular item from the basket.
##
sub item
{
    my $self = shift;
    my $ref  = shift;
    $ref = $ref->reference() if (ref $ref);
    
    my @items = map { $_ ? $_ : () } @{$self->{items}};
    @items = map { ($_->reference() eq $ref) ? $_ : () } @items;
    
    return $items[0];
}


##
# $self->total();
# ---------------
# Returns the total price for the basket.
##
sub total
{
    my $self  = shift;
    my $total = 0;
    foreach my $item ($self->items()) { $total += $item->total() }
    return $total;
}


##
# $self->total_formatted();
# -------------------------
# Same as total(), but rounded at two decimals.
##
sub total_formatted
{
    my $self = shift;
    return sprintf ("%.2f", $self->total());
}


##
# $self->count();
# ---------------
# Counts the amount of items in the basket, including
# the quantities associated with these items.
##
sub count
{
    my $self  = shift;
    my $total = 0;
    foreach my $item ($self->items()) { $total += $item->quantity() }
    return $total;
}


sub set_quantity
{
    my $self = shift;
    my $ref  = shift;
    my $qty  = shift;
    my $item = $self->item ($ref) || return;
    $item->set_quantity ($qty);
}

1;


__END__
