use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use URI;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::Raider;
use Langertha::Raider::Hall::Telegram;
use Langertha::Raider::HallTools qw( build_hall_tools_server );

# A raider spawned for a Telegram message must be able to answer that chat:
# the hall hands bot + chat_id to the child via env, and telegram_reply
# is bound to exactly that target. No live Telegram, no live model.

sub tool_named {
  my ( $server, $name ) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  return $tool;
}

subtest 'accepted telegram message spawns with its reply target' => sub {
  my @spawns;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub {};
  local *Langertha::Raider::Hall::spawn = sub {
    my ( $self, %args ) = @_;
    push @spawns, \%args;
  };
  my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  $tg->_workers->{ops} = {
    token     => 'x',
    allowlist => [42],
    routing   => { '*' => 'lagertha' },
    active    => 0
  };
  $tg->_handle_update( ops => { update_id => 1, message => {
    chat => { id => 42, type => 'private' },
    from => { id => 42 },
    text => 'hi'
  } } );
  is( scalar @spawns, 1, 'raider spawned' );
  is( $spawns[0]{mission}, 'hi', 'mission is the message text' );
  is( $spawns[0]{telegram}, { bot => 'ops', chat_id => 42 }, 'reply target passed' );
};

subtest 'reply target survives the singleton queue' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my $hall = Langertha::Raider::Hall->new( root => path($tmp) );
  $hall->raiders->{old} = Langertha::Raider::Hall::Raider->new( {
    id        => 'old',
    pid       => 12345,
    slot_name => '1bjorn',
    base_name => 'bjorn',
    log_path  => path($tmp)->child('old.log'),
    mission   => 'old mission'
  } );
  my $queued = $hall->spawn(
    name     => '1bjorn',
    mission  => 'next',
    telegram => { bot => 'ops', chat_id => 42 }
  );
  ok( $queued->{queued}, 'queued' );

  my @spawned;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_spawn_raider = sub {
    my ( $self, @args ) = @_;
    push @spawned, \@args;
    return { id => 'new', pid => 999, slot => $args[0] };
  };
  $hall->_reap_raider( 12345, 0 );
  is( $spawned[0][3], { bot => 'ops', chat_id => 42 }, 'reply target replayed from the queue' );
};

sub spawn_and_read_env {
  my ( %spawn ) = @_;
  my $tmp = path( tempdir( CLEANUP => 1 ) );
  my $out = $tmp->child('env.json');
  my $bin = $tmp->child('fake-raider');
  $bin->spew_utf8( "#!$^X\n"
    .'use JSON::PP; open my $fh, ">", "'.$out.'" or die $!;'
    .' print $fh JSON::PP->new->encode({ map { $_ => $ENV{$_} } grep { /^RAIDER_HALL_/ } keys %ENV });'
    ."\n" );
  $bin->chmod(0755);
  local $ENV{RAIDER_HALL_RAIDER_BIN} = "$bin";
  my $hall = Langertha::Raider::Hall->new( root => $tmp );
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub {};
  $hall->spawn( name => 'bjorn', mission => 'm', %spawn );
  my $deadline = time + 20;
  $hall->loop->loop_once(0.1) until ( -s $out && !%{ $hall->raiders } ) || time > $deadline;
  return JSON::MaybeXS->new->decode( $out->slurp_utf8 );
}

subtest 'spawned raider gets the reply target in its env' => sub {
  my $env = spawn_and_read_env( telegram => { bot => 'ops', chat_id => 42 } );
  is( $env->{RAIDER_HALL_TELEGRAM_BOT}, 'ops', 'bot' );
  is( $env->{RAIDER_HALL_TELEGRAM_CHAT_ID}, 42, 'chat_id' );
};

subtest 'non-telegram spawn gets no reply target, not even an inherited one' => sub {
  local $ENV{RAIDER_HALL_TELEGRAM_BOT} = 'leaked';
  local $ENV{RAIDER_HALL_TELEGRAM_CHAT_ID} = 666;
  my $env = spawn_and_read_env();
  ok( !exists $env->{RAIDER_HALL_TELEGRAM_BOT}, 'no bot' );
  ok( !exists $env->{RAIDER_HALL_TELEGRAM_CHAT_ID}, 'no chat_id' );
};

my @calls;
{
  no warnings 'redefine';
  *Langertha::Raider::HallTools::_call = sub {
    my ( $sock, $cmd, %payload ) = @_;
    push @calls, { cmd => $cmd, %payload };
    return { ok => 1 };
  };
}

subtest 'bound telegram_reply only needs text and sends to the bound chat' => sub {
  @calls = ();
  my $tool = tool_named( build_hall_tools_server(
    socket   => '/nonexistent',
    telegram => { bot => 'ops', chat_id => 42 }
  ), 'telegram_reply' );
  is( $tool->input_schema->{required}, ['text'], 'only text required' );
  my $r = $tool->code->( $tool, { text => 'hello' } );
  ok( !$r->{isError}, 'sent' );
  is( \@calls, [ { cmd => 'telegram_reply', bot => 'ops', chat_id => 42, text => 'hello' } ],
    'bound bot and chat_id used' );
};

subtest 'bound telegram_reply refuses another chat' => sub {
  @calls = ();
  my $tool = tool_named( build_hall_tools_server(
    socket   => '/nonexistent',
    telegram => { bot => 'ops', chat_id => 42 }
  ), 'telegram_reply' );
  my $r = $tool->code->( $tool, { text => 'x', chat_id => 666 } );
  ok( $r->{isError}, 'error' );
  $r = $tool->code->( $tool, { text => 'x', bot => 'other' } );
  ok( $r->{isError}, 'error for another bot' );
  is( \@calls, [], 'nothing sent' );
  $r = $tool->code->( $tool, { text => 'x', bot => 'ops', chat_id => '42' } );
  ok( !$r->{isError}, 'restating the bound target is fine' );
};

subtest 'bound target is read from the env the hall sets' => sub {
  @calls = ();
  local $ENV{RAIDER_HALL_TELEGRAM_BOT} = 'ops';
  local $ENV{RAIDER_HALL_TELEGRAM_CHAT_ID} = 42;
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'telegram_reply' );
  $tool->code->( $tool, { text => 'hello' } );
  is( $calls[0]{chat_id}, 42, 'chat_id from env' );
  is( $calls[0]{bot}, 'ops', 'bot from env' );
};

subtest 'unbound telegram_reply still requires bot and chat_id' => sub {
  local $ENV{RAIDER_HALL_TELEGRAM_BOT};
  local $ENV{RAIDER_HALL_TELEGRAM_CHAT_ID};
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'telegram_reply' );
  is( $tool->input_schema->{required}, [qw( bot chat_id text )], 'all three required' );
};


# Forum topics: the thread is part of the reply target, like bot and chat_id,
# so the answer lands in the topic the message came from.

subtest 'a forum topic message carries its thread in the reply target' => sub {
  my @spawns;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_emit = sub {};
  local *Langertha::Raider::Hall::spawn = sub { my ( $self, %args ) = @_; push @spawns, \%args };
  my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ) );
  my $tg = Langertha::Raider::Hall::Telegram->new( hall => $hall );
  $tg->_workers->{ops} = { token => 'x', allowlist => [42], allowed_chats => [-100],
    routing => { '*' => 'lagertha' }, active => 0 };
  $tg->_handle_update( ops => { update_id => 1, message => {
    chat => { id => -100 }, from => { id => 42 }, message_thread_id => 7, text => 'hi' } } );
  is( $spawns[0]{telegram}, { bot => 'ops', chat_id => -100, message_thread_id => 7 }, 'thread passed' );
};

subtest 'spawned raider gets the thread in its env, never an inherited one' => sub {
  my $env = spawn_and_read_env( telegram => { bot => 'ops', chat_id => -100, message_thread_id => 7 } );
  is( $env->{RAIDER_HALL_TELEGRAM_THREAD_ID}, 7, 'thread' );
  local $ENV{RAIDER_HALL_TELEGRAM_THREAD_ID} = 666;
  $env = spawn_and_read_env( telegram => { bot => 'ops', chat_id => 42 } );
  ok( !exists $env->{RAIDER_HALL_TELEGRAM_THREAD_ID}, 'none for a chat without topics' );
};

subtest 'bound telegram_reply answers into the bound thread' => sub {
  @calls = ();
  my $tool = tool_named( build_hall_tools_server(
    socket   => '/nonexistent',
    telegram => { bot => 'ops', chat_id => -100, message_thread_id => 7 }
  ), 'telegram_reply' );
  is( $tool->input_schema->{required}, ['text'], 'still only text required' );
  $tool->code->( $tool, { text => 'hello' } );
  is( \@calls, [ { cmd => 'telegram_reply', bot => 'ops', chat_id => -100,
    message_thread_id => 7, text => 'hello' } ], 'thread sent along' );

  @calls = ();
  local $ENV{RAIDER_HALL_TELEGRAM_BOT} = 'ops';
  local $ENV{RAIDER_HALL_TELEGRAM_CHAT_ID} = -100;
  local $ENV{RAIDER_HALL_TELEGRAM_THREAD_ID} = 7;
  $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'telegram_reply' );
  $tool->code->( $tool, { text => 'hello', message_thread_id => 9 } );
  is( $calls[0]{message_thread_id}, 7, 'from the env, not from the model' );
};

subtest 'unbound telegram_reply takes an optional thread' => sub {
  @calls = ();
  local $ENV{RAIDER_HALL_TELEGRAM_BOT};
  local $ENV{RAIDER_HALL_TELEGRAM_CHAT_ID};
  local $ENV{RAIDER_HALL_TELEGRAM_THREAD_ID};
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'telegram_reply' );
  ok( $tool->input_schema->{properties}{message_thread_id}, 'offered' );
  $tool->code->( $tool, { bot => 'ops', chat_id => -100, message_thread_id => 7, text => 'x' } );
  is( $calls[0]{message_thread_id}, 7, 'passed on' );
  $tool->code->( $tool, { bot => 'ops', chat_id => 42, text => 'x' } );
  ok( !exists $calls[1]{message_thread_id}, 'and left out without one' );
};

subtest 'the hall sends message_thread_id to Telegram' => sub {
  my $hall = Langertha::Raider::Hall->new( root => path( tempdir( CLEANUP => 1 ) ),
    config => { telegram => { bots => { ops => { token => 'x' } } } } );
  my @sent;
  {
    no warnings 'redefine';
    local *Langertha::Raider::Hall::Telegram::send_message = sub { my ( $self, %args ) = @_; push @sent, \%args; { ok => 1 } };
    $hall->protocol;
    $hall->_handle_command( CaptureStream->new, { cmd => 'telegram_reply', bot => 'ops',
      chat_id => -100, message_thread_id => 7, text => 'hi' } );
  }
  is( $sent[0]{message_thread_id}, 7, 'telegram_reply command passes the thread' );

  my @requests;
  my $tg = $hall->telegram;
  $tg->_workers->{ops} = { token => 'x', ua => FakeUA->new( \@requests ), active => 0 };
  $tg->send_message( bot => 'ops', chat_id => -100, message_thread_id => 7, text => 'hi' );
  $tg->send_message( bot => 'ops', chat_id => 42, text => 'hi' );
  my @forms = map { { URI->new( '?'.$_->content )->query_form } } @requests;
  is( $forms[0]{message_thread_id}, 7, 'sendMessage into the topic' );
  ok( !exists $forms[1]{message_thread_id}, 'not for a plain chat' );
};

{
  package CaptureStream;
  sub new { bless { lines => [] }, shift }
  sub write { push @{ $_[0]{lines} }, $_[1]; 1 }
}

{
  package FakeUA;
  use Future;
  sub new { bless { requests => $_[1] }, $_[0] }
  sub do_request { my ( $self, %args ) = @_; push @{ $self->{requests} }, $args{request}; Future->done }
}

done_testing;
