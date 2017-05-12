package LWP::Authen::OAuth2::AccessToken;
use strict;
use warnings;

use Carp qw(confess);
our @CARP_NOT = qw(LWP::Authen::OAuth2);

=head1 NAME

LWP::Authen::OAuth2::AccessToken - Access tokens for OAuth 2.

=head1 VERSION

Version 0.02;

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This is a base class for signing API requests with OAuth2 access tokens.  A
subclass should override the C<request> method with something that knows how
to make a request, detect the need to try to refresh, and attmpts to do that.
See L<lWP::Authen::OAuth2::AccessToken::Bearer> for an example.

Subclasses of this one are not directly useful.  Please see
L<LWP::Authen::OAuth2> for the interface that you should be using.

=head1 METHODS

=head2 C<from_ref>

Construct an access token from a hash reference.  The default implementation
merely blesses it as an object, defaulting the C<create_time> field to the
current time.

    my $access_token = $class->from_ref($data);

If you roll your own, be aware that the fields C<refresh_token> and
C<_class> get used for purposes out of this class' control.  Any other fields
may be used.  Please die fatally if you cannot construct an object.

=cut

sub from_ref {
    my ($class, $data) = @_;
    # If create_time is passed, then that will overwrite this default.
    return bless {create_time => time(), %$data}, $class;
}

=head2 C<to_ref>

Construct an unblessed data structure to represent the object that can be
serialized as JSON.  The default implementation just creates a shallow copy
and assumes there are no blessed subobjects.

=cut

sub to_ref {
    my $self = shift;
    return { %$self };
}

=head2 C<expires_time>

Estimate expiration time.  Not always correct, due to transit
delays, clock skew, etc.

=cut

sub expires_time {
    my $self = shift;
    my $initial_expires_in = $self->{expires_in} || 3600;
    return $self->{create_time} + $initial_expires_in;
}

=head2 C<expires_in>

Estimate the seconds until expiration.  Not always correct, due to transit
delays, clock skew, etc.

=cut

sub expires_in {
    my $self = shift;
    return $self->expires_time - time();
}

=head2 C<should_refresh>

Boolean saying whether a refresh should be emitted now.

=cut

sub should_refresh {
    my ($self, $early_refresh_time) = @_;
    # If the access tokens are short lived relative to $early_refresh_time
    # we cheat to avoid refreshing TOO often....
    if ($self->expires_in/2 < $early_refresh_time) {
        $early_refresh_time = $self->expires_in/2;
    }
    my $expires_in = $self->expires_in();
    if ($expires_in < $early_refresh_time) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 C<for_refresh>

Returns key/value pairs for C<$oauth2> (and eventually the service provider
class) to use in trying to refresh.

=cut

sub for_refresh {
    my $self = shift;
    if ($self->{refresh_token}) {
        return refresh_token => $self->{refresh_token};
    }
    else {
        return ();
    }
}

=head2 C<copy_refresh_from>

Pass in a previous access token, copy anything needed to refresh.

=cut

sub copy_refresh_from {
    my ($self, $other) = @_;
    if ($other->{refresh_token}) {
        $self->{refresh_token} ||= $other->{refresh_token};
    }
}

=head2 C<request>

Make a request.  If expiration is detected, refreshing by the best
available method (if any).

    my $response = $access_token->request($oauth2, @request_for_lwp);

=cut

sub request {
    # Shift off one for easy redispatch to _request.
    my $self = shift;
    my ($oauth2, $request, @rest) = @_;
    if (
        $self->should_refresh($oauth2->{early_refresh_time} || 300) and
        $oauth2->can_refresh_tokens()
    ) {
        $oauth2->refresh_access_token();
        $self = $oauth2->access_token if ref($oauth2->access_token);
    }
    my ($response, $try_refresh) = $self->_request(@_);
    if ($try_refresh and $oauth2->can_refresh_tokens()) {
        # Someone's clock is wrong?  Try to refresh.
        $oauth2->refresh_access_token();
        if ($self->expires_in < $oauth2->access_token->expires_in) {
            # We seem to have renewed, try again.
            ($response, $try_refresh) = $oauth2->access_token->_request(@_);
        }
    }
    return $response;
}


=head2 C<_request>

Make a request with no retry logic, and return a response, and a flag
for whether it is possible the access token is expired..

    my ($response, $try_refresh)
        = $access_token->_request($oauth2, @request_for_lwp);

B<THIS IS THE ONLY METHOD A SUBCLASS MUST OVERRIDE!>

=cut

sub _request {
    my ($self, $oauth2, $request, @rest) = @_;
    # ...
    # return ($response, $try_refresh);
    confess("Method _request needs to be overwritten.");
}

=head1 AUTHOR

Ben Tilly, C<< <btilly at gmail.com> >>

=head1 BUGS

We should support more kinds of access tokens.

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
