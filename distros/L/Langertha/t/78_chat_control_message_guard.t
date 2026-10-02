#!/usr/bin/env perl
# ABSTRACT: karr #122 -- carp when a control name is passed as a simple_chat message

# Role::Chat::simple_chat / simple_chat_f / chat all funnel their positional
# @messages through chat_messages, which turns every non-ref scalar into a
# { role => 'user' } turn. A caller who mistakes those methods for chat_f and
# appends a control as a kwarg tail -- simple_chat($prompt, reasoning_effort =>
# 'high') -- silently sends the control NAME and its value as extra user
# messages. karr #122 adds a diagnostic carp (never a die) when a plain-scalar
# message exactly matches a canonical control name (the %CANONICAL_CONTROLS set
# used by _extract_controls / chat_f). Behaviour is otherwise unchanged: the
# strings still become messages as before. These tests are fully offline --
# chat_messages is a pure transform and chat() only builds the request object,
# so no live provider call is made.

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::OpenAI;

# Collect warnings emitted while $code runs, without letting them reach STDERR.
sub warnings_from {
  my ($code) = @_;
  my @w;
  local $SIG{__WARN__} = sub { push @w, $_[0] };
  $code->();
  return @w;
}

# Return only the control-guard warnings (ignore any unrelated noise).
sub control_warnings_from {
  my ($code) = @_;
  return grep { /chat_f control name/ } warnings_from($code);
}

my $engine = Langertha::Engine::OpenAI->new(
  api_key => 'apikey',
  model   => 'gpt-4o-mini',
);

# --- Positive: the exact copy-paste mistake fires the guard ---------------

subtest 'control name as trailing message arg warns' => sub {
  my @w = control_warnings_from(
    sub { $engine->chat_messages( 'What time is it?', 'reasoning_effort', 'high' ) }
  );
  is(scalar @w, 1, 'exactly one control-guard warning (once per call)');
  like($w[0], qr/reasoning_effort/, 'names the offending key');
  like($w[0], qr/chat_f/,           'points the caller at chat_f');
  unlike($w[0], qr/\bdie\b/,        'phrased as a warning, not a fatal');
};

subtest 'a representative sample of the canonical control set each warns' => sub {
  # Not the whole set -- a spread across the concern groups so the test fails
  # if the guard stops matching %CANONICAL_CONTROLS, without duplicating it.
  for my $key (qw(
    temperature max_tokens response_format seed reasoning_effort
    thinking_budget prompt_cache prompt_cache_key
  )) {
    my @w = control_warnings_from( sub { $engine->chat_messages( $key ) } );
    is(scalar @w, 1, "control key '$key' warns");
    like($w[0], qr/\Q$key\E/, "warning for '$key' names it");
  }
};

subtest 'the real funnel: chat() triggers the same guard offline' => sub {
  # chat() -> chat_messages() -> chat_request() builds an HTTP::Request; no
  # network. Proves the guard sits on the shared funnel, not just the helper.
  my @w = control_warnings_from(
    sub { $engine->chat( 'summarise this', 'response_format', 'json' ) }
  );
  is(scalar @w, 1, 'chat() emits exactly one control-guard warning');
  like($w[0], qr/response_format/, 'names the offending key via the funnel');
};

subtest 'multiple distinct control keys warn once, naming each' => sub {
  my @w = control_warnings_from(
    sub { $engine->chat_messages( 'temperature', 'reasoning_effort' ) }
  );
  is(scalar @w, 1, 'still a single warning for the whole call');
  like($w[0], qr/temperature/,      'names the first key');
  like($w[0], qr/reasoning_effort/, 'names the second key');
};

subtest 'a repeated control key is named once (deduped)' => sub {
  my @w = control_warnings_from(
    sub { $engine->chat_messages( 'seed', 'seed' ) }
  );
  is(scalar @w, 1, 'one warning');
  my $count = () = $w[0] =~ /'seed'/g;
  is($count, 1, "'seed' named exactly once even though passed twice");
};

# --- Negative: no false positives on legitimate calls ---------------------

subtest 'legitimate multi-string simple_chat does NOT warn' => sub {
  my @w = control_warnings_from(
    sub { $engine->chat_messages( 'foo', 'bar' ) }
  );
  is(scalar @w, 0, 'plain multi-string call is silent');
};

subtest 'normal single-prompt call does NOT warn' => sub {
  my @w = control_warnings_from(
    sub { $engine->chat_messages( 'What is Perl?' ) }
  );
  is(scalar @w, 0, 'single prompt is silent');
};

subtest 'a control name inside hashref content does NOT warn' => sub {
  # Only plain (non-ref) scalar arguments are the mistake; a legitimately
  # authored message whose content happens to be a control word is fine.
  my @w = control_warnings_from(
    sub { $engine->chat_messages( { role => 'user', content => 'reasoning_effort' } ) }
  );
  is(scalar @w, 0, 'hashref message with control-word content is silent');
};

subtest 'a control name as a substring of a prompt does NOT warn' => sub {
  my @w = control_warnings_from(
    sub { $engine->chat_messages( 'tell me about reasoning_effort settings' ) }
  );
  is(scalar @w, 0, 'only an exact whole-argument match triggers the guard');
};

# --- Behaviour otherwise unchanged: the strings still become messages -----

subtest 'behaviour unchanged: offending scalars still become user messages' => sub {
  my @w;
  my $msgs;
  {
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    $msgs = $engine->chat_messages( 'reasoning_effort', 'high' );
  }
  is(scalar @$msgs, 2, 'both scalars still turned into messages');
  is($msgs->[0]{role},    'user',             'first is a user turn');
  is($msgs->[0]{content}, 'reasoning_effort', 'first content unchanged');
  is($msgs->[1]{role},    'user',             'second is a user turn');
  is($msgs->[1]{content}, 'high',             'second content unchanged');
};

done_testing;
