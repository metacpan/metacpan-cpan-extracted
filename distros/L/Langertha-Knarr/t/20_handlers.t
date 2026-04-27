use strict;
use warnings;
use Test2::V0;
use Future;
use Future::AsyncAwait;

use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Engine;
use Langertha::Knarr::Handler::Raider;

# --- Mock engine: implements chat_f (named-args) and simple_chat_f (positional) ---
{
  package MockEngine;
  use Moose;
  has chat_model => ( is => 'ro', isa => 'Str', default => 'mock-1' );
  sub chat_f {
    my ($self, %args) = @_;
    my @msgs = @{ $args{messages} || [] };
    my $last = $msgs[-1];
    my $text = ref $last ? ($last->{content} // '') : "$last";
    return Future->done( "engine-said: $text" );
  }
  sub simple_chat_f {
    my ($self, @msgs) = @_;
    return $self->chat_f( messages => \@msgs );
  }
  __PACKAGE__->meta->make_immutable;
}

# --- Mock raider: implements raid_f ---
{
  package MockRaider;
  use Moose;
  has count => ( is => 'rw', isa => 'Int', default => 0 );
  sub raid_f {
    my ($self, $msg) = @_;
    $self->count( $self->count + 1 );
    return Future->done( "raider-turn-" . $self->count . ": $msg" );
  }
  __PACKAGE__->meta->make_immutable;
}

# Engine handler
{
  my $h = Langertha::Knarr::Handler::Engine->new( engine => MockEngine->new );
  my $session = Langertha::Knarr::Session->new( id => 's1' );
  my $req = Langertha::Knarr::Request->new(
    protocol => 'openai',
    messages => [ { role => 'user', content => 'ping' } ],
  );
  my $r = $h->handle_chat_f( $session, $req )->get;
  is( $r->content, 'engine-said: ping', 'engine handler proxies' );
  is( $h->list_models->[0]{id}, 'mock-1', 'model id from engine' );
}

# Raider handler — verifies per-session Raider re-use
{
  my @created;
  my $h = Langertha::Knarr::Handler::Raider->new(
    raider_factory => sub { push @created, MockRaider->new; $created[-1] },
  );

  my $s1 = Langertha::Knarr::Session->new( id => 'a' );
  my $s2 = Langertha::Knarr::Session->new( id => 'b' );

  my $req1 = Langertha::Knarr::Request->new(
    protocol => 'openai',
    messages => [ { role => 'user', content => 'first' } ],
  );
  my $req2 = Langertha::Knarr::Request->new(
    protocol => 'openai',
    messages => [ { role => 'user', content => 'second' } ],
  );

  my $r1 = $h->handle_chat_f( $s1, $req1 )->get;
  my $r2 = $h->handle_chat_f( $s1, $req2 )->get;
  my $r3 = $h->handle_chat_f( $s2, $req1 )->get;

  is( $r1->content, 'raider-turn-1: first',  'session a turn 1' );
  is( $r2->content, 'raider-turn-2: second', 'session a turn 2 (same raider)' );
  is( $r3->content, 'raider-turn-1: first',  'session b uses fresh raider' );
  is( scalar @created, 2, 'two raiders created (one per session)' );
}

done_testing;
