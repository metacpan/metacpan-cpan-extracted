use strict;
use warnings;
use Test2::V0;
use Future;

use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Router;

# Mock router: knows one model, dies on others.
{
  package MockRouter;
  use Moose;
  has known => ( is => 'ro', isa => 'HashRef', default => sub { { 'gpt-test' => 1 } } );
  sub resolve {
    my ($self, $model) = @_;
    die "no such model: $model\n" unless $self->known->{ $model // '' };
    return ( MockEngine->new, $model );
  }
  sub list_models { [ { id => 'gpt-test', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}
{
  package MockEngine;
  use Moose;
  use Future;
  sub simple_chat_f {
    my ($self, @msgs) = @_;
    my $last = $msgs[-1];
    my $text = ref $last ? ($last->{content} // '') : "$last";
    return Future->done("ENGINE: $text");
  }
  __PACKAGE__->meta->make_immutable;
}

# Mock passthrough handler that records calls.
{
  package MockPassthrough;
  use Moose;
  use Future;
  with 'Langertha::Knarr::Handler';
  has calls => ( is => 'ro', default => sub { [] } );
  sub handle_chat_f {
    my ($self, $session, $request) = @_;
    push @{ $self->calls }, $request->model // '';
    return Future->done({ content => "PASSTHROUGH: " . ($request->model // ''), model => 'pt' });
  }
  sub list_models { [] }
  __PACKAGE__->meta->make_immutable;
}

my $session = Langertha::Knarr::Session->new( id => 's' );

# --- 1) Without passthrough: known model resolves, unknown dies ---
{
  my $h = Langertha::Knarr::Handler::Router->new( router => MockRouter->new );
  my $req_known = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-test',
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $r = $h->handle_chat_f( $session, $req_known )->get;
  is( $r->{content}, 'ENGINE: hi', 'known model goes to engine' );

  my $req_unknown = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-mystery',
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $f = $h->handle_chat_f( $session, $req_unknown );
  ok( $f->is_failed, 'unknown model fails without passthrough' );
}

# --- 2) With passthrough: unknown falls through ---
{
  my $pt = MockPassthrough->new;
  my $h = Langertha::Knarr::Handler::Router->new(
    router      => MockRouter->new,
    passthrough => $pt,
  );

  # Known still goes to engine.
  my $req_known = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-test',
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $r1 = $h->handle_chat_f( $session, $req_known )->get;
  is( $r1->{content}, 'ENGINE: hi', 'known still uses engine when passthrough configured' );
  is( scalar @{ $pt->calls }, 0, 'passthrough not called for known model' );

  # Unknown falls through.
  my $req_unknown = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-mystery',
    messages => [ { role => 'user', content => 'hi' } ],
  );
  my $r2 = $h->handle_chat_f( $session, $req_unknown )->get;
  is( $r2->{content}, 'PASSTHROUGH: gpt-mystery', 'unknown falls through' );
  is( scalar @{ $pt->calls }, 1, 'passthrough called once' );
  is( $pt->calls->[0], 'gpt-mystery', 'passthrough received the model name' );
}

done_testing;
