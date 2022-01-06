# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Deep;
use Test::Fatal;
use OpenAPI::Modern;
use JSON::Schema::Modern::Utilities 'jsonp';
use Test::File::ShareDir -share => { -dist => { 'JSON-Schema-Modern-Document-OpenAPI' => 'share' } };
use constant { true => JSON::PP::true, false => JSON::PP::false };
use HTTP::Request::Common;
use HTTP::Response;
use YAML::PP 0.005;

my $path_template = '/foo/{foo_id}/bar/{bar_id}';

my $openapi_preamble = <<'YAML';
---
openapi: 3.1.0
info:
  title: Test API
  version: 1.2.3
YAML

my $doc_uri = Mojo::URL->new('openapi.yaml');

subtest 'validation errors' => sub {
  my $response = HTTP::Response->new(404);
  $response->request(my $request = POST 'http://example.com/some/path');
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => 'openapi.yaml',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
paths:
  /foo/{foo_id}:
    post:
      operationId: my-post-path
  /foo/bar:
    get:
      operationId: my-get-path
webhooks:
  my_hook:
    description: I like webhooks
    post:
      operationId: hooky
YAML
    },
  );

  like(
    exception { $openapi->validate_response($response, {}) },
    qr/^missing option path_template or operation_id at /,
    'path_template or operation_id is required',
  );

  cmp_deeply(
    (my $result = $openapi->validate_response($response,
      { path_template => $path_template }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => '/paths',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/paths')->to_string,
          error => 'missing path-item "/foo/{foo_id}/bar/{bar_id}"',
        },
      ],
    },
    'path template does not exist under /paths',
  );

  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { operation_id => 'bloop', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp('/paths'),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths'))->to_string,
          error => 'unknown operation_id "bloop"',
        },
      ],
    },
    'path template does not exist under /paths',
  );

  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { operation_id => 'hooky', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => '/webhooks/my_hook/post/operationId',
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/webhooks/my_hook/post/operationId'))->to_string,
          error => 'operation id does not have an associated path',
        },
      ],
    },
    'path template does not exist under /paths',
  );


  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { path_template => '/foo/{foo_id}', operation_id => 'my-get-path', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => '/paths/~1foo~1bar',
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', qw(/foo/bar)))->to_string,
          error => 'operation does not match provided path_template',
        },
      ],
    },
    'path_template and operation_id are inconsistent',
  );


  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { operation_id => 'my-get-path', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => '/paths/~1foo~1bar/get',
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', qw(/foo/bar get)))->to_string,
          error => 'wrong HTTP method POST',
        },
      ],
    },
    'request HTTP method does not match operation',
  );


  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { path_template => '/foo/{foo_id}', operation_id => 'my-post-path', path_captures => {} }))->TO_JSON,
    { valid => true },
    'path_template and operation_id can both be passed, if consistent',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => 'openapi.yaml',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
paths:
  /foo/{foo_id}/bar/{bar_id}: {}
YAML
    },
  );
  cmp_deeply(
    ($result = $openapi->validate_response($response, { path_template => $path_template }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', 'post'),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', 'post'))->to_string,
          error => 'missing entry for HTTP method "post"',
        },
      ],
    },
    'operation does not exist under /paths/<path-template>',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => 'openapi.yaml',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
paths:
  /foo/{foo_id}/bar/{bar_id}:
    post: {}
YAML
    },
  );
  cmp_deeply(
    ($result = $openapi->validate_response($response, { path_template => $path_template }))->TO_JSON,
    { valid => true },
    'no responses object - nothing to validate against',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => 'openapi.yaml',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
paths:
  /foo/{foo_id}/bar/{bar_id}:
    post:
      responses:
        200:
          description: success
        2XX:
          description: other success
YAML
    },
  );
  cmp_deeply(
    ($result = $openapi->validate_response($response, { path_template => $path_template }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses)))->to_string,
          error => 'no response object found for code 404',
        },
      ],
    },
    'response code not found - nothing to validate against',
  );

  $response->code(200);
  cmp_deeply(
    ($result = $openapi->validate_response($response, { path_template => $path_template }))->TO_JSON,
    { valid => true },
    'response code matched exactly',
  );

  $response->code(202);
  cmp_deeply(
    ($result = $openapi->validate_response($response, { path_template => $path_template }))->TO_JSON,
    { valid => true },
    'response code matched wildcard',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => 'openapi.yaml',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
components:
  responses:
    foo:
      \$ref: '#/i_do_not_exist'
    default:
      description: unexpected failure
      headers:
        Content-Type:
          # this is ignored!
          required: true
          schema: {}
        Foo-Bar:
          \$ref: '#/components/headers/foo-header'
  headers:
    foo-header:
      required: true
      schema:
        pattern: ^[0-9]+\$
paths:
  /foo/{foo_id}/bar/{bar_id}:
    post:
      responses:
        303:
          \$ref: '#/components/responses/foo'
        default:
          \$ref: '#/components/responses/default'
YAML
    },
  );
  $response->code(303);
  cmp_deeply(
    ($result = $openapi->validate_response($response, { path_template => $path_template }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses 303 $ref $ref)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/responses/foo/$ref')->to_string,
          error => 'EXCEPTION: unable to find resource openapi.yaml#/i_do_not_exist',
        },
      ],
    },
    'bad $ref in responses',
  );

  $response->code(500);
  cmp_deeply(
    ($result = $openapi->validate_response($response, { path_template => $path_template }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Foo-Bar',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses default $ref headers Foo-Bar $ref required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/headers/foo-header/required')->to_string,
          error => 'missing header: Foo-Bar',
        },
      ],
    },
    'header is missing',
  );

  $response->headers->header('FOO-BAR' => 'header value');
  cmp_deeply(
    ($result = $openapi->validate_response($response, { path_template => $path_template }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Foo-Bar',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses default $ref headers Foo-Bar $ref schema pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/headers/foo-header/schema/pattern')->to_string,
          error => 'pattern does not match',
        },
      ],
    },
    'header is evaluated against its schema',
  );

  $openapi = OpenAPI::Modern->new(
    openapi_uri => 'openapi.yaml',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
components:
  responses:
    default:
      description: unexpected failure
      content:
        application/json:
          schema:
            type: object
            properties:
              alpha:
                type: string
                pattern: ^[0-9]+\$
              beta:
                type: string
                const: éclair
              gamma:
                type: string
                const: ಠ_ಠ
            additionalProperties: false
        text/html:
          schema: false
paths:
  /foo/{foo_id}/bar/{bar_id}:
    post:
      responses:
        303:
          \$ref: '#/components/responses/foo'
        default:
          \$ref: '#/components/responses/default'
YAML
    },
  );

  # response has no content-type, content-length or body.
  $response = HTTP::Response->new(200, 'ok');
  $response->request($request = POST 'http://example.com/some/path');
  cmp_deeply(
    $result = $openapi->validate_response($response, { path_template => $path_template })->TO_JSON,
    { valid => true },
    'missing Content-Type does not cause an exception',
  );


  $response->content_type('application/json');
  $response->content('null');
  cmp_deeply(
    $result = $openapi->validate_response($response, { path_template => $path_template })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses default $ref content application/json schema type)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/responses/default/content/application~1json/schema/type')->to_string,
          error => 'got null, not object',
        },
      ],
    },
    'missing Content-Length does not prevent the response body from being checked',
  );


  $response = HTTP::Response->new(200, 'ok', [ 'Content-Type' => 'text/plain' ], 'plain text');
  $response->request($request = POST 'http://example.com/some/path');
  cmp_deeply(
    $result = $openapi->validate_response($response, { path_template => $path_template })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses default $ref content)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/responses/default/content')->to_string,
          error => 'incorrect Content-Type "text/plain"',
        },
      ],
    },
    'wrong Content-Type',
  );

  $response->content_type('text/html');
  $response->content('html text');
  cmp_deeply(
    $result = $openapi->validate_response($response, { path_template => $path_template })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses default $ref content text/html)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/components/responses/default/content', 'text/html'))->to_string,
          error => 'EXCEPTION: unsupported Content-Type "text/html": add support with $openapi->add_media_type(...)',
        },
      ],
    },
    'unsupported Content-Type',
  );

  $response->content_type('application/json; charset=ISO-8859-1');
  $response->content('{"alpha": "123", "beta": "'.chr(0xe9).'clair"}');
  cmp_deeply(
    $result = $openapi->validate_response($response, { path_template => $path_template })->TO_JSON,
    { valid => true },
    'content matches',
  );

  $response->content_type('application/json; charset=UTF-8');
  $response->content('{"alpha": "foo", "gamma": "o.o"}');
  cmp_deeply(
    $result = $openapi->validate_response($response, { path_template => $path_template })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/alpha',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses default $ref content application/json schema properties alpha pattern)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/components/responses/default/content', qw(application/json schema properties alpha pattern)))->to_string,
          error => 'pattern does not match',
        },
        {
          instanceLocation => '/response/body/gamma',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses default $ref content application/json schema properties gamma const)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/components/responses/default/content', qw(application/json schema properties gamma const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}/bar/{bar_id}', qw(post responses default $ref content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/components/responses/default/content', qw(application/json schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    'decoded content does not match the schema',
  );


  my $disapprove = v224.178.160.95.224.178.160; # utf-8-encoded "ಠ_ಠ"
  $response->content('{"alpha": "123", "gamma": "'.$disapprove.'"}');
  cmp_deeply(
    $result = $openapi->validate_response($response, { path_template => $path_template })->TO_JSON,
    { valid => true },
    'decoded content matches the schema',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => 'openapi.yaml',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
components:
  headers:
    no_content_permitted:
      description: when used with the Content-Length or Content-Type headers, indicates that, if present, the header value must be 0 or empty
      required: false
      schema:
        type: string
        enum: ['', '0']
paths:
  /foo/{foo_id}:
    post:
      responses:
        '204':
          description: no content permitted
          headers:
            Content-Length:
              \$ref: '#/components/headers/no_content_permitted'
            Content-Type:
              \$ref: '#/components/headers/no_content_permitted'
          content:
            text/plain: # TODO: support */* and then this would be guaranteed
              schema:
                type: string
                maxLength: 0
        default:
          description: default
          headers:
            Content-Length:
              required: true
              schema:
                type: integer
                minimum: 1
          content:
            text/plain:
              schema:
                minLength: 10
YAML
      },
  );
  $response = HTTP::Response->new(POST => 'http://example.com/foo/123', [ 'Content-Length' => 10 ], 'plain text');
  $response->request($request = POST 'http://example.com/some/path');
  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Type',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post responses default content)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post responses default content)))->to_string,
          error => 'missing header: Content-Type',
        },
      ],
    },
    'missing Content-Type does not cause an exception',
  );


  $response = HTTP::Response->new(POST => 'http://example.com/foo/123',
    [ 'Content-Length' => 1, 'Content-Type' => 'text/plain' ], ''); # Content-Length lies!
  $response->request($request = POST 'http://example.com/some/path');
  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post responses default content text/plain schema minLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post responses default content text/plain schema minLength)))->to_string,
          error => 'length is less than 10',
        },
      ],
    },
    'missing body (with a lying Content-Length) does not cause an exception, but is detectable',
  );

  # no Content-Length
  $response = HTTP::Response->new(POST => 'http://example.com/foo/123', [ 'Content-Type' => 'text/plain' ]);
  $response->request($request = POST 'http://example.com/some/path');
  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Length',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post responses default headers Content-Length required)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post responses default headers Content-Length required)))->to_string,
          error => 'missing header: Content-Length',
        },
      ],
    },
    'missing body and no Content-Length does not cause an exception, but is still detectable',
  );


  $response->code(204);
  $response->content_length('20');
  $response->content('I should not have content');
  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { path_template => '/foo/{foo_id}', path_captures => { foo_id => 123 } }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/header/Content-Length',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post responses 204 headers Content-Length $ref schema enum)),
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/headers/no_content_permitted/schema/enum')->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post responses 204 content text/plain schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post responses 204 content text/plain schema maxLength)))->to_string,
          error => 'length is greater than 0',
        },
      ],
    },
    'an undesired response body is detectable',
  );


  $openapi = OpenAPI::Modern->new(
    openapi_uri => 'openapi.yaml',
    openapi_schema => do {
      YAML::PP->new( boolean => 'JSON::PP' )->load_string(<<YAML);
$openapi_preamble
paths:
  /foo/{foo_id}:
    post:
      responses:
        default:
          description: no content permitted
          content:
            '*/*':
              schema:
                maxLength: 0
YAML
    },
  );
  $response = HTTP::Response->new(POST => 'http://example.com/foo/123',
    [ 'Content-Length' => 1, 'Content-Type' => 'unknown/unknown' ], '!!!');
  $response->request(POST 'http://example.com/some/path');
  cmp_deeply(
    ($result = $openapi->validate_response($response,
      { path_template => '/foo/{foo_id}', path_captures => {} }))->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp('/paths', '/foo/{foo_id}', qw(post responses default content */* schema maxLength)),
          absoluteKeywordLocation => $doc_uri->clone->fragment(jsonp('/paths', '/foo/{foo_id}', qw(post responses default content */* schema maxLength)))->to_string,
          error => 'length is greater than 0',
        },
      ],
    },
    'demonstrate recipe for guaranteeing that there is no response body',
  );
};

done_testing;
