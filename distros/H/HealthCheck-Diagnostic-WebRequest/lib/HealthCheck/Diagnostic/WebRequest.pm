package HealthCheck::Diagnostic::WebRequest;
use parent 'HealthCheck::Diagnostic';

# ABSTRACT: Make HTTP/HTTPS requests to web servers to check connectivity
use version;
our $VERSION = 'v1.3.5'; # VERSION

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use HTTP::Request;
use Scalar::Util 'blessed';

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    my @bad_params = grep {
        !/^(tags|label|id|options|timeout|url|request|options|content_regex|status_code_eval|status_code|no_follow_redirects)$/
    } keys %params; 

    carp("Invalid parameter: " . join(", ", @bad_params)) if @bad_params;

    die "No url or HTTP::Request specified!" unless ($params{url} ||
        ($params{request} && blessed $params{request} &&
            $params{request}->isa('HTTP::Request')));
    die "The 'request' and 'url' options are mutually exclusive!"
        if $params{url} && $params{request};

    # Process and serialize the status code checker
    $params{status_code} ||= '200';
    my (@and, @or);
    foreach my $part (split qr{\s*,\s*}, $params{status_code}) {
        # Strict validation of each part, since we're throwing these into an eval
        my ($op, $code) = $part =~ m{\A\s*(>=|>|<=|<|!=|!)?\s*(\d{3})\z};

        die "The 'status_code' condition '$part' is not in the correct format!"
            unless defined $code;
        $op = '!=' if defined $op && $op eq '!';

        unless ($op) { push @or,  '$_ == '.$code;    }
        else         { push @and, '$_ '."$op $code"; }
    }
    push @or, '('.join(' && ', @and).')' if @and;  # merge @and as one big condition into @or
    $params{status_code_eval} = join ' || ', @or;

    $params{request}        //= HTTP::Request->new('GET', $params{url});
    $params{options}        //= {};
    $params{options}{agent} //= LWP::UserAgent->_agent .
        " HealthCheck-Diagnostic-WebRequest/" . ( $class->VERSION || '0' );

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
    my $ua = LWP::UserAgent->new( %{$self->{options}} );

    $ua->requests_redirectable([]) if $self->{'no_follow_redirects'};

    my $response = $ua->request( $self->{request} );

    my @results = $self->check_status( $response );
    push @results, $self->check_content( $response )
        if $results[0]->{status} eq 'OK';

    my $info = join '; ', map { $_->{info} } @results;

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::WebRequest - Make HTTP/HTTPS requests to web servers to check connectivity

=head1 VERSION

version v1.3.5

=head1 SYNOPSIS

    # site:    https://foo.com
    # content: <html><head></head><body>This is my content</body></html>

    use HealthCheck::Diagnostic::WebRequest;

    # Look for a 200 status code and pass.
    my $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url => 'https://foo.com',
    );
    my $result = $diagnostic->check;
    print $result->{status}; # OK

    # Look for a 401 status code and fail.
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url         => 'https://foo.com',
        status_code => 401,
    );
    $result = $diagnostic->check;
    print $result->{status}; # CRITICAL

    # Look for any status code less than 500.
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url         => 'https://foo.com',
        status_code => '<500',
    );
    $result = $diagnostic->check;
    print $result->{status}; # CRITICAL

    # Look for any 403, 405, or any 2xx range code
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url         => 'https://foo.com',
        status_code => '403, 405, >=200, <300',
    );
    $result = $diagnostic->check;
    print $result->{status}; # CRITICAL

    # Look for a 200 status code and content matching the string regex.
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url           => 'https://foo.com',
        content_regex => 'is my',
    );
    $result = $diagnostic->check;
    print $result->{status}; # OK

    # Use a regex as the content_regex.
    $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
        url           => 'https://foo.com',
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

=head2 content_regex

The content regex to test for in the HTTP response.
This is an optional field and is only checked if the status
code check passes.
This can either be a I<string> or a I<regex>.

=head2 no_follow_redirects

Setting this variable prevents the healthcheck from following redirects.

=head2 options

See L<LWP::UserAgent> for available options. Takes a hash reference of key/value
pairs in order to configure things like ssl_opts, timeout, etc.

It is optional.

=head1 DEPENDENCIES

L<HealthCheck::Diagnostic>
L<LWP::UserAgent>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
