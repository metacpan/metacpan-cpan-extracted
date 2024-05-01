use strict;
use Test::More;
use Plack::Test;
use Lemonldap::NG::Common::PSGI::Request;

use JSON;
use HTTP::Request;
use HTTP::Message::PSGI;

# UTF-8 awareness
use utf8;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

sub build_json_request {
    my ($href) = @_;
    my $header = [ 'Content-Type' => 'application/json; charset=UTF-8' ];
    return HTTP::Request->new( 'POST', "http://www.example.com", $header,
        encode_json($href) );
}

subtest "Request ID" => sub {
    my $req = Lemonldap::NG::Common::PSGI::Request->new(
        HTTP::Request->new( GET => 'http://www.example.com/' )->to_psgi );

    my $request_id = $req->request_id;
    like( $request_id, qr/^\w{16}$/, "Generated request ID" );
    is( $req->request_id, $request_id, "Request ID is stable across calls" );

    my $req2 = Lemonldap::NG::Common::PSGI::Request->new(
        HTTP::Request->new( GET => 'http://www.example.com/' )->to_psgi );
    isnt( $req2->request_id, $request_id,
        "Request ID is different for each request" );

    my $req3 = Lemonldap::NG::Common::PSGI::Request->new(
        HTTP::Request->new( GET => 'http://www.example.com/' )
          ->to_psgi( UNIQUE_ID => 123456 ) );

    is( $req3->request_id, "123456",
        "Request ID is read from UNIQUE_ID env if set" );
};

subtest "Request JSON body" => sub {
    my $req = Lemonldap::NG::Common::PSGI::Request->new(
        build_json_request( { key1 => 123, key2 => "€ncoded" } )->to_psgi );

    ok(1);
    ok( my $obj = $req->jsonBodyToObj, "Found JSON body" );
    is( $obj->{key1}, "123", "Found correct ascii value" );

  TODO: {
        local $TODO = "UTF-8 handling in request is broken, see #2748";
        is( $obj->{key2}, "€ncoded", "Found correct UTF-8 value" );
    }
};

done_testing();
