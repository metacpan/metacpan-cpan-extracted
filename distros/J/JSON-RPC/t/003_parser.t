use strict;
use Test::More;
use Plack::Request;
use JSON;

use_ok "JSON::RPC::Parser";
use_ok "JSON::RPC::Procedure";

subtest 'basic' => sub {
    my $req = Plack::Request->new( {
        QUERY_STRING   => 'method=sum&params=[1,2,3]&id=1',
        REQUEST_METHOD => "GET",
    } );
    my $parser = JSON::RPC::Parser->new(
        coder => JSON->new,
    );

    my $procedure = $parser->construct_from_req( $req );
    ok $procedure, "procedure is defined";
    isa_ok $procedure, "JSON::RPC::Procedure";
    is $procedure->id, 1, "id matches";
    is $procedure->method, "sum", "method matches";
    is_deeply $procedure->params, [ 1, 2, 3 ], "parameters match";

    my $request_hash = {
        "method" => "sum",
        "params" => [1, 2, 3],
        "id" => 2,
        "jsonrpc" => "2.0"
    };
    my $request_json = to_json($request_hash);
    open my $input, "<", \$request_json;
    my $cl = length $request_json;
    $req = Plack::Request->new( {
        'psgi.input'   => $input,
        REQUEST_METHOD => "POST",
        CONTENT_LENGTH => $cl,
        CONTENT_TYPE   => 'application/json'
    } );
    $procedure = $parser->construct_from_req( $req );
    is $procedure->jsonrpc, "2.0", "jsonrpc matches";
    ok $procedure->has_id, "has id";
    close $input;

    delete $request_hash->{id};
    $request_json = to_json($request_hash);
    open $input, "<", \$request_json;
    $cl = length $request_json;
    $req = Plack::Request->new( {
        'psgi.input'   => $input,
        REQUEST_METHOD => "POST",
        CONTENT_LENGTH => $cl,
        CONTENT_TYPE   => 'application/json'
    } );
    $procedure = $parser->construct_from_req( $req );
    ok !$procedure->has_id, "does not have an id";
    close $input;

    my $request_array = [
        {
            "method" => "ping",
            "id" => undef,
            "jsonrpc" => "2.0"
        },
        {
            "method" => "ping",
            "id" => 3,
            "jsonrpc" => "2.0"
        },
    ];
    $request_json = to_json($request_array);
    open $input, "<", \$request_json;
    $cl = length $request_json;
    $req = Plack::Request->new( {
        'psgi.input'   => $input,
        REQUEST_METHOD => "POST",
        CONTENT_LENGTH => $cl,
        CONTENT_TYPE   => 'application/json'
    } );
    my $procedures = $parser->construct_from_req( $req );
    ok $procedures, "procedures are defined";
    is @$procedures, 2, "should be 2 procedures";
    ok (($procedures->[0]->has_id && $procedures->[1]->has_id), "both procedures have ids");
    ok ((!defined $procedures->[0]->id), "first procedure has NULL id");
    is $procedures->[1]->id, 3, "second procedure id matches";
    close $input;
};

done_testing;
