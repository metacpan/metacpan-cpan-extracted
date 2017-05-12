package Finance::Nadex::Order;

use 5.006;
use strict;
use warnings FATAL => 'all';

sub id {

    my $self = shift;

    if ( exists $self->{id} ) {
        return $self->{id};
    }

    return;
}

sub bid {

    my $self = shift;

    if ( exists $self->{bid} ) {
        return $self->{bid};
    }

    return;
}

sub contract {

    my $self = shift;

    if ( exists $self->{contract} ) {
        return $self->{contract};
    }

    return;
}

sub direction {

    my $self = shift;

    if ( exists $self->{direction} ) {
        return 'buy'
          if $self->{direction} eq '+' || $self->{direction} eq 'buy';
        return 'sell'
          if $self->{direction} eq '-' || $self->{direction} eq 'sell';
        return;
    }

    return;
}

sub epic {

    my $self = shift;

    if ( exists $self->{epic} ) {
        return $self->{epic};
    }

    return;

}

sub offer {

    my $self = shift;

    if ( exists $self->{offer} ) {
        return $self->{offer};
    }

    return;
}

sub price {

    my $self = shift;

    if ( exists $self->{price} ) {
        return $self->{price};
    }

    return;

}

sub size {

    my $self = shift;

    if ( exists $self->{size} ) {
        return $self->{size};
    }
}

sub _new {

    my $hashref = shift;

    my $self = {};

    if ( exists $hashref->{'market'} && exists $hashref->{'workingOrder'} ) {
        $self->{direction} = $hashref->{'workingOrder'}->{'direction'} || undef;
        $self->{price}     = $hashref->{'workingOrder'}->{'level'}     || undef;
        $self->{id}        = $hashref->{'workingOrder'}->{'dealId'}    || undef;
        $self->{epic}      = $hashref->{'workingOrder'}->{'epic'}      || undef;
        $self->{contract}  = $hashref->{'market'}->{'instrumentName'}  || undef;
        $self->{bid}   = $hashref->{'market'}->{'displayBid'}   || 'NoBid';
        $self->{offer} = $hashref->{'market'}->{'displayOffer'} || 'NoOffer';
        $self->{size}  = $hashref->{'workingOrder'}->{'size'}   || undef;
    }
    elsif (exists $hashref->{'order'}
        && exists $hashref->{'instrument'}
        && $hashref->{'marketSnapshot'} )
    {
        $self->{direction} = $hashref->{'order'}->{'direction'}       || undef;
        $self->{price}     = $hashref->{'order'}->{'triggerLevel'}    || undef;
        $self->{id}        = $hashref->{'order'}->{'id'}              || undef;
        $self->{epic}      = $hashref->{'instrument'}->{'epic'}       || undef;
        $self->{contract}  = $hashref->{'instrument'}->{'marketName'} || undef;
        $self->{bid} = $hashref->{'marketSnapshot'}->{'displayBid'} || 'NoBid';
        $self->{offer} =
          $hashref->{'marketSnapshot'}->{'displayOffer'} || 'NoOffer';
        $self->{size} = $hashref->{'order'}->{'size'} || undef;
    }
    else { return }

    return bless $self, __PACKAGE__;
}

=head1 NAME

Finance::Nadex::Order - Provides information about an order on the North American Derivatives Exchange

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Container for information about orders; used by L<Finance::Nadex>; not meant to be instantiated
directly in client code; certain methods in L<Finance::Nadex> return a Finance::Nadex::Order or a list
of Finance::Nadex::Order objects; given an instance or a list of instances, the accessor methods
below can be used to retrieve information about the order; 
see L<Finance::Nadex> for information on how to retrieve an order

=head1 ACCESSORS

=head2 bid

Retrieves the current high bid for the contract (example: "34.50")

=head2 contract

Retrieves the name of the contract (example: "GBP/USD >1.5120 (3PM)")

=head2 direction

Retrieves the direction of the order instance; either 'buy' or 'sell'

=head2 epic

Retrieves the unique identifier for the contract created by the exchange (example: "NB.D.OPT-GBP-USD-1-20-12Jan15")

=head2 id

Retrieves the order id for the order instance (example: "NZ34DE908QZASW")

=head2 offer

Retrieves the current low offer for the contract (example: "50.00")

=head2 price

Retrieves the price at which the contract is to be bought or sold (example: "30.00")

=head2 size

Retrieves the number of contracts to be bought or sold (example: "2")

=head1 AUTHOR

mhandisi, C<< <mhandisi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nadex-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nadex-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Nadex::Order


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nadex-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nadex-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nadex-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Nadex-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 mhandisi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

42;    # End of Finance::Nadex::Order
