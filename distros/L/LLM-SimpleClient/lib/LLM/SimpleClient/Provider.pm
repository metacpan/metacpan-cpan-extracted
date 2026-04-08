package LLM::SimpleClient::Provider;

use strict;
use warnings;
use 5.028;
no warnings 'experimental';
use feature qw{signatures};
use utf8;
use Mojo::UserAgent;
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

our $VERSION = '0.01';

# Base class for all LLM providers
sub new ( $class, %params ) {
    my $self = bless {}, $class;

    # Required parameters
    $self->{api_key} = $params{api_key} or die "API key is required";
    $self->{model}   = $params{model}   or die "Model name is required";

    # Optional parameters
    $self->{temperature} = $params{temperature} if exists $params{temperature};
    $self->{max_tokens}  = $params{max_tokens}  if exists $params{max_tokens};
    $self->{top_p}       = $params{top_p}       if exists $params{top_p};

    # Logger (optional, will create if not provided)
    $self->{logger} = $params{logger};

    # Initialize HTTP client
    $self->{ua} = Mojo::UserAgent->new;
    $self->{ua}->max_redirects(5);
    $self->{ua}->inactivity_timeout( $params{timeout} // 60 );

    return $self;
}

# Build the API URL - to be overridden by subclasses
sub _build_url ($self) {
    die "Subclass must implement _build_url()";
}

# Build headers - to be overridden by subclasses
sub _build_headers ($self) {
    die "Subclass must implement _build_headers()";
}

# Build request payload - can be overridden by subclasses
sub _build_payload ( $self, $messages ) {
    my $payload = {
        model    => $self->{model},
        messages => $messages,
    };

    # Add optional parameters only if they were explicitly set
    $payload->{temperature} = $self->{temperature} if exists $self->{temperature};
    $payload->{top_p}       = $self->{top_p}       if exists $self->{top_p};
    $payload->{max_tokens}  = $self->{max_tokens}  if exists $self->{max_tokens};

    return $payload;
}

# Parse response - to be overridden by subclasses
sub _parse_response ( $self, $response ) {
    die "Subclass must implement _parse_response()";
}

# Main method to send API request
sub send_request ( $self, $messages ) {
    my $log = $self->{logger};

    my $url     = $self->_build_url();
    my $headers = $self->_build_headers();
    my $payload = $self->_build_payload($messages);

    $log->debug("Sending request to: $url");
    $log->debug( "Payload: " . encode_json($payload) );

    my $tx = $self->{ua}->build_tx( POST => $url => $headers => json => $payload );

    my $result;
    eval { $tx = $self->{ua}->start($tx); };

    if ($@) {
        $log->error("Connection error: $@");
        return {
            success             => 0,
            error               => "Connection error: $@",
            is_connection_error => 1,
        };
    }

    my $status = $tx->result->code;
    my $body   = $tx->result->body;

    # say Dumper $body;

    $log->debug("Response status: $status");

    if ( $status eq '200' || $status eq '201' ) {

        # Success
        my $parsed = eval { decode_json($body) };
        if ($@) {
            $log->error("Failed to parse response: $@");
            return {
                success     => 0,
                error       => "Failed to parse response: $@",
                status_code => $status,
            };
        }

        return $self->_parse_response($parsed);
    }

    # Error response
    my $error_msg = "HTTP error $status";
    my $parsed_error;

    eval {
        $parsed_error = decode_json($body);
        if ( ref $parsed_error eq 'HASH' ) {

            # Try to extract error message
            $error_msg = $parsed_error->{message} // $parsed_error->{error}
              // $parsed_error->{detail} // "Unknown error";

            if ( ref $error_msg eq 'HASH' ) {
                $error_msg = $error_msg->{message} // "Unknown error";
            }
        }
    };

    $log->warn("Request failed: $error_msg (status: $status)");

    return {
        success     => 0,
        error       => $error_msg,
        status_code => $status,
        raw_error   => $parsed_error // $body,
    };
}

1;

__END__

=head1 NAME

LLM::SimpleClient::Provider - Base class for LLM providers

=head1 DESCRIPTION

This is the base class that all LLM provider classes inherit from.
It provides common functionality for making API requests.

=head1 METHODS

=head2 new(%params)

Creates a new provider instance.

Parameters:
- api_key: API key for authentication
- model: Model identifier
- temperature: Sampling temperature
- max_tokens: Maximum tokens to generate
- top_p: Nucleus sampling parameter
- timeout: Request timeout in seconds
- logger: Log4perl logger instance

=head2 send_request($messages)

Sends a chat request to the provider and returns the response.

=head2 _build_url()

Returns the API endpoint URL. Must be implemented by subclasses.

=head2 _build_headers()

Returns headers for the request. Must be implemented by subclasses.

=head2 _build_payload($messages)

Returns the request payload. Can be overridden by subclasses.

=head2 _parse_response($response)

Parses the API response. Must be implemented by subclasses.

=cut
