#!/usr/bin/env perl
# ABSTRACT: xAI image generation: /v1/images/generations request, dropped OpenAI-only extras, response

use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';

use HTTP::Response;
use JSON::MaybeXS;
use Path::Tiny qw( path );
use Test::MockAsyncHTTP;

use Langertha::Engine::XAI;
use Langertha::ImageGen;

# karr k309: xAI serves image generation (Imagine API) on the OpenAI-shaped
# /v1/images/generations, but the engine did not compose
# Role::ImageGeneration and restricted itself to createChatCompletion. The
# engine must send grok-imagine-image-2.0 by default, pass xAI's own
# aspect_ratio / resolution / n / response_format through, and never send the
# OpenAI-only size / quality / style: xAI does not accept them, so one passed
# in (e.g. by Langertha::ImageGen's size/quality attributes) is dropped with
# a warning -- the same drop-and-carp as k308's response_format for gpt-image.
#
# The response fixture is NOT a capture (live calls need the maintainer's
# approval): docs.x.ai (guides/image-generations) shows no response JSON, only
# SDK access to data[0].url / base64; xai_image_url_doc.json is that
# OpenAI-shaped data[].url answer.

my $data_dir = path(__FILE__)->parent->child('data');
my $json     = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $xai      = Langertha::Engine::XAI->new( api_key => 'test-key' );

sub body_with_warnings {
  my ( $engine, @args ) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $req = $engine->image_request(@args);
  return ( $json->decode( $req->content ), \@warnings, $req );
}

subtest 'composition and defaults' => sub {
  ok( $xai->does('Langertha::Role::ImageGeneration'), 'XAI does ImageGeneration' );
  ok( $xai->supports('image_generation'), 'supports image_generation' );
  is( $xai->image_model, 'grok-imagine-image-2.0', 'default image_model' );
};

subtest 'request: xAI endpoint, model, xAI extras pass through' => sub {
  my ( $body, $warnings, $req ) = body_with_warnings( $xai, 'A cat in space',
    aspect_ratio => '16:9', resolution => '2k', n => 4, response_format => 'b64_json' );
  is( $req->method, 'POST', 'POST' );
  is( $req->uri, 'https://api.x.ai/v1/images/generations', 'xAI images endpoint' );
  is( $req->header('Authorization'), 'Bearer test-key', 'Bearer auth' );
  is_deeply( $body, {
    model => 'grok-imagine-image-2.0', prompt => 'A cat in space',
    aspect_ratio => '16:9', resolution => '2k', n => 4, response_format => 'b64_json',
  }, 'body carries exactly model, prompt and the xAI extras' );
  is( scalar @$warnings, 0, 'no warning' );
};

subtest 'size / quality / style are dropped with a warning' => sub {
  my ( $body, $warnings ) = body_with_warnings( $xai, 'A cat',
    size => '1024x1024', quality => 'hd', style => 'vivid', aspect_ratio => '1:1' );
  ok( !exists $body->{$_}, "$_ not sent" ) for qw( size quality style );
  is( $body->{aspect_ratio}, '1:1', 'aspect_ratio still sent' );
  is( scalar @$warnings, 1, 'one warning for the drop' );
  like( $warnings->[0] // '', qr/does not take quality, size, style.*dropped/, 'warning names the fields' );

  my $ig = Langertha::ImageGen->new( engine => $xai, size => '1024x1024' );
  ( $body, $warnings ) = body_with_warnings( $xai, 'A cat', $ig->_extra );
  ok( !exists $body->{size}, 'ImageGen size attribute is dropped for xAI' );
  is( scalar @$warnings, 1, '... with a warning' );
};

sub fixture_http {
  my ( $name ) = @_;
  my $headers = $json->decode( $data_dir->child("$name.headers.json")->slurp_raw );
  my $http    = HTTP::Response->new( 200, 'OK' );
  $http->header( $_ => $headers->{$_} ) for sort keys %$headers;
  $http->content( $data_dir->child("$name.json")->slurp_raw );
  return $http;
}

subtest 'response parsing' => sub {
  my $images = $xai->image_response( fixture_http('xai_image_url_doc') );
  like( $images->[0]{url}, qr{\Ahttps://imgen\.x\.ai/}, 'url image' );
};

subtest 'simple_image_f over the async backend' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response(
      $json->decode( $data_dir->child('xai_image_url_doc.json')->slurp_raw ) ),
  ] );
  my $engine = Langertha::Engine::XAI->new( api_key => 'k', _async_http => $mock );
  my $images = $engine->simple_image_f( 'A cat', aspect_ratio => '3:2' )->get;
  like( $images->[0]{url}, qr{\Ahttps://imgen\.x\.ai/}, 'resolves to the images' );
  my ($req) = $mock->requests;
  is( $req->uri->path, '/v1/images/generations', 'async request on the images path' );
  is( $json->decode( $req->content )->{aspect_ratio}, '3:2', 'async request carries the extras' );
};

subtest 'chat stays allowed, other OpenAI operations stay closed' => sub {
  ok( $xai->can_operation('createChatCompletion'), 'createChatCompletion' );
  ok( $xai->can_operation('createImage'), 'createImage' );
  ok( !$xai->can_operation('createImageEdit'), 'createImageEdit is not opened' );
};

done_testing;
