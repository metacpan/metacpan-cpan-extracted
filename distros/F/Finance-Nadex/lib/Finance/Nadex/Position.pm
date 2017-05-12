package Finance::Nadex::Position;

use 5.006;
use strict;
use warnings FATAL => 'all';

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
        return undef;
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

sub id {

    my $self = shift;

    if ( exists $self->{id} ) {
        return $self->{id};
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

    return;
}

sub _new {

    my $hashref = shift;

    my $self = {};

    if ( exists $hashref->{'market'} && exists $hashref->{'position'} ) {
        $self->{direction} = $hashref->{'position'}->{'direction'}    || undef;
        $self->{price}     = $hashref->{'position'}->{'openLevel'}    || undef;
        $self->{id}        = $hashref->{'position'}->{'dealId'}       || undef;
        $self->{epic}      = $hashref->{'position'}->{'epic'}         || undef;
        $self->{contract}  = $hashref->{'market'}->{'instrumentName'} || undef;
        $self->{bid}   = $hashref->{'market'}->{'displayBid'}   || 'NoBid';
        $self->{offer} = $hashref->{'market'}->{'displayOffer'} || 'NoOffer';
        $self->{size}  = $hashref->{'position'}->{'dealSize'}   || undef;
    }
    elsif (exists $hashref->{'order'}
        && exists $hashref->{'instrument'}
        && $hashref->{'marketSnapshot'} )
    {
        $self->{direction} = $hashref->{'order'}->{'direction'}       || undef;
        $self->{price}     = $hashref->{'order'}->{'openingLevel'}    || undef;
        $self->{id}        = $hashref->{'order'}->{'id'}              || undef;
        $self->{epic}      = $hashref->{'instrument'}->{'epic'}       || undef;
        $self->{contract}  = $hashref->{'instrument'}->{'marketName'} || undef;
        $self->{bid} = $hashref->{'marketSnapshot'}->{'displayBid'} || 'NoBid';
        $self->{offer} =
          $hashref->{'marketSnapshot'}->{'displayOffer'} || 'NoOffer';
        $self->{size} = $hashref->{'order'}->{'size'} || undef;
    }
    else { return undef }

    return bless $self, __PACKAGE__;
}

=head1 NAME

Finance::Nadex::Position - Retrieve details about an open position(a filled order) on the North American Derivatives Exchange

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Container for information about positions; used by L<Finance::Nadex>; not meant to be instantiated
directly in client code; certain methods in L<Finance::Nadex> return an instance or list of Finance::Nadex::Position
objects;  given an instance of Finance::Nadex::Position, the following methods can be used to access
information in the instance; see L<Finance::Nadex> for information on the methods used to retrieve positions

=head1 ACCESSORS

=head2 bid

Retrieves the current high bid for the contract

=head2 contract

Retrieves the name of the contract 

=head2 direction

Retrieves the direction of the position: either 'buy' or 'sell'

=head2 epic

Retrieves the unique identifier for the contract associated with the position

=head2 id

The id created by the exchange for the position

=head2 offer

Retrieves the current low offer for the contract

=head2 price

Retrieves the price level at which the position was entered (either bought or sold)

=head2 size

Retrieves the number of contracts bought or sold to create the position


=head1 AUTHOR

mhandisi, C<< <mhandisi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nadex-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nadex-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Nadex::Position


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

42;    # End of Finance::Nadex::Position
