package Loctools::Net::HTTP::Client;

use strict;

use HTTP::Headers;
use HTTP::Request;
use LWP::UserAgent;
use JSON qw(decode_json encode_json);

my $DEFAULT_MAX_RETRIES = 5;

sub new {
    my ($class, %params) = @_;

    my $self => {
        max_retries => $DEFAULT_MAX_RETRIES,
    };

    $self->{max_retries} = $params{max_retries} if defined $params{max_retries};

    $self->{ua} = LWP::UserAgent->new();
    $self->{ua}->cookie_jar({});

    if (defined $params{session}) {
        $self->{session} = $params{session};
        $self->{session}->start;
    }

    bless $self, $class;
    return $self;
}

# do the request with an exponential back-off
sub request {
    my ($self, $method, $url, $raw_content, $headers) = @_;

    my $attempt = 1;
    my $code;
    my $content;
    while (1) {
        if ($attempt > 1) {
            print "Attempt #".$attempt."\n";
        }
        # upgrade headers hash to HTTP::Headers
        $headers = {} unless defined $headers;
        bless($headers, 'HTTP::Headers');

        my $request = HTTP::Request->new($method, $url, $headers, $raw_content);
        if (defined $raw_content) {
            my $len = length($raw_content);
            $request->header('Content-Length', $len);
        }
        if (defined $self->{session}) {
            $request->header($self->{session}->authorization_header);
        }

        my $response = $self->{ua}->request($request);
        $code = $response->code;
        $content = $response->content;

        last if ($code == 200 || $attempt >= $self->{max_retries});

        my $need_sleep = 1;

        if ($code == 401) {
            if (defined $self->{session}) {
                $self->{session}->renew;
                $need_sleep = undef if $attempt == 1; # don't sleep the first time
            }
        } elsif ($code =~ m/^(500|503)$/) {
            # one of the known error codes, just retry
        } else {
            last; # unexpected error code
        }

        if ($code != 200) {
            my $sleep_time = $need_sleep ? 2**$attempt : 0;

            warn "Server returned error #", "$code when requesting the URL ",
                $self->{ua}->{_res}->base(), ", will make attempt #", "$attempt in $sleep_time seconds\n";

            sleep $sleep_time if $need_sleep;
            $attempt++;
        }
    }

    if ($code != 200) {
        warn "Server returned error #", $code, " after $attempt attempt(s). Won't continue.\n";
        warn "Returned content:\n\n===========\n$content\n===========\n\n";
    }

    return $code, $content;
}

sub get {
    my $self = shift;
    return $self->request('GET', @_);
}

sub put {
    my $self = shift;
    return $self->request('PUT', @_);
}

sub post {
    my $self = shift;
    return $self->request('POST', @_);
}

sub post_json {
    my ($self, $url, $content, $headers) = @_;
    return $self->post($url, encode_json($content), _add_json_header($headers));
}

sub put_json {
    my ($self, $url, $content, $headers) = @_;
    return $self->put($url, encode_json($content), _add_json_header($headers));
}

sub _add_json_header {
    my $headers = shift;
    $headers = {} unless defined $headers;
    $headers->{'Content-type'} = 'application/json; charset=UTF-8';
    return $headers;
}
