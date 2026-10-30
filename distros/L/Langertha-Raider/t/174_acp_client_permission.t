#!/usr/bin/env perl
# ABSTRACT: The ACP client answers the agent's session/request_permission; without a handler it rejects (ADR 0021 Nachtrag P2, k158)
use strict;
use warnings;
use Test2::V0;
use IO::Socket::IP;
use JSON::MaybeXS;
use Langertha::Raider::ACP::Client;

my $JSON = JSON::MaybeXS->new( canonical => 1 );

# A fake agent: waits for session/prompt, asks permission under the id 1 (the
# same id as the prompt: the client must tell a request from a response),
# reports what the client answered, then finishes the prompt.
sub run_case {
  my ( $on_permission ) = @_;
  my $listen = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1 ) or die $!;
  my $port = $listen->sockport;
  pipe( my $r, my $w ) or die $!;
  my $pid = fork // die $!;
  if ( !$pid ) {
    close $r;
    my $c = Langertha::Raider::ACP::Client->new( port => $port, ( $on_permission ? ( on_permission => $on_permission ) : () ) );
    my $res = eval { $c->prompt_stream( 's1', 'go', sub { } ) };
    print {$w} $JSON->encode({ result => $res, error => "$@" });
    close $w;
    POSIX::_exit(0);
  }
  close $w;
  my $conn = $listen->accept;
  my $line = <$conn>;
  my $prompt = $JSON->decode($line);
  print {$conn} $JSON->encode({ jsonrpc => '2.0', id => 1, method => 'session/request_permission', params => {
    sessionId => 's1', toolCall => { toolCallId => 'perm-1', title => 'bash: ls' },
    options => [ { optionId => 'a-once', name => 'Allow once', kind => 'allow_once' }, { optionId => 'r-once', name => 'Reject', kind => 'reject_once' } ],
  } } ), "\n";
  my $answer = $JSON->decode( scalar <$conn> );
  print {$conn} $JSON->encode({ jsonrpc => '2.0', id => 2, method => 'fs/read_text_file', params => {} }), "\n";
  my $unknown = $JSON->decode( scalar <$conn> );
  print {$conn} $JSON->encode({ jsonrpc => '2.0', id => $prompt->{id}, result => { stopReason => 'end_turn' } }), "\n";
  local $/;
  my $out = $JSON->decode( scalar <$r> );
  waitpid $pid, 0;
  return ( $answer, $unknown, $out );
}

subtest 'a handler picks an option' => sub {
  my ( $answer, $unknown, $out ) = run_case( sub { $_[0]{options}[0]{optionId} } );
  is $answer, { jsonrpc => '2.0', id => 1, result => { outcome => { outcome => 'selected', optionId => 'a-once' } } }, 'selected';
  is $unknown->{error}{code}, -32601, 'an unknown agent request gets method not found';
  is $out->{result}, { stopReason => 'end_turn' }, 'the prompt still ends with its own response (ids may collide)';
};

subtest 'no handler: reject' => sub {
  my ( $answer, undef, $out ) = run_case();
  is $answer->{result}{outcome}, { outcome => 'selected', optionId => 'r-once' }, 'reject_once';
  is $out->{result}, { stopReason => 'end_turn' }, 'prompt ends';
};

subtest 'a handler that picks nothing offered, dies or says undef: reject' => sub {
  for my $h ( sub { 'made-up' }, sub { die 'x' }, sub { undef } ) {
    my ($answer) = run_case($h);
    is $answer->{result}{outcome}, { outcome => 'selected', optionId => 'r-once' }, 'reject_once';
  }
};

done_testing;
