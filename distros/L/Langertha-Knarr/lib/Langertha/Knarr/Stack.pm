package Langertha::Knarr::Stack;
# ABSTRACT: The routing parts of a running Knarr, built from one config
our $VERSION = '1.103';
use Moose;
use JSON::MaybeXS ();
use Langertha::Knarr::Router;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::RequestLog;
use Langertha::Knarr::Handler::TokenRoutes;
use Langertha::Knarr::Authorizer::Token;
use Langertha::Knarr::TokenStore::Pg;


has config => (
  is       => 'ro',
  required => 1,
);

has loop => (
  is => 'ro',
);

has tracing => (
  is      => 'ro',
  isa     => 'Maybe[Object]',
  default => sub { undef },
);

has request_log => (
  is      => 'ro',
  isa     => 'Maybe[Object]',
  default => sub { undef },
);

has router => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_router',
);

has raw_passthrough => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_raw_passthrough',
);

has token_store => (
  is      => 'ro',
  isa     => 'Maybe[Object]',
  lazy    => 1,
  builder => '_build_token_store',
);

has authorizer => (
  is      => 'ro',
  isa     => 'Maybe[Object]',
  lazy    => 1,
  builder => '_build_authorizer',
);

has handler => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_handler',
);

# The classes the stack is made of, named once each (override points).
sub router_class              { 'Langertha::Knarr::Router' }
sub token_routes_class        { 'Langertha::Knarr::Handler::TokenRoutes' }
sub authorizer_class          { 'Langertha::Knarr::Authorizer::Token' }
sub token_store_class         { 'Langertha::Knarr::TokenStore::Pg' }
sub passthrough_class         { 'Langertha::Knarr::Handler::Passthrough' }
sub router_handler_class      { 'Langertha::Knarr::Handler::Router' }
sub tracing_handler_class     { 'Langertha::Knarr::Handler::Tracing' }
sub request_log_handler_class { 'Langertha::Knarr::Handler::RequestLog' }

sub _build_router {
  my ($self) = @_;
  return $self->router_class->new( config => $self->config );
}

sub _build_token_store {
  my ($self) = @_;
  my $auth = $self->config->token_auth or return undef;
  return $self->token_store_class->new(
    dsn      => $auth->{dsn},
    relation => $auth->{relation},
    listen   => $auth->{listen},
    columns  => $auth->{columns},
    ( defined $auth->{user}         ? ( user         => $auth->{user} )         : () ),
    ( defined $auth->{password_env} ? ( password_env => $auth->{password_env} ) : () ),
    ( $self->loop ? ( loop => $self->loop ) : () ),
  );
}

sub _build_authorizer {
  my ($self) = @_;
  my $auth = $self->config->token_auth or return undef;
  return $self->authorizer_class->new(
    store       => $self->token_store,
    match_model => $auth->{match_model},
  );
}

sub _build_raw_passthrough {
  my ($self) = @_;
  my $config = $self->config;
  # Token-checked requests never go through the raw passthrough: it would
  # hand the client's token upstream.
  return undef if $config->token_auth;
  my $upstreams = $config->passthrough;
  return undef unless $upstreams && %$upstreams;
  return $self->passthrough_class->new(
    upstreams     => $upstreams,
    ( $self->loop ? ( loop => $self->loop ) : () ),
    timeout       => $config->upstream_timeout,
    stall_timeout => $config->upstream_stall_timeout,
  );
}

sub _build_handler {
  my ($self) = @_;
  my $passthrough = $self->raw_passthrough;
  my $handler = $self->config->token_auth
    ? $self->token_routes_class->new(
        routes => $self->config->routes,
        router => $self->router,
      )
    : $self->router_handler_class->new(
        router => $self->router,
        ( $passthrough ? ( passthrough => $passthrough ) : () ),
      );
  $handler = $self->tracing_handler_class->new(
    wrapped => $handler,
    tracing => $self->tracing,
  ) if $self->tracing;
  $handler = $self->request_log_handler_class->new(
    wrapped     => $handler,
    request_log => $self->request_log,
  ) if $self->request_log;
  return $handler;
}

sub auth_token {
  my ($self) = @_;
  return $self->config->has_proxy_api_key ? $self->config->proxy_api_key : undef;
}

sub with_config {
  my ($self, $config, %over) = @_;
  my $same_auth = $self->_same_token_auth($config);
  return ref($self)->new(
    ( $same_auth && $self->authorizer
      ? ( authorizer => $self->authorizer, token_store => $self->token_store ) : () ),
    config      => $config,
    loop        => $self->loop,
    tracing     => ( exists $over{tracing} ? $over{tracing} : $self->tracing ),
    request_log => $self->request_log,
  );
}

# Whether $config asks for the very token check this stack has.
sub _same_token_auth {
  my ($self, $config) = @_;
  my ( $mine, $next ) = ( $self->config->token_auth, $config->token_auth );
  return 0 unless $mine && $next;
  my $json = JSON::MaybeXS->new( canonical => 1 );
  return $json->encode($mine) eq $json->encode($next) ? 1 : 0;
}

sub build {
  my ($self) = @_;
  $self->$_ for qw( router raw_passthrough token_store authorizer handler );
  return $self;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Stack - The routing parts of a running Knarr, built from one config

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Langertha::Knarr::Stack;

    my $stack = Langertha::Knarr::Stack->new(
        config      => $config,      # Langertha::Knarr::Config
        loop        => $loop,
        tracing     => $tracing,     # enabled Langertha::Knarr::Tracing, or undef
        request_log => $request_log, # enabled Langertha::Knarr::RequestLog, or undef
    );

    my $knarr = Langertha::Knarr->new(
        handler         => $stack->handler,
        router          => $stack->router,
        raw_passthrough => $stack->raw_passthrough,
        auth_token      => $stack->auth_token,
        ( $stack->authorizer ? ( authorizer => $stack->authorizer ) : () ),
        ...
    );

    # Same loop, tracing and request log, a new config, fresh engines:
    my $next = $stack->with_config($new_config);
    my $lf   = $stack->with_config( $new_config, tracing => $other_tracing );

=head1 DESCRIPTION

Everything of a running Knarr that its routing config decides, built the way
C<knarr start> builds it: the L<Langertha::Knarr::Router>, the
L<Langertha::Knarr::Handler::Passthrough> for the configured upstreams, the
L<Langertha::Knarr::Handler::Router> on top of both, wrapped in the
L<Langertha::Knarr::Handler::Tracing> and
L<Langertha::Knarr::Handler::RequestLog> decorators when L</tracing> and
L</request_log> are given, and the proxy key.

L<Langertha::Knarr::Admin> builds a new stack for every admin push with
L</with_config> and hands it to the running Knarr in one step. The new
stack has its own router, so its engine cache starts empty; the old stack
lives on only as long as a request that is still running holds on to it.

=head2 config

Required. The L<Langertha::Knarr::Config> the stack is built from.

=head2 loop

Optional L<IO::Async::Loop> for the passthrough's HTTP client.

=head2 tracing

Optional, enabled L<Langertha::Knarr::Tracing>. Wraps the handler in a
L<Langertha::Knarr::Handler::Tracing>. It is a process setting: L</with_config>
keeps it.

=head2 request_log

Optional, enabled L<Langertha::Knarr::RequestLog>. Wraps the handler in a
L<Langertha::Knarr::Handler::RequestLog>, outside the tracing. Kept by
L</with_config> like L</tracing>.

=head2 router

The L<Langertha::Knarr::Router> over L</config>. Built on first use.

=head2 raw_passthrough

The L<Langertha::Knarr::Handler::Passthrough> for
L<Langertha::Knarr::Config/passthrough>, or C<undef> when no upstream is
configured. Built on first use.

=head2 handler

The handler chain: L<Langertha::Knarr::Handler::Router> (with
L</raw_passthrough> as its fallback), inside the tracing and request-log
decorators. Built on first use. With L<Langertha::Knarr::Config/token_auth>
the core is a L<Langertha::Knarr::Handler::TokenRoutes> over
L<Langertha::Knarr::Config/routes> instead, and there is no
L</raw_passthrough>.

=head2 token_store

The L<Langertha::Knarr::TokenStore> behind L</authorizer>: with
L<Langertha::Knarr::Config/token_auth> a L<Langertha::Knarr::TokenStore::Pg>
over the config's C<dsn>, C<user>, C<password_env>, C<relation>, C<listen> and
C<columns>, using L</loop>; C<undef> without it. Building the store loads
C<DBD::Pg> (a missing one croaks C<token_auth backend postgresql needs
DBD::Pg>) but does not connect: the store connects in the process that serves,
when L<Langertha::Knarr> starts the L</authorizer> there (else on its first
lookup), so a forked worker never shares the parent's connection.
Can be given to the constructor (tests hand in a
L<Langertha::Knarr::TokenStore::Memory>).

=head2 authorizer

The L<Langertha::Knarr::Authorizer::Token> over L</token_store> with the
config's C<match_model>, or C<undef> without C<token_auth>. L<Langertha::Knarr>
takes it from the stack (C<_apply_stack>); without one it keeps checking the
proxy key. Can be given to the constructor.

=head2 auth_token

The proxy key (L<Langertha::Knarr::Config/proxy_api_key>), or C<undef>
when none is set.

=head2 with_config

    my $next = $stack->with_config($config);
    my $next = $stack->with_config( $config, tracing => $tracing_or_undef );

A new stack for C<$config> with the same L</loop>, L</tracing> and
L</request_log>, and, when C<$config> has the same
L<Langertha::Knarr::Config/token_auth> section as this stack's config, the
same L</authorizer> and L</token_store> -- a push of other settings must not
drop the token check or reconnect to the database. A different (or no)
C<token_auth> section gets a fresh store and authorizer. Nothing of this stack's router, engines or passthrough is
reused. A C<tracing> argument (an enabled tracing, or C<undef> for none)
replaces the tracing: a delivered C<langfuse> section brings its own.

=head2 build

    $stack->build;

Builds L</router>, L</raw_passthrough>, L</token_store>, L</authorizer> and L</handler> now, so a config
they cannot be built from fails here and not on the first request. Returns
the stack.

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
