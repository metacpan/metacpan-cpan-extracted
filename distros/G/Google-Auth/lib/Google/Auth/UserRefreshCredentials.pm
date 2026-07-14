package Google::Auth::UserRefreshCredentials;

use strict;
use warnings;

use Moo;
extends 'Google::Auth::Credentials';

use JSON::PP;
use LWP::UserAgent;
use Google::Auth;
use Google::Auth::Exceptions;
use Google::Auth::RetryHelper;
use Log::Any qw($log);

our $VERSION = '0.02';

has json_key => (
    is       => 'ro',
    required => 0,
);

has client_id => (
    is       => 'ro',
    required => 0,
);

has client_secret => (
    is       => 'ro',
    required => 0,
);

has refresh_token => (
    is       => 'ro',
    required => 0,
);

has token_uri => (
    is       => 'ro',
    required => 0,
);

has ua => (
    is      => 'ro',
    default => sub { LWP::UserAgent->new( timeout => 10 ) },
);

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $args = $class->$orig(@args);

    if ( my $json = $args->{json_key} ) {
        $args->{client_id}     //= $json->{client_id};
        $args->{client_secret} //= $json->{client_secret};
        $args->{refresh_token} //= $json->{refresh_token};
        $args->{token_uri}     //= $json->{token_uri};
    }

    return $args;
};

sub fetch_access_token {
    my ( $self, %options ) = @_;

    my $client_id     = $self->client_id;
    my $client_secret = $self->client_secret;
    my $refresh_token = $self->refresh_token;
    my $token_uri     = $self->token_uri // 'https://oauth2.googleapis.com/token';

    if ( !defined $client_id || !defined $client_secret || !defined $refresh_token ) {
        $log->errorf('Missing client_id, client_secret, or refresh_token for UserRefreshCredentials token exchange');
        Google::Auth::Error->throw('Missing client_id, client_secret, or refresh_token to fetch token');
    }

    my $ua = $self->ua;
    my $post_body = {
        'grant_type'    => 'refresh_token',
        'client_id'     => $client_id,
        'client_secret' => $client_secret,
        'refresh_token' => $refresh_token,
    };

    $log->infof('Refreshing access token at %s...', $token_uri);
    my $response = Google::Auth::RetryHelper->execute_with_retry(sub {
        my $res = $ua->post(
            $token_uri,
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Content'      => $post_body
        );
        if ( !$res->is_success ) {
            $log->warnf('Token refresh request failed at %s: status %s', $token_uri, $res->code);
            Google::Auth::Error->throw('HTTP request failed with status ' . $res->code . ': ' . $res->decoded_content);
        }
        return $res;
    }, %options);

    my $res_data = decode_json($response->decoded_content);
    my $token    = $res_data->{access_token};
    my $expires  = $res_data->{expires_in} // 3600;

    $self->access_token($token);
    $self->expires_at(time() + $expires);

    return $token;
}

1;
