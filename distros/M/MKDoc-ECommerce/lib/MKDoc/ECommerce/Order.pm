# -------------------------------------------------------------------------------------
# MKDoc::ECommerce::Order
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This class represents an order. An order is connected to a basket object (which
# represents a list of products ordered), a delivery address (an Address object),
# a country of delivery, and a tactic for zone delivery and shipping rules.
# -------------------------------------------------------------------------------------
package MKDoc::ECommerce::Order;
use strict;
use warnings;
use MKDoc::ECommerce::Rules;
use MKDoc::ECommerce::Basket;
use MKDoc::ECommerce::Address;

use Petal::Mail; 
use Petal;


##
# $class->new (%args);
# --------------------
# Constructs a new Address object, comprising:
#
# session_id => $session_id
# address    => $address_object
# basket     => $shopping_basket
##
sub new
{
    my $class = shift;
    my $self  = bless { @_ }, $class;
    $self->{timestamp}  = time();
    
    my $rules = new MKDoc::ECommerce::Rules (
        session => $self->{session},
        basket  => $self->{basket},
        address => $self->{address},

        subtotal => $self->{basket}->total(),
        country  => $self->{address}->country(),
    );

    $self->{deal_price} = $rules->deal_price();
    
    $self->save();
    return $self;
}


sub is_pending
{
    my $self = shift;
    $self->is_accepted() && return;
    $self->is_rejected() && return;
    return 1;
}


sub is_accepted
{
    my $self = shift;
    return $self->{is_accepted};
}


sub is_rejected
{
    my $self = shift;
    return $self->{is_rejected};
}


sub accept
{
    my $self = shift;
    $self->is_pending() || return;
    $self->_accept_send_mail_merchant();
    $self->_accept_send_mail_customer();
    $self->_accept_clear_session();
    $self->{is_accepted} = 1;
    $self->save();
}


sub reject
{
    my $self = shift;
    $self->is_pending() || return;
    $self->_reject_send_mail_merchant();
    $self->_reject_send_mail_customer();
    $self->{is_rejected} = 1;
    $self->save();
}


sub _reject_send_mail_customer
{
    my $self = shift;
    my $mail = new Petal::Mail (
        file => 'shop/email/reject_customer',
        lang => flo::Standard::current_document()->language(),
    );
    
    $mail->send (self => $self);
}


sub _reject_send_mail_merchant
{
    my $self = shift;
    my $mail = new Petal::Mail (
        file => 'shop/email/reject_merchant',
        lang => flo::Standard::current_document()->language(),
    );
    
    $mail->send (self => $self);
}


sub _accept_send_mail_customer
{
    my $self = shift;
    my $mail = new Petal::Mail (
        file => 'shop/email/accept_customer',
        lang => flo::Standard::current_document()->language(),
    );
    
    $mail->send (self => $self);
}


sub _accept_send_mail_merchant
{
    my $self = shift;
    my $mail = new Petal::Mail (
        file => 'shop/email/accept_merchant',
        lang => flo::Standard::current_document()->language(),
    );
    
    $mail->send (self => $self);
}


sub _accept_clear_session
{
    my $self = shift;
    my $session = $self->session() || return; 
    $session->{basket}->clear();
    $session->save();
}


sub session
{
    my $self = shift;
    return MKDoc::Session->load ( $self->{session_id} ) || return;
}


sub date_placed
{
    my $self = shift;
    my $time = $self->{timestamp};
     
    #  0    1    2     3     4    5     6     7     8
    # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
    my @time = localtime ($time);
 
    $time[4] += 1;
    $time[4] = "0$time[4]" unless (length ($time[4]) == 2);
     
    $time[5] += 1900;
    $time[2] = "0$time[2]" unless (length ($time[2]) == 2);
    $time[1] = "0$time[1]" unless (length ($time[1]) == 2);
    $time[0] = "0$time[0]" unless (length ($time[0]) == 2);
     
    return "$time[5]-$time[4]-$time[3] $time[2]:$time[1]:$time[0]";
}


sub admin_user { return flo::Standard::table ('Editor')->get ( Login => 'admin') } 


sub root       { return flo::Standard::table ('Document')->get ( Full_Path => '/' ) } 
 
sub _gen_id
{
    my $class = shift;
    my $time  = time();
    my ($_1, $_2, $_3, $_4) = $time =~ /(.)(...)(...)(...)/;
    my $r1 = join '', map { uc (chr (ord ('a') + int (rand 26))) } 1..3;
     
    return "$_1-$_2-$_3-$_4-$r1";
}


1;


__END__
