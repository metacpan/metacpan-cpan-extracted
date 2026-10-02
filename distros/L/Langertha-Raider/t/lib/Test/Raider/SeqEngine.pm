package Test::Raider::SeqEngine;
# ABSTRACT: A scripted in-process engine and CLI app: two tool calls, then an answer

use strict;
use warnings;
use utf8;

=head1 SYNOPSIS

    use Test::Raider::SeqEngine;

    package My::Main {
      use Moose;
      extends 'Langertha::Raider::CLI::Main';
      sub app_class { 'Test::Raider::SeqEngine::App' }
    }

    # after a run:
    @Test::Raider::SeqEngine::REQUESTS;   # the conversation of every engine request
    @Test::Raider::SeqEngine::CALLS;      # [ name, input ] of every tool call
    $Test::Raider::SeqEngine::APP;        # the last app built

=head1 DESCRIPTION

Every raid of C<Test::Raider::SeqEngine::App> runs the real raid loop
against a scripted engine without network: the first request answers with
calls of C<bash> (1500 characters of output) and C<broken> (a two-line tool error),
the second with the text C<Fertig ✓>. The prompt C<fail> makes the run die
with C<kaputt>.

=cut

our ( @REQUESTS, @CALLS, $APP );

{
  package Test::Raider::SeqEngine::Response;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Raider::SeqEngine::HTTP;
  use Moose;
  use IO::Async::Loop;
  has loop => (is => 'ro', default => sub { IO::Async::Loop->new });
  sub do_request { return $_[0]->loop->new_future->done(Test::Raider::SeqEngine::Response->new) }
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Raider::SeqEngine::MCP;
  use Moose;
  use Future;
  sub list_tools { return Future->done([ { name => 'bash' }, { name => 'broken' } ]) }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @Test::Raider::SeqEngine::CALLS, [ $name, $input ];
    return Future->done({ content => [ { type => 'text', text => 'x' x 1500 } ] }) if $name eq 'bash';
    return Future->done({ content => [ { type => 'text', text => "nope: ä\nline 2" } ], isError => 1 });
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Raider::SeqEngine::Engine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model     => (is => 'ro', default => 'seq-model');
  has '+mcp_servers' => (default => sub { [] });
  has _turn_idx      => (is => 'rw', default => 0);
  has _http          => (is => 'ro', lazy => 1, default => sub { Test::Raider::SeqEngine::HTTP->new });

  sub async_request_f { return $_[0]->_http->do_request }
  sub async_loop      { return $_[0]->_http->loop }

  sub format_tools            { return $_[1] }
  sub response_tool_calls     { return $_[1]->{tool_calls} // [] }
  sub response_text_content   { return $_[1]->{text} // 'final answer' }
  sub extract_tool_call       { return ($_[1]->{name}, $_[1]->{input}) }
  sub think_tag_filter        { 0 }
  sub format_tool_results     { my ( $self, $data, $results ) = @_; return map { { role => 'tool', content => 'r' } } @$results }

  sub build_tool_chat_request {
    my ( $self, $conversation ) = @_;
    push @Test::Raider::SeqEngine::REQUESTS, [ @$conversation ];
    return { request => 1 };
  }

  sub parse_response {
    my ( $self ) = @_;
    my $i = $self->_turn_idx;
    $self->_turn_idx(($i + 1) % 2);
    return $i ? { tool_calls => [], text => 'Fertig ✓' } : { tool_calls => [
      { name => 'bash',   input => { command => 'ls' } },
      { name => 'broken', input => {} },
    ] };
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Raider::SeqEngine::App;
  use Moose;
  extends 'Langertha::Raider::CLI';
  sub BUILD { $Test::Raider::SeqEngine::APP = $_[0] }
  sub _build_mcps { [] }
  sub _build_engine { Test::Raider::SeqEngine::Engine->new(mcp_servers => [ Test::Raider::SeqEngine::MCP->new ]) }
  around run => sub {
    my ( $orig, $self, $text ) = @_;
    die "kaputt\n" if $text eq 'fail';
    return $self->$orig($text);
  };
  __PACKAGE__->meta->make_immutable;
}

1;
