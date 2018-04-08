package JSON::RPC2::Server;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.1.2';

use JSON::MaybeXS;

use constant ERR_PARSE  => -32700;
use constant ERR_REQ    => -32600;
use constant ERR_METHOD => -32601;
use constant ERR_PARAMS => -32602;


sub new {
    my ($class) = @_;
    my $self = {
        method  => {},
    };
    return bless $self, $class;
}

sub register {
    my ($self, $name, $cb) = @_;
    $self->{method}{ $name } = [ $cb, 1, 0 ];
    return;
}

sub register_named {
    my ($self, $name, $cb) = @_;
    $self->{method}{ $name } = [ $cb, 1, 1 ];
    return;
}

sub register_nb {
    my ($self, $name, $cb) = @_;
    $self->{method}{ $name } = [ $cb, 0, 0 ];
    return;
}

sub register_named_nb {
    my ($self, $name, $cb) = @_;
    $self->{method}{ $name } = [ $cb, 0, 1 ];
    return;
}

sub execute {
    my ($self, $json, $cb) = @_;
    croak 'require 2 params' if 1+2 != @_;
    croak 'second param must be callback' if ref $cb ne 'CODE';

    undef $@;
    my $request = ref $json ? $json : eval { decode_json($json) };
    if ($@) {
        return _error($cb, undef, ERR_PARSE, 'Parse error.');
    }
    if (ref $request eq 'HASH') {
        return $self->_execute($request, $cb);
    }
    if (ref $request ne 'ARRAY') {
        return _error($cb, undef, ERR_REQ, 'Invalid Request: expect Array or Object.');
    }
    if (!@{$request}) {
        return _error($cb, undef, ERR_REQ, 'Invalid Request: empty Array.');
    }

    my $pending = @{$request};
    my @responses;
    my $cb_acc = sub {
        my ($json_response) = @_;
        if ($json_response) {
            push @responses, $json_response;
        }
        if (!--$pending) {
            if (@responses) {
                $cb->( '[' . join(q{,}, @responses) . ']' );
            } else {
                $cb->( q{} );
            }
        }
        return;
    };
    for (@{$request}) {
        $self->_execute($_, $cb_acc);
    }

    return;
}

sub _execute {
    my ($self, $request, $cb) = @_;

    my $error = \&_error;
    my $done  = \&_done;

    # jsonrpc =>
    if (!defined $request->{jsonrpc} || ref $request->{jsonrpc} || $request->{jsonrpc} ne '2.0') {
        return $error->($cb, undef, ERR_REQ, 'Invalid Request: expect {jsonrpc}="2.0".');
    }

    # id =>
    my $id;
    if (exists $request->{id}) {
        # Request
        if (ref $request->{id}) {
            return $error->($cb, undef, ERR_REQ, 'Invalid Request: expect {id} is scalar.');
        }
        $id = $request->{id};
    }

    # method =>
    if (!defined $request->{method} || ref $request->{method}) {
        return $error->($cb, $id, ERR_REQ, 'Invalid Request: expect {method} is String.');
    }
    my $handler = $self->{method}{ $request->{method} };
    if (!$handler) {
        return $error->($cb, $id, ERR_METHOD, 'Method not found.');
    }
    my ($method, $is_blocking, $is_named) = @{$handler};

    # params =>
    if (!exists $request->{params}) {
        $request->{params} = $is_named ? {} : [];
    }
    if (ref $request->{params} ne 'ARRAY' && ref $request->{params} ne 'HASH') {
        return $error->($cb, $id, ERR_REQ, 'Invalid Request: expect {params} is Array or Object.');
    }
    if (ref $request->{params} ne ($is_named ? 'HASH' : 'ARRAY')) {
        return $error->($cb, $id, ERR_PARAMS, 'This method expect '.($is_named ? 'named' : 'positional').' params.');
    }
    my @params = $is_named ? %{ $request->{params} } : @{ $request->{params} };

    # id => (continue)
    if (!exists $request->{id}) {
        # Notification
        $error = \&_nothing;
        $done  = \&_nothing;
    }

    # execute
    if ($is_blocking) {
        my @returns = $method->( @params );
        $done->($cb, $id, \@returns);
    }
    else {
        my $cb_done = sub { $done->($cb, $id, \@_) };
        $method->( $cb_done, @params );
    }
    return;
}

sub _done {
    my ($cb, $id, $returns) = @_;
    my ($result, $code, $msg, $data) = @{$returns};
    if (defined $code) {
        return _error($cb, $id, $code, $msg, $data);
    }
    return _result($cb, $id, $result);
}

sub _error {
    my ($cb, $id, $code, $message, $data) = @_;
    $cb->( encode_json({
        jsonrpc     => '2.0',
        id          => $id,
        error       => {
            code        => $code,
            message     => $message,
            (defined $data ? ( data => $data ) : ()),
        },
    }) );
    return;
}

sub _result {
    my ($cb, $id, $result) = @_;
    $cb->( encode_json({
        jsonrpc     => '2.0',
        id          => $id,
        result      => $result,
    }) );
    return;
}

sub _nothing {
    my ($cb) = @_;
    $cb->( q{} );
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

JSON::RPC2::Server - Transport-independent JSON-RPC 2.0 server


=head1 VERSION

This document describes JSON::RPC2::Server version v2.1.2


=head1 SYNOPSIS

    use JSON::RPC2::Server;

    my $rpcsrv = JSON::RPC2::Server->new();

    $rpcsrv->register('func1', \&func1);
    $rpcsrv->register_nb('func2', \&func2);
    $rpcsrv->register_named('func3', \&func3);
    $rpcsrv->register_named_nb('func4', \&func4);

    # receive remote request in $json_request somehow, then:
    $rpcsrv->execute( $json_request, \&send_response );

    sub send_response {
        my ($json_response) = @_;
        # send $json_response somehow
    }

    sub func1 {
        my (@remote_params) = @_;
        if (success) {
            return ($result);
        } else {
            return (undef, $err_code, $err_message);
        }
    }

    sub func2 {
        my ($callback, @remote_params) = @_;
        # setup some event to call func2_finished($callback) later
    }
    sub func2_finished {
        my ($callback) = @_;
        if (success) {
            $callback->($result);
        } else {
            $callback->(undef, $err_code, $err_message);
        }
        return;
    }

    sub func3 {
        my (%remote_params) = @_;
        # rest the same as in func1
    }

    sub func4 {
        my ($callback, %remote_params) = @_;
        # rest the same as in func2
    }

    #
    # EXAMPLE of simple blocking STDIN-STDOUT server
    #

    my $rpcsrv = JSON::RPC2::Server->new();
    $rpcsrv->register('method1', \&method1);
    $rpcsrv->register('method2', \&method2);
    while (<STDIN>) {
        chomp;
        $rpcsrv->execute($_, sub { printf "%s\n", @_ });
    }
    sub method1 {
        return { my_params => \@_ };
    }
    sub method2 {
        return (undef, 0, "don't call me please");
    }

=head1 DESCRIPTION

Transport-independent implementation of JSON-RPC 2.0 server.
Server methods can be blocking (simpler) or non-blocking (useful if
method have to do some slow tasks like another RPC or I/O which can
be done in non-blocking way - this way several methods can be executing
in parallel on server).


=head1 INTERFACE 

=head2 new

    $rpcsrv = JSON::RPC2::Server->new();

Create and return new server object, which can be used to register and
execute user methods.

=head2 register

=head2 register_named

    $rpcsrv->register( $rpc_method_name, \&method_handler );
    $rpcsrv->register_named( $rpc_method_name, \&method_handler );

Register $rpc_method_name as allowed method name for remote procedure call
and set \&method_handler as BLOCKING handler for that method.

If there already was some handler set (using register() or
register_named() or register_nb() or register_named_nb()) for that
$rpc_method_name - it will be replaced by \&method_handler.

While processing request to $rpc_method_name user handler will be called
with parameters provided by remote side (as ARRAY for register() or HASH
for register_named()), and should return it result as list with 4
elements:

 ($result, $code, $message, $data) = method_handler(@remote_params);
 ($result, $code, $message, $data) = method_handler(%remote_params);

 $result        scalar or complex structure if method call success
 $code          error code (integer, > -32600) if method call failed
 $message       error message (string) if message call failed
 $data          optional scalar with additional error-related data

If $code is defined then $result shouldn't be defined; $message required
only if $code defined.

Return nothing.

=head2 register_nb

=head2 register_named_nb

    $rpcsrv->register_nb( $rpc_method_name, \&nb_method_handler );
    $rpcsrv->register_named_nb( $rpc_method_name, \&nb_method_handler );

Register $rpc_method_name as allowed method name for remote procedure call
and set \&method_handler as NON-BLOCKING handler for that method.

If there already was some handler set (using register() or
register_named() or register_nb() or register_named_nb()) for that
$rpc_method_name - it will be replaced by \&method_handler.

While processing request to $rpc_method_name user handler will be called
with callback needed to return result in first parameter and parameters
provided by remote side as next parameters (as ARRAY for register_nb() or
HASH for register_named_nb()), and should call provided callback with list
with 4 elements when done:

 nb_method_handler($callback, @remote_params);
 nb_method_handler($callback, %remote_params);

 # somewhere in that method handlers:
 $callback->($result, $code, $message, $data);
 return;

Meaning of ($result, $code, $message, $data) is same as documented in
register() above.

Return nothing.

=head2 execute

    $rpcsrv->execute( $json_request, $callback );

The $json_request can be either JSON string or ARRAYREF/HASHREF (useful
with C<< $handle->push_read(json => sub{...}) >> from L<AnyEvent::Handle>).

Parse $json_request and execute registered user handlers. Reply will be
sent into $callback, when ready:

 $callback->( $json_response );

The $callback will be always executed after finishing processing
$json_request - even if request type was "notification" (in this case
$json_response will be an empty string).

Return nothing.


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
