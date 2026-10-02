#!/usr/bin/env perl
# ABSTRACT: Gemini with an explicit api_key => undef sends no key at all

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::Gemini;

# karr k376 / langertha-raider #119: a keyless proxy or gateway in front of
# Gemini must not get "?key=" appended, nor an 'uninitialized' warning. An
# explicit api_key => undef means "no key, do not read the environment";
# leaving api_key out keeps the Developer API contract (env, croak if unset).

my $base = 'https://generativelanguage.googleapis.com/v1beta';

{
  local %ENV = %ENV;
  $ENV{LANGERTHA_GEMINI_API_KEY} = 'env_key_must_not_be_used';

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $engine = Langertha::Engine::Gemini->new(
    api_key => undef,
    model   => 'gemini-2.0-flash',
  );

  my %urls = (
    chat       => "" . $engine->chat('hi')->uri,
    stream     => "" . $engine->chat_stream('hi')->uri,
    embedding  => "" . $engine->embedding_request('hi')->uri,
    list       => "" . $engine->list_models_request->uri,
    list_page  => "" . $engine->list_models_request( pageToken => 'tok' )->uri,
    plain      => $engine->gemini_url('cachedContents'),
    plain_q    => $engine->gemini_url( 'cachedContents', pageSize => 5 ),
  );

  is( $urls{chat}, "$base/models/gemini-2.0-flash:generateContent",
    'chat URL has no query string' );
  is( $urls{stream},
    "$base/models/gemini-2.0-flash:streamGenerateContent?alt=sse",
    'streaming URL keeps alt=sse, no key' );
  is( $urls{list}, "$base/models", 'model listing has no query string' );
  is( $urls{list_page}, "$base/models?pageToken=tok",
    'caller query pairs survive without a key' );
  is( $urls{plain}, "$base/cachedContents", 'cachedContents URL has no key' );
  is( $urls{plain_q}, "$base/cachedContents?pageSize=5",
    'cachedContents with a caller query has no key' );
  unlike( $urls{embedding}, qr/key=/, 'embedding URL has no key' );
  unlike( $_, qr/key=/, 'no key= anywhere' ) for values %urls;

  is_deeply( [ $engine->gemini_auth_query ], [], 'empty auth query' );

  for my $request ( $engine->chat('hi'), $engine->chat_stream('hi'),
                    $engine->list_models_request ) {
    my @auth = grep { /key|auth/i } $request->headers->header_field_names;
    is_deeply( \@auth, [], 'no credential header' );
  }

  is_deeply( \@warnings, [], 'no warnings' ) or diag( join "", @warnings );
}

# With a key nothing changes; without one passed the env still applies.
{
  local %ENV = %ENV;
  $ENV{LANGERTHA_GEMINI_API_KEY} = 'env_key';
  my $from_env = Langertha::Engine::Gemini->new( model => 'gemini-2.0-flash' );
  is( "" . $from_env->chat('hi')->uri,
    "$base/models/gemini-2.0-flash:generateContent?key=env_key",
    'api_key not passed: environment key still used' );

  my $explicit = Langertha::Engine::Gemini->new(
    api_key => 'explicit', model => 'gemini-2.0-flash' );
  is( "" . $explicit->chat('hi')->uri,
    "$base/models/gemini-2.0-flash:generateContent?key=explicit",
    'explicit key unchanged' );

  delete $ENV{LANGERTHA_GEMINI_API_KEY};
  my $missing = Langertha::Engine::Gemini->new( model => 'gemini-2.0-flash' );
  eval { $missing->gemini_url('models') };
  like( $@, qr/requires LANGERTHA_GEMINI_API_KEY or api_key/,
    'api_key not passed and no env: still croaks' );
}

done_testing;
