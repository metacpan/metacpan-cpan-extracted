package HealthCheck::Diagnostic::WebRequest;
use parent 'HealthCheck::Diagnostic';

# ABSTRACT: Make HTTP/HTTPS requests to web servers to check connectivity
use version;
our $VERSION = 'v1.4.4'; # VERSION

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use HTTP::Request;
use Scalar::Util 'blessed';
use Time::HiRes  'gettimeofday';

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    my @bad_params = grep {
        !/^(  content_regex
            | id
            | label
            | no_follow_redirects
            | options
            | request
            | response_time_threshold
            | status_code
            | status_code_eval
            | tags
            | timeout
            | ua
            | url
        )$/x
    } keys %params;

    carp("Invalid parameter: " . join(", ", @bad_params)) if @bad_params;

    croak "The 'request' and 'url' parameters are mutually exclusive!"
        if $params{url} && $params{request};
    if ($params{url}) {
        # Validation for url can be added here
        $params{request} = HTTP::Request->new('GET', $params{url});
    }
    elsif ($params{request}) {
        croak "request must be an HTTP::Request" unless blessed $params{request} && $params{request}->isa('HTTP::Request');
    }
    else{
        croak "Either url or request is required";
    }

    if ($params{ua}) {
        croak "The 'ua' parameter must be of type LWP::UserAgent if provided" unless blessed $params{ua} && $params{ua}->isa('LWP::UserAgent');
        carp "no_follow_redirects does not do anything when 'ua' is provided" if $params{no_follow_redirects};
    }

    # Process and serialize the status code checker
    $params{status_code} ||= '200';
    my (@and, @or);
    foreach my $part (split qr{\s*,\s*}, $params{status_code}) {
        # Strict validation of each part, since we're throwing these into an eval
        my ($op, $code) = $part =~ m{\A\s*(>=|>|<=|<|!=|!)?\s*(\d{3})\z};

        croak "The 'status_code' condition '$part' is not in the correct format!"
            unless defined $code;
        $op = '!=' if defined $op && $op eq '!';

        unless ($op) { push @or,  '$_ == '.$code;    }
        else         { push @and, '$_ '."$op $code"; }
    }
    push @or, '('.join(' && ', @and).')' if @and;  # merge @and as one big condition into @or
    $params{status_code_eval} = join ' || ', @or;

    $params{options}        //= {};
    $params{options}{agent} //= LWP::UserAgent->_agent .
        " HealthCheck-Diagnostic-WebRequest/" . ( $class->VERSION || '0' );
    $params{options}{timeout} //= 7;    # Decided by committee
    unless ($params{ua}) {
        $params{ua} //= LWP::UserAgent->new( %{$params{options}} );
        $params{ua}->requests_redirectable([]) if $params{'no_follow_redirects'};
    }

    return $class->SUPER::new(
        label => 'web_request',
        %params,
    );
}

sub check {
    my ($self, @args) = @_;

    croak("check cannot be called as a class method")
        unless ref $self;
    return $self->SUPER::check(@args);
}

sub run {
    my ( $self, %params ) = @_;

    my ($response, $elapsed_time);
    {
        my $t1        = gettimeofday;
        $response     = $self->send_request;
        $elapsed_time = gettimeofday - $t1;
    }

    my @results;
    push @results, $self->check_status( $response );
    push @results, $self->check_response_time( $elapsed_time );
    push @results, $self->check_content( $response )
        if $results[0]->{status} eq 'OK';

    my $info = join '; ', grep { length } map { $_->{info} } @results;

    return { info => $info, results => \@results };
}

sub check_status {
    my ( $self, $response ) = @_;
    my $status;

    my $client_warning = $response->header('Client-Warning') // '';
    my $proxy_error    = $response->header('X-Squid-Error')  // '';

    # Eval the status checker
    my $success;
    {
        local $_ = $response->code;
        $success = eval $self->{status_code_eval};
    }

    # An unfortunate post-constructor die, but this would be a validation bug (ie: our fault)
    die "Status code checker eval '".$self->{status_code_eval}."' failed: $@" if $@;

    $status = $success ? 'OK' : 'CRITICAL';

    # Proxy error is an automatic failure
    $status = 'CRITICAL' if $proxy_error;

    my $info  = sprintf( "Requested %s and got%s status code %s",
        $self->{request}->uri,
        $status eq 'OK' ? ' expected' : '',
        $response->code,
    );
    $info .= " from proxy with error '$proxy_error'" if $proxy_error;
    $info .= ", expected ".$self->{status_code}      unless $status eq 'OK' || $proxy_error;

    # If LWP returned 'Internal response', the status code doesn't actually mean anything
    if ($client_warning && $client_warning eq 'Internal response') {
        $status = 'CRITICAL';
        $info   = "User Agent returned: ".$response->message;
    }

    return { status => $status, info => $info };
}

sub check_content {
    my ( $self, $response ) = @_;

    return unless $self->{content_regex};

    my $regex      = $self->{content_regex};
    my $content    = $response->content;
    my $status     = $content =~ /$regex/ ? 'OK' : 'CRITICAL';
    my $successful = $status eq 'OK' ? 'matches' : 'does not match';

    return {
        status => $status,
        info   => "Response content $successful /$regex/",
    };
}

sub check_response_time {
    my ( $self, $elapsed_time ) = @_;

    my $response_time_threshold = $self->{response_time_threshold};
    my $status = 'OK';
    $status = 'WARNING' if defined $response_time_threshold && $elapsed_time > $response_time_threshold;

    return {
        status => $status,
        info   => "Request took $elapsed_time second" . ( $elapsed_time == 1 ? '' : 's' ),
    };
}

sub send_request {
    my ( $self ) = @_;

    return $self->{ua}->request( $self->{request} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::WebRequest - Make HTTP/HTTPS requests to web servers to check connectivity

=head1 VERSION

version v1.4.4

=head1 SYNOPSIS

    # site:    https://foo.example
    # content: <html><head></head><body>This is my content</body></html>

    use HealthCheck::Diagnostic::WebRequest;

    # Look for a 200 status code and pass.
    my $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url => 'https://foo.example',
    );
    my $result = $diagnostic->check;
    print $result->{status}; # OK

    # Look for a 200 status code and verify request takes no more than 10 seconds.
    my $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url => 'https://foo.example',
        response_time_threshold => 10,
    );
    my $result = $diagnostic->check;
    print $result->{status}; # OK if no more than 10, WARNING if more than 10

    # Look for a 401 status code and fail.
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url         => 'https://foo.example',
        status_code => 401,
    );
    $result = $diagnostic->check;
    print $result->{status}; # CRITICAL

    # Look for any status code less than 500.
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url         => 'https://foo.example',
        status_code => '<500',
    );
    $result = $diagnostic->check;
    print $result->{status}; # CRITICAL

    # Look for any 403, 405, or any 2xx range code
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url         => 'https://foo.example',
        status_code => '403, 405, >=200, <300',
    );
    $result = $diagnostic->check;
    print $result->{status}; # CRITICAL

    # Look for a 200 status code and content matching the string regex.
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url           => 'https://foo.example',
        content_regex => 'is my',
    );
    $result = $diagnostic->check;
    print $result->{status}; # OK

    # Use a regex as the content_regex.
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url           => 'https://foo.example',
        content_regex => qr/is my/,
    );
    $result = $diagnostic->check;
    print $result->{status}; # OK

    # POST Method: Look for a 200 status code and content matching the string.
    my $data = {
        foo => 'tell me something',
    };

    my $encoded_data = encode_utf8(encode_json($data));
    my $header = [ 'Content-Type' => 'application/json; charset=UTF-8' ];
    my $url = 'https://dev.payment-express.net/dev/env_test';

    my $request = HTTP::Request->new('POST', $url, $header, $encoded_data);
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        request     => $request,
        status_code => 200,
        content_regex => "tell me something",
    );

    $result = $diagnostic->check;
    print $result->{status}; # OK

=head1 DESCRIPTION

Determines if a web request to a C<url> or C<request> is achievable.
Also has the ability to check if the HTTP response contains the
right content, specified by C<content_regex>. Sets the C<status> to "OK"
or "CRITICAL" based on the success of the checks.

=head1 ATTRIBUTES

=head2 url

The site that is checked during the HealthCheck. It can be any HTTP/S link.
By default, it will send GET requests. Use L</request> if you want a more
complicated HTTP request.

Either this option or L</request> are required, and are mutually exclusive.

=head2 request

Allows passing in L<HTTP::Request> object in order to use other HTTP request
methods and form data during the HealthCheck.

Either this option or L</url> are required, and are mutually exclusive.

=head2 status_code

The expected HTTP response status code, or a string of status code conditions.

Conditions are comma-delimited, and can optionally have an operator prefix. Any
condition without a prefix goes into an C<OR> set, while the prefixed ones go
into an C<AND> set. As such, C<==> is not allowed as a prefix, because it's less
confusing to not use a prefix here, and more than one condition while a C<==>
condition exists would not make sense.

Some examples:

    !500              # Anything besides 500
    200, 202          # 200 or 202
    200, >=300, <400  # 200 or any 3xx code
    <400, 405, !202   # Any code below 400 except 202, or 405,
                      # ie: (<400 && !202) || 405

The default value for this is '200', which means that we expect a successful request.

=head2 response_time_threshold

An optional number of seconds to compare the response time to. If it takes no more
than this threshold to receive the response or if the threshold is not provided,
the status is C<OK>. If the time exceeds this threshold, the status is C<WARNING>.

=head2 content_regex

The content regex to test for in the HTTP response.
This is an optional field and is only checked if the status
code check passes.
This can either be a I<string> or a I<regex>.

=head2 no_follow_redirects

Setting this variable prevents the healthcheck from following redirects.

=head2 ua

An optional attribute to override the default user agent. This must be of type L<LWP::UserAgent>.

=head2 options

See L<LWP::UserAgent> for available options. Takes a hash reference of key/value
pairs in order to configure things like ssl_opts, timeout, etc.

It is optional.

By default provides a custom C<agent> string and a default C<timeout> of 7.

=head1 METHODS

=head2 Check Methods

Individual HealthCheck results are added in this order as the return value from these methods:

=head3 check_status

    my $result = $self->check_status( $response );

This method takes in a L<HTTP::Response> object and returns a L<healthcheck result|https://grantstreetgroup.github.io/HealthCheck.html#results>
with a C<status> key and an C<info> key. The status is C<CRITICAL> if a successful HTTP status code was not received,
if the C<Client-Warning> HTTP response header is 'Internal response', or if the C<X-Squid-Error> HTTP response header is set.
Otherwise, it is C<OK>.

=head3 check_response_time

    my $result = $self->check_response_time( $elapsed_time );

This method takes in a number of seconds and returns a L<healthcheck result|https://grantstreetgroup.github.io/HealthCheck.html#results>
with a C<status> key and an C<info> key. The status is C<WARNING> if the response time exceeds the C<response_time_threshold>.
Otherwise, it is C<OK>.

=head3 check_content

    my $response = $self->check_content( $response );

This method takes in a L<HTTP::Response> object and returns a L<healthcheck result|https://grantstreetgroup.github.io/HealthCheck.html#results>
with a C<status> key and an C<info> key. The status is C<CRITICAL> if the content of the response does not match the C<content_regex> attribute.
Otherwise, it is C<OK>.

Note, this is not called if the result of L</check_status> is not C<OK>.

=head2 send_request

    my $response = $self->send_request;

This is the method called internally to receive a response for the healthcheck. Defaults to calling
the C<request> method on the user agent and provided C<request> attribute, but this can be overridden in
a subclass.

=head1 DEPENDENCIES

L<HealthCheck::Diagnostic>
L<LWP::UserAgent>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2024 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
