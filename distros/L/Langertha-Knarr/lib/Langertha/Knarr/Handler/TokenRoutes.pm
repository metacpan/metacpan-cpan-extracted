package Langertha::Knarr::Handler::TokenRoutes;
# ABSTRACT: Knarr handler that routes a token-checked request by its token's provider
our $VERSION = '1.103';
use Moose;
use Carp qw( croak );
use Future::Exception;
use Log::Any qw( $log );
use Langertha ();
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use namespace::autoclean;

extends 'Langertha::Knarr::Handler::Router';


has routes => (
  is       => 'ro',
  isa      => 'HashRef[HashRef]',
  required => 1,
);

has '+router' => (
  required => 0,
  lazy     => 1,
  builder  => '_build_router',
);

# The engine an upstream route speaks through, and the classes named once
# (override points).
sub upstream_engine { 'OpenAI' }
sub router_class    { 'Langertha::Knarr::Router' }
sub config_class    { 'Langertha::Knarr::Config' }

sub _build_router {
  my ($self) = @_;
  return $self->router_class->new( config => $self->config_class->new( data => {} ) );
}

# Engine name per route, resolved once at construction.
has _engines => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_engines',
  init_arg => undef,
);

sub BUILD {
  my ($self) = @_;
  my $engines = $self->_engines;
  $self->_load_engine_class( $_, $engines->{$_} ) for sort keys %$engines;
  return;
}

sub _build_engines {
  my ($self) = @_;
  my %engine;
  for my $name ( sort keys %{ $self->routes } ) {
    my $route = $self->routes->{$name};
    croak __PACKAGE__.": route '$name' needs key_env"
      unless defined $route->{key_env} && length $route->{key_env};
    my $has_upstream = defined $route->{upstream} && length $route->{upstream};
    my $has_provider = defined $route->{provider} && length $route->{provider};
    croak __PACKAGE__.": route '$name' needs exactly one of upstream and provider"
      unless $has_upstream xor $has_provider;
    $engine{$name} = $has_upstream ? $self->upstream_engine : $self->engine_name( $route->{provider} );
  }
  return \%engine;
}

# Loads a route's engine class now -- in the prefork parent, before the
# fork, so the workers share it and none pays the load on its first request
# -- and fails here, naming the route, when it cannot be loaded. Class only:
# no engine, no key, no connection.
sub _load_engine_class {
  my ($self, $name, $engine) = @_;
  my $class = eval { Langertha->resolve_engine_class($engine) };
  return $class if $class;
  my $err = ( split /\n/, ( $@ // '' ) )[0] // '';
  $err =~ s/\s*\(\@INC[^)]*\).*//;
  $err =~ s/ at \S+ line \d+.*//;
  # reported from the code that built the handler, not Moose's constructor
  local $Carp::CarpLevel = 1;
  croak __PACKAGE__.": route '$name': engine $engine cannot be loaded"
    .( length $err ? ": $err" : '' );
}


sub engine_name {
  my ($self, $provider) = @_;
  my ($known) = grep { lc $_ eq lc $provider }
    map { $_->{engine} } @{ $self->config_class->engine_catalog };
  return $known if defined $known;
  return $provider if eval { Langertha->resolve_engine_class($provider) };
  croak __PACKAGE__.": unknown provider '$provider'";
}


sub route_def {
  my ($self, $name, $model) = @_;
  my $route = $self->routes->{$name} or return;
  my $url = $route->{upstream} // $route->{url};
  return {
    engine      => $self->_engines->{$name},
    ( defined $url && length $url ? ( url => $url ) : () ),
    api_key_env => $route->{key_env},
    model       => $model,
  };
}

# The engine for the request's grant (overrides Handler::Router's model
# lookup): its provider's route, with the request's model.
sub _resolve {
  my ($self, $request) = @_;
  my $grant = $request->grant;
  my $provider = $grant ? $grant->{provider} : undef;
  my $route = defined $provider ? $self->routes->{$provider} : undef;
  unless ( $route ) {
    $log->debug('token routes: no route for the token\'s provider');
    die Future::Exception->new( 'forbidden: no route for this token', 'forbidden' );
  }
  my $model = $request->model;
  die Future::Exception->new( 'The request names no model', 'model_not_found' )
    unless defined $model && length $model;
  my $key = $ENV{ $route->{key_env} };
  unless ( defined $key && length $key ) {
    $log->errorf( 'token routes: environment variable %s of route %s is not set',
      $route->{key_env}, $provider );
    die Future::Exception->new( 'backend unavailable', 'unavailable' );
  }
  my $engine = $self->router->engine_for( $self->route_def( $provider, $model ), $model );
  return ( $engine, $model, 0 );
}


sub list_models { [] }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::TokenRoutes - Knarr handler that routes a token-checked request by its token's provider

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Langertha::Knarr::Handler::TokenRoutes;

    my $handler = Langertha::Knarr::Handler::TokenRoutes->new( routes => {
      local     => { upstream => 'http://api:8080/v1', key_env => 'SKEID_KEY' },
      openai    => { provider => 'openai',    key_env => 'OPENAI_API_KEY' },
      anthropic => { provider => 'anthropic', key_env => 'ANTHROPIC_API_KEY' },
    } );

=head1 DESCRIPTION

The handler behind C<token_auth>. Each request carries the identity
L<Langertha::Knarr::Authorizer::Token> found for its token
(L<Langertha::Knarr::Request/grant>); its C<provider> picks the route, and
the request's model -- the token's model -- goes to it:

=over

=item * C<< { upstream => $url, key_env => $var } >> -- an OpenAI-compatible
endpoint (C</chat/completions> under C<$url>), through
L<Langertha::Engine::OpenAI>.

=item * C<< { provider => $name, key_env => $var } >> -- that provider's
Langertha engine: C<openai>, C<anthropic>, ... (an engine name of
L<Langertha::Knarr::Config/engine_catalog>, any case), or any other engine
class name Langertha resolves (C<Langertha::Engine::*>,
C<LangerthaX::Engine::*>). An optional C<url> sends it to another endpoint
of that provider (a regional one).

=back

The engine's key is read from the environment variable C<key_env> when the
request comes; the client's token never goes anywhere. Engines are built
and cached by L<Langertha::Knarr::Router/engine_for>, one per route and
model, like routed models (upstream timeout, Langfuse keys).

A request whose grant names a provider without a route, or that has no
grant, fails with the category C<forbidden>: L<Langertha::Knarr> answers
C<403> C<forbidden: no route for this token> in the client protocol's error
shape, and nothing is sent anywhere. A route whose C<key_env> is unset or
empty fails with the category C<unavailable> (C<503>,
C<backend unavailable>); the log names the variable, never its value.

Answers, streams included, are those of
L<Langertha::Knarr::Handler::Router>. L</list_models> is empty: the model
lists show the token's own model (L<Langertha::Knarr::Authorizer::Token>).
Wrap it in L<Langertha::Knarr::Handler::Tracing> and
L<Langertha::Knarr::Handler::RequestLog> like any handler.

=head2 routes

Required. HashRef of provider value (the token row's C<provider>) to route,
see L</DESCRIPTION>. Checked at construction: each route has C<key_env> and
exactly one of C<upstream> and C<provider>, and the provider's engine must
exist. The engine class of every route is loaded at construction too --
L<Langertha::Knarr::Stack/build>, so in C<knarr start> before any worker is
forked: the workers share the loaded classes, and no first request waits for
them. Only the class is loaded; no engine is built, no key read, nothing
connects. A class that cannot be loaded croaks naming the route
(C<route 'local': engine OpenAI cannot be loaded: ...>), so C<knarr start>
and C<knarr check> stop on it.

=head2 router

Optional L<Langertha::Knarr::Router> that builds and caches the engines;
its config gives the upstream timeout and the Langfuse keys. Default: one
over an empty L<Langertha::Knarr::Config>.

=head2 engine_name

    my $engine = $handler->engine_name('anthropic');   # Anthropic

The Langertha engine name of a route's C<provider>: the catalog name it
matches without regard to case, else the name as given, when Langertha
resolves it to an engine class. Croaks for an unknown provider.

=head2 route_def

    my $def = $handler->route_def( $route_name, $model );

The model config the route's engine for C<$model> is built from:
C<engine>, C<url>, C<api_key_env>, C<model>.

=head2 list_models

Empty: a token's client sees the token's model, from the authorizer.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

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
