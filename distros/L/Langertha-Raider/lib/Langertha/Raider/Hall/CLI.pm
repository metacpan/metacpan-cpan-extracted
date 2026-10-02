package Langertha::Raider::Hall::CLI;
our $VERSION = '0.503';
# ABSTRACT: Internal dispatcher of the raider hall subcommands


use strict;
use warnings;
use Path::Tiny;
use Getopt::Long qw( GetOptions );
use JSON::MaybeXS ();
use IO::Async::Loop;
use IO::Async::Stream;
use IO::Socket::UNIX;
use POSIX qw(WNOHANG);
use Socket qw(SOCK_STREAM);
use YAML::PP;
use Langertha::Raider::EngineResolver;
use Langertha::Raider::Hall;

sub main {
  my ($class, @args) = @_;

  if (!@args || $args[0] eq '--help' || $args[0] eq '-h') {
    print usage();
    exit 0;
  }

  my $cmd = shift @args;

  if ($cmd eq 'init')       { return run_init(@args); }
  if ($cmd eq 'add-raider') { return run_add_raider(@args); }
  if ($cmd eq 'start')      { return run_start(@args); }
  if ($cmd eq 'stop')       { return run_stop(@args); }
  if ($cmd eq 'status')     { return run_status(@args); }
  if ($cmd eq 'ps')         { return run_ps(@args); }
  if ($cmd eq 'spawn')      { return run_spawn(@args); }
  if ($cmd eq 'attach')     { return run_attach(@args); }
  if ($cmd eq 'logs')       { return run_logs(@args); }
  if ($cmd eq 'kill')       { return run_kill(@args); }
  if ($cmd eq 'session')    { return run_session(@args); }
  if ($cmd eq 'install')   { return run_install(@args); }
  if ($cmd eq 'help')       { print usage(); exit 0; }

  die "Unknown subcommand: $cmd\n\n" . usage();
}

sub cwd {
  path('.')->absolute->stringify;
}

# DIR is only ever the first positional and is removed from @$args when
# taken. Where it is the sole positional (start, stop, status, ps, install)
# any existing directory counts, and anything else is an error. Where $need more positionals (NAME, ID)
# must follow, it counts only if they remain and it looks like a hall, so a
# NAME or ID that happens to be a directory is not swallowed.
sub hall_dir {
  my ( $args, $need ) = @_;
  $need //= 0;
  my $d = $args->[0];
  return cwd unless defined $d && $d !~ /^-/;
  die "Not a directory: $d\n" if !$need && !-d $d;
  return cwd unless -d $d;
  return cwd if $need && ( @$args <= $need || !is_hall_dir($d) );
  shift @$args;
  return path($d)->absolute->stringify;
}

sub is_hall_dir {
  my ( $d ) = @_;
  return -e path($d)->child('.raider-hall.yml')
    || -e path($d)->child('.raider-hall.socket');
}

sub usage {
  return <<"EOF";
Usage: raider hall <subcommand> [options]

Subcommands:
  init               Bootstrap a new hall in the current directory
  add-raider NAME    Append a raider entry to .raider-hall.yml
  start [DIR]        Start the hall daemon (default: cwd)
  stop [DIR]         Stop the hall daemon
  status [DIR]       Show hall status
  ps [DIR]           List running raiders
  spawn [DIR] NAME MISSION  Spawn a raider
  attach [DIR] ID    Follow a running raider's event stream
  logs [DIR] ID      Fetch raider logs
  kill [DIR] ID      Terminate a raider
  session reset [DIR] BINDING  Start a new session for a binding
  install [DIR]      Install systemd user unit
  help               Show this help

Run 'raider hall <subcommand> --help' for per-command options.
EOF
}

sub run_init {
  my @args = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt, 'name=s', 'engine=s', 'persona=s', 'help');
  return print_init_help() if $opt{help};

  my $name = $opt{name};
  if (!$name) {
    print "Raider name (e.g. Bjorn, Ragnar, Astrid, Ivar, Lagertha): ";
    $name = <STDIN>;
    chomp $name;
    exit 1 unless length $name;
  }

  my $persona = $opt{persona} // 'caveman';
  my $dir = cwd;

  # No --engine: no engine key, the spawned raider decides itself.
  my %yml;
  $yml{longhouse} = 0;
  $yml{raiders}{$name} = {
    ($opt{engine} ? (engine => $opt{engine}) : ()),
    persona => $persona,
    packs => [],
  };

  my $cfg_file = path($dir)->child('.raider-hall.yml');
  if (-f $cfg_file) {
    die "Refusing to overwrite existing $cfg_file\n";
  }
  $cfg_file->spew_utf8(YAML::PP->new->dump(\%yml));

  print "Hall initialised in $dir with raider '$name'.\n";
  print "Start with: raider hall start\n";
  return 0;
}

sub run_add_raider {
  my @args = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt,
    'engine=s', 'persona=s', 'model=s', 'pack=s@', 'help');
  return print_add_raider_help() if $opt{help};

  my $name = shift @ARGV;
  die "Usage: raider hall add-raider NAME [--engine E] [--persona P] [--model M] [--pack X]...\n"
    unless $name;

  my $dir = cwd;
  my $cfg_file = path($dir)->child('.raider-hall.yml');
  die "No .raider-hall.yml found (run: raider hall init)\n" unless -f $cfg_file;

  my $yml = YAML::PP->new->load_string($cfg_file->slurp_utf8) // {};
  $yml->{raiders} //= {};
  if ($yml->{raiders}{$name}) {
    die "Raider '$name' already defined in $cfg_file\n";
  }

  $yml->{raiders}{$name} = {
    ($opt{engine} ? (engine => $opt{engine}) : ()),
    persona  => $opt{persona} // 'caveman',
    ($opt{model} ? (model => $opt{model}) : ()),
    packs    => $opt{pack} // [],
  };

  $cfg_file->spew_utf8(YAML::PP->new->dump_string($yml));
  print "Added raider '$name' to $cfg_file.\n";
  return 0;
}

sub print_add_raider_help {
  print <<"EOF";
raider hall add-raider NAME [options]

Append a raider entry to .raider-hall.yml.

Options:
  --engine NAME      Engine (default: none, the raider decides)
  --persona NAME     A pack used as the raider's persona (default: caveman)
  --model NAME       Model override
  --pack NAME        Additional pack (repeatable)
EOF
  exit 0;
}

sub print_init_help {
  print <<"EOF";
raider hall init [--name NAME] [--engine ENGINE] [--persona PERSONA]

Bootstrap a new hall directory with a starter .raider-hall.yml.
Prompts interactively if --name not provided.

Options:
  --name NAME        Name of the first raider
  --engine NAME      Engine (default: none, the raider decides)
  --persona NAME     A pack used as the raider's persona (default: caveman)
EOF
  exit 0;
}

sub run_start {
  my @args = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt, 'daemon', 'acp-port=i', 'acp-host=s', 'help');
  return print_start_help() if $opt{help};
  @args = @ARGV;

  my $dir = hall_dir(\@args);
  $dir = path($dir);

  # --acp-port wins over yml; persist nothing, pass through env.
  if (defined $opt{'acp-port'}) {
    $ENV{RAIDER_HALL_ACP_PORT} = $opt{'acp-port'};
    $ENV{RAIDER_HALL_ACP_HOST} = $opt{'acp-host'} if defined $opt{'acp-host'};
  }

  my $pidfile = $dir->child('.raider-hall.pid');
  if (-f $pidfile) {
    my $pid = eval { $pidfile->slurp_utf8 };
    if ($pid && $pid =~ /^\d+$/ && kill(0, $pid)) {
      die "Hall already running with PID $pid\n";
    }
  }

  my $hall = Langertha::Raider::Hall->new(root => $dir);

  if ($opt{daemon}) {
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if ($pid != 0) {
      print "Hall started with PID $pid\n";
      exit 0;
    }
    eval {
      POSIX::setsid() or die "setsid: $!";
      open STDIN, '<', '/dev/null';
      open STDOUT, '>', '/dev/null';
      open STDERR, '>', '/dev/null';
    };
    $hall->_write_pidfile;
  }

  eval { $hall->run };
  if ($@) {
    die "Hall error: $@\n";
  }
  return 0;
}

sub print_start_help {
  print <<"EOF";
raider hall start [DIR] [--daemon] [--acp-port N] [--acp-host H]

Start the hall daemon in DIR (default: cwd).
  --daemon          Fork to background
  --acp-port N      Enable ACP adapter on TCP port N (127.0.0.1)
  --acp-host H      Bind ACP to H (default: 127.0.0.1; use 0.0.0.0 for all)
EOF
  exit 0;
}

sub run_stop {
  my (@args) = @_;
  my $dir = hall_dir(\@args);
  $dir = path($dir);

  my $pidfile = $dir->child('.raider-hall.pid');
  if (!-f $pidfile) {
    die "No PID file found. Is the hall running?\n";
  }
  my $pid = eval { $pidfile->slurp_utf8 };
  if (!$pid || $pid !~ /^\d+$/) {
    die "Invalid PID file\n";
  }
  kill 'TERM', $pid or die "Failed to send TERM to $pid: $!\n";
  print "Sent TERM to hall PID $pid\n";
  return 0;
}

sub run_status {
  my (@args) = @_;
  my $dir = hall_dir(\@args);
  my $socket = path($dir)->child('.raider-hall.socket');
  die "Hall not running (no socket found)\n" unless -e $socket;

  my $result = _send_command($socket, { type => 'command', payload => { cmd => 'status' } });
  print JSON::MaybeXS->new(pretty => 1)->encode($result), "\n";
  return 0;
}

sub run_ps {
  my (@args) = @_;
  my $dir = hall_dir(\@args);
  my $socket = path($dir)->child('.raider-hall.socket');
  die "Hall not running (no socket found)\n" unless -e $socket;

  my $result = _send_command($socket, { type => 'command', payload => { cmd => 'ps' } });
  my $list = $result->{raiders} // [];
  if (!@$list) {
    print "No running raiders.\n";
    return 0;
  }
  printf "%-10s %-8s %s\n", 'SLOT', 'PID', 'BASE_NAME';
  for my $r (@$list) {
    printf "%-10s %-8s %s\n", $r->{slot}, $r->{pid}, $r->{base_name};
  }
  return 0;
}

sub _send_command {
  my ($socket_path, $msg) = @_;

  my $sock = IO::Socket::UNIX->new(
    Type => SOCK_STREAM,
    Peer => $socket_path,
  ) or die "Cannot connect to $socket_path: $!\n";

  my $result;
  my $stream = IO::Async::Stream->new(
    handle => $sock,
    on_read => sub {
      my ($stream, $bufref, $eof) = @_;
      if ($$bufref =~ s/^(.*?)\n//) {
        $result = JSON::MaybeXS->new->decode($1);
        $stream->loop->stop;
        return length($1);
      }
      return 0;
    },
  );

  my $loop = IO::Async::Loop->new;
  $loop->add($stream);

  my $json = JSON::MaybeXS->new->encode($msg);
  $stream->write("$json\n");

  $loop->run;

  die "No response from hall\n" unless defined $result;
  return $result;
}

sub run_spawn {
  my @args = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt, 'attach', 'help');
  return print_spawn_help() if $opt{help};
  @args = @ARGV;

  my $dir = hall_dir(\@args, 2);
  die "Usage: raider hall spawn NAME MISSION [--attach]\n" unless @args >= 2;

  my $name = shift @args;
  my $mission = join ' ', @args;

  my $socket = path($dir)->child('.raider-hall.socket');
  die "Hall not running (no socket found)\n" unless -e $socket;

  my $result = _send_command($socket, {
    type => 'command',
    payload => {
      cmd => 'spawn',
      name => $name,
      mission => $mission,
    },
  });

  if ($result->{queued}) {
    print "Mission queued for slot $result->{slot} (queue depth: $result->{queue_depth}).\n";
    print STDERR "Not attached: the mission has no run yet.\n" if $opt{attach};
  }
  elsif ($result->{id}) {
    # Attached, stdout is the event stream alone.
    my $out = $opt{attach} ? \*STDERR : \*STDOUT;
    print {$out} "Spawned raider $result->{id} (PID $result->{pid}) in slot $result->{slot}.\n";
    if ($opt{attach}) {
      die "Hall: raider $result->{id} has no event stream\n" unless $result->{events_path};
      return _follow_file($socket, $result->{id}, $result->{events_path});
    }
  }
  elsif ($result->{error}) {
    my $e = JSON::MaybeXS->new->decode($result->{error});
    die "Hall error: $e->{error}\n";
  }
  return 0;
}

sub print_spawn_help {
  print <<"EOF";
raider hall spawn [DIR] NAME MISSION [--attach]

Spawn a raider with the given NAME and MISSION in DIR (default: cwd).
--attach then prints the run's event stream like 'attach' does; a
mission that waits in a queue has no run yet and is not attached.
EOF
  exit 0;
}

sub run_attach {
  my @args = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt, 'help');
  return print_attach_help() if $opt{help};
  @args = @ARGV;

  my $dir = hall_dir(\@args, 1);
  die "Usage: raider hall attach ID\n" unless @args;

  my $id = shift @args;
  my $socket = path($dir)->child('.raider-hall.socket');
  die "Hall not running (no socket found)\n" unless -e $socket;

  my $result = _send_command($socket, {
    type => 'command',
    payload => { cmd => 'attach', id => $id },
  });

  if ($result->{error}) {
    die "Hall: $result->{error}\n";
  }
  die "Hall: raider $id has no event stream\n" unless $result->{events_path};
  return _follow_file($socket, $id, $result->{events_path});
}

sub print_attach_help {
  print <<"EOF";
raider hall attach [DIR] ID

Print the event stream of the running raider ID (its --stream-json
events, one JSON object per line) and keep printing new events until
the raider has exited. For an ended run, see 'logs'.
EOF
  exit 0;
}

sub run_logs {
  my @args = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt, 'follow', 'help');
  return print_logs_help() if $opt{help};
  @args = @ARGV;

  my $dir = hall_dir(\@args, 1);
  die "Usage: raider hall logs ID [--follow]\n" unless @args;

  my $id = shift @args;
  my $socket = path($dir)->child('.raider-hall.socket');
  die "Hall not running (no socket found)\n" unless -e $socket;

  return _follow_log($socket, $id) if $opt{follow};
  return _print_logs($socket, $id);
}

sub _print_logs {
  my ( $socket, $id ) = @_;
  my $result = _send_command($socket, {
    type => 'command',
    payload => { cmd => 'logs', id => $id },
  });

  if ($result->{error}) {
    die "Hall: $result->{error}\n";
  }
  print $result->{log};
  return 0;
}

sub _follow_log {
  my ( $socket, $id ) = @_;
  my $result = _send_command($socket, { type => 'command', payload => { cmd => 'attach', id => $id } });
  # Already ended: nothing to follow, print what the hall still has.
  return _print_logs($socket, $id) if $result->{error};
  return _follow_file($socket, $id, $result->{log_path});
}

# Print a file of the raider and keep printing what is appended, until the
# hall no longer knows the raider (it exited and was reaped); what it wrote
# before that is still printed. The CLI talks to the hall over a local UNIX
# socket, so the path is readable here.
sub _follow_file {
  my ( $socket, $id, $file ) = @_;
  my $attach = { type => 'command', payload => { cmd => 'attach', id => $id } };

  local $| = 1;
  my $fh;
  while (1) {
    my $gone = _send_command($socket, $attach)->{error};
    $fh //= path($file)->openr_raw if -f $file;
    if ($fh) {
      seek $fh, 0, 1;    # clear EOF so appended bytes are seen
      while ( read $fh, my $buf, 65536 ) { print $buf }
    }
    last if $gone;
    _follow_wait();
  }
  return 0;
}

sub _follow_wait { sleep 1 }

sub print_logs_help {
  print <<"EOF";
raider hall logs [DIR] ID [--follow]

Fetch logs for a raider, also after its run has ended: the slot log, or
the run's result when the slot log no longer has it. --follow keeps
printing new output until the raider has exited.
EOF
  exit 0;
}

sub run_kill {
  my @args = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt, 'help');
  return print_kill_help() if $opt{help};
  @args = @ARGV;

  my $dir = hall_dir(\@args, 1);
  die "Usage: raider hall kill ID\n" unless @args;

  my $id = shift @args;
  my $socket = path($dir)->child('.raider-hall.socket');
  die "Hall not running (no socket found)\n" unless -e $socket;

  my $result = _send_command($socket, {
    type => 'command',
    payload => { cmd => 'kill', id => $id },
  });

  if ($result->{killed}) {
    print "Killed raider $id.\n";
  }
  elsif ($result->{error}) {
    die "Hall: $result->{error}\n";
  }
  return 0;
}

sub print_kill_help {
  print <<"EOF";
raider hall kill [DIR] ID

Terminate a raider.
EOF
  exit 0;
}

sub run_session {
  my @args = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt, 'help');
  return print_session_help() if $opt{help};
  @args = @ARGV;

  my $usage = "Usage: raider hall session reset [DIR] BINDING\n";
  my $sub = shift @args // '';
  die $usage unless $sub eq 'reset';
  my $dir = hall_dir(\@args, 1);
  die $usage unless @args == 1;

  my $binding = shift @args;
  my $socket = path($dir)->child('.raider-hall.socket');
  die "Hall not running (no socket found)\n" unless -e $socket;

  my $result = _send_command($socket, {
    type => 'command',
    payload => { cmd => 'session_reset', binding => $binding },
  });
  die "Hall: $result->{error}\n" if $result->{error};
  print 'Binding '.$binding.' reset: its next mission starts a new session'
    .' (the old one, '.$result->{session}.', is kept).'."\n";
  return 0;
}

sub print_session_help {
  print <<"EOF";
raider hall session reset [DIR] BINDING

Start BINDING over: its next mission runs in a new session. BINDING is a
key of .raider-hall/state/sessions.json, e.g. telegram:ops:42,
telegram:ops:-1001234:7, cron:nightly, slot:1bjorn. The old journal is
kept. In a Telegram chat, /new does the same for that chat.
EOF
  exit 0;
}

sub run_install {
  my (@args) = @_;
  my %opt;
  local @ARGV = @args;
  Getopt::Long::GetOptions(\%opt,
    'docker', 'host', 'image=s', 'name=s',
    'acp-port=i', 'acp-host=s', 'stdout', 'help');
  return print_install_help() if $opt{help};

  my $dir = hall_dir(\@ARGV);
  $dir = path($dir);
  my $cwd = $dir->stringify;
  my $unit_name = $opt{name} // 'raider-hall';
  my $in_container = -f '/.dockerenv' || ($ENV{container} // '') ne '';

  # The hard truth: systemd lives on the host. Writing to
  # ~/.config/systemd/user/ from inside a container puts the unit in
  # the container's filesystem where no systemd will ever read it.
  # So: inside a container, we *always* emit to stdout and tell the
  # user where to put it. The choice of --docker vs --host only
  # changes the template.
  #
  # Outside a container we write to ~/.config by default, unless
  # --stdout is explicitly requested.
  if ($in_container && !$opt{docker} && !$opt{host}) {
    die "Detected container environment (/.dockerenv present).\n"
      . "Pick one:\n"
      . "  --docker        emit a unit that runs `docker run` on the host\n"
      . "                  (install it on the HOST — systemd isn't in here)\n"
      . "  --host          emit a native unit that execs the in-container raider\n"
      . "                  (only makes sense if you also bind-mount\n"
      . "                  ~/.config/systemd/user into the container)\n";
  }

  my $unit_content = $opt{docker}
    ? _render_docker_unit($cwd, $unit_name, \%opt)
    : _render_native_unit($cwd, \%opt);

  if ($opt{stdout}) {
    print $unit_content;
    return 0;
  }

  # Inside a container: write to `$root/.raider-hall/systemd/…` — the
  # working dir is almost always a bind-mount from the host, so the
  # file shows up in the user's project tree and a single `ln -s` (or
  # `cp`) from the host pulls it into ~/.config/systemd/user/.
  if ($in_container) {
    my $staging = $dir->child('.raider-hall', 'systemd');
    $staging->mkpath unless -d $staging;
    my $unit_file = $staging->child("$unit_name.service");
    $unit_file->spew_utf8($unit_content);

    print "Wrote $unit_file\n";
    print "(inside a container — systemd lives on the host)\n\n";
    print "On the HOST, run:\n\n";
    print "  cp .raider-hall/systemd/$unit_name.service ~/.config/systemd/user/\n";
    print "  systemctl --user daemon-reload\n";
    print "  systemctl --user enable --now $unit_name\n";
    return 0;
  }

  my $xdg = $ENV{XDG_CONFIG_HOME} // path($ENV{HOME})->child('.config');
  my $systemd_dir = path($xdg)->child('systemd', 'user');
  $systemd_dir->mkpath unless -d $systemd_dir;
  my $unit_file = $systemd_dir->child("$unit_name.service");
  $unit_file->spew_utf8($unit_content);

  print "Installed $unit_file\n";
  if ($opt{docker}) {
    print "(docker-mode unit — docker must be available on this host)\n";
  }
  print "Run:\n";
  print "  systemctl --user daemon-reload\n";
  print "  systemctl --user enable --now $unit_name\n";
  return 0;
}

sub _render_native_unit {
  my ($cwd, $opt) = @_;
  my $raider_bin = path($0)->absolute->stringify;
  my @start = ($raider_bin, 'hall', 'start');
  push @start, '--acp-port', $opt->{'acp-port'} if $opt->{'acp-port'};
  push @start, '--acp-host', $opt->{'acp-host'} if $opt->{'acp-host'};
  my $exec = join ' ', map { /\s/ ? qq("$_") : $_ } @start;

  return <<"EOF";
[Unit]
Description=Raider Hall daemon
After=network.target

[Service]
Type=simple
WorkingDirectory=$cwd
ExecStart=$exec
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
}

sub _render_docker_unit {
  my ($cwd, $unit_name, $opt) = @_;
  my $image = $opt->{image} // 'raudssus/raider:latest';
  my $container_name = $unit_name;

  my @docker = (
    '/usr/bin/docker', 'run', '--rm',
    '--name', $container_name,
    '-v', "$cwd:/work",
    '-w', '/work',
  );

  # Publish the ACP port out of the container when asked for.
  if ($opt->{'acp-port'}) {
    push @docker, '-p', "$opt->{'acp-port'}:$opt->{'acp-port'}";
  }

  # Forward the API-key env vars — systemd EnvironmentFile is the
  # cleaner long-term answer, but -e on the docker command line is
  # explicit and survives without extra files.
  for my $e (api_key_env_vars()) {
    push @docker, '-e', $e;
  }

  push @docker, $image, 'hall', 'start';
  push @docker, '--acp-port', $opt->{'acp-port'} if $opt->{'acp-port'};
  push @docker, '--acp-host', ($opt->{'acp-host'} // '0.0.0.0')
    if $opt->{'acp-port'};  # inside container must bind to 0.0.0.0 to be reachable

  my $exec_start = join ' ', map { /\s/ ? qq("$_") : $_ } @docker;
  my $exec_stop  = qq(/usr/bin/docker stop $container_name);

  return <<"EOF";
[Unit]
Description=Raider Hall daemon (Docker)
Requires=docker.service
After=docker.service network.target

[Service]
Type=simple
WorkingDirectory=$cwd
ExecStartPre=-/usr/bin/docker stop $container_name
ExecStartPre=-/usr/bin/docker rm $container_name
ExecStart=$exec_start
ExecStop=$exec_stop
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
}

# The engines' key variables come from the resolver that picks the
# engine inside the raider; the web-search keys are WebTools'.
sub api_key_env_vars {
  return (
    Langertha::Raider::EngineResolver->api_key_env_vars,
    qw( BRAVE_API_KEY SERPER_API_KEY GOOGLE_API_KEY GOOGLE_CSE_ID )
  );
}

sub print_install_help {
  print <<"EOF";
raider hall install [DIR] [options]

Write a systemd user unit that starts the hall daemon.

Options:
  --docker          Emit a Docker unit (docker run raudssus/raider …)
  --host            Emit a native unit even inside a container
                    (overrides the safety check)
  --image IMG       Docker image (default: raudssus/raider:latest)
  --name NAME       Unit / container name (default: raider-hall)
  --acp-port N      Pass --acp-port N to raider hall start; for --docker
                    this also publishes the port out of the container
  --acp-host H      Pass --acp-host H to raider hall start
  --stdout          Print the unit to stdout instead of writing it

Inside a container, --docker or --host must be chosen explicitly —
otherwise the unit would point at container-internal paths the host
cannot reach.
EOF
  exit 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall::CLI - Internal dispatcher of the raider hall subcommands

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Dispatches the C<raider hall> subcommands: it reads the subcommand and its
options and runs the matching handler -- C<init> and C<add-raider> to set up
a L<Langertha::Raider::Hall>, C<start> and C<stop> for its daemon, and
C<status>, C<ps>, C<spawn>, C<attach>, C<logs>, C<kill>, C<session> and
C<install> to drive a running hall over its control socket.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
