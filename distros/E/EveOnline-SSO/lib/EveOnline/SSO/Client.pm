=encoding utf-8

=head1 NAME

EveOnline::SSO::Client - base class for any Eve Online ESI API calls

=head1 SYNOPSIS

    use EveOnline::SSO::Client;

    my $client = EveOnline::SSO::Client->new(token => '************', x_user_agent => 'Pilot Name <email@gmail.com>');

    $api->get(['characters', 90922771, 'location'] );
    # url converting to https://esi.tech.ccp.is/latest/characters/90922771/location/?datasource=tranquility

=head1 DESCRIPTION

EveOnline::SSO::Client is base class for any EveOnline ESI API
Contains get, post, put, delete methods for calls to any APIs.

=cut

package EveOnline::SSO::Client;
use 5.008001;
use utf8;
use Modern::Perl;

use LWP::UserAgent;
use Storable qw/ dclone /;
use JSON::XS;
use Moo;

has 'ua' => (
    is => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new();
        $ua->agent( 'EveOnline::SSO::Client Perl API Client' );
        $ua->timeout( 120 );
        return $ua;
    }
);

has 'token' => (
    is => 'rw',
    required => 1,
);

has 'endpoint' => (
    is => 'rw',
    required => 1,
    default  => 'https://esi.tech.ccp.is/latest/',
);

has 'datasource' => (
    is => 'rw',
    required => 1,
    default => 'tranquility',
);

has 'x_user_agent' => (
    is => 'rw',
    required => 1,
);

has 'demo' => (
    is => 'rw'
);

=head1 CONSTRUCTOR

=over

=item B<new()>

Require arguments: token, x_user_agent

    my $client = EveOnline::SSO::Client->new(
                    token        => 'lPhJ_DLk345334532yfssfdJgFsnKI9rR4EZpcQnJ2',
                    x_user_agent => 'Pilot Name <email@gmail.com>',
                    endpoint     => 'https://esi.tech.ccp.is/latest/', # optional
                    datasource   => 'tranquility',                     # optional 
                );

For module based on EveOnline::SSO::Client
you can override atributes:
    
    extends 'EveOnline::SSO::Client';
    has '+endpoint' => (
        is      => 'rw',
        default => 'https://esi.tech.ccp.is/dev/',
    ); 
    has '+datasource' => (
        is => 'rw',
        default => 'singularity',
    );

=back

=head1 METHODS

=over

=item B<get()>

Send GET request.

    $client->get(['array', 'of', 'path', 'blocks'], 
        {
            # query string hash ref. Optional
        });

    $client->get(['characters', $character_id, 'location']);
    
    # or 
    
    $api->get(['characters', 90922771, 'contacts'], { page => 1 } );

    # or full link

    $client->get('https://esi.tech.ccp.is/latest/incursions/');

You can add any params for query hashref, it should be added to query_string

=cut

sub get {
    my ($self, $url, $query) = @_;

    return $self->request( 'get', $url, $query );
}

=item B<post()>

Send POST request.
    
    $client->post(['array', 'of', 'path', 'blocks'], 
        {
            # query string hash ref. Can be empty
        },
        [ {}, [] ]  # Body structure. Converting to json. Optional
        );

    $client->post(['universe', 'names'], {}, [90922771,188956223]);

=cut

sub post {
    my ($self, $url, $query, $body) = @_;

    return $self->request( 'post', $url, $query, $body );
}

=item B<put()>

Send PUT request.

    $client->put(['characters', 90922771, 'contacts'], { standing => 5, watched => 'false' }, [188956223] );

=cut

sub put {
    my ($self, $url, $query, $body) = @_;

    return $self->request( 'put', $url, $query, $body );
}

=item B<delete()>

Send DELETE request.

    $client->delete(['characters', 90922771, 'contacts'], {}, [188956223] );

=cut

sub delete {
    my ($self, $url, $query, $body) = @_;

    return $self->request( 'delete', $url, $query, $body );
}

sub request {
    my ( $self, $method, $url, $query, $body ) = @_;

    my $req = HTTP::Request->new( uc $method => $self->make_url( $url, $query ) );

    $self->prepare_request( $req, $body );

    my $answer = $self->ua->request( $req );

    return $answer->code unless $answer->content;

    return $self->parse_response( $answer->content );   
}

sub make_url {
    my ( $self, $resource, $params ) = @_;

    return $resource if $resource =~ /^http/i;

    my $url = '';

    $url = $self->endpoint;
    $url .= join '/', @$resource;
    $url .= '/';

    my $uri = URI->new( $url );
    $uri->query_form( %{$params || {}}, datasource => $self->datasource );
    $url = $uri->as_string;

    return $url;
}

sub prepare_request {
    my ( $self, $request, $body_param ) = @_;

    my $body = '';
    if ( $body_param ) {
        my $params = dclone( $body_param );

        state $json = JSON::XS->new->utf8;

        $body = $json->encode( $params );

        $request->content( $body );
    }
    $request->header( 'content-type'   => 'application/json; charset=UTF-8' );
    $request->header( 'content-length' => length( $body ) );
    $request->header( 'X-User-Agent'   => $self->x_user_agent );
    $request->header( 'Authorization'  => 'Bearer ' . $self->token );

    return 1;
}

sub parse_response {
    my ( $self, $response ) = @_;

    my $json = JSON::XS::decode_json( $response );

    return $json;
}


1;
__END__

=back

=head1 LICENSE

Copyright (C) Andrey Kuzmin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Andrey Kuzmin E<lt>chipsoid@cpan.orgE<gt>

=cut

