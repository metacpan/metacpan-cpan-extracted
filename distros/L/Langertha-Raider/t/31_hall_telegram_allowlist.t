use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Temp qw( tempdir );
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::Telegram;

# No live Telegram: workers are registered by hand and updates are fed
# straight into _handle_update. Hall->_emit and Hall->spawn are captured.

my @events;
my @spawns;
{
  no warnings 'redefine';
  *Langertha::Raider::Hall::_emit = sub {
    my ( $self, $type, $data ) = @_;
    push @events, { %$data, type => $type };
  };
  *Langertha::Raider::Hall::spawn = sub {
    my ( $self, %args ) = @_;
    push @spawns, \%args;
  };
}

my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );

sub telegram_with {
  my ( %worker ) = @_;
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  $tg->_workers->{ops} = {
    token     => 'x',
    allowlist => [],
    routing   => { '*' => 'lagertha' },
    active    => 0,
    %worker
  };
  return $tg;
}

sub feed {
  my ( $tg, $msg ) = @_;
  @events = ();
  @spawns = ();
  $tg->_handle_update( ops => { update_id => 1, message => $msg } );
}

sub types { [ map { $_->{type} } @events ] }

my $dm_from_42 = {
  chat => { id => 42, type => 'private' },
  from => { id => 42 },
  text => 'hi'
};
my $group_from = sub {
  my ( $from_id ) = @_;
  return {
    chat => { id => -1001234, type => 'supergroup' },
    from => { id => $from_id },
    text => 'rm -rf everything'
  };
};

subtest 'empty allowlist rejects everyone' => sub {
  my $tg = telegram_with( allowlist => [] );
  feed( $tg, $dm_from_42 );
  is( types(), ['telegram.rejected'], 'only a rejection event' );
  is( $events[0]{reason}, 'sender_not_allowed', 'reason' );
  is( $events[0]{from_id}, 42, 'rejected sender reported' );
  is( scalar @spawns, 0, 'no raider spawned' );
};

subtest 'missing allowlist rejects everyone' => sub {
  my $tg = telegram_with( allowlist => undef );
  feed( $tg, $dm_from_42 );
  is( types(), ['telegram.rejected'], 'rejected' );
  is( scalar @spawns, 0, 'no raider spawned' );
};

subtest 'allowed sender in private chat passes' => sub {
  my $tg = telegram_with( allowlist => [42] );
  feed( $tg, $dm_from_42 );
  is( types(), ['telegram.in'], 'accepted' );
  is( scalar @spawns, 1, 'raider spawned' );
  is( $spawns[0]{name}, 'lagertha', 'routed' );
};

subtest 'string ids in config still match' => sub {
  my $tg = telegram_with( allowlist => ['42'] );
  feed( $tg, $dm_from_42 );
  is( types(), ['telegram.in'], 'accepted' );
};

subtest 'unknown sender in an allowed group chat rejects' => sub {
  my $tg = telegram_with( allowlist => [42], allowed_chats => [-1001234] );
  feed( $tg, $group_from->(666) );
  is( types(), ['telegram.rejected'], 'rejected' );
  is( $events[0]{reason}, 'sender_not_allowed', 'reason' );
  is( scalar @spawns, 0, 'no raider spawned' );
};

subtest 'group chat id in allowlist does not open the group' => sub {
  # the pre-fix behaviour: a chat id in allowlist let every member through
  my $tg = telegram_with( allowlist => [-1001234] );
  feed( $tg, $group_from->(666) );
  is( types(), ['telegram.rejected'], 'rejected' );
  is( scalar @spawns, 0, 'no raider spawned' );
};

subtest 'allowed sender in an allowed group chat passes' => sub {
  my $tg = telegram_with( allowlist => [42], allowed_chats => [-1001234] );
  feed( $tg, $group_from->(42) );
  is( types(), ['telegram.in'], 'accepted' );
  is( scalar @spawns, 1, 'raider spawned' );
};

subtest 'allowed sender in a chat not listed rejects' => sub {
  my $tg = telegram_with( allowlist => [42] );
  feed( $tg, $group_from->(42) );
  is( types(), ['telegram.rejected'], 'rejected' );
  is( $events[0]{reason}, 'chat_not_allowed', 'reason' );
  is( scalar @spawns, 0, 'no raider spawned' );
};

subtest 'message without from rejects' => sub {
  my $tg = telegram_with( allowlist => [42], allowed_chats => [42] );
  feed( $tg, { chat => { id => 42, type => 'private' }, text => 'hi' } );
  is( types(), ['telegram.rejected'], 'rejected' );
  is( $events[0]{reason}, 'no_sender', 'reason' );
  is( scalar @spawns, 0, 'no raider spawned' );
};

subtest 'telegram.in names the sender, not the chat' => sub {
  my $tg = telegram_with( allowlist => [42], allowed_chats => [-1001234] );
  feed( $tg, {
    chat => { id => -1001234, type => 'supergroup', title => 'Ops Crew' },
    from => { id => 42, first_name => 'Astrid', username => 'astrid_ops' },
    text => 'status?'
  } );
  is( types(), ['telegram.in'], 'accepted' );
  is( $events[0]{first_name}, 'Astrid', 'first_name from message.from' );
  is( $events[0]{username}, 'astrid_ops', 'username from message.from' );
};

subtest 'startup warns about an empty allowlist' => sub {
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  @events = ();
  my $warnings = warnings { $tg->_check_bot_config( ops => { token => 'x' } ) };
  is( scalar @$warnings, 1, 'one warning' );
  like( $warnings->[0], qr/ops.*empty allowlist/, 'names the bot and the cause' );
  is( types(), ['telegram.config_warning'], 'event emitted' );

  @events = ();
  $warnings = warnings { $tg->_check_bot_config( ops => { token => 'x', allowlist => [42] } ) };
  is( scalar @$warnings, 0, 'no warning with a user id' );

  $warnings = warnings { $tg->_check_bot_config( ops => { token => 'x', allowlist => [42, -1001234] } ) };
  is( scalar @$warnings, 1, 'warns about a chat id in allowlist' );
  like( $warnings->[0], qr/-1001234.*allowed_chats/, 'points at allowed_chats' );
};

done_testing;
