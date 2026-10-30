package Test::Raider::SlowAI;
# ABSTRACT: The scripted mock model of Test::Raider::MockAI, answering on the loop after a delay

use strict;
use warnings;
use Exporter 'import';
use Test::Raider::MockAI ();
use Langertha::Raider::Loadguard;

our @EXPORT_OK = qw( slow_app );

=head1 SYNOPSIS

    use Test::Raider::SlowAI qw( slow_app );

    my $app = slow_app(
      root      => $dir,
      delay     => 0.05,   # the main run's model answers after 50 ms on the loop
      sub_delay => 0,      # a subagent's model answers at once
      usage     => { prompt_tokens => 100, completion_tokens => 20 },   # optional
      script    => [ ... ],
    );

=head1 DESCRIPTION

L<Test::Raider::MockAI> with time: the in-process model answers a request
only after C<delay> (the main engine) or C<sub_delay> (every subagent's
engine) seconds on the application's loop, so work that runs on the loop
meanwhile -- a background subagent -- really runs in between. The script is
still consumed in the order the requests are B<answered>. A delay of C<0>
answers at once, as the plain mock does.

=cut

{
  package Test::Raider::SlowAI::Engine;
  use Moose;
  extends 'Langertha::Engine::Virtual';
  has loop  => ( is => 'ro' );
  has delay => ( is => 'ro', default => 0 );
  around async_request_f => sub {
    my ( $orig, $self, @args ) = @_;
    return $self->$orig(@args) unless $self->delay;
    return $self->loop->delay_future( after => $self->delay )->then( sub { $self->$orig(@args) } );
  };
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Raider::SlowAI::SubEngine;
  use Moose;
  extends 'Test::Raider::MockAI::SubEngine';
  has loop  => ( is => 'ro' );
  has delay => ( is => 'ro', default => 0 );
  around async_request_f => sub {
    my ( $orig, $self, @args ) = @_;
    return $self->$orig(@args) unless $self->delay;
    return $self->loop->delay_future( after => $self->delay )->then( sub { $self->$orig(@args) } );
  };
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Raider::SlowAI::App;
  use Moose;
  extends 'Test::Raider::MockAI::App';
  has delay     => ( is => 'ro', default => 0 );
  has sub_delay => ( is => 'ro', default => 0 );
  # The usage every reply reports (Langertha::Engine::Virtual/default_usage).
  has usage     => ( is => 'ro' );
  sub _build_engine {
    my ( $self ) = @_;
    my $engine = $self->SUPER::_build_engine;
    return Test::Raider::SlowAI::Engine->new(
      script           => $engine->script,
      fallback         => $engine->fallback,
      langfuse_enabled => 0,
      mcp_servers      => $self->_mcps,
      loop             => $self->loop,
      delay            => $self->delay,
      ( $self->usage ? ( default_usage => $self->usage ) : () ),
    );
  }
  sub build_subagent_engine {
    my ( $self, %o ) = @_;
    return Test::Raider::SlowAI::SubEngine->new(
      main             => $self->_engine,
      langfuse_enabled => 0,
      mcp_servers      => $o{mcp_servers},
      loop             => $self->loop,
      delay            => $self->sub_delay,
      ( defined $o{model} ? ( model => $o{model} ) : () ),
    );
  }
  __PACKAGE__->meta->make_immutable;
}

=func slow_app

    my $app = slow_app( root => $dir, script => \@steps, delay => 0.05, %application_args );

=cut

sub slow_app {
  my ( %args ) = @_;
  return Test::Raider::SlowAI::App->new(
    engine_name => 'openai',
    api_key     => 'mock',
    loadguard   => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
    %args,
  );
}

1;
