package LWP::Authen::OAuth2::AccessToken;

# ABSTRACT: Access tokens for OAuth2.
our $VERSION = '0.19'; # VERSION

use strict;
use warnings;

use Carp qw(confess);
our @CARP_NOT = qw(LWP::Authen::OAuth2);


sub from_ref {
    my ($class, $data) = @_;
    # If create_time is passed, then that will overwrite this default.
    return bless {create_time => time(), %$data}, $class;
}


sub to_ref {
    my $self = shift;
    return { %$self };
}


sub expires_time {
    my $self = shift;
    my $initial_expires_in = $self->{expires_in} || 3600;
    return $self->{create_time} + $initial_expires_in;
}


sub expires_in {
    my $self = shift;
    return $self->expires_time - time();
}


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


sub for_refresh {
    my $self = shift;
    if ($self->{refresh_token}) {
        return refresh_token => $self->{refresh_token};
    }
    else {
        return ();
    }
}


sub copy_refresh_from {
    my ($self, $other) = @_;
    if ($other->{refresh_token}) {
        $self->{refresh_token} ||= $other->{refresh_token};
    }
}


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


sub _request {
    my ($self, $oauth2, $request, @rest) = @_;
    # ...
    # return ($response, $try_refresh);
    confess("Method _request needs to be overwritten.");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::AccessToken - Access tokens for OAuth2.

=head1 VERSION

version 0.19

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

=head2 C<to_ref>

Construct an unblessed data structure to represent the object that can be
serialized as JSON.  The default implementation just creates a shallow copy
and assumes there are no blessed subobjects.

=head2 C<expires_time>

Estimate expiration time.  Not always correct, due to transit
delays, clock skew, etc.

=head2 C<expires_in>

Estimate the seconds until expiration.  Not always correct, due to transit
delays, clock skew, etc.

=head2 C<should_refresh>

Boolean saying whether a refresh should be emitted now.

=head2 C<for_refresh>

Returns key/value pairs for C<$oauth2> (and eventually the service provider
class) to use in trying to refresh.

=head2 C<copy_refresh_from>

Pass in a previous access token, copy anything needed to refresh.

=head2 C<request>

Make a request.  If expiration is detected, refreshing by the best
available method (if any).

    my $response = $access_token->request($oauth2, @request_for_lwp);

=head2 C<_request>

Make a request with no retry logic, and return a response, and a flag
for whether it is possible the access token is expired..

    my ($response, $try_refresh)
        = $access_token->_request($oauth2, @request_for_lwp);

B<THIS IS THE ONLY METHOD A SUBCLASS MUST OVERRIDE!>

=head1 AUTHORS

=over 4

=item *

Ben Tilly, <btilly at gmail.com>

=item *

Thomas Klausner <domm@plix.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2022 by Ben Tilly, Rent.com, Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
