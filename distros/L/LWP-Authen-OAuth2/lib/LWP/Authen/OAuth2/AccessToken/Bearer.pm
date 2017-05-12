package LWP::Authen::OAuth2::AccessToken::Bearer;
use strict;
use warnings;
use base "LWP::Authen::OAuth2::AccessToken";
use Storable qw(dclone);

sub _request {
    my ($self, $oauth2, $request, @rest) = @_;
    my $actual_request = dclone($request);
    # This is where we sign it.
    $actual_request->header('Authorization' => "Bearer $self->{access_token}");
    my $response = $oauth2->user_agent->request($actual_request, @rest);

    # One would hope for a 401 status, but the specification only requires
    # this header.  (Though recommends a 401 status.)
    my $try_refresh = ($response->header("WWW-Authenticate")||'') =~ m/\binvalid_token\b/
      || ($response->header('Client-Warning')||'') =~ m/Missing Authenticate header/ # Dwolla does not send WWW-Authenticate
      || $response->content() =~ m/\bExpiredAccessToken\b/
      ? 1 : 0;
    return ($response, $try_refresh);
}

=head1 NAME

LWP::Authen::OAuth2::AccessToken::Bearer - Bearer access tokens for OAuth 2.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This implements bearer tokens.  See
L<RFC 6750|http://tools.ietf.org/html/rfc6750> for details,
L<LWP::Authen::OAuth2::AccessToken> for how this module works, and
L<LWP::Authen::OAuth2> for the interface to use to this module.

Whether this module gets used depends on the service provider.

=head1 AUTHOR

Ben Tilly, C<< <btilly at gmail.com> >>

=head1 BUGS

We should test this...

=head1 ACKNOWLEDGEMENTS

Thanks to L<Rent.com|http://www.rent.com> for their generous support in
letting me develop and release this module.  My thanks also to Nick
Wellnhofer <wellnhofer@aevum.de> for Net::Google::Analytics::OAuth2 which
was very enlightening while I was trying to figure out the details of how to
connect to Google with OAuth2.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Rent.com.

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

1;
