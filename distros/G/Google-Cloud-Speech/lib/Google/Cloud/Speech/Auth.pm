package Google::Cloud::Speech::Auth;

use Mojo::Base '-base';
use Mojo::Collection;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::JWT::Google;
use Mojo::UserAgent;

has scopes => sub { ['https://www.googleapis.com/auth/cloud-platform']; };
has grant_type    => 'urn:ietf:params:oauth:grant-type:jwt-bearer';
has oauth_url     => 'https://www.googleapis.com/oauth2/v4/token';
has ua            => sub { Mojo::UserAgent->new; };
has from_json     => sub { };
has jwt_token_enc => undef;
has jwt_token     => undef;

sub jwt {
    my $self = shift;

    return Mojo::JWT::Google->new(
        from_json  => $self->from_json,
        target     => $self->oauth_url,
        scopes     => Mojo::Collection->new( $self->scopes )->flatten,
        issue_at   => time,
        expires_in => 20,
    );
}

has token => undef;

sub request_token {
    my $self = shift;

    $self->jwt_token( $self->jwt );
    $self->jwt_token_enc( $self->jwt_token->encode );

    my $tx = $self->ua->post(
        $self->oauth_url,
        form => {
            grant_type => $self->grant_type,
            assertion  => $self->jwt_token_enc
        },
    );

    my $res = $tx->res;
    if ( $res->is_success and $res->json('/access_token') ) {
        my $token_obj = $res->json;
        my $token = $token_obj->{'token_type'} . ' ' . $token_obj->{'access_token'};
        $self->{'token'} = $token;

        return $self;
    }

    my $error_obj = $tx->res->json;
    die "No authorization provided: `$error_obj->{error_description}`";
}

sub has_valid_token {
    my $self = shift;
    return undef unless my $token = $self->token;
    return undef unless my $jwt   = $self->jwt_token;
    return undef
        unless my $expires_in
        = $self->jwt_token->issue_at + $self->jwt_token->expires_in;
    return undef unless time < ( $expires_in - 10 );

    return 1;
}

sub refresh {
    my $self = shift;
    
    delete $self->{'token'};
    $self->{'token'} = $self->_request_token;
  
    return $self;
}

1;
