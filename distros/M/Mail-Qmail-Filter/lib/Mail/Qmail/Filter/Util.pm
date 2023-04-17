use 5.014;
use warnings;

package Mail::Qmail::Filter::Util;

our $VERSION = '1.11';

use base 'Exporter';

our @EXPORT_OK = qw(addresses_to_hash match_address split_address);

sub addresses_to_hash {
    my $addrs = shift;
    my %struct;
    for ( ref $addrs ? @$addrs : $addrs ) {
        my ( $localpart, $domain ) = split_address($_);
        unless ( length $localpart ) {
            $struct{$domain} = '';    # match for whole domain
        }
        else {
            my $slot = $struct{$domain} //= {};
            $slot->{$localpart} = '' if ref $slot;
        }
    }
    \%struct;
}

sub match_address {
    my ( $struct,    $addr )   = @_;
    my ( $localpart, $domain ) = split_address($addr);
    defined( my $slot = $struct->{$domain} ) or return;
    !ref $slot || !length $localpart || defined $slot->{$localpart};
}

sub split_address {
    my $lc_addr = lc shift;
    if ( $lc_addr =~ /\@/ ) {
        split /\@/, $lc_addr, 2;
    }
    else {
        undef, $lc_addr;
    }
}

1;

=head1 NAME

Mail::Qmail::Filter::Util -
utility functions for Mail::Qmail::Filter modules

=head1 SYNOPSIS

    use Mail::Qmail::Filter::Util qw(addresses_to_hash match_address);
    use Mo qw(coerce default);

    has addresses => coerce => \&addresses_to_hash;

    sub filter {
        ...
        if ( match_address( $self->addresses, $address ) ) {
            ...
        }
        ...
    }

=head1 DESCRIPTION

This module is not a filter itself, but provides utility functions
for other filters, possibly your own.

=head1 EXPORTABLE FUNCTIONS

=head2 addresses_to_hash

Takes a single e-mail address or domain name as string or an array of such
strings and turns it into a data structure you can later pass to
L</match_address>.
Returns a reference to this data structure.

=head2 match_address

Expects two arguments:

=over 4

=item 1.

the reference returned by L</addresses_to_hash>

=item 2.

an e-mail address (as a string)

=back

Will return a true value if the e-mail address given is one of the
addresses you had given to L</addresses_to_hash> or if its domain name
is one of the domain names you had given to L</addresses_to_hash>.

Everything will be compared case-insensitively, because domain names are
not case-sensitive anyway, and presumably no-one uses case-sensitive
localparts.

=head2 split_address

Expects a domain name or an e-mail address as its only argument.

Returns two values:

=over 4

=item 1.

the local-part of the e-mail address, or L<undef|perlfunc/undef> for
domains

=item 2.

the domain part, converted to lowercase

=back

=head1 SEE ALSO

L<Mail::Qmail::Filter>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Martin Sluka.

This module is free software; you can redistribute it and/or modify it
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
