package LWP::Authen::OAuth2::ServiceProvider::Line;

use strict;
use warnings;

use parent 'LWP::Authen::OAuth2::ServiceProvider';

sub required_init {
    return qw(client_id client_secret redirect_uri);
}

sub authorization_required_params {
    return qw(client_id redirect_uri response_type state);
}

sub authorization_default_params {
    return response_type => 'code';
}

sub request_required_params {
    return qw(client_id redirect_uri grant_type client_secret code);
}

sub request_default_params {
    return grant_type => 'authorization_code';
}

sub init {
    my ($self, $opts) = @_;
    $self->copy_option($opts, line_server => 'line.me');
    $self->SUPER::init($opts);
}

sub authorization_endpoint {
    my $self = shift;
    my $server = $self->{line_server} or die 'line_server not configured. Forgot to call init()?';

    return "https://access.$server/dialog/oauth/weblogin";
}

sub token_endpoint {
    my $self = shift;
    my $server = $self->{line_server} or die 'line_server not configured. Forgot to call init()?';

    return "https://api.$server/v2/oauth/accessToken";
}

sub api_url_base {
    my $self = shift;
    my $server = $self->{line_server} or die 'line_server not configured. Forgot to call init()?';

    return "https://api.$server/v2/";
}

sub access_token_class {
    my ($self, $type) = @_;

    if ($type eq 'bearer') {
        return 'LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken';
    }

    return $self->SUPER::access_token_class($type);
}

=pod

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Line - Access Line OAuth2 API v2

=head1 SYNOPSIS

    my $oauth2 = LWP::Authen::OAuth2->new(
        service_provider => 'Line',
        redirect_uri     => 'http://example.com/',
        client_id        => 'line_client_id'      # Retrieved from https://developers.line.me/
        client_secret    => 'line_client_secret'  # Retrieved from https://developers.line.me/
    );

    my $url = $oauth2->authorization_url(state => $state);

    # ... Send user to authorization URL and get authorization $code ...

    $oauth2->request_tokens(code => $code);

    # Simple requests

    # User Info
    my $profile       = $oauth2->make_api_call('profile');
    my $userId        = $profile->{userId};
    my $displayName   = $profile->{displayName};
    my $pictureUrl    = $profile->{pictureUrl};
    my $statusMessage = $profile->{statusMessage};

    # Refresh
    $oauth2->refresh_access_token();

    # More complex requests...

    # Verify
    # Manually send the request using the internal user agent - see explanation in "Line API Documentation" below.
    my $access_token_str = $oauth2->access_token->access_token;
    my $res = $oauth2->user_agent->post($oauth2->api_url_base.'oauth/verify' => { access_token => $access_token_str });
    my $content = eval { decode_json($res->content) };
    my $scope      = $content->{scope};
    my $client_id  = $content->{client_id};
    my $expires_in = $content->{expires_in};

    # Revoke
    # Look up the internal refresh token - see explanation in "Line API Documentation" below.
    my $refresh_token_str = $oauth2->access_token->refresh_token;
    $oauth2->post($oauth2->api_url_base.'oauth/revoke' => { refresh_token => $refresh_token_str });

=head1 REGISTERING

Individual users must have an account created with the L<Line application|https://line.me/download>.  In order to log in with OAuth2, users must register their email address. Device-specific instructions can be found on the L<Line support site|https://help.line.me/>.

API clients can follow the L<Line Login|https://developers.line.me/line-login/overview> documentation to set up the OAuth2 credentials.

=head1 Line API Documentation

See the Line L<Social REST API Reference|https://devdocs.line.me/en/#how-to-use-the-apis>.

As of writing, there are two simple API calls: C<profile> and C<refresh>.

There are also C<verify> and C<revoke> endpoints, which require a bit more work.

=over

=item C<verify>

C<verify> is designed for verifying pre-existing access tokens. Instead of using the C<Authorization> header, this endpoint expects the access token to be form-urlencoded in the request body. Because of this, it's necessary to get access to the internal access token string to send in the request body. The L<LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken> token class used by this service provider provides the C<access_token> accessor for this purpose.

The server seems to ignore the C<Authorization> header for this request, so including it is probably not a problem. If you want to avoid sending the access token in the header, it's necessary to manually construct the request and decode the response.

See L</SYNOPSYS> for usage examples.

=item C<revoke>

C<revoke> requires the refresh token to be form-urlencoded in the request body. Because of this, it's necessary to get access to the internal refresh token string to send in the request body. The L<LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken> token class used by this service provider provides the C<refresh_token> accessor for this purpose. See L</SYNOPSYS> for usage examples.

=back

=head1 Refresh timing

Line access tokens can be refreshed at any time up until 10 days after the access token expires. The L<LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken> token class used by this service provider extends the C<should_refresh> method for this purpose, causing C<< $oauth2->should_refresh() >> to return false if this 10-day period has lapsed.

=head1 AUTHOR

Adam Millerchip, C<< <adam at millerchip.net> >>

=cut

1;

