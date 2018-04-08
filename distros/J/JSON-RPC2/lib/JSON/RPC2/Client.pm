package JSON::RPC2::Client;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.1.2';

use JSON::MaybeXS;
use Scalar::Util qw( weaken refaddr );


sub new {
    my ($class) = @_;
    my $self = {
        next_id     => 0,
        free_id     => [],
        call        => {},
        id          => {},
    };
    return bless $self, $class;
}

sub batch {
    my ($self, @requests) = @_;
    my @call  = grep {ref}  @requests;
    @requests = grep {!ref} @requests;
    croak 'at least one request required' if !@requests;
    my $request = '['.join(q{,}, @requests).']';
    return ($request, @call);
}

sub notify {
    my ($self, $method, @params) = @_;
    croak 'method required' if !defined $method;
    return encode_json({
        jsonrpc     => '2.0',
        method      => $method,
        (!@params ? () : (
        params      => \@params,
        )),
    });
}

sub notify_named {
    my ($self, $method, @params) = @_;
    croak 'method required' if !defined $method;
    croak 'odd number of elements in %params' if @params % 2;
    my %params = @params;
    return encode_json({
        jsonrpc     => '2.0',
        method      => $method,
        (!@params ? () : (
        params      => \%params,
        )),
    });
}

sub call {
    my ($self, $method, @params) = @_;
    croak 'method required' if !defined $method;
    my ($id, $call) = $self->_get_id();
    my $request = encode_json({
        jsonrpc     => '2.0',
        method      => $method,
        (!@params ? () : (
        params      => \@params,
        )),
        id          => $id,
    });
    return wantarray ? ($request, $call) : $request;
}

sub call_named {
    my ($self, $method, @params) = @_;
    croak 'method required' if !defined $method;
    croak 'odd number of elements in %params' if @params % 2;
    my %params = @params;
    my ($id, $call) = $self->_get_id();
    my $request = encode_json({
        jsonrpc     => '2.0',
        method      => $method,
        (!@params ? () : (
        params      => \%params,
        )),
        id          => $id,
    });
    return wantarray ? ($request, $call) : $request;
}

sub _get_id {
    my $self = shift;
    my $id = @{$self->{free_id}} ? pop @{$self->{free_id}} : $self->{next_id}++;
    my $call = {};
    $self->{call}{ refaddr($call) } = $call;
    $self->{id}{ $id } = $call;
    weaken($self->{id}{ $id });
    return ($id, $call);
}

sub pending {
    my ($self) = @_;
    return values %{ $self->{call} };
}

sub cancel {
    my ($self, $call) = @_;
    croak 'no such request' if !delete $self->{call}{ refaddr($call) };
    return;
}

sub batch_response {
    my ($self, $json) = @_;
    croak 'require 1 param' if @_ != 2;

    undef $@;
    my $response = ref $json ? $json : eval { decode_json($json) };
    if ($@) {
        return [ 'Parse error' ];
    }
    if ($response && ref $response eq 'HASH') {
        return [ $self->response($response) ];
    }
    if (!$response || ref $response ne 'ARRAY') {
        return [ 'expect Array or Object' ];
    }
    if (!@{$response}) {
        return [ 'empty Array' ];
    }

    return map {[ $self->response($_) ]} @{$response};
}

sub response {      ## no critic (ProhibitExcessComplexity RequireArgUnpacking)
    my ($self, $json) = @_;
    croak 'require 1 param' if @_ != 2;

    undef $@;
    my $response = ref $json ? $json : eval { decode_json($json) };
    if ($@) {
        return 'Parse error';
    }
    if (ref $response ne 'HASH') {
        return 'expect Object';
    }
    if (!defined $response->{jsonrpc} || $response->{jsonrpc} ne '2.0') {
        return 'expect {jsonrpc}="2.0"';
    }
    if (!exists $response->{id} || ref $response->{id} || !defined $response->{id}) {
        return 'expect {id} is scalar';
    }
    if (!exists $self->{id}{ $response->{id} }) {
        return 'unknown {id}';
    }
    if (!(exists $response->{result} xor exists $response->{error})) {
        return 'expect {result} or {error}';
    }
    if (exists $response->{error}) {
        my $e = $response->{error};
        if (ref $e ne 'HASH') {
            return 'expect {error} is Object';
        }
        if (!defined $e->{code} || ref $e->{code} || $e->{code} !~ /\A-?\d+\z/xms) {
            return 'expect {error}{code} is Integer';
        }
        if (!defined $e->{message} || ref $e->{message}) {
            return 'expect {error}{message} is String';
        }
        ## no critic (ProhibitMagicNumbers)
        if ((3 == keys %{$e} && !exists $e->{data}) || 3 < keys %{$e}) {
            return 'only optional key must be {error}{data}';
        }
    }

    my $id = $response->{id};
    push @{ $self->{free_id} }, $id;
    my $call = delete $self->{id}{ $id };
    if ($call) {
        $call = delete $self->{call}{ refaddr($call) };
    }
    if (!$call) {
        return; # call was canceled
    }
    return (undef, $response->{result}, $response->{error}, $call);
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

JSON::RPC2::Client - Transport-independent JSON-RPC 2.0 client


=head1 VERSION

This document describes JSON::RPC2::Client version v2.1.2


=head1 SYNOPSIS

 use JSON::RPC2::Client;

 $client = JSON::RPC2::Client->new();

 $json_request = $client->notify('method', @params);
 $json_request = $client->notify_named('method', %params);
 ($json_request, $call) = $client->call('method', @params);
 ($json_request, $call) = $client->call_named('method', %params);

 ($json_request, @call) = $client->batch(
    $client->call('method1', @params),
    $client->call('method2', @params),
    $client->notify('method', @params),
    $client->call_named('method', %params),
    $client->notify_named('method', %params),
 );

 $client->cancel($call);

 ($failed, $result, $error, $call) = $client->response($json_response);

 for ($client->batch_response($json_response)) {
    ($failed, $result, $error, $call) = @{ $_ };
    ...
 }

 @call = $client->pending();

 #
 # EXAMPLE of simple blocking STDIN-STDOUT client
 #
 
 $client = JSON::RPC2::Client->new();
 $json_request = $client->call('method', @params);

 printf "%s\n", $json_request;
 $json_response = <STDIN>;
 chomp $json_response;

 ($failed, $result, $error) = $client->response($json_response);
 if ($failed) {
    die "bad response: $failed";
 } elsif ($error) {
    printf "method(@params) failed with code=%d: %s\n",
        $error->{code}, $error->{message};
 } else {
    print "method(@params) returned $result\n";
 }

=head1 DESCRIPTION

Transport-independent implementation of JSON-RPC 2.0 client.
Can be used both in sync (simple, for blocking I/O) and async
(for non-blocking I/O in event-based environment) mode.


=head1 INTERFACE 

=head2 new

    $client = JSON::RPC2::Client->new();

Create and return new client object, which can be used to generate requests
(notify(), call()), parse responses (responses()) and cancel pending requests
(cancel(), pending()).

Each client object keep track of request IDs, so you must use dedicated
client object for each connection to server.

=head2 notify

=head2 notify_named

    $json_request = $client->notify( $remote_method, @remote_params );
    $json_request = $client->notify_named( $remote_method, %remote_params );

Notifications doesn't receive any replies, so they unreliable.

Return ($json_request) - scalar which should be sent to server in any way.

=head2 call

=head2 call_named

    ($json_request, $call) = $client->call( $remote_method, @remote_params );
    ($json_request, $call) = $client->call_named( $remote_method, %remote_params );

Return ($json_request, $call) - scalar which should be sent to server in
any way and identifier of this remote procedure call.

The $call is just empty HASHREF, which can be used to: 1) keep user data
related to this call in hash fields - that $call will be returned by
response() when response to this call will be received; 2) to cancel()
this call before response will be received. There usually no need for
user to keep $call somewhere unless he wanna be able to cancel() that call.

In scalar context return only $json_request - this enough for simple
blocking clients which doesn't need to detect which of several pending()
calls was just replied or cancel() pending calls.

=head2 batch

    ($json_request, @call) = $client->batch(
        $json_request1,
        $json_request2,
        $call2,
        $json_request3,
        ...
    );

Return ($json_request, @call) - scalar which should be sent to server in
any way and identifiers of these remote procedure calls (they'll be in
same order as they was in params). These two example are equivalent:

    ($json_request, $call1, $call3) = $client->batch(
        $client->call('method1'),
        $client->notify('method2'),
        $client->call('method3'),
    );

    ($json1, $call1) = $client->call('method1');
    $json2           = $client->notify('method2');
    ($json3, $call3) = $client->call('method3');
    $json_request = $client->batch($json1, $json2, $json3);

If you're using batch() to send some requests then you should process
RPC server's responses using batch_response(), not response().

=head2 batch_response

    @responses = $client->batch_response( $json_response );

The $json_response can be either JSON string or ARRAYREF/HASHREF (useful
with C<< $handle->push_read(json => sub{...}) >> from L<AnyEvent::Handle>).

Will parse $json_response and return list with ARRAYREFS, which contain
4 elements returned by response().

It is safe to always use batch_response() instead of response(), even if
you don't send batch() requests at all.

=head2 response

    ($failed, $result, $error, $call) = $client->response( $json_response );

The $json_response can be either JSON string or HASHREF (useful
with C<< $handle->push_read(json => sub{...}) >> from L<AnyEvent::Handle>).

Will parse $json_response and return list with 4 elements:

 ($failed, $result, $error, $call)

 $failed        parse error message if $json_response is incorrect
 $result        data returned by successful remote method call
 $error         error returned by failed remote method call
 $call          identifier of this call

If $failed defined then all others are undefined. Usually that mean either
bug in JSON-RPC client or server.

Only one of $result and $error will be defined. Format of $result
completely depends on data returned by remote method. $error is HASHREF
with fields {code}, {message}, {data} - code should be integer, message
should be string, and data is optional value in arbitrary format.

The $call should be used to identify which of currently pending() calls
just returns - it will be same HASHREF as was initially returned by call()
when starting this remote procedure call, and may contain any user data
which was placed in it after calling call().

There also special case when all 4 values will be undefined - that happens
if $json_response was related to call which was already cancel()ed by user.

If you're using batch() to send some requests then you should process
RPC server's responses using batch_response(), not response().

=head2 cancel

    $client->cancel( $call );

Will cancel that $call. This doesn't affect server - it will continue
processing related request and will send response when ready, but that
response will be ignored by client's response().

Return nothing.

=head2 pending

    @call = $client->pending();

Return list with all currently pending $call's.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-JSON-RPC2/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-JSON-RPC2>

    git clone https://github.com/powerman/perl-JSON-RPC2.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=JSON-RPC2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/JSON-RPC2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JSON-RPC2>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=JSON-RPC2>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/JSON-RPC2>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
