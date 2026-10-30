package Test::Raider::MockAI;
# ABSTRACT: A scripted model driving the real raider application and its real tools

use strict;
use warnings;
use utf8;
use Exporter 'import';
use Path::Tiny;
use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules ();
use Langertha::Raider::Loadguard;

our @EXPORT_OK = qw( mock_app );

=head1 SYNOPSIS

    use Test::Raider::MockAI qw( mock_app );

    my $app = mock_app(
      root   => $dir,
      script => [
        { tool_calls => [ [ write_file => { path => 'a.txt', content => 'hi' } ] ] },
        { text => 'written' },
      ],
    );
    my $result = $app->run('write a file');

    $app->mock_engine->results;    # what every tool call returned, in order
    $app->mock_engine->requests;   # the conversation of every model request

=head1 DESCRIPTION

The mock model is L<Langertha::Engine::Virtual> (Langertha 0.504 and later)
answering from a script, one entry per model request: either
C<< { tool_calls => [ [ $name, \%arguments ], ... ] } >>, C<< { text => $answer } >>
or C<< { error => [ $status, $message ] } >> (the request fails with that HTTP status).
When the script runs out it answers C<done>. Everything else is the real
thing: L<Langertha::Raider::Application>, the raid loop, the plugins, and the
stock tool servers (files, bash, web) mounted over L<Net::Async::MCP>. A tool
that is called really runs, inside C<root>. No network, no key, no cost.

A subagent (the C<agent> tool) gets an engine that answers from the same
script: its requests take the next entries, in the order they are made, and
its requests and tool results are recorded on the main engine's C<requests>
and C<results> too.

This is the base of the scenario suite (F<t/scenarios/>, F<t/200_scenarios.t>):
each scenario scripts the model, runs a prompt and states what must have
happened to the files, the tool results and the answer.

=cut

{
  package Test::Raider::MockAI::App;
  use Moose;
  extends 'Langertha::Raider::Application';
  has script => (is => 'ro', default => sub { [] });
  sub mock_engine { $_[0]->_engine }
  # A scenario step { tool_calls => [ [ name, \%args ], ... ] } or { text => ... }
  # as the engine's own reaction; with usage => { prompt_tokens, completion_tokens }
  # the reply reports that usage.
  sub _build_engine {
    my ( $self ) = @_;
    return Langertha::Engine::Virtual->new(
      script => [ map {
        my @usage = $_->{usage} ? ( usage => $_->{usage} ) : ();
        $_->{tool_calls} ? Langertha::Virtual::Rules::tools( $_->{tool_calls}, @usage )
          : $_->{error}  ? Langertha::Virtual::Rules::error( @{ $_->{error} } )
                         : Langertha::Virtual::Rules::answer( $_->{text} // 'done', @usage )
      } @{ $self->script } ],
      fallback        => Langertha::Virtual::Rules::answer('done'),
      langfuse_enabled => 0,
      mcp_servers     => $self->_mcps,
    );
  }
  # A subagent's engine answers from the same script, in request order: its
  # requests and tool results land on the main engine's requests and results.
  sub build_subagent_engine {
    my ( $self, %o ) = @_;
    return Test::Raider::MockAI::SubEngine->new(
      main             => $self->_engine,
      langfuse_enabled => 0,
      mcp_servers      => $o{mcp_servers},
      ( defined $o{model} ? ( model => $o{model} ) : () ),
    );
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Raider::MockAI::SubEngine;
  use Moose;
  extends 'Langertha::Engine::Virtual';
  has main => (is => 'ro', required => 1, weak_ref => 1);
  sub virtual_reply { my $self = shift; return $self->main->virtual_reply(@_) }
  around format_tool_results => sub {
    my ( $orig, $self, $data, $results ) = @_;
    push @{ $self->main->results }, @{ $results // [] };
    return $self->$orig( $data, $results );
  };
  __PACKAGE__->meta->make_immutable;
}

=func mock_app

    my $app = mock_app( root => $dir, script => \@steps, %application_args );

Builds the application over C<root> with the mock model. Every further
argument goes to L<Langertha::Raider::Application>.

=cut

sub mock_app {
  my ( %args ) = @_;
  return Test::Raider::MockAI::App->new(
    engine_name => 'openai',
    api_key     => 'mock',
    # The gate never measures the real host: off, unless a scenario gives its own.
    loadguard   => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
    %args,
  );
}

1;
