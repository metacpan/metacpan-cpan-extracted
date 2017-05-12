# -------------------------------------------------------------------------------------
# MKDoc::ECommerce::Item
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This class represents an item, i.e. a price component attached to an MKDoc
# document which describes a certain product.
# -------------------------------------------------------------------------------------
package MKDoc::ECommerce::Item;
use Digest::MD5 qw(md5_hex);
use warnings;
use strict;

use constant MD5_SECRET => $ENV{ECOMMERCE_SECRET_ITEM} || $ENV{ECOMMERCE_SECRET} || 'SHHHT! It is a SECRET!';


##
# $class->new (%args);
# --------------------
# Creates a new Item from a given price component.
# An item is an object which lives in the shopping basket.
#
# Arguments should look like:
#
# reference   => $ref_id,
# description => $desc,
# unit_price  => $price,
# quantity    => $quantity,
# signature   => $md5_sig,
##
sub new
{
    my $class  = shift;
    my $self   = bless { @_ }, $class;
    $self->validate() && return $self;
    return;
}


sub reference
{
    my $self = shift;
    return $self->{reference};
}


sub description
{
    my $self = shift;
    return $self->{description};
}


sub unit_price
{
    my $self = shift;
    return $self->{unit_price};
}


sub quantity
{
    my $self = shift;
    return $self->{quantity};
}


sub set_quantity
{
    my $self = shift;
    $self->{quantity}  = shift;
    $self->{signature} = $self->sign();
}


sub signature
{
    my $self = shift;
    return $self->{signature};
}


sub sign
{
    my $self = shift;
    my $secret = $ENV{ECOMMERCE_SECRET_ITEM} || $ENV{ECOMMERCE_SECRET} || 'SHHHT! It is a SECRET!';
    my $string = join ':', ( $secret,
                             $self->reference()   || '',
                             $self->description() || '',
                             $self->unit_price()  || '',
                             $self->quantity()    || '' );

    return md5_hex ($string);
}


sub validate
{
    my $self = shift;
    $self->reference()   || return 0;
    $self->description() || return 0;
    $self->unit_price()  || return 0;
    $self->quantity()    || return 0;
    $self->signature()   || return 1;
    return $self->signature() eq $self->sign();
}


sub total
{
    my $self = shift;
    return $self->unit_price() * $self->quantity();
}


sub total_formatted
{
    my $self = shift;
    return sprintf ("%.2f", $self->total());
}


1;


__END__
