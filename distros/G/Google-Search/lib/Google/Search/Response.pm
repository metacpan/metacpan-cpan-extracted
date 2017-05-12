package Google::Search::Response;

use Any::Moose;
use Google::Search::Carp;

use Google::Search::Error;
use JSON; my $json = JSON->new;
use Try::Tiny;

has http_response => qw/ is ro required 1 isa HTTP::Response /;

has content => qw/ is rw lazy_build 1 /;
sub _build_content {
    my $self = shift;
    $self->parse;
    return $self->content;
}

has error => qw/ is rw lazy_build 1 /;
sub _build_error {
    my $self = shift;
    $self->parse;
    return $self->error;
}

has responseData => qw/ is ro lazy_build 1 /;
sub _build_responseData {
    return shift->content->{responseData} || {};
}

has results => qw/ is ro lazy_build 1 /;
sub _build_results {
    return shift->responseData->{results};
}

has parsed => qw/ is rw /, default => 0;

sub success {
    my $self = shift;
    return $self->error ? 0 : 1;
}

sub is_success { return shift->success( @_ ) };

sub parse {
    my $self = shift;

    return if $self->parsed;
    $self->parsed( 1 );

    my $response = $self->http_response;
    my $fail = sub { $self->_parse_error( @_ ) };

    my ( @error, $content );

    return $fail->( $response->code, $response->message ) unless $response->is_success;

    $content = $response->content;

    try {
        $content = $json->decode( $content );
    } catch {
        @error = ( -1, "Unable to JSON parse content: $@" );
    };

    return $fail->( @error ) if @error;

    return $fail->( -1, "Unable to JSON parse content" ) unless $content ;

    unless ( $content->{responseStatus} eq 200 ) {
        return $fail->( @$content{qw/ responseStatus responseDetails /} );
    }

    return $fail->( -1, "responseData is missing" ) unless $content->{responseData};

    return $fail->( -1, "responseData.results is missing" ) unless
        $content->{responseData}->{results};

    $self->content( $content );
    $self->error( undef );
}

sub _parse_error {
    my $self = shift;
    my ( $code, $message ) = ( shift, shift );

    $self->content( { responseData => { results => undef } } );
    $self->error( Google::Search::Error->new(
        http_response => $self->http_response, code => $code, message => $message, @_ ) );
}

1;
