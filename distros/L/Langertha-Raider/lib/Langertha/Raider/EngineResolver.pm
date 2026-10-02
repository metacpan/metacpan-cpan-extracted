package Langertha::Raider::EngineResolver;
# ABSTRACT: Internal choice of engine, model and API key for a raider
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Module::Runtime ();



has config => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Config',
  required => 1,
);


has engine_options => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);


has provider => (
  is        => 'ro',
  isa       => 'HashRef',
  predicate => 'has_provider',
);


has engine_name => (
  is       => 'ro',
  isa      => 'Str',
  lazy     => 1,
  builder  => '_build_engine_name',
  init_arg => 'engine',
);

sub _build_engine_name {
  my ($self) = @_;
  return $self->provider->{engine_name} if $self->has_provider;
  my $opt = $self->engine_options->{engine};
  return $opt if defined $opt && length $opt;
  my $yml = $self->config->engine;
  return $yml if defined $yml;
  return 'anthropic' if $ENV{ANTHROPIC_API_KEY};
  return 'openai'    if $ENV{OPENAI_API_KEY};
  return 'deepseek'  if $ENV{DEEPSEEK_API_KEY};
  return 'groq'      if $ENV{GROQ_API_KEY};
  return 'mistral'   if $ENV{MISTRAL_API_KEY};
  return 'gemini'    if $ENV{GEMINI_API_KEY};
  return 'anthropic';
}

my %DEFAULT_MODEL = (
  anthropic => 'claude-haiku-4-5',
  openai    => 'gpt-4o-mini',
  deepseek  => 'deepseek-chat',
  groq      => 'llama-3.3-70b-versatile',
  mistral   => 'mistral-small-latest',
  gemini    => 'gemini-2.5-flash',
  cerebras  => 'llama3.1-8b',
);

my %ENV_VAR = (
  anthropic  => 'ANTHROPIC_API_KEY',
  openai     => 'OPENAI_API_KEY',
  deepseek   => 'DEEPSEEK_API_KEY',
  groq       => 'GROQ_API_KEY',
  mistral    => 'MISTRAL_API_KEY',
  gemini     => 'GEMINI_API_KEY',
  minimax    => 'MINIMAX_API_KEY',
  cerebras   => 'CEREBRAS_API_KEY',
  openrouter => 'OPENROUTER_API_KEY',
  ollama     => undef,
);

my %ENGINE_CLASS = (
  anthropic  => 'Langertha::Engine::Anthropic',
  openai     => 'Langertha::Engine::OpenAI',
  deepseek   => 'Langertha::Engine::DeepSeek',
  groq       => 'Langertha::Engine::Groq',
  mistral    => 'Langertha::Engine::Mistral',
  gemini     => 'Langertha::Engine::Gemini',
  minimax    => 'Langertha::Engine::MiniMax',
  cerebras   => 'Langertha::Engine::Cerebras',
  openrouter => 'Langertha::Engine::OpenRouter',
  ollama     => 'Langertha::Engine::Ollama',
);

my @ENGINE_NAMES = qw(
  anthropic openai deepseek groq mistral gemini minimax cerebras openrouter ollama
);


sub engine_names {
  my ($self) = @_;
  return @ENGINE_NAMES;
}


sub api_key_env_vars {
  my ($self) = @_;
  return grep { defined } map { $self->env_var_for_engine($_) } $self->engine_names;
}


sub env_var_for_engine {
  my ( $self, $engine ) = @_;
  return $ENV_VAR{$engine};
}


sub default_model_for_engine {
  my ( $self, $engine ) = @_;
  return $DEFAULT_MODEL{$engine} if defined $DEFAULT_MODEL{$engine};
  my $class = $ENGINE_CLASS{$engine} or return undef;
  my $model = eval {
    Module::Runtime::require_module($class);
    $class->default_model;   # croaks on engines that demand an explicit model
  };
  return defined $model && length $model ? $model : undef;
}


has model => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_model',
);

sub _build_model {
  my ($self) = @_;
  return $self->provider->{model} if $self->has_provider;
  return $self->engine_options->{model}
    // $self->engine_yml_options->{model}
    // $DEFAULT_MODEL{$self->engine_name}
    // '';
}


sub has_model {
  my ($self) = @_;
  return length($self->model) ? 1 : 0;
}


has api_key => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_api_key',
);

sub _build_api_key {
  my ($self) = @_;
  return $self->engine_options->{api_key} // '' if $self->has_provider;
  my $configured =$self->engine_options->{api_key} // $self->engine_yml_options->{api_key};
  return $configured if defined $configured;
  my $var = $self->env_var_for_engine($self->engine_name);
  return '' unless $var;
  return $ENV{$var} // '';
}


sub api_key_env {
  my ($self) = @_;
  return undef if $self->has_provider;
  return $self->env_var_for_engine($self->engine_name);
}


sub engine_class {
  my ($self) = @_;
  return $self->provider->{engine_class} if $self->has_provider;
  my $class = $ENGINE_CLASS{$self->engine_name}
    or die "Unknown engine: ".$self->engine_name."\n";   # die: the message is shown as is
  return $class;
}


sub engine_yml_options {
  my ($self) = @_;
  return $self->config->engine_options($self->engine_name);
}


sub cli_engine_options {
  my ($self) = @_;
  my $opts = $self->engine_options;
  return { map { $_ => $opts->{$_} } grep { !$self->config->is_app_key($_) } keys %$opts };
}


sub engine_args {
  my ( $self, %extra ) = @_;
  my %args = (
    %{$self->engine_yml_options},
    %{$self->cli_engine_options},
    %extra,
  );
  delete @args{qw( model api_key )};
  $args{api_key} = $self->api_key if length $self->api_key;
  $args{model}   = $self->model   if $self->has_model;
  if ($self->has_provider) {
    my $address = $self->provider->{connect_address};
    croak __PACKAGE__.': the provider activation carries no connect_address; not building an unpinned engine'
      unless defined $address && length $address;
    $args{url}             = $self->provider->{url};
    $args{connect_address} = $address;
    $args{api_key}         = length $self->api_key ? $self->api_key : undef;
  }
  return %args;
}


sub build_engine {
  my ( $self, %extra ) = @_;
  my $class = $self->engine_class;
  Module::Runtime::require_module($class);
  my $engine = $class->new($self->engine_args(%extra));
  if ($self->has_provider && $engine->can('user_agent')) {
    # Not for the key (Langertha's agent strips it on another origin), and
    # no longer for another host (the pin refuses that hop, k141): for the
    # origin. The pin follows a hop on the same host to another port.
    $engine->user_agent->max_redirect(0);
    $engine->user_agent->requests_redirectable([]);
  }
  return $engine;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::EngineResolver - Internal choice of engine, model and API key for a raider

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $resolver = Langertha::Raider::EngineResolver->new(
      config         => $config,                 # Langertha::Raider::Config
      engine_options => { temperature => 0.2 },  # the -o pairs
      engine         => 'openai',                # optional, -e
    );

    my $name  = $resolver->engine_name;          # 'openai'
    my $class = $resolver->engine_class;         # 'Langertha::Engine::OpenAI'
    my %args  = $resolver->engine_args(mcp_servers => \@clients);
    my $engine = $resolver->build_engine(mcp_servers => \@clients);

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The provider choice of L<Langertha::Raider::Application>: which engine
(flag, C<-o engine=>, C<engine:> in F<.raider.yml>, the first C<*_API_KEY>
in the environment, C<anthropic>), which model and API key it is built
with, and the constructor arguments of the L<Langertha> engine class --
the F<.raider.yml> engine options, the C<-o> engine options on top, and
the model and key. Builds nothing but the engine itself.

With L</provider> (C<raider --provider>) the provider activation decides
engine, engine class, model and URL instead, and the API key comes only
from the command line -- see L</provider>.

=head2 config

The L<Langertha::Raider::Config> of the workspace. Required.

=head2 engine_options

HashRef of the C<-o KEY=VALUE> options, raider's own keys (see
L<Langertha::Raider::Config/is_app_key>) included; only C<engine> of
those is read here.

=head2 provider

The completed activation of C<raider --provider>
(L<Langertha::Raider::Provider::Activation/activate_f>), or none. With it:

=over

=item * L</engine_name>, L</engine_class> and L</model> are the
activation's; C<-o engine=>, C<engine:>, C<model:> in F<.raider.yml>, the
table defaults and the C<*_API_KEY> autodetection do not apply.

=item * L</engine_args> set C<url> to the endpoint's C<base_url>, whatever
F<.raider.yml> says.

=item * L</engine_args> set C<connect_address> to the activation's: the
address raider checked for the endpoint host. The engine connects there
instead of resolving the name again (Langertha ADR 0037), while C<Host>,
TLS SNI and the certificate check stay on the host name; neither C<-o> nor
F<.raider.yml> can change it. An activation without one croaks: an
unpinned engine is never built in provider mode. The engine is built with
its own HTTP clients (none is passed in), so no client is shared with
another engine.

=item * L</api_key> comes only from C<-k> or C<-o api_key=>: never from
F<.raider.yml> and never from the environment, and C<api_key> is always
passed to the engine (C<undef> without a key), so the engine class does
not read its C<LANGERTHA_*_API_KEY> either. A key configured for another
provider never reaches this one.

=item * L</build_engine> turns off redirects on the engine's synchronous
user agent, so its requests stay on the endpoint's origin. With the pin,
Langertha itself refuses a redirect to another host on every backend, and
it keeps the key on its origin; but it follows a redirect on the same host
to another port (still pinned, without the key), and raider's rule is the
endpoint's origin, not only its address (chat requests are POSTs, which
Langertha never redirects).

=back

=head2 engine_name

Langertha engine class shortcut, passed as C<engine>. Defaults to
C<-o engine=>, then to C<engine:> in F<.raider.yml>, then to the first
C<*_API_KEY> environment variable found, then to C<'anthropic'>.

=head2 engine_names

    my @names = $resolver->engine_names;   # ('anthropic', 'openai', ...)

Every engine name L</engine_class> knows, always in the same order. Also
callable on the class.

=head2 api_key_env_vars

    my @vars = $resolver->api_key_env_vars;   # ('ANTHROPIC_API_KEY', ...)

The API key environment variables of all L</engine_names>, in that
order; engines without one are left out. Also callable on the class.

=head2 env_var_for_engine

    my $var = $resolver->env_var_for_engine('openai');   # 'OPENAI_API_KEY'

The environment variable holding the API key of an engine; C<undef> for
engines without one (C<ollama>) and unknown ones. Also callable on the
class.

=head2 default_model_for_engine

    my $model = $resolver->default_model_for_engine('openai');   # 'gpt-4o-mini'

The model an engine uses without an explicit C<-m>: raider's cheap
default from the built-in table, or -- for an engine the table does not
list -- the engine class's own C<default_model>. C<undef> for an engine
that requires an explicit model (e.g. openrouter). For display only;
L</model> imposes only the table default, never the engine's own. Also
callable on the class.

=head2 model

Model identifier the engine is built with. Defaults to C<model> in
L</engine_options>, then C<model:> in F<.raider.yml>, then the per-engine
cheap default from the built-in table. With no such default the value is
empty and L</engine_args> passes no C<model>, so the engine's own
C<default_model> applies. An explicit C<model> always wins.

=head2 has_model

True when a non-empty model resolves. False when no C<-m>, C<-o model=>,
C<model:> or table default is set, so L</engine_args> leaves C<model> off
and the engine falls back to its own C<default_model>.

=head2 api_key

API key for the engine. Defaults to C<api_key> in L</engine_options>, then
C<api_key:> in F<.raider.yml>, then the engine's environment variable
(L</env_var_for_engine>). An explicit C<api_key> always wins.

=head2 api_key_env

Name of the environment variable of the current engine's API key, for
display; C<undef> for engines without one and with L</provider>.

=head2 engine_class

The L<Langertha> engine class of L</engine_name>. Dies with C<Unknown
engine: NAME> for a name it does not know.

=head2 engine_yml_options

The engine options of F<.raider.yml> for L</engine_name>
(L<Langertha::Raider::Config/engine_options>).

=head2 cli_engine_options

The C<-o> pairs that go to the engine: L</engine_options> without
raider's own keys.

=head2 engine_args

    my %args = $resolver->engine_args(mcp_servers => \@clients);

Engine constructor arguments: F<.raider.yml> then C<-o> (C<-o> wins),
raider's own keys left out, then C<%extra>. C<model> and C<api_key> go
last: L</model> and L</api_key> already resolve flag over C<-o> over
F<.raider.yml>, so an explicit C<-m> / C<-k> is never overwritten.

=head2 build_engine

    my $engine = $resolver->build_engine(mcp_servers => \@clients);

Loads L</engine_class> and builds it with L</engine_args>; with
L</provider> the engine connects to the checked address and its
synchronous user agent follows no redirect.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Application>

=item * L<Langertha::Raider::Config>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
