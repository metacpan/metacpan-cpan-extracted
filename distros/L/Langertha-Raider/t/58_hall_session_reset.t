#!/usr/bin/env perl
# ABSTRACT: resetting and cleaning up hall session bindings (ADR 0015, Hall bindings)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::CLI;
use Langertha::Raider::Hall::Telegram;
use Langertha::Raider::SessionStore;

clear_engine_env();

my $orig_cwd = path('.')->absolute;

sub new_hall { Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) ) }

sub store_of { Langertha::Raider::SessionStore->new( root => ''.$_[0]->root ) }

sub bindings_file { JSON::MaybeXS->new->decode( $_[0]->state_dir->child('sessions.json')->slurp_utf8 ) }

{
  package CaptureStream;
  sub new { bless { lines => [] }, shift }
  sub write { push @{ $_[0]{lines} }, JSON::MaybeXS->new->decode( $_[1] ); 1 }
}

sub command {
  my ( $hall, %payload ) = @_;
  $hall->protocol;
  my $stream = CaptureStream->new;
  $hall->_handle_command( $stream, \%payload );
  return $stream->{lines}[0];
}

subtest 'session_reset: the binding starts over, the journal stays' => sub {
  my $hall = new_hall();
  my $id = $hall->session_for('telegram:ops:42');
  $hall->session_for('cron:nightly');
  my @events;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub { push @events, [ $_[1], { %{ $_[2] } } ] };

  is( command( $hall, cmd => 'session_reset', binding => 'telegram:ops:42' ),
    { reset => 1, binding => 'telegram:ops:42', session => $id }, 'reply names the old session' );
  ok( !exists $hall->session_bindings->{'telegram:ops:42'}, 'unbound' );
  ok( !exists bindings_file($hall)->{'telegram:ops:42'}, 'in sessions.json too' );
  ok( exists bindings_file($hall)->{'cron:nightly'}, 'other bindings untouched' );
  ok( store_of($hall)->exists($id), 'the journal stays' );
  is( [ grep { $_->[0] eq 'session.reset' } @events ],
    [ [ 'session.reset', { binding => 'telegram:ops:42', session => $id } ] ], 'session.reset event' );
  isnt( $hall->session_for('telegram:ops:42'), $id, 'the next mission gets a new session' );
};

subtest 'session_reset: unknown or missing binding is an error' => sub {
  my $hall = new_hall();
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub {};
  is( command( $hall, cmd => 'session_reset', binding => 'telegram:ops:42' ),
    { error => 'no session bound to telegram:ops:42' }, 'unknown' );
  is( command( $hall, cmd => 'session_reset' ), { error => 'session_reset requires a binding' }, 'missing' );
};

sub run_cli {
  my ( $reply, @argv ) = @_;
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.socket')->touch;
  chdir $tmp or die "chdir $tmp: $!";
  my ( $sent, $out, $died ) = ( undef, '' );
  {
    no warnings 'redefine';
    local *Langertha::Raider::Hall::CLI::_send_command = sub { $sent = $_[1]{payload}; return $reply };
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    $died = dies { Langertha::Raider::Hall::CLI->main(@argv) };
  }
  chdir $orig_cwd or die "chdir $orig_cwd: $!";
  return ( $sent, $out, $died );
}

subtest 'raider hall session reset BINDING' => sub {
  my ( $sent, $out, $died ) = run_cli(
    { reset => 1, binding => 'telegram:ops:42', session => '20260925-000000-abcd' },
    'session', 'reset', 'telegram:ops:42' );
  is( $died, undef, 'lives' );
  is( $sent, { cmd => 'session_reset', binding => 'telegram:ops:42' }, 'sends session_reset' );
  like( $out, qr/telegram:ops:42 .*new session.*20260925-000000-abcd/, 'says what happened' );

  ( undef, undef, $died ) = run_cli( { error => 'no session bound to x' }, 'session', 'reset', 'x' );
  like( $died, qr/no session bound to x/, 'a hall error dies' );
  ( $sent, undef, $died ) = run_cli( {}, 'session', 'reset' );
  like( $died, qr/Usage: raider hall session reset/, 'BINDING is required' );
  is( $sent, undef, 'nothing sent' );
  ( undef, undef, $died ) = run_cli( {}, 'session', 'frobnicate' );
  like( $died, qr/Usage: raider hall session reset/, 'unknown session subcommand' );
};

sub telegram_hall {
  my $hall = new_hall();
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  $tg->_workers->{ops} = { token => 'x', allowlist => [42], allowed_chats => [-100],
    routing => { '*' => 'bjorn' }, active => 0 };
  return ( $hall, $tg );
}

subtest 'telegram /new starts a fresh session for that chat' => sub {
  my ( $hall, $tg ) = telegram_hall();
  my ( @spawns, @sent, @events );
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub { push @events, $_[1] };
  local *Langertha::Raider::Hall::spawn = sub { my ( $self, %args ) = @_; push @spawns, \%args; {} };
  local *Langertha::Raider::Hall::Telegram::send_message = sub { my ( $self, %args ) = @_; push @sent, \%args; { ok => 1 } };

  my $topic = $hall->session_for('telegram:ops:-100:7');
  my $other = $hall->session_for('telegram:ops:-100');
  $tg->_handle_update( ops => { update_id => 1, message => {
    chat => { id => -100 }, from => { id => 42 }, message_thread_id => 7, text => '/new' } } );
  is( \@spawns, [], 'not handed to a raider' );
  ok( !exists $hall->session_bindings->{'telegram:ops:-100:7'}, 'the topic binding is reset' );
  is( $hall->session_bindings->{'telegram:ops:-100'}, $other, 'the rest of the group is not' );
  ok( store_of($hall)->exists($topic), 'the journal stays' );
  is( scalar @sent, 1, 'one confirmation' );
  is( { map { $_ => $sent[0]{$_} } qw( bot chat_id message_thread_id ) },
    { bot => 'ops', chat_id => -100, message_thread_id => 7 }, 'into the same topic' );
  like( $sent[0]{text}, qr/new session/i, 'saying so' );

  $tg->_handle_update( ops => { update_id => 2, message => {
    chat => { id => 42 }, from => { id => 42 }, text => '/new@raider_bot' } } );
  is( \@spawns, [], '/new@BOT in a private chat is the command too' );
  is( scalar @sent, 2, 'confirmed, even without a session to reset' );

  $tg->_handle_update( ops => { update_id => 3, message => {
    chat => { id => -100 }, from => { id => 666 }, text => '/new' } } );
  is( $hall->session_bindings->{'telegram:ops:-100'}, $other, 'a rejected sender resets nothing' );
  is( scalar @sent, 2, 'and gets no answer' );

  $tg->_handle_update( ops => { update_id => 4, message => {
    chat => { id => -100 }, from => { id => 42 }, text => '/newer ideas' } } );
  is( scalar @spawns, 1, 'other text starting with /new is a mission' );
};

subtest 'hall start forgets ACP bindings, keeps the others' => sub {
  my $hall = new_hall();
  my %id = map { $_ => $hall->session_for($_) } qw( acp:acp-1 telegram:ops:42 cron:nightly slot:1ivar );
  $hall->binding_queues->{'acp:acp-1'} = [ { name => 'bjorn', mission => 'p', binding => 'acp:acp-1' } ];
  $hall->binding_queues->{'telegram:ops:42'} = [ { name => 'bjorn', mission => 't', binding => 'telegram:ops:42' } ];
  $hall->_persist_binding_queues;

  my $restarted = Langertha::Raider::Hall->new( root => $hall->root );
  $restarted->_forget_acp_bindings;
  is( [ sort keys %{ $restarted->session_bindings } ], [qw( cron:nightly slot:1ivar telegram:ops:42 )],
    'only the ACP binding is gone' );
  is( [ sort keys %{ bindings_file($restarted) } ], [qw( cron:nightly slot:1ivar telegram:ops:42 )],
    'persisted' );
  is( [ keys %{ $restarted->binding_queues } ], ['telegram:ops:42'], 'with its waiting prompts' );
  ok( ( !grep { !store_of($hall)->exists($_) } values %id ), 'no journal deleted' );
};

done_testing;
