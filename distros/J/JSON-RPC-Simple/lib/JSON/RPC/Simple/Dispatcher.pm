package JSON::RPC::Simple::Dispatcher;

use strict;
use warnings;

use Carp qw(croak);
use HTTP::Response;
use JSON qw();

sub new {
    my ($pkg, $args) = @_;

    $args = {} unless ref $args eq "HASH";
    
    my $self = bless { 
        charset => "UTF-8",
        json => JSON->new->utf8,
        error_handler => undef,
        %$args,
        target => {} 
    }, $pkg;
    return $self;
}

sub json {
    my $self = shift;
    $self->{json} = shift if @_;
    return $self->{json};
}

sub error_handler {
    my $self = shift;
    $self->{error_handler} = shift if @_;
    return $self->{error_handler};    
}

sub charset {
    my $self = shift;
    $self->{charset} = shift if @_;
    return $self->{charset};
}

sub dispatch_to {
    my ($self, $targets) = @_;
    
    croak "Targets is not hash reference" unless ref $targets eq "HASH";

    while (my ($path, $target) = each %$targets) {
        unless ($target->isa("JSON::RPC::Simple")) {
            croak qq{Target for "${path}" is not a JSON::RPC::Simple};
        }
        $self->{target}->{$path} = $target;
    }
    
    return $self;
}

sub JSONRPC_ERROR { undef; }

our $HTTP_ERROR_CODE;
sub _error {
    my ($self, $request, $id, $code, $message, $error_obj, $call, $target) = @_;

    $message = "Uknown error" unless defined $message;
    
    my $error = {
        (defined $id ? (id => $id) : ()),
        version => "1.1",
        error   => {
            name    => "JSONRPCError",
            code    => int($code),
            message => $message,
        },
    };
    
    if ($error_obj) {
        $error->{error}->{error} = $error_obj;
    }
    else {
        # No error object provided
        # Here, if there's a error callback handler registered on the
        # target first user that, secondly check if there's an
        # error handler on the dispatcher
        my $new_error_obj;
        if ($target && $target->can("JSONRPC_ERROR")) {
            $new_error_obj = $target->JSONRPC_ERROR(
                $request, $code, $message, $call
            );
        }
        $new_error_obj = $self->JSONRPC_ERROR unless $new_error_obj;
        if ($self->error_handler && !$new_error_obj) {
            $new_error_obj = $self->error_handler->(
                $request, $code, $message, $call, $target
            );
        }

        $error->{error}->{error} = $new_error_obj if $new_error_obj;
    }
    
    my $status_line = $HTTP_ERROR_CODE == 200 ? "OK" : "Internal Server Error";
    return $self->_encode_response($HTTP_ERROR_CODE, $status_line, $error);        
}

sub _encode_response {
    my ($self, $code, $message, $response) = @_;
    
    my $content = $self->json->encode($response);
    my $h = HTTP::Headers->new();
    $h->header("Content-Type" => "application/json; charset=" . $self->charset);
    $h->header("Content-Length" => length $content);
    
    return HTTP::Response->new($code, $message, $h, $content);
}

sub errstr { 
    return shift->{errstr} || ""; 
}

sub errobj {
    return shift->{errobj};
}

sub handle {
    my ($self, $path, $request) = @_;
    
    $HTTP_ERROR_CODE = 500;
    
    # Clear any previous errors
    delete $self->{errstr};
    
    # Don't support GET or other methods
    unless ($request->method eq "POST") {
        $self->{errstr} = "I only do POST";
        return $self->_error($request, undef, 0, $self->errstr);
    }
    
    unless ($request->content_type =~ m{^application/json}) {
        $self->{errstr} = 
            "Invalid Content-Type, got '" . $request->content_type . "'";
        return $self->_error($request, undef, 0, $self->errstr);
    }

    # Some requests, like HTTP::Request lazy load content_length so we can't ->can("") it which is why the eval
    my $content_length = eval { $request->content_length };
    if ($@) {
        # Apache2::RequestReq
        $content_length = $request->headers_in->{'Content-Length'} if $request->can("headers_in");
        
        # Fallback
        $content_length = $request->headers->{'Content-Length'} if !defined $content_length && $request->can("headers");
    };
    
    unless (defined $content_length) {
        $self->{errstr} = 
            "JSON-RPC 1.1 requires header Content-Length to be specified";
        return $self->_error($request, undef, 0, $self->errstr);
    }
    
    # Find target
    my $target = $self->{target}->{$path};
    
    # Decode the call and trap errors because it might
    # be invalid JSON
    my $call;
    eval {
        my $content = $request->content;

        # Remove utf-8 BOM if present
        $content =~ s/^(?:\xef\xbb\xbf|\xfe\xff|\xff\xfe)//;
        
        $call = $self->json->decode($content);
    };
    if ($@) {
        $self->{errstr} = "$@";
        $self->{errobj} = $@;
        return $self->_error(
            $request, undef, 0, $self->errstr, undef, undef, $target
        );
    }
    
    my $id = $call->{id};
    my $version = $call->{version};
    unless (defined $version) {
        $self->{errstr} = "Missing 'version'";
        return $self->_error(
            $request, $id, 0, $self->errstr, undef, $call, $target
        );
    }
    unless ($version eq "1.1") {
        $self->{errstr} = "I only do JSON-RPC 1.1";
        return $self->_error(
            $request, $id, 0, $self->errstr, undef, $call, $target
        );
    }
    
    my $method = $call->{method};
    unless ($method) {
        $self->{errstr} = "Missing method";
        $self->_error($request, $id, 0, $self->errstr, undef, $call, $target);
    }
    
    
    my $params = $call->{params};
    unless ($params) {
        $self->_error($id, 0, $self->errstr, undef, $call, $target);
    }

    unless (ref $params eq "HASH" || ref $params eq "ARRAY") {
        $self->{errstr} = "Invalid params, expecting object or array";
        return $self->_error(
            $request, $id, 0, $self->errstr, undef, $call, $target
        );
    }    

    unless ($target) {
        $self->{errstr} = "No target for '${path}' exists";
        return $self->_error(
            $request, $id, 0, $self->errstr, undef, $call, $target
        );
    }
    
    my $cv = $target->can($method);
    my $check_attrs;
    if ($cv) {
        # Check that it's a JSONRpcMethod
        my @attrs = JSON::RPC::Simple->fetch_method_arguments($cv);
        unless (@attrs) {
            $self->{errstr} = "Procedure not found";
            return $self->_error(
                $request, $id, 0, $self->errstr, undef, $call, $target
            );
        }
        $check_attrs = shift @attrs;
    }
    else {
        # Check for fallback
        if ($cv = $target->can("JSONRPC_AUTOLOAD")) {
            my $pkg = ref $target || $target;
            no strict 'refs';
            ${"${pkg}::JSONRPC_AUTOLOAD"} = $method;
            
            if (my $attrs_cv = $target->can("JSONRPC_AUTOLOAD_ATTRS")) {
                my @attrs = $attrs_cv->($target, $request);
                unless (@attrs) {
                    $self->{errstr} = "Procedure not found";
                    return $self->_error(
                        $request, $id, 0, $self->errstr, undef, $call, $target
                    );
                }
                $check_attrs = shift @attrs;
            }
        }
        else {
            $self->{errstr} = "Procedure not found";
            return $self->_error(
                $request, $id, 0, $self->errstr, undef, $call, $target
            );        
        }
    }
    
    # Named arguments defined, 
    if ($check_attrs && @$check_attrs && ref $params eq "ARRAY") {
        my %named_params = map {
            $_ => shift @$params
        } @$check_attrs;
        $params = \%named_params;
    }
    
    my $rval;
    eval {
        $rval = $cv->($target, $request, $params);
    };
    if ($@) {
        $self->{errstr} = "$@";
        $self->{errobj} = $@;
        return $self->_error($request, $id, @{$@}) if ref $@ eq "ARRAY";
        return $self->_error($request, $id, 0, "$@", undef, $call, $target);
    }
    
    my $response;
    eval {
        $response = $self->_encode_response(200, "OK", {
            (defined $id ? (id => $id) : ()),
            version => "1.1",
            result  => $rval,
        });
    };
    if ($@) {
        $self->{errstr} = "$@";
        $self->{errobj} = $@;
        return $self->_error(
            $request, $id, 0, "Failed to encode response", undef, $call, $target
        );
    }
    
    return $response;
}

sub target {
    my ($self, $target) = @_;
    return $self->{target}->{$target};
}

1;

=head1 NAME

JSON::RPC::Simple::Dispatcher - Decodes JSON-RPC calls and dispatches them

=head1 DESCRIPTION

Instances of this class decodes JSON-RPC calls over HTTP and dispatches them to 
modules/objects registered for a given path and then encodes the result as in a 
JSON-RPC format.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( %opts )

Creates a new dispatcher instance. Can take the the following optional named 
arguments:

=over 4

=item json

The encoder/decoder object to use. Defaults to L<JSON> with utf8 on.

=item charset

The charset to send in the content-type when creating the response. Defaults 
to C<utf-8>.

=item error_handler 

A reference to a subroutine which is invoked when an error occurs. May 
optionally return an object which will be sent as the 'error' member of the 
result. When called it is passed the request object, the error code, error 
message, the call ID and target object if any.

=back

=back

=head2 CLASS VARIABLES

=over 4

=item $HTTP_ERROR_CODE

This is the HTTP result code. It's reset to 500 (Internal Server Error) each 
time handle is called. You may change this in your error handling routine.

=back

=head2 INSTANCE METHODS

=over 4

=item json

=item json ( $json )
 
Gets/sets the json object to use for encoding/decoding

=item charset

=item charset ( $charset )

Gets/sets the charset to use when creating the HTTP::Response object.

=item error_handler ( \&handler )

Gets/sets the error handler to call when an error occurs.

=item dispatch_to ( \%targets )

Sets the dispatch table. The dispatch-table is a path to instance mapping where 
the key is a path and the value the instance of class for which to call the 
method on. For example

  $o->dispatch_to({
    "/API" => "MyApp::API",
    "/Other/API" => MyApp::OtherAPI->new(),
  });

=item handle ( $path, $request )

This method decodes the $request which should be a HTTP::Request look-a-like 
object and finds the appropriate target in the dispatch table for $path.

The $request object MUST provide the following methods:

=over 4

=item method

The HTTP method of the request such as GET, POST, HEAD, PUT in captial letters.

=item content_type

The Content-Type header from the request.

=item content_length

The Content-Length header from the request.

=item content

The content of the request as we only handle POST.

=back

The content is stripped from any unicode BOM before being passed to the JSON 
decoder. 

=back

=cut