#!/usr/bin/env perl
# ABSTRACT: Engines and plugins take their constructor arguments as a hash reference too

use strict;
use warnings;

use Test2::Bundle::More;

use Scalar::Util qw( refaddr );

use Langertha::Engine::Anthropic;
use Langertha::Engine::OllamaOpenAI;
use Langertha::Plugin;

# Moose's new() takes its arguments as a list or as one hash reference. The
# BUILDARGS wrappers of Langertha::Role::Langfuse (composed into every chat
# engine through Role::Chat) and Langertha::Plugin unpacked @_ into a hash
# themselves, so ->new({ ... }) warned "Reference found where even-sized list
# expected" and lost every argument: url, api_key, model, host. Both now let
# Moose normalize the arguments first and work on the hash reference it
# returns, like Role::ParallelToolUse and Role::ReasoningEffort do. So the two
# call forms must build the same object, silently, with and without the
# Langfuse keys in the environment.

# Runs $code, returns the object (undef if it died), the error and the
# warnings it raised.
sub construct {
  my ($code) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my $object = eval { $code->() };
  return ( $object, $@, \@warnings );
}

# Builds $class from %args both ways and checks that both forms give the same
# state, without dying and without a warning. Returns the list-form object.
sub both_forms_agree {
  my ( $class, $state_of, %args ) = @_;
  my ( $from_list, $list_error, $list_warnings ) = construct(sub { $class->new(%args) });
  my ( $from_ref,  $ref_error,  $ref_warnings )  = construct(sub { $class->new({ %args }) });

  is( $list_error, '', '->new( ... ) lives' );
  is( $ref_error,  '', '->new({ ... }) lives' );
  is_deeply( $list_warnings, [], '->new( ... ) warns nothing' );
  is_deeply( $ref_warnings,  [], '->new({ ... }) warns nothing' );
  ok( defined $from_list && defined $from_ref, 'both forms built an object' )
    or return;
  # A lost lazy attribute (api_key) only croaks when read, so read in an eval.
  my %state;
  for my $form ( [ list => $from_list ], [ ref => $from_ref ] ) {
    my ( $name, $object ) = @$form;
    $state{$name} = eval { $state_of->($object) } || { error => $@ };
  }
  is_deeply( $state{ref}, $state{list}, 'both forms give the same attributes' );
  return $from_list;
}

sub langfuse_state {
  my ($engine) = @_;
  return {
    langfuse_public_key => $engine->has_langfuse_public_key ? $engine->langfuse_public_key : '(unset)',
    langfuse_secret_key => $engine->has_langfuse_secret_key ? $engine->langfuse_secret_key : '(unset)',
    langfuse_enabled    => $engine->langfuse_enabled,
    langfuse_url        => $engine->langfuse_url,
  };
}

sub ollama_state {
  my ($engine) = @_;
  return {
    %{ langfuse_state($engine) },
    url           => $engine->url,
    model         => $engine->model,
    system_prompt => $engine->system_prompt,
    temperature   => $engine->temperature,
  };
}

sub anthropic_state {
  my ($engine) = @_;
  return {
    %{ langfuse_state($engine) },
    url              => $engine->url,
    api_key          => $engine->api_key,
    model            => $engine->model,
    reasoning_effort => $engine->reasoning_effort,
  };
}

my %ollama_args = (
  url           => 'http://127.0.0.1:11434/v1',
  model         => 'llama3.1',
  system_prompt => 'Be brief.',
  temperature   => 0.25,
);

# Anthropic stacks its own BUILDARGS wrapper (the `effort` alias in
# Engine::AnthropicBase) and Role::ReasoningEffort's on top of Role::Langfuse's,
# so the hash reference must make it through the whole chain.
my %anthropic_args = (
  api_key => 'sk-ant-test',
  model   => 'claude-test-model',
  effort  => 'high',
);

subtest 'engine, no Langfuse keys in the environment' => sub {
  delete local $ENV{LANGERTHA_ANTHROPIC_API_KEY};
  delete local $ENV{LANGFUSE_PUBLIC_KEY};
  delete local $ENV{LANGFUSE_SECRET_KEY};
  delete local $ENV{LANGFUSE_URL};

  my $ollama = both_forms_agree( 'Langertha::Engine::OllamaOpenAI', \&ollama_state, %ollama_args );
  if ($ollama) {
    is( $ollama->url, $ollama_args{url}, 'url is the one passed' );
    ok( !$ollama->has_langfuse_public_key, 'no Langfuse public key' );
    ok( !$ollama->langfuse_enabled, 'Langfuse stays off' );
  }

  my $claude = both_forms_agree( 'Langertha::Engine::Anthropic', \&anthropic_state, %anthropic_args );
  if ($claude) {
    is( $claude->api_key, $anthropic_args{api_key}, 'api_key is the one passed' );
    is( $claude->reasoning_effort, 'high', 'the effort alias still reaches reasoning_effort' );
  }
};

subtest 'engine, Langfuse keys in the environment' => sub {
  delete local $ENV{LANGERTHA_ANTHROPIC_API_KEY};
  local $ENV{LANGFUSE_PUBLIC_KEY} = 'pk-lf-env';
  local $ENV{LANGFUSE_SECRET_KEY} = 'sk-lf-env';
  delete local $ENV{LANGFUSE_URL};

  my $ollama = both_forms_agree( 'Langertha::Engine::OllamaOpenAI', \&ollama_state, %ollama_args );
  if ($ollama) {
    is( $ollama->url, $ollama_args{url}, 'url is the one passed' );
    is( $ollama->langfuse_public_key, 'pk-lf-env', 'public key taken from the environment' );
    is( $ollama->langfuse_secret_key, 'sk-lf-env', 'secret key taken from the environment' );
    ok( $ollama->langfuse_enabled, 'Langfuse turns on' );
  }

  both_forms_agree( 'Langertha::Engine::Anthropic', \&anthropic_state, %anthropic_args );

  my $explicit = both_forms_agree(
    'Langertha::Engine::OllamaOpenAI', \&ollama_state,
    %ollama_args,
    langfuse_public_key => 'pk-lf-arg',
    langfuse_secret_key => 'sk-lf-arg',
  );
  if ($explicit) {
    is( $explicit->langfuse_public_key, 'pk-lf-arg', 'a passed public key wins over the environment' );
    is( $explicit->langfuse_secret_key, 'sk-lf-arg', 'a passed secret key wins over the environment' );
  }
};

subtest 'plugin, host and the raider alias' => sub {
  delete local $ENV{LANGFUSE_PUBLIC_KEY};
  delete local $ENV{LANGFUSE_SECRET_KEY};

  # host is a weak reference, so the test keeps the host alive itself.
  my $host = Langertha::Engine::OllamaOpenAI->new( url => 'http://127.0.0.1:11434/v1' );
  my $host_of = sub { { host => refaddr( $_[0]->host ) } };

  for my $key (qw( host raider )) {
    my $plugin = both_forms_agree( 'Langertha::Plugin', $host_of, $key => $host );
    next unless $plugin;
    is( refaddr( $plugin->host ), refaddr($host), "$key => \$host becomes the plugin's host" );
  }
};

done_testing;
