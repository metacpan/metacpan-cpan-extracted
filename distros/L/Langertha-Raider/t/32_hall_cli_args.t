use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Temp qw( tempdir );
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::Hall::CLI;

# Regression: GetOptions consumed @ARGV but the subcommands kept working on
# the untouched argument list, so options placed before positional arguments
# leaked into them (k14). Options must work before AND after positionals.

my $orig_cwd = path('.')->absolute;

# Run a hall subcommand inside a fresh hall dir with a fake socket and a
# captured _send_command. Returns the payload sent to the hall.
sub run_cmd {
  my ( @argv ) = @_;
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.socket')->touch;
  chdir $tmp or die "chdir $tmp: $!";

  my $sent;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::CLI::_send_command = sub {
    my ( $socket, $msg ) = @_;
    $sent = $msg->{payload};
    return { id => 'r1', pid => 1, slot => 's1', log_path => 'x', events_path => 'x', log => '' };
  };
  local *Langertha::Raider::Hall::CLI::_follow_file = sub { 0 };
  my ( $out, $err ) = ( '', '' );
  {
    local *STDOUT;
    local *STDERR;
    open STDOUT, '>', \$out or die $!;
    open STDERR, '>', \$err or die $!;
    Langertha::Raider::Hall::CLI->main(@argv);
  }
  chdir $orig_cwd or die "chdir $orig_cwd: $!";
  return $sent;
}

subtest 'start: DIR is honoured with options before it' => sub {
  my $hall_dir = tempdir( CLEANUP => 1 );
  for my $argv (
    [ 'start', '--daemon', $hall_dir ],
    [ 'start', $hall_dir, '--daemon' ],
    [ 'start', '--acp-port', '4711', $hall_dir ],
  ) {
    my $root;
    no warnings 'redefine';
    local *Langertha::Raider::Hall::new = sub {
      my ( $class, %arg ) = @_;
      $root = "$arg{root}";
      die "stop before run\n";
    };
    local $ENV{RAIDER_HALL_ACP_PORT};
    local $ENV{RAIDER_HALL_ACP_HOST};
    like(
      dies { Langertha::Raider::Hall::CLI->main(@$argv) },
      qr/stop before run/, 'reached Hall->new: '.join(' ', @$argv)
    );
    is( $root, path($hall_dir)->absolute->stringify,
      'root is DIR: '.join(' ', @$argv) );
  }
};

subtest 'spawn: --attach does not leak into the mission' => sub {
  for my $argv (
    [ 'spawn', 'Bjorn', 'raid', 'the', 'coast', '--attach' ],
    [ 'spawn', '--attach', 'Bjorn', 'raid', 'the', 'coast' ],
  ) {
    my $p = run_cmd(@$argv);
    is( $p, {
      cmd     => 'spawn',
      name    => 'Bjorn',
      mission => 'raid the coast',
    }, join(' ', @$argv).' (attaching is the CLI\'s part, not the hall\'s)' );
  }
};

subtest 'attach: ID is the positional, not an option' => sub {
  for my $argv (
    [ 'attach', 'r42' ],
    [ 'attach', '--', 'r42' ],
  ) {
    my $p = run_cmd(@$argv);
    is( $p, { cmd => 'attach', id => 'r42' }, join(' ', @$argv) );
  }
};

subtest 'logs: ID without --follow' => sub {
  my $p = run_cmd( 'logs', 'r42' );
  is( $p, { cmd => 'logs', id => 'r42' }, 'logs r42' );
};

# logs --follow streams the raider's log file until the hall no longer
# knows the raider (k28). The hall is faked: attach reports the log path
# while the raider "runs", every wait appends a line, then it is gone.
sub run_follow {
  my ( @argv ) = @_;
  my $tmp = path( tempdir( CLEANUP => 1 ) );
  $tmp->child('.raider-hall.socket')->touch;
  my $log = $tmp->child('s1.log');
  $log->spew_raw("line1\n");
  chdir "$tmp" or die "chdir $tmp: $!";

  my ( @sent, $waits );
  no warnings 'redefine';
  local *Langertha::Raider::Hall::CLI::_send_command = sub {
    my ( $socket, $msg ) = @_;
    push @sent, $msg->{payload};
    return { error => 'raider not found' } if $waits && $waits >= 2;
    return { id => 'r42', pid => 1, slot => 's1', log_path => "$log" };
  };
  local *Langertha::Raider::Hall::CLI::_follow_wait = sub {
    $waits++;
    $log->append_raw('line'.( $waits + 1 )."\n");
  };
  my $out = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    Langertha::Raider::Hall::CLI->main(@argv);
  }
  chdir $orig_cwd or die "chdir $orig_cwd: $!";
  return ( $out, \@sent );
}

subtest 'logs --follow streams until the raider is gone' => sub {
  for my $argv (
    [ 'logs', '--follow', 'r42' ],
    [ 'logs', 'r42', '--follow' ],
  ) {
    my ( $out, $sent ) = run_follow(@$argv);
    is( $out, "line1\nline2\nline3\n",
      'whole log, appended lines included: '.join(' ', @$argv) );
    is( [ map { $_->{id} } @$sent ], [ ('r42') x scalar @$sent ],
      'every request asks for r42' );
    is( $sent->[-1]{cmd}, 'attach', 'liveness polled via attach' );
  }
};

subtest 'logs --follow on a finished raider prints its logs' => sub {
  my $tmp = path( tempdir( CLEANUP => 1 ) );
  $tmp->child('.raider-hall.socket')->touch;
  chdir "$tmp" or die "chdir $tmp: $!";
  my @sent;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::CLI::_send_command = sub {
    my ( $socket, $msg ) = @_;
    push @sent, $msg->{payload};
    return $msg->{payload}{cmd} eq 'logs'
      ? { log => "done log\n" } : { error => 'raider not found' };
  };
  local *Langertha::Raider::Hall::CLI::_follow_wait = sub { die "must not wait\n" };
  my $out = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    Langertha::Raider::Hall::CLI->main( 'logs', '--follow', 'r42' );
  }
  chdir $orig_cwd or die "chdir $orig_cwd: $!";
  is( $out, "done log\n", 'the logs of the ended run' );
  is( [ map { $_->{cmd} } @sent ], [ 'attach', 'logs' ], 'attach, then logs' );
};

# attach and spawn --attach print the run's events file until the hall no
# longer knows the raider (k102). The hall is faked: spawn answers with the
# run, attach reports the events path while the raider "runs", every wait
# appends an event, and after $alive attach polls it is gone.
sub run_attach_stream {
  my ( %arg ) = @_;
  my $tmp = path( tempdir( CLEANUP => 1 ) );
  $tmp->child('.raider-hall.socket')->touch;
  my $events = $tmp->child('r42.events.jsonl');
  $events->spew_raw(qq({"seq":1,"type":"run.started"}\n));
  chdir "$tmp" or die "chdir $tmp: $!";

  my ( @sent, $waits );
  my $polls = 0;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::CLI::_send_command = sub {
    my ( $socket, $msg ) = @_;
    my $p = $msg->{payload};
    push @sent, $p;
    return $arg{spawn} // { id => 'r42', pid => 1, slot => 's1', events_path => "$events" }
      if $p->{cmd} eq 'spawn';
    return { error => 'raider not found' } if $polls++ >= $arg{alive};
    return { id => 'r42', pid => 1, slot => 's1', log_path => 'x', events_path => "$events" };
  };
  local *Langertha::Raider::Hall::CLI::_follow_wait = sub {
    $waits++;
    $events->append_raw(qq({"seq":).( $waits + 1 ).qq(,"type":"message"}\n));
  };
  my ( $out, $err ) = ( '', '' );
  my $died;
  {
    local *STDOUT;
    local *STDERR;
    open STDOUT, '>', \$out or die $!;
    open STDERR, '>', \$err or die $!;
    $died = dies { Langertha::Raider::Hall::CLI->main( @{ $arg{argv} } ) };
  }
  chdir $orig_cwd or die "chdir $orig_cwd: $!";
  return { out => $out, err => $err, died => $died, sent => \@sent, waits => $waits // 0 };
}

my $three_events = qq({"seq":1,"type":"run.started"}\n{"seq":2,"type":"message"}\n{"seq":3,"type":"message"}\n);

subtest 'attach streams the events file until the raider is gone' => sub {
  my $r = run_attach_stream( argv => [ 'attach', 'r42' ], alive => 3 );
  is( $r->{died}, undef, 'lives' );
  is( $r->{out}, $three_events, 'every event, appended ones included, and nothing else' );
  is( [ map { $_->{cmd} } @{ $r->{sent} } ], [ ('attach') x 4 ], 'liveness polled via attach' );
};

subtest 'attach on a run the hall no longer knows dies' => sub {
  my $r = run_attach_stream( argv => [ 'attach', 'r42' ], alive => 0 );
  like( $r->{died}, qr/^Hall: raider not found/, 'dies with the hall error' );
  is( $r->{out}, '', 'prints nothing' );
};

subtest 'spawn --attach: the run ID on stderr, the event stream on stdout' => sub {
  my $r = run_attach_stream( argv => [ 'spawn', '--attach', 'Bjorn', 'raid' ], alive => 2 );
  is( $r->{died}, undef, 'lives' );
  is( $r->{out}, $three_events, 'stdout is the event stream alone' );
  like( $r->{err}, qr/^Spawned raider r42 \(PID 1\) in slot s1\.$/m, 'run ID on stderr' );
  is( [ map { $_->{cmd} } @{ $r->{sent} } ], [ 'spawn', ('attach') x 3 ], 'spawn, then follow' );
};

subtest 'spawn --attach: a run that ended before the first poll is printed whole' => sub {
  my $r = run_attach_stream( argv => [ 'spawn', '--attach', 'Bjorn', 'raid' ], alive => 0 );
  is( $r->{died}, undef, 'lives' );
  is( $r->{out}, qq({"seq":1,"type":"run.started"}\n), 'what the run wrote' );
  is( $r->{waits}, 0, 'no waiting' );
};

subtest 'spawn --attach on a queued mission does not attach' => sub {
  my $r = run_attach_stream( argv => [ 'spawn', '--attach', '1bjorn', 'raid' ], alive => 5,
    spawn => { queued => 1, slot => '1bjorn', queue_depth => 2 } );
  is( $r->{died}, undef, 'lives' );
  is( $r->{out}, "Mission queued for slot 1bjorn (queue depth: 2).\n", 'queued line' );
  like( $r->{err}, qr/^Not attached: the mission has no run yet\.$/m, 'says why on stderr' );
  is( [ map { $_->{cmd} } @{ $r->{sent} } ], ['spawn'], 'no attach' );
};

subtest 'kill: ID after --' => sub {
  my $p = run_cmd( 'kill', '--', 'r42' );
  is( $p, { cmd => 'kill', id => 'r42' }, 'kill -- r42' );
};

# DIR is only ever the first positional and must be removed from the list
# before NAME/ID/MISSION are read (k27). Where a NAME or ID follows, only a
# directory that looks like a hall (.raider-hall.yml or .raider-hall.socket)
# counts as DIR, and never the last remaining positional.

# Run a subcommand from a plain cwd (no hall) with a hall at $hall_dir.
# Returns the payload sent and the socket it was sent to.
sub run_in {
  my ( $cwd, @argv ) = @_;
  chdir $cwd or die "chdir $cwd: $!";
  my ( $sent, $socket );
  no warnings 'redefine';
  local *Langertha::Raider::Hall::CLI::_send_command = sub {
    my ( $s, $msg ) = @_;
    ( $socket, $sent ) = ( "$s", $msg->{payload} );
    return { id => 'r1', pid => 1, slot => 's1', log_path => 'x', events_path => 'x', log => '',
      killed => 1, raiders => [] };
  };
  local *Langertha::Raider::Hall::CLI::_follow_file = sub { 0 };
  my $out = '';
  my $err;
  {
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    $err = dies { Langertha::Raider::Hall::CLI->main(@argv) };
  }
  chdir $orig_cwd or die "chdir $orig_cwd: $!";
  return ( $sent, $socket, $err, $out );
}

sub new_hall {
  my $dir = path( tempdir( CLEANUP => 1 ) )->realpath;
  $dir->child('.raider-hall.socket')->touch;
  return $dir;
}

subtest 'DIR is consumed before the positionals that follow it' => sub {
  my $hall = new_hall();
  my $cwd  = tempdir( CLEANUP => 1 );
  my $sock = $hall->child('.raider-hall.socket')->stringify;

  my ( $p, $s, $err ) = run_in( $cwd, 'spawn', "$hall", 'Bjorn', 'raid', 'the', 'coast' );
  is( $err, undef, 'spawn DIR NAME MISSION lives' );
  is( $p, { cmd => 'spawn', name => 'Bjorn', mission => 'raid the coast' },
    'spawn: NAME and MISSION follow DIR' );
  is( $s, $sock, 'spawn: socket of DIR' );

  for my $cmd (qw( attach logs kill )) {
    ( $p, $s, $err ) = run_in( $cwd, $cmd, "$hall", 'r42' );
    is( $err, undef, "$cmd DIR ID lives" );
    is( $p, { cmd => $cmd, id => 'r42' }, "$cmd: ID follows DIR" );
    is( $s, $sock, "$cmd: socket of DIR" );
  }

  for my $cmd (qw( status ps )) {
    ( $p, $s, $err ) = run_in( $cwd, $cmd, "$hall" );
    is( $err, undef, "$cmd DIR lives" );
    is( $s, $sock, "$cmd: socket of DIR" );
  }

  $hall->child('.raider-hall.pid')->spew('not-a-pid');
  ( undef, undef, $err ) = run_in( $cwd, 'stop', "$hall" );
  like( $err, qr/Invalid PID file/, 'stop: reads the pidfile of DIR' );

  my $out;
  ( undef, undef, $err, $out ) = run_in( $cwd, 'install', "$hall", '--stdout' );
  is( $err, undef, 'install DIR --stdout lives' );
  like( $out, qr/^WorkingDirectory=\Q$hall\E$/m, 'install: unit runs in DIR' );
};

subtest 'DIR that is not a directory is an error, not cwd' => sub {
  my $hall    = new_hall();
  my $missing = $hall->child('no-such-hall')->stringify;
  my $file    = $hall->child('a-file');
  $file->touch;
  $hall->child('.raider-hall.pid')->spew('not-a-pid');
  no warnings 'redefine';
  local *Langertha::Raider::Hall::new = sub { die "Hall->new reached\n" };

  for my $bad ( $missing, "$file" ) {
    for my $argv (
      [ 'start', $bad ], [ 'start', '--daemon', $bad ],
      [ 'stop', $bad ], [ 'status', $bad ], [ 'ps', $bad ],
      [ 'install', $bad, '--stdout' ],
    ) {
      my ( $p, $s, $err, $out ) = run_in( "$hall", @$argv );
      like( $err, qr/^Not a directory: \Q$bad\E$/, 'dies: '.join(' ', @$argv) );
      is( $s, undef, 'nothing sent to the cwd hall: '.join(' ', @$argv) );
      is( $out, '', 'no output: '.join(' ', @$argv) );
    }
  }
};

subtest 'a NAME or ID that happens to be a directory is not DIR' => sub {
  my $hall = new_hall();
  $hall->child('Bjorn')->mkpath;          # plain directory, not a hall
  my $inner = $hall->child('r42');        # even a hall-looking one ...
  $inner->mkpath;
  $inner->child('.raider-hall.yml')->touch;
  my $sock = $hall->child('.raider-hall.socket')->stringify;

  my ( $p, $s ) = run_in( "$hall", 'spawn', 'Bjorn', 'raid' );
  is( $p, { cmd => 'spawn', name => 'Bjorn', mission => 'raid' },
    'spawn: plain directory NAME stays the NAME' );
  is( $s, $sock, 'spawn: socket of cwd' );

  for my $cmd (qw( attach logs kill )) {
    ( $p, $s ) = run_in( "$hall", $cmd, 'r42' );
    is( $p, { cmd => $cmd, id => 'r42' }, "$cmd: ... is still the ID when it is the only positional" );
    is( $s, $sock, "$cmd: socket of cwd" );
  }
};

done_testing;
