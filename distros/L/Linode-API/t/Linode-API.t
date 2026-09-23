#!/usr/bin/env perl
use 5.016;

use strict;
use warnings FATAL => 'all';
use re '/aa';

=head1 NAME

t/Linode-API.t - that a client built from Linode's specification sends its
token, puts the API version in the URL, and refuses what the specification
would

=cut

use Test2::V1 -i;
use Test2::Plugin::NoWarnings;

use Test::File::ShareDir::Dist { 'Linode-API' => 'share' };
use FindBin::libs;

use Cpanel::JSON::XS();
use File::ShareDir();
use Mojolicious();

use Linode::API();

# A stand-in for api.linode.com that answers everything and remembers what it
# was asked, so a test can say what went over the wire.
my @requests;
my $fake = Mojolicious->new;
$fake->log->level('fatal');
$fake->routes->any(
    '/*whatever' => sub {
        my ($c) = @_;
        push @requests, $c->req;
        $c->render( json => { data => [], page => 1, pages => 1, results => 0 } );
    }
);

sub client {
    my (%options) = @_;
    return Linode::API->new( app => $fake, %options );
}

sub last_request {
    my ($what) = @_;
    @requests = ();
    my $tx = $what->();
    is( scalar @requests, 1, 'one request reached the fake API' ) or diag( $tx->res->body );
    return $requests[0];
}

subtest 'new' => sub {
    my $linode = client( token => 'token-one' );
    isa_ok( $linode, 'Linode::API' );

    my $req = last_request( sub { $linode->get_linode_instances( {} ) } );
    is( $req->url->path->to_string,   '/v4/linode/instances', 'the default API version is written into the path' );
    is( $req->headers->authorization, 'Bearer token-one',     'the token goes as a bearer token' );

    $req = last_request( sub { $linode->call( 'get-linode-instances' => {} ) } );
    is( $req->url->path->to_string, '/v4/linode/instances', 'the operationId as Linode spells it works through call' );

    $req = last_request(
        sub {
            my $tx;
            $linode->get_linode_instances_p( {} )->then( sub { $tx = shift } )->wait;
            $tx;
        }
    );
    is( $req->url->path->to_string, '/v4/linode/instances', 'the promise form has a snake_case alias too' );

    $req = last_request( sub { $linode->post_linode_instance( {}, json => { region => 'bogus', type => 'bogus' } ) } );
    is( $req->json, { region => 'bogus', type => 'bogus' }, 'a body the specification closes in one allOf member and opens in another is sent' );

    $req = last_request( sub { $linode->get_image( { imageId => 'private/123' } ) } );
    is( $req->url->path->to_string, '/v4/images/private/123', 'an id with a slash in it is sent with the slash, as Linode wants' );

    $req = last_request( sub { $linode->get_maintenance_policies( {} ) } );
    is( $req->url->path->to_string, '/v4beta/maintenance/policies', 'an operation that is only in v4beta goes there from a v4 client' );

    $req = last_request( sub { $linode->get_linode_instance( { linodeId => 42 } ) } );
    is( $req->url->path->to_string, '/v4/linode/instances/42', 'path parameters other than the version are still filled in' );

    $req = last_request( sub { $linode->get_linode_instances( { 'X-Filter' => '{"label":"bogus"}', page_size => 500 } ) } );
    is( $req->headers->header('X-Filter'),    '{"label":"bogus"}', 'a declared header parameter is sent' );
    is( $req->url->query->param('page_size'), 500,                 'a query parameter is sent' );

    my $beta = client( token => 'token-two', api_version => 'v4beta' );
    $req = last_request( sub { $beta->get_linode_instances( {} ) } );
    is( $req->url->path->to_string,   '/v4beta/linode/instances', 'api_version picks the version in the path' );
    is( $req->headers->authorization, 'Bearer token-two',         'each client sends its own token' );

    $req = last_request( sub { $linode->get_linode_instances( {} ) } );
    is( $req->headers->authorization, 'Bearer token-one', 'building a second client does not change the first one\'s token' );

    $req = last_request( sub { client()->get_linode_instances( {} ) } );
    is( $req->headers->authorization, undef, 'without a token, no Authorization header is sent' );

    like(
        dies { client( api_version => 'v3' ) },
        qr/api_version 'v3' is not in the specification, which offers \[v2beta, v4, v4beta\]/,
        'an API version the specification does not offer is refused, naming the ones it does',
    );
};

subtest 'invalid requests are not sent' => sub {
    my $linode = client( token => 'token-one' );

    @requests = ();
    my $tx = $linode->get_linode_instance( {} );
    is( scalar @requests,   0,   'a request missing a required path parameter never reaches the API' );
    is( $tx->error->{code}, 400, 'and says so with a 400' );
    like( $tx->res->json->{errors}[0]{path}, qr/linodeId/, 'naming the parameter that is missing' ) or diag( $tx->res->body );

    @requests = ();
    $tx       = $linode->get_linode_instances( { 'X-Filter' => { label => 'bogus' } } );
    is( scalar @requests, 0, 'an X-Filter given as a hashref is not sent as HASH(0x...)' );
    like( $tx->res->json->{errors}[0]{path}, qr/X-Filter/, 'it is refused, naming the header' ) or diag( $tx->res->body );
};

subtest '_specification' => sub {
    my $file = File::ShareDir::dist_file( 'Linode-API', 'openapi.json' );

    my $v4 = Linode::API::_specification( $file, 'v4' );
    ref_is( Linode::API::_specification( $file, 'v4' ), $v4, 'the same file and version give back the same specification' );
    ref_is_not( Linode::API::_specification( $file, 'v4beta' ), $v4, 'a different version gets one of its own' );

    is( ref client(), ref client(), 'so two clients of the same version share one generated class' );
};

subtest '_fix_json_headers' => sub {
    my $object = { in    => 'header', name => 'X-Filter', schema => { oneOf => [ { type => 'object' } ] } };
    my $string = { in    => 'header', name => 'X-Bogus',  schema => { type  => 'string', maxLength => 3 } };
    my $query  = { in    => 'query',  name => 'filter',   schema => { type  => 'object' } };
    my $spec   = { paths => { '/things' => { parameters => [$string], get => { parameters => [ $object, $query ] } } } };

    Linode::API::_fix_json_headers($spec);
    is( $object->{schema}, { type => 'string', description => 'JSON' }, 'a header described as an object becomes a string' );
    is( $string->{schema}, { type => 'string', maxLength   => 3 },      'a header that is already a string keeps its schema' );
    is( $query->{schema},  { type => 'object' }, 'a parameter that is not a header is left alone' );
};

subtest '_fix_closed_all_of' => sub {
    my $closed = sub { return { type => 'object', additionalProperties => Cpanel::JSON::XS::false(), properties => { a => {} } } };
    my $open   = { properties           => { b    => {} } };
    my $typed  = { additionalProperties => { type => 'string' } };

    my $spec = {
        paths => {
            '/things' => {
                post => {
                    requestBody => { content => { 'application/json' => { schema => { allOf => [ $closed->(), $open, $typed ] } } } },
                },
            },
        },
        alone => $closed->(),
        only  => { allOf => [ $closed->() ] },
    };

    Linode::API::_fix_closed_all_of($spec);
    is(
        $spec->{paths}{'/things'}{post}{requestBody}{content}{'application/json'}{schema}{allOf},
        [ { type => 'object', properties => { a => {} } }, { properties => { b => {} } }, { additionalProperties => { type => 'string' } } ],
        'a closed member of an allOf is opened, however deep it is, and a schema for additional properties is left alone',
    );
    is( $spec->{alone}, $closed->(),                  'a closed schema outside an allOf stays closed' );
    is( $spec->{only},  { allOf => [ $closed->() ] }, 'so does the only member of an allOf, which has no siblings to forbid' );
};

subtest '_fix_api_version' => sub {
    my $both  = { name   => 'apiVersion', in => 'path', required => 1, schema => { type => 'string', enum => [qw{v4 v4beta}] } };
    my $beta  = { name   => 'apiVersion', in => 'path', required => 1, schema => { type => 'string', enum => [qw{v4beta}] } };
    my $thing = { name   => 'thingId',    in => 'path' };
    my $ref   = { '$ref' => '#/components/parameters/bogus' };

    my $spec = sub {
        return {
            paths => {
                '/{apiVersion}/things/{thingId}' => { parameters => [ $both, $thing ] },
                '/{apiVersion}/betas'            => { parameters => [$beta] },
                '/unversioned'                   => { parameters => [$ref] },
            },
        };
    };

    is(
        Linode::API::_fix_api_version( $spec->(), 'v4' )->{paths},
        {
            '/v4/things/{thingId}' => { parameters => [$thing] },
            '/v4beta/betas'        => { parameters => [] },
            '/unversioned'         => { parameters => [$ref] },
        },
        'v4: the version replaces the placeholder where the path offers it, the only one it offers where not, and the parameter goes',
    );

    is(
        [ sort keys %{ Linode::API::_fix_api_version( $spec->(), 'v4beta' )->{paths} } ],
        [qw{/unversioned /v4beta/betas /v4beta/things/{thingId}}],
        'v4beta: the preference wins wherever the path offers it',
    );

    like(
        dies { Linode::API::_fix_api_version( $spec->(), 'v2beta' ) },
        qr/api_version 'v2beta' is not in the specification, which offers \[v4, v4beta\]/,
        'a version no path offers is refused',
    );

    like(
        dies { Linode::API::_fix_api_version( { paths => {} }, 'v4' ) },
        qr/which offers \[\]/,
        'a specification that offers no versions refuses every one',
    );
};

done_testing;
