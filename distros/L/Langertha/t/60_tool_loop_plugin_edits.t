#!/usr/bin/env perl
# ABSTRACT: A plugin_after_llm_response edit is honoured by the calls run, the final text and the echo

use strict;
use warnings;

use Test2::Bundle::More;

# karr k347: the Langertha::Chat tool loops took the calls to run and the
# final text from the reply they had already parsed, but built the assistant
# echo from the body plugin_after_llm_response returned. A plugin that removed
# a call still saw it run, and the next request carried a tool result for a
# call the echo never announced (an OpenAI 400); a plugin that rewrote the
# final text was ignored. The hook now runs on the decoded wire body first,
# and the loop reads the body it returns -- calls, text and echo from one
# source, every echoed call with exactly one result.
#
# Role::Tools::chat_with_tools_f fires no plugin hooks, so only the two
# Langertha::Chat loops are held here.

use lib 't/lib';
use Test::MockMCP;
use Test::ToolLoop qw( run_loop loop_names );

use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;

{
  package Test::Plugin::DropCall;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  # Removes the call with id c2 / toolu_2 from either wire.
  async sub plugin_after_llm_response {
    my ( $self, $data ) = @_;
    if ( my $choices = $data->{choices} ) {
      my $msg = $choices->[0]{message};
      $msg->{tool_calls} = [ grep { $_->{id} ne 'c2' } @{ $msg->{tool_calls} } ]
        if $msg->{tool_calls};
    }
    elsif ( ref $data->{content} eq 'ARRAY' ) {
      $data->{content} = [ grep { ( $_->{id} // '' ) ne 'toolu_2' } @{ $data->{content} } ];
    }
    return $data;
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Plugin::RewriteText;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  async sub plugin_after_llm_response {
    my ( $self, $data ) = @_;
    my $msg = $data->{choices}[0]{message};
    $msg->{content} = 'REWRITTEN' unless $msg->{tool_calls};
    return $data;
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Plugin::ChangeArgs;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  async sub plugin_after_llm_response {
    my ( $self, $data ) = @_;
    $_->{function}{arguments} = '{"m":"edited"}'
      for @{ $data->{choices}[0]{message}{tool_calls} // [] };
    return $data;
  }
  __PACKAGE__->meta->make_immutable;
}

my @chat_loops = grep { $_ ne 'chat_with_tools_f' } loop_names();

my %engine = (
  openai    => sub { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x', @_ ) },
  anthropic => sub { Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x', response_size => 256, @_ ) },
);

sub echo_server {
  my ( $ran ) = @_;
  return Test::MockMCP->new( tools => [ { name => 'echo', description => 'echo',
    input_schema => { type => 'object', properties => {} },
    code => sub { push @$ran, $_[1]{m}; $_[0]->text_result("ran $_[1]{m}") } } ] );
}

my $openai_batch = { id => 'x1', choices => [ { index => 0, finish_reason => 'tool_calls',
  message => { role => 'assistant', content => undef, tool_calls => [
    { id => 'c1', type => 'function', function => { name => 'echo', arguments => '{"m":"a"}' } },
    { id => 'c2', type => 'function', function => { name => 'echo', arguments => '{"m":"b"}' } },
  ] } } ] };
my $openai_done = { id => 'x2', choices => [ { index => 0, finish_reason => 'stop',
  message => { role => 'assistant', content => 'done' } } ] };

subtest 'openai: a call the plugin removes is not run, not echoed, not answered' => sub {
  for my $loop (@chat_loops) {
    my @ran;
    my $out = run_loop( $loop, engine => $engine{openai}, bodies => [ $openai_batch, $openai_done ],
      servers => [ echo_server( \@ran ) ], plugins => ['+Test::Plugin::DropCall'] );
    ok( defined $out->{ok}, "$loop finishes" ) or diag( $out->{died} // '' );
    is_deeply( \@ran, ['a'], "$loop runs only the kept call" );
    my @msgs = @{ $out->{requests}[1]{messages} };
    my @echo = map { $_->{id} } map { @{ $_->{tool_calls} // [] } }
      grep { $_->{role} eq 'assistant' } @msgs;
    my @results = map { $_->{tool_call_id} } grep { $_->{role} eq 'tool' } @msgs;
    is_deeply( \@echo, ['c1'], "$loop echoes only the kept call" );
    is_deeply( \@results, ['c1'], "$loop answers each echoed call exactly once" );
  }
};

subtest 'anthropic: a call the plugin removes is not run, not echoed, not answered' => sub {
  my $batch = { id => 'msg_1', type => 'message', role => 'assistant', model => 'claude-x',
    stop_reason => 'tool_use', content => [
      { type => 'tool_use', id => 'toolu_1', name => 'echo', input => { m => 'a' } },
      { type => 'tool_use', id => 'toolu_2', name => 'echo', input => { m => 'b' } } ] };
  my $done = { id => 'msg_2', type => 'message', role => 'assistant', model => 'claude-x',
    stop_reason => 'end_turn', content => [ { type => 'text', text => 'done' } ] };
  for my $loop (@chat_loops) {
    my @ran;
    my $out = run_loop( $loop, engine => $engine{anthropic}, bodies => [ $batch, $done ],
      servers => [ echo_server( \@ran ) ], plugins => ['+Test::Plugin::DropCall'] );
    is( $out->{ok}, 'done', "$loop finishes" ) or diag( $out->{died} // '' );
    is_deeply( \@ran, ['a'], "$loop runs only the kept call" );
    my @msgs = @{ $out->{requests}[1]{messages} };
    is_deeply( [ map { $_->{id} } grep { $_->{type} eq 'tool_use' } @{ $msgs[-2]{content} } ],
      ['toolu_1'], "$loop echoes only the kept call" );
    is_deeply( [ map { $_->{tool_use_id} } @{ $msgs[-1]{content} } ],
      ['toolu_1'], "$loop answers each echoed call exactly once" );
  }
};

subtest 'a final text the plugin rewrites is what the loop returns' => sub {
  for my $loop (@chat_loops) {
    my @ran;
    my $out = run_loop( $loop, engine => $engine{openai}, bodies => [ $openai_batch, $openai_done ],
      servers => [ echo_server( \@ran ) ], plugins => ['+Test::Plugin::RewriteText'] );
    is( $out->{ok}, 'REWRITTEN', "$loop returns the rewritten text" ) or diag( $out->{died} // '' );
  }
};

subtest 'arguments the plugin changes are what runs and what is echoed' => sub {
  for my $loop (@chat_loops) {
    my @ran;
    my $out = run_loop( $loop, engine => $engine{openai}, bodies => [ $openai_batch, $openai_done ],
      servers => [ echo_server( \@ran ) ], plugins => ['+Test::Plugin::ChangeArgs'] );
    is( $out->{ok}, 'done', "$loop finishes" ) or diag( $out->{died} // '' );
    is_deeply( \@ran, [ 'edited', 'edited' ], "$loop runs the edited arguments" );
    my ($echo) = grep { $_->{role} eq 'assistant' } @{ $out->{requests}[1]{messages} };
    is_deeply( [ map { $_->{function}{arguments} } @{ $echo->{tool_calls} } ],
      [ ('{"m":"edited"}') x 2 ], "$loop echoes the edited arguments" );
  }
};

done_testing;
