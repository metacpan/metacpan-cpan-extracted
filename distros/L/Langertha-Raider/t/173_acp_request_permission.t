#!/usr/bin/env perl
# ABSTRACT: The ACP adapter's session/request_permission: request shape, option mapping, deny-by-default (ADR 0021 Nachtrag P2, k158)
use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;
use Path::Tiny;
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::ACP;

my $JSON = JSON::MaybeXS->new( canonical => 1 );
my $root = Path::Tiny->tempdir;
my $hall = Langertha::Raider::Hall->new( root => $root );
my $acp  = Langertha::Raider::Hall::ACP->new( hall => $hall );

{ package FakeStream; sub new { bless { out => [] }, shift } sub write { push @{ $_[0]{out} }, $_[1]; 1 } sub msgs { map { $JSON->decode($_) } @{ $_[0]{out} } } }

sub session {
  my $stream = FakeStream->new;
  $acp->_sessions->{s1} = { stream => $stream };
  return $stream;
}
sub ask {
  my ( $q ) = @_;
  my $stream = session();
  my $f = $acp->_request_permission( s1 => $q );
  my ($req) = $stream->msgs;
  return ( $f, $req );
}
sub respond { my ( $req, $result ) = @_; $acp->_dispatch( undef, $JSON->encode({ jsonrpc => '2.0', id => $req->{id}, %$result }) ) }
my $bash = { tool => 'bash', arguments => { command => 'make test' }, reason => 'default mode asks', rule => 'Bash(make test)' };

subtest 'the request follows the ACP schema' => sub {
  my ( $f, $req ) = ask($bash);
  is $req->{method}, 'session/request_permission', 'method';
  is $req->{jsonrpc}, '2.0', 'jsonrpc';
  ok defined $req->{id}, 'an id';
  is $req->{params}{sessionId}, 's1', 'sessionId';
  like $req->{params}{toolCall}, {
    toolCallId => qr/\Aperm-/, title => 'bash: make test', kind => 'execute', status => 'pending',
    rawInput => { command => 'make test' },
    content => [ { type => 'content', content => { type => 'text', text => 'default mode asks' } } ],
  }, 'toolCall update';
  is [ map { [ @{$_}{qw( optionId kind )} ] } @{ $req->{params}{options} } ],
    [ [ 'allow-once', 'allow_once' ], [ 'allow-always', 'allow_always' ], [ 'reject-once', 'reject_once' ] ], 'options';
  is $req->{params}{options}[1]{name}, 'Allow for this session: Bash(make test)', 'the offered rule is named';
  ok !$f->is_ready, 'pending until the client answers';
  respond( $req, { result => { outcome => { outcome => 'selected', optionId => 'allow-once' } } } );
  is $f->get, { answer => 'once' }, 'allow_once -> once';
};

subtest 'no rule: no allow_always' => sub {
  my ( $f, $req ) = ask({ %$bash, rule => undef });
  is [ map { $_->{kind} } @{ $req->{params}{options} } ], [ 'allow_once', 'reject_once' ], 'only allow_once and reject_once';
  $acp->_answer_pending( s1 => 'done' );
};

subtest 'every outcome' => sub {
  my %case = (
    'allow-always'  => [ { result => { outcome => { outcome => 'selected', optionId => 'allow-always' } } }, 'session' ],
    'reject-once'   => [ { result => { outcome => { outcome => 'selected', optionId => 'reject-once' } } }, 'no' ],
    'unknown option' => [ { result => { outcome => { outcome => 'selected', optionId => 'allow-forever' } } }, 'no' ],
    'no optionId'   => [ { result => { outcome => { outcome => 'selected' } } }, 'no' ],
    'cancelled'     => [ { result => { outcome => { outcome => 'cancelled' } } }, 'no' ],
    'odd outcome'   => [ { result => { outcome => { outcome => 'maybe' } } }, 'no' ],
    'no outcome'    => [ { result => {} }, 'no' ],
    'error'         => [ { error => { code => -32000, message => 'x' } }, 'no' ],
  );
  for my $name ( sort keys %case ) {
    my ( $f, $req ) = ask($bash);
    respond( $req, $case{$name}[0] );
    is $f->get->{answer}, $case{$name}[1], "$name -> $case{$name}[1]";
  }
};

subtest 'a reject kind is never an allow, even under an allow-looking id' => sub {
  my ( $f, $req ) = ask($bash);
  # the client picks the id of the reject option
  respond( $req, { result => { outcome => { outcome => 'selected', optionId => 'reject-once' } } } );
  is $f->get->{answer}, 'no', 'reject';
};

subtest 'answers that do not belong' => sub {
  my ( $f, $req ) = ask($bash);
  respond( { id => 99999 }, { result => { outcome => { outcome => 'selected', optionId => 'allow-once' } } } );
  ok !$f->is_ready, 'an unknown id changes nothing';
  respond( $req, { result => { outcome => { outcome => 'selected', optionId => 'reject-once' } } } );
  respond( $req, { result => { outcome => { outcome => 'selected', optionId => 'allow-once' } } } );
  is $f->get->{answer}, 'no', 'the first answer stands; a second one is ignored';
};

subtest 'no client, ended session, cancelled turn' => sub {
  delete $acp->_sessions->{s1};
  is $acp->_request_permission( s1 => $bash )->get->{answer}, 'no', 'unknown session: no';
  my ( $f ) = ask($bash);
  $acp->_forget_session('s1');
  is $f->get->{answer}, 'no', 'the session ending answers no';
  my ( $g ) = ask($bash);
  $acp->_answer_pending( s1 => 'the prompt turn was cancelled' );
  is $g->get, { answer => 'no', reason => 'the prompt turn was cancelled' }, 'a cancelled turn answers no';
  ok !keys %{ $acp->_outgoing }, 'nothing is left open';
};

subtest 'a cancelled question (hall timeout) is forgotten' => sub {
  my ( $f, $req ) = ask($bash);
  $f->cancel;
  ok !keys %{ $acp->_outgoing }, 'forgotten';
  respond( $req, { result => { outcome => { outcome => 'selected', optionId => 'allow-once' } } } );
  ok 1, 'a late response is ignored without harm';
};

subtest 'titles and kinds' => sub {
  my ( $f, $req ) = ask({ tool => 'write_file', arguments => { path => 'lib/A.pm' } });
  is [ @{ $req->{params}{toolCall} }{qw( title kind )} ], [ 'write_file: lib/A.pm', 'edit' ], 'write_file';
  ( $f, $req ) = ask({ tool => 'mcp_thing', arguments => { x => 1 } });
  is $req->{params}{toolCall}{kind}, 'other', 'other';
  ( $f, $req ) = ask({ tool => 'bash', arguments => { command => 'x' x 500 } });
  ok length $req->{params}{toolCall}{title} < 230, 'long titles are cut';
};

done_testing;
