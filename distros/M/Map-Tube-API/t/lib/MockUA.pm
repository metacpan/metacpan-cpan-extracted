package MockUA;

# A minimal stand-in for LWP::UserAgent, used by the test suite so that
# Map::Tube::API and Map::Tube::API::UserAgent can be tested without ever
# making a real HTTP request.
#
# Since both modules expose their "ua" attribute as a plain, writable Moo
# attribute (is => 'rw'), a MockUA instance can simply be injected at
# construction time:
#
#     my $mock = MockUA->new($http_response, ...);
#     my $api  = Map::Tube::API->new(ua => $mock, base_url => 'http://x');
#
# Responses are returned in the order given, one per call to request().
# Every request actually made is recorded (in order) and can be inspected
# afterwards via requests()/last_request(), which is what lets the test
# suite assert on the exact URL (and method) each API call constructs.

use strict;
use warnings;

sub new {
    my ($class, @responses) = @_;

    return bless {
        responses => [ @responses ],
        requests  => [],
    }, $class;
}

sub request {
    my ($self, $req) = @_;

    push @{ $self->{requests} }, $req;

    my $response = shift @{ $self->{responses} };
    die "MockUA: request() called but no canned response was queued for it (" . $req->uri . ")"
        unless defined $response;

    return $response;
}

sub requests {
    my ($self) = @_;
    return @{ $self->{requests} };
}

sub last_request {
    my ($self) = @_;
    return $self->{requests}[-1];
}

sub request_count {
    my ($self) = @_;
    return scalar @{ $self->{requests} };
}

1;
