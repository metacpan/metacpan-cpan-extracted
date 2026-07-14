package Google::Cloud::REST::Client;

use strict;
use warnings;
use Moo;
use LWP::UserAgent;
use HTTP::Request;
use JSON::MaybeXS qw(encode_json decode_json);
use Carp qw(croak);
use Log::Any qw($log);
use Time::HiRes qw(sleep);

our $VERSION = '0.01';

has target => (
    is       => 'ro',
    required => 1,
);

has auth_token => (
    is       => 'ro',
    required => 0,
);

has timeout => (
    is      => 'ro',
    default => sub { 30 },
);

has max_retries => (
    is      => 'ro',
    default => sub { 3 },
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $h = $class->$orig(@args);
    if (exists $h->{ua} && !exists $h->{user_agent}) {
        $h->{user_agent} = delete $h->{ua};
    }
    return $h;
};

has user_agent => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_user_agent',
);

sub _build_user_agent {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new(
        timeout => $self->timeout,
        agent   => 'google-cloud-perl-rest/' . $VERSION,
    );
    return $ua;
}

sub ua { my $s = shift; return $s->user_agent(@_); }

sub call {
    my ($self, $args) = @_;
    if (@_ > 2 && scalar(@_) % 2 == 1) {
        my ($s, %kw) = @_;
        $args = \%kw;
    }

    my $http_method    = uc($args->{http_method} || $args->{method} || 'POST');
    my $path           = $args->{path} || $args->{url} || '';
    my $request_obj    = $args->{request};
    my $response_class = $args->{response_class};
    my $query_params   = $args->{query_params} || {};

    # Build full URL
    my $base_url = $self->target;
    unless ($base_url =~ /^https?:\/\//) {
        $base_url = 'https://' . $base_url;
    }
    $base_url =~ s/\/+$//;

    if ($path) {
        $path =~ s/^\/+//;
        $base_url .= '/' . $path;
    }

    # Append query parameters if any
    if (keys %$query_params) {
        my @pairs;
        for my $k (sort keys %$query_params) {
            push @pairs, sprintf('%s=%s', $k, $query_params->{$k});
        }
        $base_url .= '?' . join('&', @pairs);
    }

    # Build HTTP request
    my $req = HTTP::Request->new($http_method => $base_url);
    $req->header('Content-Type' => 'application/json');

    # Add Authorization token
    my $token = $self->auth_token;
    if ($token) {
        if (ref($token) && eval { $token->can('get_token') }) {
            $token = $token->get_token();
        }
        $req->header('Authorization' => 'Bearer ' . $token);
    }

    # Encode body
    if ($request_obj) {
        my $payload = {};
        if (ref($request_obj) && eval { $request_obj->can('to_hash') }) {
            $payload = $request_obj->to_hash();
        } elsif (ref($request_obj) eq 'HASH') {
            $payload = $request_obj;
        }
        if (keys %$payload) {
            $req->content(encode_json($payload));
        }
    }

    # Execute HTTP request with retries
    my $retries = 0;
    my $res;
    my $backoff = 0.1;

    while (1) {
        $log->debugf('REST Request: %s %s', $http_method, $base_url);
        $res = $self->user_agent->request($req);

        if ($res->is_success) {
            last;
        }

        my $code = $res->code;
        if (($code == 502 || $code == 503 || $code == 504) && $retries < $self->max_retries) {
            $retries++;
            $log->warnf('REST Transient HTTP %d response, retrying (%d/%d) in %.2fs...', $code, $retries, $self->max_retries, $backoff);
            sleep($backoff);
            $backoff *= 2.0;
            next;
        }

        # Unrecoverable error
        my $err_msg = sprintf('REST API HTTP Error %d: %s', $code, $res->status_line);
        if ($res->content) {
            $err_msg .= ' - ' . $res->content;
        }
        croak $err_msg;
    }

    # Parse response
    my $content = $res->content;
    return undef unless defined $content && length $content;

    my $decoded_json = eval { decode_json($content) };
    if ($@) {
        croak 'REST Error decoding JSON response: ' . $@;
    }

    if ($response_class) {
        if (eval { $response_class->can('from_hash') }) {
            return $response_class->from_hash($decoded_json);
        } elsif (eval { $response_class->can('new') }) {
            return $response_class->new(ref($decoded_json) eq 'HASH' ? %$decoded_json : ());
        }
    }

    return $decoded_json;
}

*request = \&call;

1;
