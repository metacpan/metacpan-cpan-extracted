#!/usr/bin/env perl
# ABSTRACT: the sync inline-image fetch honors inline_image_fetch_timeout
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use IO::Socket::INET;
use HTTP::Response;
use LWP::UserAgent;
use MIME::Base64 qw( encode_base64 );
use Time::HiRes qw( time );
use Langertha::Content::Image;
use Langertha::Engine::OllamaOpenAI;
use Langertha::Engine::Ollama;
use Langertha::Engine::Gemini;
use Langertha::Engine::LMStudio;

# karr k279 (ADR 0027, follow-up of k276): the _f paths bound each inline-image
# fetch by the engine's inline_image_fetch_timeout, but the synchronous
# request build (chat, simple_chat, ...) fetched through
# Content::Image->ensure_base64 with a hardcoded 30s LWP timeout, so the same
# engine setting meant different things on the sync and the async door. The
# request build now passes the engine's value to ensure_base64; direct callers
# without arguments keep 30s, and 0 (no timeout on the async path) leaves LWP's
# own default because LWP cannot run without a timeout.

# Accepts connections (the kernel completes the handshake) and never answers.
my $hang = IO::Socket::INET->new( Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
  Proto => 'tcp', ReuseAddr => 1 ) or die "listen: $!";
my $hang_url = 'http://127.0.0.1:' . $hang->sockport . '/hang.png';

# --- A hanging image host fails the sync build after the engine's timeout ---
{
  my $e = Langertha::Engine::OllamaOpenAI->new( url => 'http://127.0.0.1:1/v1', model => 'm',
    inline_image_fetch_timeout => 1 );
  my $t0 = time;
  my $ok = eval {
    $e->chat( { role => 'user',
      content => [ 'x', Langertha::Content::Image->from_url($hang_url) ] } );
    1;
  };
  my $err  = $@;
  my $took = time - $t0;
  ok !$ok, 'the sync request build fails on the hanging image host';
  like $err,
    qr/\ALangertha::Engine::OllamaOpenAI: this endpoint takes only inline images .*could not be inlined \(ensure_base64: failed to fetch \Q$hang_url\E: 500 read timeout\); pass the image as base64/s,
    '... with the engine-named inline-image error';
  ok $took >= 0.9 && $took < 10, "... after about the configured second (took ${\ sprintf '%.2f', $took }s)";
}

# --- Instrumented LWP: which timeout does each fetch get? ---
my @timeouts;
{
  no warnings 'redefine';
  *LWP::UserAgent::get = sub {
    my ( $ua, $url ) = @_;
    push @timeouts, $ua->timeout;
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'image/png' ], "\x89PNG" );
  };
}
my $url = 'http://images.invalid/a.png';
sub img { Langertha::Content::Image->from_url($url) }
sub msg { { role => 'user', content => [ 'x', @_ ] } }

@timeouts = ();
img()->ensure_base64;
is_deeply \@timeouts, [30], 'a direct ensure_base64 keeps 30s';

@timeouts = ();
img()->ensure_base64( timeout => 7 );
is_deeply \@timeouts, [7], 'ensure_base64( timeout => 7 ) sets 7s';

@timeouts = ();
img()->ensure_base64( timeout => 0 );
is_deeply \@timeouts, [180], "timeout => 0 leaves LWP's default (180s)";

@timeouts = ();
Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'm' )->chat( msg( img() ) );
is_deeply \@timeouts, [30], 'engine default inline_image_fetch_timeout gives 30s';

# Every request-build door that inlines: openai(inline => 1), ollama, gemini,
# lmstudio, and Gemini's image_url hash part.
for my $case (
  [ OllamaOpenAI => sub { Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'm', @_ ) },
    sub { msg( img() ) } ],
  [ Ollama => sub { Langertha::Engine::Ollama->new( url => 'http://h', model => 'm', @_ ) },
    sub { msg( img() ) } ],
  [ Gemini => sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash', @_ ) },
    sub { msg( img() ) } ],
  [ 'Gemini image_url part' => sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash', @_ ) },
    sub { msg( { type => 'image_url', image_url => { url => $url } } ) } ],
  [ LMStudio => sub { Langertha::Engine::LMStudio->new( url => 'http://h', model => 'm', @_ ) },
    sub { msg( img() ) } ],
) {
  my ( $name, $engine, $message ) = @$case;
  @timeouts = ();
  my $req = $engine->( inline_image_fetch_timeout => 5 )->chat( $message->() );
  ok defined $req, "$name: request built";
  is_deeply \@timeouts, [5], "$name: the fetch gets the engine's inline_image_fetch_timeout";
}

# An image that is already base64, or a URL engine that passes URLs through,
# does not fetch at all.
@timeouts = ();
Langertha::Engine::OllamaOpenAI->new( url => 'http://h/v1', model => 'm', inline_image_fetch_timeout => 5 )
  ->chat( msg( Langertha::Content::Image->from_base64( encode_base64('x', ''), media_type => 'image/png' ) ) );
require Langertha::Engine::OpenAI;
Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6', inline_image_fetch_timeout => 5 )
  ->chat( msg( img() ) );
is_deeply \@timeouts, [], 'no fetch for base64 images or URL-capable wires';

done_testing;
