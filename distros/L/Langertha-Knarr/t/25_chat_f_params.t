use strict;
use warnings;
use Test2::V0;
use Future;

use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Handler::Engine;
use Langertha::ToolCall;
use Langertha::Response;

# Mock that records the args chat_f received and reports capabilities.
{
  package CaptureEngine;
  use Moose;
  has chat_model => ( is => 'ro', default => 'cap-1' );
  has captured   => ( is => 'rw' );
  has caps       => ( is => 'ro', default => sub {
    {
      tools_native  => 1,
      temperature   => 1,
      response_size => 1,
    };
  });
  sub supports { $_[0]->caps->{ $_[1] } ? 1 : 0 }
  sub chat_f {
    my ($self, %args) = @_;
    $self->captured(\%args);
    return Future->done(
      Langertha::Response->new(
        content    => 'ok',
        model      => 'cap-1',
        tool_calls => [
          Langertha::ToolCall->new( id => 't1', name => 'lookup', arguments => { q => 'x' } ),
        ],
        finish_reason => 'tool_calls',
      )
    );
  }
  sub simple_chat_f { $_[0]->chat_f( messages => [ @_[1..$#_] ] ) }
  __PACKAGE__->meta->make_immutable;
}

subtest 'all parameters forwarded when engine supports them' => sub {
  my $engine = CaptureEngine->new;
  my $h = Langertha::Knarr::Handler::Engine->new( engine => $engine );
  my $req = Langertha::Knarr::Request->new(
    protocol        => 'openai',
    model           => 'cap-1',
    messages        => [ { role => 'user', content => 'hi' } ],
    temperature     => 0.7,
    max_tokens      => 100,
    tools           => [ { type => 'function', function => { name => 'f', parameters => {} } } ],
    tool_choice     => 'auto',
    response_format => { type => 'json_object' },
  );
  my $r = $h->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ), $req )->get;
  isa_ok $r, ['Langertha::Knarr::Response'];
  is $r->content, 'ok';

  my $cap = $engine->captured;
  is $cap->{messages},       [ { role => 'user', content => 'hi' } ];
  is $cap->{temperature},    0.7;
  is $cap->{max_tokens},     100;
  is $cap->{tool_choice},    'auto';
  is $cap->{response_format}, { type => 'json_object' };
  ok $cap->{tools},          'tools forwarded';
};

subtest 'unsupported caps cause params to be dropped' => sub {
  my $engine = CaptureEngine->new( caps => { tools_native => 0, temperature => 0, response_size => 0 } );
  my $h = Langertha::Knarr::Handler::Engine->new( engine => $engine );
  my $req = Langertha::Knarr::Request->new(
    protocol    => 'openai',
    model       => 'cap-1',
    messages    => [ { role => 'user', content => 'hi' } ],
    temperature => 0.7,
    max_tokens  => 100,
    tools       => [ {} ],
    tool_choice => 'auto',
  );
  $h->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ), $req )->get;
  my $cap = $engine->captured;
  ok !exists $cap->{temperature}, 'temperature dropped';
  ok !exists $cap->{max_tokens},  'max_tokens dropped';
  ok !exists $cap->{tools},       'tools dropped';
  ok !exists $cap->{tool_choice}, 'tool_choice dropped';
};

subtest 'tool_calls survive into Knarr::Response' => sub {
  my $engine = CaptureEngine->new;
  my $h = Langertha::Knarr::Handler::Engine->new( engine => $engine );
  my $req = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'cap-1',
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $r = $h->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ), $req )->get;
  ok $r->has_tool_calls, 'response carries tool_calls';
  is $r->tool_calls->[0]->name, 'lookup';
  is $r->finish_reason, 'tool_calls';
};

done_testing;
