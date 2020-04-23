package JSON::RPC2::AnyEvent::Constants;
use 5.010;
use strict;
use warnings;


my %constants;
BEGIN{
    # Based upon JSON-RPC spec 2.0 - http://www.jsonrpc.org/specification
    %constants = (
        ERR_PARSE_ERROR      => -32700,  # Invalid JSON was received by the server.
                                         # An error occurred on the server while parsing the JSON text.
        ERR_INVALID_REQUEST  => -32600,  # The JSON sent is not a valid Request object.
        ERR_METHOD_NOT_FOUND => -32601,  # The method does not exist / is not available.
        ERR_INVALID_PARAMS   => -32602,  # Invalid method parameter(s).
        ERR_INTERNAL_ERROR   => -32603,  # Internal JSON-RPC error.
        ERR_SERVER_ERROR     => -32000,  # -32000 to -32099: Reserved for implementation-defined server-errors.
    );
}

use constant \%constants;

use parent qw(Exporter);
our @EXPORT_OK = keys %constants;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);


1;
