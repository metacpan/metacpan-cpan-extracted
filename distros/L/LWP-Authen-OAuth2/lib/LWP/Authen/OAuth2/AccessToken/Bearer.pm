package LWP::Authen::OAuth2::AccessToken::Bearer;

# ABSTRACT: Bearer access tokens for OAuth2
our $VERSION = '0.20'; # VERSION

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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::AccessToken::Bearer - Bearer access tokens for OAuth2

=head1 VERSION

version 0.20

=head1 SYNOPSIS

This implements bearer tokens.  See
L<RFC 6750|http://tools.ietf.org/html/rfc6750> for details,
L<LWP::Authen::OAuth2::AccessToken> for how this module works, and
L<LWP::Authen::OAuth2> for the interface to use to this module.

Whether this module gets used depends on the service provider.

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
