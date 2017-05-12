package Finance::Nadex::Contract;

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

sub bidsize {

    my $self = shift;

    if ( exists $self->{bidsize} ) {
        return $self->{bidsize};
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

sub epic {

    my $self = shift;

    if ( exists $self->{epic} ) {
        return $self->{epic};
    }

    return;
}

sub expirydate {

    my $self = shift;

    if ( exists $self->{expirydate} ) {
        return $self->{expirydate};
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

sub offersize {

    my $self = shift;

    if ( exists $self->{offersize} ) {
        return $self->{offersize};
    }

    return;
}

sub type {

    my $self = shift;

    if ( exists $self->{type} ) {
        return $self->{type};
    }

    return;
}

sub _new {

    my $hashref = shift;

    my $self = {};

    $self->{offer}      = $hashref->{displayOffer}         || 'NoOffer';
    $self->{bid}        = $hashref->{displayBid}           || 'NoBid';
    $self->{contract}   = $hashref->{instrumentName}       || undef;
    $self->{epic}       = $hashref->{epic}                 || undef;
    $self->{type}       = lc( $hashref->{instrumentType} ) || undef;
    $self->{expirydate} = $hashref->{displayPeriod}        || undef;
    $self->{bidsize}    = $hashref->{displayBidSize}       || undef;
    $self->{offersize}  = $hashref->{displayOfferSize}     || undef;

    return bless $self, __PACKAGE__;
}

=head1 NAME

Finance::Nadex::Contract - Provides information about a contract available for trading on the North American Derivatives Exchange

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Container for information about contracts; used by L<Finance::Nadex>; not meant to be instantiated
directly in client code; certain methods in L<Finance::Nadex> return an instance or list of
Finance::Nadex::Contract objects; the accessor methods below can be used to retrieve information
from the object instances; see L<Finance::Nadex> for information about methods which retrieve positions

=head1 ACCESSORS

=head2 bid

Retrieves the current highest bid for the contract (example: "30.00")

=head2 bidsize

Retrieves the number of contracts bid at the current highest bid

=head2 contract

Retrieves the name of the contract (example: "GBP/USD >1.5120 (3PM)")

=head2 epic

Retrieves the unique identifier for the contract as created by the exchange (example: "NB.D.OPT-GBP-USD.1-1-15Jan15")

=head2 expirydate 

Retrieves the date on which the contract will expire (example: "20-JAN-15")

=head2 offer

Retrieves the current lowest offer for the contract (example: "20.50")

=head2 offersize

Retrieves the number of contracts offered at the current lowest offer

=head2 type

Retrieves the type of contract: one of 'binary', 'spread', or 'event'


=head1 AUTHOR

mhandisi, C<< <mhandisi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-nadex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Nadex>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Nadex::Contract


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Nadex>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Nadex>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Nadex>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Nadex/>

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

42;    # End of Finance::Nadex::Contract
