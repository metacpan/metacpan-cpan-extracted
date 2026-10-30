package Test::Raider::HallScenario;
# ABSTRACT: A real hall in its own process, real raiders on the scripted model, driven step by step

use strict;
use warnings;
use utf8;
use Carp qw( croak );
use Exporter 'import';
use File::Temp ();
use IO::Select;
use IO::Socket::INET;
use IO::Socket::IP;
use IO::Socket::UNIX;
use JSON::MaybeXS ();
use Path::Tiny;
use POSIX qw( WNOHANG );
use Time::HiRes ();
use YAML::PP;
use Langertha::Raider::Hall ();

our @EXPORT_OK = qw( free_port run_hall_scenario );

=head1 SYNOPSIS

    use Test::Raider::HallScenario qw( run_hall_scenario );
    run_hall_scenario( YAML::PP->new->load_file('t/scenarios/hall/01-spawn.yml') );

=head1 DESCRIPTION

The engine of F<t/202_hall_scenarios.t>. A scenario is a YAML document; this
module runs it against a B<real> L<Langertha::Raider::Hall> in a process of its
own (free ACP port, temporary root, nothing of the developer's home), whose
raiders are real F<raider> processes answering from rules instead of a model
(C<-e mock>, L<Langertha::Engine::Virtual>). The scenario drives the hall the
ways a user has: the control socket (the commands of C<raider hall ...>) and an
ACP client over TCP; it watches the hall's event bus and the files the hall and
its raiders leave in the root.

=head1 SCENARIO FORMAT

    title:   what the scenario shows
    skip:    reason -- the scenario is listed but not run
    hall:                       # merged over the defaults of .raider-hall.yml
      cancel_grace: 1           # (the raiders Testie -- parallel runs -- and testie
                                #  -- as 1testie a singleton slot -- on the mock
                                #  engine and the ACP port are there already)
    model:                      # rules file of the scripted model (-e mock)
      rules: { 'Hello': { answer: 'Hi' } }
      after: { write_file: { answer: 'written' } }
      fallback: { answer: 'unknown' }
    files: { path: content }    # written to the hall root before the start
    steps:                      # run in order; each one is a one-key mapping
      - spawn: { name: Testie, mission: Hello, as: a }
      - done:  { run: a, status: completed, response_like: Hi }

Steps (C<as> names the result for later steps; C<run> is such a name):

=over

=item * C<spawn: { name, mission, as }> -- the control socket's C<spawn>.
C<queued: true> when the hall queued it.

=item * C<kill: { run }>, C<ps: { as }>, C<logs: { run, as }> -- the control
socket's commands of that name.

=item * C<command: { cmd, payload, as }> -- any other control socket command.

=item * C<acp_session: { as, raider }>, C<acp_prompt: { session, text, as,
wait }> (C<wait: false> sends and returns), C<acp_wait: { prompt }>,
C<acp_cancel: { session }>, C<acp_reconnect: {}>.
C<acp_permissions: { answers: [once|always|reject|reject_always|cancelled|bogus|ignore, ...] }>
sets how the scenario's ACP client answers C<session/request_permission>
(default reject); C<expect_permission_requests: { count, first: { title_like,
kind, options, names_like } }> checks what the hall asked. C<expect_file>
takes C<absent: true>.

=item * C<wait_event: { type, <field>: value, nth, as, timeout }> -- until the
C<nth> (default first) matching event is on the bus; C<as> keeps it, and as a
C<run> it names the run an C<raider.spawned> event is about.

=item * C<done: { run, ... }> -- waits for C<raider.done> of the run, then
checks C<status>, C<response_like>, C<error_like>, C<binding>, C<exit_code>,
C<signaled> and C<session: { same_as: run | different_from: run }>.

=item * C<idle: { timeout }> -- waits until the hall has no raider left.

=item * C<expect_event: { type, <field>: value, <field>_like: regex }>,
C<expect_no_event: { ... }>, C<expect_ps: { count, missions: [...] }>,
C<expect_acp: { prompt, stop_reason, text_like, error_like }>,
C<expect_file: { path, content | like }>, C<expect_telegram_sent: { chat_id, count, text_like }>, C<expect_quiet: {}> (no process works in
the root any more), C<expect_log: { run, like }>,
C<expect_journals: { count, prompts: [[...], ...] }> -- the session journals of
the root, in order of creation, each with the user prompts it carries.

=item * C<telegram_say: { chat_id, from_id, text }> (with C<fake_telegram: true> at the top
of the scenario: a local Bot API stands in for api.telegram.org),
C<restart_hall: {}>, C<stop_hall: {}>, C<start_hall: {}>,
C<sleep: SECONDS>.

=back

Every scenario ends with the hall stopped and a check that no process of it --
the hall, its raiders, what they ran -- is left.

=cut

my $JSON = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

sub free_port {
  my $probe = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1 )
    or return;
  my $port = $probe->sockport;
  close $probe;
  return $port;
}

sub now { Time::HiRes::time() }

#### Test2 glue: the scenario reports through Test2::API's context

sub _ok {
  my ( $pass, $name, @diag ) = @_;
  require Test2::API;
  my $ctx = Test2::API::context( level => 1 );
  $ctx->ok( $pass, $name, \@diag );
  $ctx->release;
  return $pass;
}

sub _is {
  my ( $got, $want, $name ) = @_;
  my $pass = !defined $got && !defined $want || defined $got && defined $want && $got eq $want;
  return _ok( $pass, $name, $pass ? () : ( "got:      " . ( $got // 'undef' ), "expected: " . ( $want // 'undef' ) ) );
}

sub _like {
  my ( $got, $re, $name ) = @_;
  my $pass = defined $got && $got =~ /$re/s;
  return _ok( $pass, $name, $pass ? () : ( "got:      " . ( $got // 'undef' ), "expected to match: $re" ) );
}

#### The hall process

{
  package Test::Raider::HallScenario::Hall;
  use POSIX qw( WNOHANG );

  sub new {
    my ( $class, %arg ) = @_;
    return bless { %arg }, $class;
  }

  sub root        { $_[0]{root} }
  sub socket_path { $_[0]{root}->child('.raider-hall.socket')->stringify }
  sub pid         { $_[0]{pid} }

  sub start {
    my ( $self ) = @_;
    # A stale socket of a hall that died hard would make the new one fail.
    my $sock = $self->socket_path;
    unlink $sock if -S $sock;
    my $pid = fork() // die "fork: $!";
    if ( !$pid ) {
      open STDERR, '>>', $self->{log} or POSIX::_exit(3);
      open STDOUT, '>>', $self->{log} or POSIX::_exit(3);
      require Langertha::Raider::Hall;
      $self->{child_setup}->() if $self->{child_setup};
      my $hall = Langertha::Raider::Hall->new( root => $self->{root} );
      $SIG{TERM} = sub { $hall->shutdown };
      eval { $hall->run; 1 } or print STDERR "hall died: $@";
      POSIX::_exit(0);
    }
    $self->{pid} = $pid;
    # Up means: the hall answers on its control socket. The socket accepts
    # as soon as it listens, which is before the hall opened its ACP port
    # (Hall->run sets the socket up first); an answer comes only from the
    # running loop, so everything the hall sets up before is in place.
    my $deadline = Time::HiRes::time() + 60;
    while ( Time::HiRes::time() < $deadline ) {
      last if waitpid( $pid, WNOHANG ) > 0;
      return 1 if $self->answers( $deadline );
      select undef, undef, undef, 0.1;
    }
    return 0;
  }

  # Whether the hall answers a ps on its control socket before $deadline.
  sub answers {
    my ( $self, $deadline ) = @_;
    my $sock = -S $self->socket_path && IO::Socket::UNIX->new( Peer => $self->socket_path ) or return 0;
    my $conn = Test::Raider::HallScenario::Conn->new($sock);
    $conn->send( $JSON->encode({ type => 'command', payload => { cmd => 'ps' } }) . "\n" )
      or return 0;
    $conn->pump(0.1) until @{ $conn->{lines} } || $conn->{eof} || Time::HiRes::time() > $deadline;
    my $answered = @{ $conn->{lines} } ? 1 : 0;
    $conn->close;
    return $answered;
  }

  # TERM, then KILL; true when the hall is gone.
  sub stop {
    my ( $self ) = @_;
    my $pid = delete $self->{pid} or return 1;
    kill 'TERM', $pid;
    my $reaped;
    for ( 1 .. 100 ) {
      if ( waitpid( $pid, WNOHANG ) > 0 ) { $reaped = 1; last }
      select undef, undef, undef, 0.1;
    }
    if ( !$reaped ) { kill 'KILL', $pid; waitpid $pid, 0 }
    return $reaped ? 1 : 0;
  }
}

#### A line-framed connection that collects what the peer sends

{
  package Test::Raider::HallScenario::Conn;
  use IO::Select;
  use Time::HiRes ();

  sub new {
    my ( $class, $sock ) = @_;
    $sock->blocking(0);
    return bless { sock => $sock, buf => '', lines => [] }, $class;
  }

  sub send {
    my ( $self, $bytes ) = @_;
    $self->{sock}->blocking(1);
    my $n = syswrite $self->{sock}, $bytes;
    $self->{sock}->blocking(0);
    return defined $n;
  }

  # Read what is there, wait at most $seconds for something; the number of
  # new lines.
  sub pump {
    my ( $self, $seconds ) = @_;
    return 0 unless $self->{sock};
    my $sel = IO::Select->new( $self->{sock} );
    my $got = 0;
    my $first = 1;
    while ( $sel->can_read( $first ? $seconds : 0 ) ) {
      $first = 0;
      my $n = sysread $self->{sock}, my $chunk, 65536;
      if ( !defined $n ) { last }
      if ( !$n ) { $self->{eof} = 1; last }
      $self->{buf} .= $chunk;
      while ( $self->{buf} =~ s/^(.*?)\r?\n// ) {
        next unless length $1;
        push @{ $self->{lines} }, $1;
        $got++;
      }
    }
    return $got;
  }

  sub take_line {
    my ( $self ) = @_;
    return shift @{ $self->{lines} };
  }

  sub close { my ( $self ) = @_; close delete $self->{sock} if $self->{sock}; return }
}

#### A Telegram Bot API on a local port

{
  package Test::Raider::HallScenario::FakeTelegram;
  use IO::Socket::INET;
  use JSON::MaybeXS ();
  use Path::Tiny;
  use POSIX ();
  use Time::HiRes ();
  use URI;

  my $J = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

  # The part of the Bot API the hall uses, over plain HTTP: getUpdates (held
  # for a moment when there is nothing, like a long poll) and sendMessage.
  # Updates come from the file `inbox` and what the hall sends goes to the
  # file `outbox`, one JSON object per line, so the test only appends and reads.
  sub new {
    my ( $class ) = @_;
    my $dir = Path::Tiny->tempdir;
    $dir->child($_)->touch for qw( inbox outbox );
    my $listen = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 5, ReuseAddr => 1 )
      or return;
    my $self = bless { dir => $dir, port => $listen->sockport }, $class;
    my $pid = fork() // die "fork: $!";
    if ( !$pid ) {
      $SIG{TERM} = sub { POSIX::_exit(0) };
      $self->_serve($listen);
      POSIX::_exit(0);
    }
    close $listen;
    $self->{pid} = $pid;
    return $self;
  }

  sub port { $_[0]{port} }

  sub stop {
    my ( $self ) = @_;
    my $pid = delete $self->{pid} or return;
    kill 'TERM', $pid;
    waitpid $pid, 0;
    return;
  }

  sub DESTROY { $_[0]->stop }

  # Test side.
  sub say {
    my ( $self, %m ) = @_;
    my $line = $J->encode({
      message => {
        message_id => 1,
        date       => time,
        from       => { id => 0 + $m{from_id}, first_name => $m{first_name} // 'Tester', username => $m{username} // 'tester' },
        chat       => { id => 0 + $m{chat_id} },
        text       => $m{text},
      },
    });
    $self->{dir}->child('inbox')->append_utf8( $line . "\n" );
    return;
  }

  sub sent {
    my ( $self ) = @_;
    return map { $J->decode($_) } $self->{dir}->child('outbox')->lines_utf8( { chomp => 1 } );
  }

  # Server side.
  sub _serve {
    my ( $self, $listen ) = @_;
    while ( my $c = $listen->accept ) {
      eval { $self->_handle($c); 1 };
      close $c;
    }
  }

  sub _handle {
    my ( $self, $c ) = @_;
    $c->autoflush(1);
    my $request_line = <$c>;
    return unless defined $request_line;
    my ( $method, $target ) = $request_line =~ m{\A(\w+) (\S+)};
    my $length = 0;
    while ( defined( my $h = <$c> ) ) {
      last if $h eq "\r\n";
      $length = $1 if $h =~ /\AContent-Length:\s*(\d+)/i;
    }
    my $body = '';
    read $c, $body, $length if $length;
    my $uri = URI->new( 'http://x' . $target );
    my ($call) = $uri->path =~ m{/bot[^/]+/(\w+)\z};
    my $answer = { ok => JSON::MaybeXS::true(), result => [] };
    if ( ( $call // '' ) eq 'getUpdates' ) {
      my %q = $uri->query_form;
      my $offset = $q{offset} // 0;
      my $deadline = Time::HiRes::time() + 1.5;
      my @updates;
      while (1) {
        my $n = 0;
        @updates = grep { $_->{update_id} >= $offset } map { { %{ $J->decode($_) }, update_id => ++$n } }
          $self->{dir}->child('inbox')->lines_utf8( { chomp => 1 } );
        last if @updates || Time::HiRes::time() > $deadline;
        select undef, undef, undef, 0.1;
      }
      $answer->{result} = \@updates;
    }
    elsif ( ( $call // '' ) eq 'sendMessage' ) {
      my %form = URI->new( '?' . $body )->query_form;
      $self->{dir}->child('outbox')->append_utf8( $J->encode( \%form ) . "\n" );
      $answer->{result} = { message_id => 1 };
    }
    my $json = $J->encode($answer);
    print $c "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " . length($json) . "\r\nConnection: close\r\n\r\n" . $json;
    return;
  }

  1;
}

#### One scenario run

sub run_hall_scenario {
  my ( $spec, %opt ) = @_;
  my $run = Test::Raider::HallScenario::Run->new( spec => $spec, %opt );
  return $run->execute;
}

{
  package Test::Raider::HallScenario::Run;
  use Carp qw( croak );
  use Path::Tiny;
  use POSIX qw( WNOHANG );
  use Time::HiRes ();

  sub new {
    my ( $class, %arg ) = @_;
    return bless { %arg, vars => {}, events => [], acp_updates => {}, acp_results => {}, pids => {} }, $class;
  }

  sub _ok   { Test::Raider::HallScenario::_ok(@_[ 1 .. $#_ ]) }
  sub _is   { Test::Raider::HallScenario::_is(@_[ 1 .. $#_ ]) }
  sub _like { Test::Raider::HallScenario::_like(@_[ 1 .. $#_ ]) }

  sub execute {
    my ( $self ) = @_;
    my $spec = $self->{spec};
    my $root = $self->{root} = Path::Tiny->tempdir;
    my $port = $self->{port} = Test::Raider::HallScenario::free_port();
    unless ($port) {
      $self->_ok( 0, 'a free local TCP port' );
      return;
    }
    $self->_prepare_root($spec);

    my $child_setup;
    if ( $spec->{fake_telegram} ) {
      my $fake = $self->{telegram} = Test::Raider::HallScenario::FakeTelegram->new;
      unless ($fake) {
        $self->_ok( 0, 'a fake Telegram Bot API' );
        return;
      }
      $child_setup = $self->_telegram_redirect( $fake->port );
    }
    $self->{hall} = Test::Raider::HallScenario::Hall->new(
      root => $root, log => $root->child('hall.stderr')->stringify,
      $child_setup ? ( child_setup => $child_setup ) : (),
    );
    local %ENV = %ENV;
    $self->_prepare_env;

    my $started = $self->_start_hall;
    my $failed;
    if ($started) {
      for my $step ( @{ $spec->{steps} // [] } ) {
        my ( $action, $arg ) = %$step;
        my $method = $self->can( 'step_' . $action );
        unless ($method) {
          $self->_ok( 0, "known step '$action'" );
          $failed = 1;
          last;
        }
        my $ok = eval { $self->$method( $arg // {} ); 1 };
        unless ($ok) {
          my $err = $@; $err =~ s/\s+\z//;
          $self->_ok( 0, "step $action did not die", $err );
          $failed = 1;
          last;
        }
      }
    }
    $self->_diagnose if $failed || !$started || $ENV{HALL_SCENARIO_DEBUG};
    $self->_teardown;
    return;
  }

  # The hall talks to https://api.telegram.org and has no setting for another
  # base URL (see the notes of the scenario 07). In the hall's process only,
  # requests for that host go to the fake Bot API on this port instead.
  sub _telegram_redirect {
    my ( $self, $port ) = @_;
    return sub {
      require Net::Async::HTTP;
      require URI;
      my $rewrite = sub {
        my $uri = URI->new( shift );
        return $uri unless ( $uri->can('host') && ( $uri->host // '' ) eq 'api.telegram.org' );
        $uri->scheme('http');
        $uri->host('127.0.0.1');
        $uri->port($port);
        return $uri;
      };
      my $orig = \&Net::Async::HTTP::do_request;
      no warnings 'redefine';
      *Net::Async::HTTP::do_request = sub {
        my ( $ua, %args ) = @_;
        $args{uri} = $rewrite->( $args{uri} ) if defined $args{uri};
        $args{request}->uri( $rewrite->( $args{request}->uri ) ) if $args{request};
        return $ua->$orig(%args);
      };
    };
  }

  sub _prepare_root {
    my ( $self, $spec ) = @_;
    my $root = $self->{root};
    my $hall_conf = {
      raiders => {
        # The scenarios test the hall, not approvals (ADR 0021).
        Testie => { engine => 'mock', packs => [], mcp => [], isolated => 0, permission_mode => 'bypassPermissions' },
        testie => { engine => 'mock', packs => [], mcp => [], isolated => 0, permission_mode => 'bypassPermissions' },
      },
      acp     => { port => $self->{port}, host => '127.0.0.1' },
      %{ $spec->{hall} // {} },
    };
    $root->child('.raider-hall.yml')->spew_utf8( YAML::PP->new->dump_string($hall_conf) );
    $root->child('rules.yml')->spew_utf8( YAML::PP->new->dump_string( $spec->{model} // { fallback => { answer => 'done' } } ) );
    $root->child('.raider.yml')->spew_utf8(<<"YAML");
engine: mock
rules_file: $root/rules.yml
langfuse_enabled: 0
YAML
    $root->child($_)->touchpath->spew_utf8( $spec->{files}{$_} ) for keys %{ $spec->{files} // {} };
    return;
  }

  # What the hall and its raiders inherit: no keys of a real engine, a home of
  # their own, and the libraries of this process (the dev tree, not an
  # installed older Langertha).
  sub _prepare_env {
    my ( $self ) = @_;
    require Langertha::Engine::Virtual;
    delete @ENV{ grep { /_API_KEY$/ } keys %ENV };
    delete @ENV{qw( HF_TOKEN REPLICATE_API_TOKEN OLLAMA_URL WHISPER_URL RAIDER_HALL_ACP_PORT RAIDER_HALL_ACP_HOST )};
    delete @ENV{ grep { /^RAIDER_HALL_(?:SOCKET|ROOT|SLOT|MODE|TELEGRAM_)/ } keys %ENV };
    my $home = $self->{root}->child('home');
    $home->mkpath;
    $ENV{HOME} = $home->stringify;
    $ENV{RAIDER_HALL_RAIDER_BIN} = path($INC{'Langertha/Raider/Hall.pm'})->absolute->parent(4)->child('bin', 'raider')->stringify;
    my @lib = map { path( $INC{$_} )->absolute->parent( scalar( () = $_ =~ m{/}g ) + 1 )->stringify }
      qw( Langertha/Raider/Hall.pm Langertha/Engine/Virtual.pm );
    my %seen;
    $ENV{PERL5LIB} = join ':', grep { length && !$seen{$_}++ } @lib, split( /:/, $ENV{PERL5LIB} // '' );
    return;
  }

  sub _start_hall {
    my ( $self ) = @_;
    my $up = $self->{hall}->start;
    $self->_ok( $up, 'the hall starts' );
    return unless $up;
    $self->_connect_events;
    $self->_connect_acp;
    return 1;
  }

  sub _connect_events {
    my ( $self ) = @_;
    my $sock = IO::Socket::UNIX->new( Peer => $self->{hall}->socket_path ) or croak "events socket: $!";
    my $conn = Test::Raider::HallScenario::Conn->new($sock);
    $conn->send( $JSON->encode({ type => 'subscribe', payload => { filter => '' } }) . "\n" );
    $self->{events_conn} = $conn;
    return;
  }

  sub _connect_acp {
    my ( $self ) = @_;
    my $sock = IO::Socket::IP->new( PeerHost => '127.0.0.1', PeerPort => $self->{port}, Timeout => 5 );
    unless ($sock) { $self->{acp} = undef; return }
    $self->{acp} = Test::Raider::HallScenario::Conn->new($sock);
    $self->{acp_next} = 1;
    $self->{acp_responses} = {};
    $self->_acp_call( initialize => {}, 10 );
    return;
  }

  sub _pump_events {
    my ( $self, $seconds ) = @_;
    my $conn = $self->{events_conn} or return;
    $conn->pump($seconds);
    while ( defined( my $line = $conn->take_line ) ) {
      my $evt = eval { $JSON->decode($line) } or next;
      push @{ $self->{events} }, $evt;
      $self->{pids}{ $evt->{pid} } = 1 if $evt->{type} eq 'raider.spawned' && $evt->{pid};
    }
    return;
  }

  # Turn the event feed until $cond->() (given the events) holds or time is up.
  sub _wait {
    my ( $self, $cond, $seconds ) = @_;
    my $deadline = Test::Raider::HallScenario::now() + ( $seconds // 30 );
    $self->_pump_events(0);
    until ( my $r = $cond->() ) {
      return if Test::Raider::HallScenario::now() > $deadline;
      $self->_pump_events(0.1);
      $self->_pump_acp(0);
    }
    return $cond->();
  }

  sub _command {
    my ( $self, $cmd, %payload ) = @_;
    my $sock = IO::Socket::UNIX->new( Peer => $self->{hall}->socket_path ) or croak "control socket: $!";
    my $conn = Test::Raider::HallScenario::Conn->new($sock);
    $conn->send( $JSON->encode({ type => 'command', payload => { cmd => $cmd, %payload } }) . "\n" );
    my $deadline = Test::Raider::HallScenario::now() + 15;
    until ( @{ $conn->{lines} } ) {
      croak "no answer to $cmd" if Test::Raider::HallScenario::now() > $deadline || $conn->{eof};
      $conn->pump(0.1);
    }
    my $line = $conn->take_line;
    $conn->close;
    return $JSON->decode($line);
  }

  #### ACP

  sub _acp_send {
    my ( $self, $method, $params ) = @_;
    croak 'no ACP connection' unless $self->{acp};
    my $id = $self->{acp_next}++;
    $self->{acp}->send( $JSON->encode({ jsonrpc => '2.0', id => $id, method => $method, params => $params }) . "\n" );
    return $id;
  }

  sub _pump_acp {
    my ( $self, $seconds ) = @_;
    my $conn = $self->{acp} or return;
    $conn->pump($seconds);
    while ( defined( my $line = $conn->take_line ) ) {
      my $msg = eval { $JSON->decode($line) } or next;
      if ( defined $msg->{id} && !defined $msg->{method} ) { $self->{acp_responses}{ $msg->{id} } = $msg }
      elsif ( ( $msg->{method} // '' ) eq 'session/update' ) {
        my $u = $msg->{params}{update} // {};
        push @{ $self->{acp_streams}{ $msg->{params}{sessionId} // '' } }, $u->{content}{text} // ''
          if ref $u->{content} eq 'HASH';
      }
      elsif ( ( $msg->{method} // '' ) eq 'session/request_permission' ) {
        # The ACP client of the scenario answers from acp_permissions (default: reject).
        push @{ $self->{permission_requests} }, $msg->{params};
        my $how = shift @{ $self->{permission_answers} } // 'reject';
        my %kind = ( once => 'allow_once', always => 'allow_always', reject => 'reject_once', reject_always => 'reject_always' );
        my ($opt) = grep { $_->{kind} eq ( $kind{$how} // '' ) } @{ $msg->{params}{options} };
        my $outcome = $how eq 'ignore'    ? undef
                    : $how eq 'cancelled' ? { outcome => 'cancelled' }
                    : $how eq 'bogus'     ? { outcome => 'selected', optionId => 'no-such-option' }
                    : { outcome => 'selected', optionId => $opt ? $opt->{optionId} : 'none-offered' };
        $self->{acp}->send( $JSON->encode({ jsonrpc => '2.0', id => $msg->{id}, result => { outcome => $outcome } }) . "\n" )
          if $outcome;
      }
    }
    return;
  }

  sub _acp_await {
    my ( $self, $id, $seconds ) = @_;
    my $deadline = Test::Raider::HallScenario::now() + ( $seconds // 30 );
    until ( $self->{acp_responses}{$id} ) {
      return if Test::Raider::HallScenario::now() > $deadline;
      $self->_pump_acp(0.1);
      $self->_pump_events(0);
      return if $self->{acp} && $self->{acp}{eof} && !$self->{acp_responses}{$id};
    }
    return $self->{acp_responses}{$id};
  }

  sub _acp_call {
    my ( $self, $method, $params, $seconds ) = @_;
    my $id = $self->_acp_send( $method, $params );
    return $self->_acp_await( $id, $seconds );
  }

  #### Matching

  # Does $thing (a HashRef) satisfy the conditions of $want: FIELD => value,
  # FIELD_like => regex? Control keys are skipped.
  sub _matches {
    my ( $self, $thing, $want, @skip ) = @_;
    my %skip = map { $_ => 1 } @skip;
    for my $key ( keys %$want ) {
      next if $skip{$key};
      if ( $key =~ /^(.+)_like$/ ) {
        return 0 unless defined $thing->{$1} && $thing->{$1} =~ /$want->{$key}/s;
      }
      else {
        return 0 unless defined $thing->{$key} && $thing->{$key} eq $want->{$key};
      }
    }
    return 1;
  }

  sub _event_cond {
    my ( $self, $want, $from ) = @_;
    my $nth = $want->{nth} // 1;
    return sub {
      my @found = grep { $self->_matches( $_, $want, qw( as timeout nth ) ) }
        @{ $self->{events} }[ ( $from // 0 ) .. $#{ $self->{events} } ];
      return $found[ $nth - 1 ];
    };
  }

  sub _var {
    my ( $self, $name ) = @_;
    return $self->{vars}{$name} // croak "scenario names no '$name' yet";
  }

  sub _done_event {
    my ( $self, $name ) = @_;
    my $id = $self->_var($name)->{id} // croak "'$name' has no run id";
    for my $evt ( @{ $self->{events} } ) {
      return $evt if $evt->{type} eq 'raider.done' && ( $evt->{id} // '' ) eq $id;
    }
    return;
  }

  #### Steps

  sub step_spawn {
    my ( $self, $a ) = @_;
    my $reply = $self->_command( spawn => name => $a->{name}, mission => $a->{mission} );
    $self->{vars}{ $a->{as} } = $reply if $a->{as};
    $self->_ok( !$reply->{error}, "spawn $a->{name}: '$a->{mission}'", $reply->{error} // () );
    $self->_ok( $reply->{queued}, "spawn $a->{name}: queued" ) if $a->{queued};
    $self->_pump_events(0.05);
    return;
  }

  sub step_command {
    my ( $self, $a ) = @_;
    my $reply = $self->_command( $a->{cmd}, %{ $a->{payload} // {} } );
    $self->{vars}{ $a->{as} } = $reply if $a->{as};
    return;
  }

  sub step_kill {
    my ( $self, $a ) = @_;
    my $reply = $self->_command( kill => id => $self->_var( $a->{run} )->{id} );
    $self->_ok( $reply->{killed}, "kill $a->{run}" );
    return;
  }

  sub step_ps {
    my ( $self, $a ) = @_;
    my $reply = $self->_command('ps');
    $self->{ps} = $reply->{raiders} // [];
    $self->{vars}{ $a->{as} } = { ps => $self->{ps} } if $a->{as};
    return;
  }

  sub step_logs {
    my ( $self, $a ) = @_;
    my $reply = $self->_command( logs => id => $self->_var( $a->{run} )->{id} );
    $self->{logs}{ $a->{run} } = $reply;
    return;
  }

  sub step_sleep { select undef, undef, undef, $_[1]; $_[0]->_pump_events(0); $_[0]->_pump_acp(0) }

  sub step_wait_event {
    my ( $self, $a ) = @_;
    my $evt = $self->_wait( $self->_event_cond($a), $a->{timeout} );
    $self->_ok( $evt, 'event ' . join( ' ', map { "$_=$a->{$_}" } grep { !/^(?:as|timeout)$/ } sort keys %$a ) );
    $self->{vars}{ $a->{as} } = $evt if $evt && $a->{as};
    return;
  }

  sub step_idle {
    my ( $self, $a ) = @_;
    my $idle = $self->_wait( sub {
      my $r = eval { $self->_command('ps') } or return;
      return !@{ $r->{raiders} // [] };
    }, $a->{timeout} );
    $self->_ok( $idle, 'the hall has no raider left' );
    $self->_pump_events(0.2);
    return;
  }

  sub step_done {
    my ( $self, $a ) = @_;
    my $run  = $a->{run};
    my $done = $self->_wait( sub { $self->_done_event($run) }, $a->{timeout} );
    $self->_ok( $done, "raider.done of $run" ) or return;
    $self->_is( $done->{status}, $a->{status}, "$run: status" ) if exists $a->{status};
    $self->_like( $done->{response}, $a->{response_like}, "$run: response" ) if exists $a->{response_like};
    $self->_like( $done->{error}, $a->{error_like}, "$run: error" ) if exists $a->{error_like};
    $self->_is( $done->{binding}, $a->{binding}, "$run: binding" ) if exists $a->{binding};
    $self->_is( $done->{exit_code}, $a->{exit_code}, "$run: exit code" ) if exists $a->{exit_code};
    $self->_is( $done->{signaled}, $a->{signaled}, "$run: signaled" ) if exists $a->{signaled};
    if ( my $s = $a->{session} ) {
      if ( my $other = $s->{same_as} ) {
        my $o = $self->_done_event($other);
        $self->_ok( $done->{session} && $o && ( $o->{session} // '' ) eq $done->{session}, "$run: same session as $other" );
      }
      if ( my $other = $s->{different_from} ) {
        my $o = $self->_done_event($other);
        $self->_ok( $done->{session} && $o && $o->{session} && $o->{session} ne $done->{session}, "$run: another session than $other" );
      }
    }
    return;
  }

  sub step_expect_event {
    my ( $self, $a ) = @_;
    $self->_pump_events(0.1);
    my $found = $self->_event_cond($a)->();
    $self->_ok( $found, 'event seen: ' . join( ' ', map { "$_=$a->{$_}" } sort keys %$a ) );
    return;
  }

  sub step_expect_no_event {
    my ( $self, $a ) = @_;
    $self->_pump_events(0.1);
    my $found = $self->_event_cond($a)->();
    $self->_ok( !$found, 'event not seen: ' . join( ' ', map { "$_=$a->{$_}" } sort keys %$a ) );
    return;
  }

  sub step_expect_ps {
    my ( $self, $a ) = @_;
    my $ps = $self->{ps} // croak 'expect_ps needs a ps step before';
    $self->_is( scalar @$ps, $a->{count}, 'ps: number of raiders' ) if exists $a->{count};
    for my $m ( @{ $a->{missions} // [] } ) {
      $self->_ok( ( grep { ( $_->{mission} // '' ) eq $m } @$ps ), "ps lists the mission '$m'" );
    }
    return;
  }

  sub step_expect_log {
    my ( $self, $a ) = @_;
    my $reply = $self->{logs}{ $a->{run} } // croak 'expect_log needs a logs step before';
    $self->_like( $reply->{log}, $a->{like}, "log of $a->{run}" );
    return;
  }

  sub step_wait_file {
    my ( $self, $a ) = @_;
    my $file = $self->{root}->child( $a->{path} );
    my $there = $self->_wait( sub { -e $file }, $a->{timeout} );
    $self->_ok( $there, "$a->{path} appears" );
    return;
  }

  # The files a run leaves: its events file (the --stream-json output) with the
  # text it must carry, and its part of the slot log.
  sub step_expect_run_files {
    my ( $self, $a ) = @_;
    my $id = $self->_var( $a->{run} )->{id};
    my $dir = $self->{root}->child( '.raider-hall', 'logs' );
    my $events = $dir->child( $id . '.events.jsonl' );
    $self->_ok( -s $events, "$a->{run}: events file is there and not empty" ) or return;
    $self->_like( $events->slurp_utf8, $a->{events_like}, "$a->{run}: events" ) if exists $a->{events_like};
    $self->_like( $events->slurp_utf8, qr/"type":"run\.finished"/, "$a->{run}: events end with run.finished" );
    my ($slot) = $id =~ /\A(.+)-\d+(?:\.\d+)?\z/;
    my $log = $dir->child( $slot . '.log' );
    $self->_like( -f $log ? $log->slurp_utf8 : '', qr/\[hall\] raider \Q$id\E started/, "$a->{run}: slot log has its start line" );
    return;
  }

  # Nothing started by the run is left: no process works in the root.
  sub step_expect_quiet {
    my ( $self ) = @_;
    my @in = $self->_in_root;
    $self->_ok( !@in, 'no process of the run is left in the root', @in ? ( 'still there: ' . join( ' ', map { $_ . ' ' . ( eval { path( '/proc', $_, 'cmdline' )->slurp_raw } =~ tr/\0/ /r ) } @in ) ) : () );
    return;
  }

  sub step_telegram_say {
    my ( $self, $a ) = @_;
    my $fake = $self->{telegram} or croak 'the scenario has no fake_telegram';
    $fake->say( chat_id => $a->{chat_id}, from_id => $a->{from_id} // $a->{chat_id}, text => $a->{text} );
    return;
  }

  sub step_expect_telegram_sent {
    my ( $self, $a ) = @_;
    my $fake = $self->{telegram} or croak 'the scenario has no fake_telegram';
    my $sent = $self->_wait( sub {
      my @all = $fake->sent;
      @all = grep { $_->{chat_id} eq $a->{chat_id} } @all if exists $a->{chat_id};
      return ( !exists $a->{count} || @all >= $a->{count} ) && ( @all || exists $a->{count} ) ? \@all : undef;
    }, $a->{timeout} // 10 );
    $self->_ok( $sent, 'the bot sent a message' . ( exists $a->{chat_id} ? " to chat $a->{chat_id}" : '' ) ) or return;
    $self->_is( scalar @$sent, $a->{count}, 'number of messages sent' ) if exists $a->{count};
    $self->_ok( ( grep { ( $_->{text} // '' ) =~ /$a->{text_like}/s } @$sent ), "a message matches /$a->{text_like}/",
      'sent: ' . join( ' | ', map { $_->{text} // '' } @$sent ) ) if exists $a->{text_like};
    return;
  }

  sub step_expect_file {
    my ( $self, $a ) = @_;
    my $file = $self->{root}->child( $a->{path} );
    return $self->_ok( !$file->exists, "$a->{path} is absent" ) if exists $a->{absent} && $a->{absent};
    $self->_ok( $file->is_file, "$a->{path} exists" ) or return;
    $self->_is( $file->slurp_utf8, $a->{content}, "$a->{path} content" ) if exists $a->{content};
    $self->_like( $file->slurp_utf8, $a->{like}, "$a->{path} content" ) if exists $a->{like};
    return;
  }

  # The user prompts of every session journal in the root, oldest journal first.
  sub journals {
    my ( $self ) = @_;
    my @files = sort { $a->stat->mtime <=> $b->stat->mtime || $a cmp $b }
      grep { $_->basename =~ /\.jsonl\z/ } $self->{root}->child('.raider', 'sessions')->children;
    my @journals;
    for my $file (@files) {
      my @prompts;
      for my $line ( $file->lines_utf8 ) {
        my $evt = eval { $JSON->decode($line) } or next;
        next unless ( $evt->{type} // '' ) eq 'message' && ( $evt->{role} // '' ) eq 'user';
        push @prompts, $evt->{content};
      }
      push @journals, { file => $file->basename, prompts => \@prompts };
    }
    return @journals;
  }

  sub step_expect_journals {
    my ( $self, $a ) = @_;
    my @j = $self->journals;
    $self->_is( scalar @j, $a->{count}, 'number of session journals' ) if exists $a->{count};
    if ( my $want = $a->{prompts} ) {
      # Order of journals is not the contract; compare as a set of prompt lists.
      my @got  = sort map { join "\n", @{ $_->{prompts} } } @j;
      my @need = sort map { join "\n", @$_ } @$want;
      $self->_ok( "@got" eq "@need", 'the prompts of the journals',
        'got:      ' . join( ' | ', map { s/\n/ + /gr } @got ), 'expected: ' . join( ' | ', map { s/\n/ + /gr } @need ) );
    }
    return;
  }

  sub step_acp_session {
    my ( $self, $a ) = @_;
    my $resp = $self->_acp_call( 'session/new', { cwd => "$self->{root}", $a->{raider} ? ( raiderName => $a->{raider} ) : () } );
    my $sid = $resp && $resp->{result} && $resp->{result}{sessionId};
    $self->_ok( $sid, 'ACP session opened' );
    $self->{vars}{ $a->{as} } = { sid => $sid };
    return;
  }

  sub step_acp_prompt {
    my ( $self, $a ) = @_;
    my $sid = $self->_var( $a->{session} )->{sid};
    my $id = $self->_acp_send( 'session/prompt', { sessionId => $sid, prompt => [ { type => 'text', text => $a->{text} } ] } );
    $self->{prompts}{ $a->{as} // $id } = { id => $id, sid => $sid, from => scalar @{ $self->{acp_streams}{$sid} // [] } };
    $self->step_acp_wait({ prompt => $a->{as} // $id }) unless defined $a->{wait} && !$a->{wait};
    return;
  }

  sub step_acp_wait {
    my ( $self, $a ) = @_;
    my $p = $self->{prompts}{ $a->{prompt} } // croak "no prompt '$a->{prompt}'";
    my $resp = $self->_acp_await( $p->{id}, $a->{timeout} );
    $self->_ok( $resp, "ACP prompt $a->{prompt} answered" );
    $p->{response} = $resp;
    return;
  }

  sub step_expect_acp {
    my ( $self, $a ) = @_;
    my $p = $self->{prompts}{ $a->{prompt} } // croak "no prompt '$a->{prompt}'";
    my $resp = $p->{response} // $self->{acp_responses}{ $p->{id} };
    $self->_ok( $resp, "ACP prompt $a->{prompt} has an answer" ) or return;
    my $stream = join '', @{ $self->{acp_streams}{ $p->{sid} } // [] }[ $p->{from} .. $#{ $self->{acp_streams}{ $p->{sid} } // [] } ];
    $self->_is( $resp->{result} && $resp->{result}{stopReason}, $a->{stop_reason}, "ACP $a->{prompt}: stop reason" ) if exists $a->{stop_reason};
    $self->_like( $stream, $a->{text_like}, "ACP $a->{prompt}: streamed text" ) if exists $a->{text_like};
    $self->_like( $resp->{error} && $resp->{error}{message}, $a->{error_like}, "ACP $a->{prompt}: error" ) if exists $a->{error_like};
    return;
  }

  # The answers the scenario's ACP client gives to session/request_permission,
  # one per question in order: once | always | reject | reject_always |
  # cancelled | bogus (an option that was not offered) | ignore (no response).
  # When the list runs out the client rejects.
  sub step_acp_permissions {
    my ( $self, $a ) = @_;
    $self->{permission_answers} = [ @{ $a->{answers} // [] } ];
    return;
  }

  # Waits until the hall has asked `count` (default 1) questions.
  sub step_wait_permission_request {
    my ( $self, $a ) = @_;
    my $deadline = Test::Raider::HallScenario::now() + ( $a->{timeout} // 30 );
    while ( @{ $self->{permission_requests} // [] } < ( $a->{count} // 1 ) && Test::Raider::HallScenario::now() < $deadline ) {
      $self->_pump_acp(0.1);
      $self->_pump_events(0);
    }
    $self->_ok( @{ $self->{permission_requests} // [] } >= ( $a->{count} // 1 ), 'the hall asked the client' );
    return;
  }

  sub step_expect_permission_requests {
    my ( $self, $a ) = @_;
    my @got = @{ $self->{permission_requests} // [] };
    $self->_is( scalar @got, $a->{count}, 'number of session/request_permission requests' ) if exists $a->{count};
    if ( my $first = $a->{first} ) {
      my $req = $got[0] or return $self->_ok( 0, 'a session/request_permission request was made' );
      $self->_like( $req->{toolCall}{title}, $first->{title_like}, 'permission request: title' ) if exists $first->{title_like};
      $self->_is( $req->{toolCall}{kind}, $first->{kind}, 'permission request: kind' ) if exists $first->{kind};
      $self->_is( $req->{toolCall}{status}, 'pending', 'permission request: status' );
      $self->_is( join( ',', map { $_->{kind} } @{ $req->{options} } ), $first->{options}, 'permission request: option kinds' )
        if exists $first->{options};
      $self->_like( join( ' | ', map { $_->{name} } @{ $req->{options} } ), $first->{names_like}, 'permission request: option names' )
        if exists $first->{names_like};
    }
    return;
  }

  sub step_acp_cancel {
    my ( $self, $a ) = @_;
    my $resp = $self->_acp_call( 'session/cancel', { sessionId => $self->_var( $a->{session} )->{sid} } );
    $self->_ok( $resp && !$resp->{error}, 'ACP cancel accepted' );
    return;
  }

  sub step_acp_reconnect {
    my ( $self ) = @_;
    $self->{acp}->close if $self->{acp};
    $self->_connect_acp;
    return;
  }

  #### Hall lifecycle

  sub step_stop_hall {
    my ( $self ) = @_;
    $self->_pump_events(0.2);
    $self->{acp}->close if $self->{acp};
    $self->{acp} = undef;
    $self->{events_conn}->close if $self->{events_conn};
    $self->_ok( $self->{hall}->stop, 'the hall stops on TERM' );
    return;
  }

  sub step_start_hall {
    my ( $self ) = @_;
    $self->_start_hall;
    return;
  }

  sub step_restart_hall {
    my ( $self ) = @_;
    $self->step_stop_hall;
    $self->step_start_hall;
    return;
  }

  #### End

  sub _diagnose {
    my ( $self ) = @_;
    my $log = $self->{root}->child('hall.stderr');
    my $dir = $self->{root}->child('.raider-hall', 'logs');
    my @diag;
    push @diag, 'hall stderr: ' . $log->slurp_utf8 if -s $log;
    if ( -d $dir ) {
      for my $f ( sort grep { $_->basename =~ /\.log\z/ } $dir->children ) {
        push @diag, $f->basename . ': ' . $f->slurp_utf8;
      }
    }
    push @diag, 'events: ' . ( $ENV{HALL_SCENARIO_DEBUG} ? join( "\n", map { $JSON->encode($_) } @{ $self->{events} } ) : join( ' ', map { $_->{type} } @{ $self->{events} } ) );
    return unless @diag;
    require Test2::API;
    my $ctx = Test2::API::context();
    $ctx->diag( join "\n", @diag );
    $ctx->release;
    return;
  }

  # Processes that work in the scenario's root: what a raider's tools started
  # (bash runs there) and the raiders themselves.
  sub _in_root {
    my ( $self ) = @_;
    my $root = $self->{root}->realpath->stringify;
    my @in;
    for my $dir ( path('/proc')->children(qr/\A\d+\z/) ) {
      my $cwd = readlink $dir->child('cwd')->stringify // next;
      push @in, $dir->basename if $cwd eq $root || index( $cwd, "$root/" ) == 0;
    }
    return @in;
  }

  sub _teardown {
    my ( $self ) = @_;
    $self->{acp}->close if $self->{acp};
    $self->{events_conn}->close if $self->{events_conn};
    my $hall = $self->{hall};
    my $stopped = $hall->stop;
    $self->{telegram}->stop if $self->{telegram};
    # What the hall started is gone with it: a raider is not ours to wait for
    # (it is a child of the hall), so look at the process table.
    # The deadline only bounds a failing run; on a loaded machine a raider
    # takes seconds to end (04c leaves its tool behind for a moment on purpose).
    my @left;
    my $deadline = Test::Raider::HallScenario::now() + 30;
    while (1) {
      @left = ( ( grep { kill 0, $_ } keys %{ $self->{pids} } ), $self->_in_root );
      last if !@left || Test::Raider::HallScenario::now() > $deadline;
      select undef, undef, undef, 0.1;
    }
    if (@left) {
      kill 'KILL', @left;
      select undef, undef, undef, 0.3;
    }
    $self->_ok( $stopped && !@left, 'nothing of the hall is left running', @left ? ( 'still running: ' . join( ' ', @left ) ) : () );
    return;
  }
}

1;
