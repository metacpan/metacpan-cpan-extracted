
=encoding utf-8

=head1 NAME

EveOnline::SSO - Module for Single Sign On in EveOnline API-services.

=head1 SYNOPSIS

    use EveOnline::SSO;

    my $sso = EveOnline::SSO->new(client_id => '03ed7324fe4f455', client_secret => 'bgHejXdYo0YJf9NnYs');
    
    # return url for open in browser
    print $sso->get_code();
    # or
    print $sso->get_code(state => 'some_ids_or_flags');
    # or
    print $sso->get_code(state => 'some_ids_or_flags', scope=>'esi-calendar.respond_calendar_events.v1 esi-location.read_location.v1');

    # return hash with access and refresh tokens by auth code
    print Dumper $sso->get_token(code=>'tCaVozogf45ttk-Fb71DeEFcSYJXnCHjhGy');
    # or hash with access and refresh tokens by refresh_token
    print Dumper $sso->get_token(refresh_token=>'berF1ZVu_bkt2ud1JzuqmjFkpafSkobqdso');
    
    # return hash with access and refresh tokens through listening light web-server
    print Dumper $sso->get_token_through_webserver(
                        scope=>'esi-calendar.respond_calendar_events.v1 esi-location.read_location.v1', 
                        state=> 'Awesome'
                    );


=head1 DESCRIPTION

EveOnline::SSO is a perl module for get auth in https://eveonline.com through Single Sign-On (OAuth) interface.

=cut

package EveOnline::SSO;
use 5.008001;
use utf8;
use Modern::Perl;
use JSON::XS;
use URI::Escape;
use MIME::Base64;
use URI::URL;

use LWP::UserAgent;
use LWP::Socket;

use Moo;

our $VERSION = "0.02";


has 'ua' => (
    is => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new();
        $ua->agent( 'EveOnline::SSO Perl Client' );
        $ua->timeout( 120 );
        return $ua;
    }
);

has 'auth_url' => (
    is      => 'ro',
    default => 'https://login.eveonline.com/oauth/authorize/',

);

has 'token_url' => (
    is      => 'ro',
    default => 'https://login.eveonline.com/oauth/token',
);

has 'callback_url' => (
    is      => 'rw',
    default => 'http://localhost:10707/',
);

has 'client_id' => (
    is => 'rw',
    required => 1,
);

has 'client_secret' => (
    is => 'rw',
    required => 1,
);

has 'demo' => (
    is => 'rw'
);

=head1 CONSTRUCTOR

=over

=item B<new()>

Require two arguments: client_id and client_secret. 
Optional arguments: callback_url. Default is http://localhost:10707/

Get your client_id and client_secret on EveOnline developers page:
L<https://developers.eveonline.com/>

=back

=head1 METHODS

=over

=item B<get_code()>

Return URL for open in browser.

Optional params: state, scope

See available scopes on L<https://developers.eveonline.com/>

    # return url for open in browser
    print $sso->get_code();
    
    # or
    print $sso->get_code(state => 'some_ids_or_flags');
    
    # or
    print $sso->get_code(scope=>'esi-calendar.respond_calendar_events.v1 esi-location.read_location.v1');

=back
=cut

sub get_code {
    my ( $self, %params ) = @_;

    return $self->auth_url . 
            "?response_type=code&client_id=".$self->client_id . 
            "&redirect_uri=".uri_escape( $self->callback_url ) . 
            ( ( defined $params{scope} ) ? "&scope=" . uri_escape( $params{scope} ) : '' ) .
            ( ( defined $params{state} ) ? "&state=" . uri_escape( $params{state} ) : '' );
}

=over

=item B<get_token()>

Return hashref with access and refresh tokens.
refresh_token is undef if code was received without scopes.

Need "code" or "refresh_token" in arguments. 
    
    # return hash with access and refresh tokens by auth code
    print Dumper $sso->get_token(code=>'tCaVozogf45ttk-Fb71DeEFcSYJXnCHjhGy');
    
    # or hash with access and refresh tokens by refresh_token
    print Dumper $sso->get_token(refresh_token=>'berF1ZVu_bkt2ud1JzuqmjFkpafSkobqdso');

=back
=cut

sub get_token {
    my ( $self, %params ) = @_;

    return unless $params{code} || $params{refresh_token};

    return JSON::XS::decode_json( $self->demo ) if $self->demo;

    $self->ua->default_header('Authorization' => "Basic " . encode_base64($self->client_id.':'.$self->client_secret) );
    $self->ua->default_header('Content-Type' => "application/x-www-form-urlencoded");

    my $post_params = {};
    foreach my $key ( keys %params ) {
        $post_params->{$key} = $params{$key};
    }

    my $res = $self->ua->post($self->token_url, {
        %$post_params,
        grant_type => $params{code} ? 'authorization_code' : 'refresh_token', 
    });

    return JSON::XS::decode_json( $res->content );
}

=over

=item B<get_token_through_webserver()>

Return hashref with access and refresh tokens by using local webserver for get code.
Use callback_url parameter for start private web server on host and port in callback url.

Default url: http://localhost:10707/

    # return hash with access and refresh tokens
    print Dumper $sso->get_token_through_webserver(scope=>'esi-location.read_location.v1');

=back
=cut

sub get_token_through_webserver {
    my ( $self, %params ) = @_;

    my $url = $self->get_code( %params );

    if ( $url ) {

        say "Go to url: " . $url;
        my $code = $self->_webserver();

        if ( $code ) {
            say $code;
            return $self->get_token(code=>$code);
        }
    }
    return;
}

sub _webserver {
    my ( $self, %params ) = @_;

    my $headers = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n";
    
    my $conn = new URI::URL $self->callback_url;

    my $sock = new LWP::Socket();
    die "Can't bind a socket" unless $sock->bind($conn->host, $conn->port);
    $sock->listen(1);

    my $code;
    while ( my $socket = $sock->accept(1) ) {
        my $content = "<b>EveOnline::SSO code receiver</b><br />";
        my $request = '';
        $socket->read( \$request );
        if ( $request =~ /code=/g ) {
            if ( $request =~ /code=([\w-]+)/ ) {
                $code = $1;
                $request =~ s/GET \/\?([^ ]*) HTTP.+/$1/s;
                $request =~ s/&/<br \/>/g;
                $request =~ s/=/:/g;

                $content .= $request;
                $content .= "<br />Now you can close this page<br />Fly safe!";
                $socket->write( $headers . $content );
                $socket->shutdown();
                $socket = undef;
                last;
            }
        }
    }
     
    $sock->shutdown();
    $sock = undef;
    return $code;
}

1;
__END__

=head1 LICENSE

Copyright (C) Andrey Kuzmin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Andrey Kuzmin E<lt>chipsoid@cpan.orgE<gt>

=cut

