package LLM::SimpleClient::HuggingFace;

use strict;
use warnings;
use 5.028;
no warnings 'experimental';
use feature qw{signatures};
use utf8;

use Log::Log4perl qw(:easy);
use Mojo::JSON qw(encode_json);
use base 'LLM::SimpleClient::Provider';

our $VERSION = '0.01';

# HuggingFace Router API endpoint
use constant API_URL => 'https://router.huggingface.co/v1/chat/completions';

sub _build_url ($self) {
    return API_URL;
}

sub _build_headers ($self) {
    return {
        'Authorization' => 'Bearer ' . $self->{api_key},
        'Content-Type'  => 'application/json',
        'Accept'        => 'application/json',
    };
}

sub _parse_response ($self, $response) {
    my $logger = $self->{logger};

    # Check for error in response
    if (exists $response->{error}) {
        my $error = $response->{error};
        $logger->warn("HuggingFace API error: " . ($error->{message} // $error));
        return {
            success => 0,
            error   => $error->{message} // $error,
        };
    }

    # Extract the response content
    my $choices = $response->{choices};
    unless ($choices && ref $choices eq 'ARRAY' && scalar @$choices > 0) {
        $logger->error("No choices in response");
        return {
            success => 0,
            error   => "No response choices in API response",
        };
    }

    my $message = $choices->[0]->{message};
    unless ($message) {
        $logger->error("No message in first choice");
        return {
            success => 0,
            error   => "No message in API response",
        };
    }

    my $content = $message->{content};
    unless (defined $content) {
        $logger->error("No content in message");
        return {
            success => 0,
            error   => "No content in message",
        };
    }

    $logger->debug("Received response: " . substr($content, 0, 100) . "...");

    return {
        success     => 1,
        content     => $content,
        raw_response => $response,
        # Additional metadata
        model       => $response->{model},
        usage       => $response->{usage},
        finish_reason => $message->{finish_reason},
    };
}

1;

__END__

=head1 NAME

LLM::SimpleClient::HuggingFace - HuggingFace Router provider for LLM::SimpleClient

=head1 DESCRIPTION

Provider implementation for HuggingFace Router (router.huggingface.co).
This provider uses OpenAI-compatible API format.

=head1 SEE ALSO

L<LLM::SimpleClient>, L<LLM::SimpleClient::Provider>

=cut
