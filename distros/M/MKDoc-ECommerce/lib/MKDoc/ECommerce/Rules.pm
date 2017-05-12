# -------------------------------------------------------------------------------------
# MKDoc::ECommerce::Rules
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# Billing Rules can become very, very complicated and ugly. This module attempts to
# sort of sort out this ugly mess.
# -------------------------------------------------------------------------------------
package MKDoc::ECommerce::Rules;
use MKDoc::Control_List;
use strict;
use warnings;

our @LIST = ();
our $Self = undef;


sub no_warnings { $::Rules }


sub new
{
    my $class = shift;
    my $self  = bless { @_ }, $class;
}


# returns a list of hashes comprising three fields:
# { title  => $title
#   desc   => $description
#   amount => $new_amount }
sub explain
{
    my $self = shift;
    my $billing = $ENV{ECOMMERCE_BILLING_RULES} || $ENV{MKDOC_DIR} . '/conf/ecommerce.list.conf';
    
    # no rules specified? return the total price...
    my @res = { amount => $self->{basket}->total() };
    $billing && -e $billing || return wantarray ? @res : \@res;
    
    my $control = new MKDoc::Control_List ( file => $billing );
    $::Rules = $self;
    
    @res = $control->process();

    my $prev = $self->{basket}->total();
    for (@res)
    {
        $_->{title}  = $_->{title}->($prev)  if ( ref $_->{title} );
        $_->{desc}   = $_->{desc}->($prev)   if ( ref $_->{desc} );
        $_->{amount} = $_->{amount}->($prev) if ( ref $_->{amount} );
        $prev = $_->{amount};
    }

    return wantarray ? @res : \@res;
}


sub deal_price
{
    my $self    = shift;
    my @results = reverse $self->explain();
    return $results[0]->{amount};
}


1;


__END__
