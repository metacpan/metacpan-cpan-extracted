#!/usr/bin/env perl
# ABSTRACT: Langertha::Raider::Hall::CLI — init/add-raider/status/ps/stop/start/
# install (t/32_hall_cli_args.t covers argument parsing and DIR resolution for
# spawn/attach/logs/kill/start/install; this covers the subcommands and output
# it does not touch)

use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::EngineResolver;
use Langertha::Raider::Hall::CLI;

my $orig_cwd = path('.')->absolute;

# Runs a hall subcommand with cwd set to $dir and STDIN fed from $stdin
# (default: empty). Returns (exit value, captured stdout, death message).
sub run_hall_cli_in {
  my ( $dir, $stdin, @argv ) = @_;
  $stdin //= '';
  chdir $dir or die "chdir $dir: $!";
  my $out = '';
  my ( $rv, $died );
  {
    local *STDIN;
    open STDIN, '<', \$stdin or die $!;
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    $died = dies { $rv = Langertha::Raider::Hall::CLI->main(@argv) };
  }
  chdir $orig_cwd or die "chdir $orig_cwd: $!";
  return ( $rv, $out, $died );
}

sub new_hall_dir {
  my $dir = path( tempdir( CLEANUP => 1 ) )->realpath;
  $dir->child('.raider-hall.socket')->touch;
  return "$dir";
}

# --- init ---

subtest 'init: writes .raider-hall.yml with the given/default values' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'init', '--name', 'Bjorn' );
  is( $died, undef, 'lives' );
  is( $rv, 0, 'returns 0' );
  like( $out, qr/Hall initialised in .* with raider 'Bjorn'/, 'confirmation message' );

  my $yml = YAML::PP->new->load_string( path($tmp)->child('.raider-hall.yml')->slurp_utf8 );
  is( $yml->{longhouse}, 0, 'longhouse off by default' );
  ok( !exists $yml->{raiders}{Bjorn}{engine}, 'no engine: the raider decides itself' );
  is( $yml->{raiders}{Bjorn}{persona}, 'caveman', 'default persona' );
  ok( !exists $yml->{raiders}{Bjorn}{$_}, 'no '.$_.' key' ) for qw( mcp isolated );
  ok( !exists $yml->{preferred_lib_target}, 'no preferred_lib_target: the hall default applies' );
};

subtest 'init: --engine/--persona override the defaults' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  run_hall_cli_in( $tmp, undef, 'init', '--name', 'Astrid', '--engine', 'openai', '--persona', 'scholar' );
  my $yml = YAML::PP->new->load_string( path($tmp)->child('.raider-hall.yml')->slurp_utf8 );
  is( $yml->{raiders}{Astrid}{engine}, 'openai', 'engine overridden' );
  is( $yml->{raiders}{Astrid}{persona}, 'scholar', 'persona overridden' );
};

subtest 'init: refuses to overwrite an existing .raider-hall.yml' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.yml')->spew_utf8("already: here\n");
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'init', '--name', 'Bjorn' );
  like( $died, qr/^Refusing to overwrite existing/, 'dies rather than clobbering it' );
};

subtest 'init: prompts on STDIN when --name is omitted' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, "Astrid\n", 'init' );
  is( $died, undef, 'lives' );
  like( $out, qr/raider 'Astrid'/, 'name taken from stdin' );
};

# --- add-raider ---

subtest 'add-raider: appends to an existing config, keeps the other raider' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.yml')->spew_utf8( YAML::PP->new->dump({
    raiders => { Bjorn => { engine => 'anthropic', persona => 'caveman', packs => [] } },
  }) );

  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'add-raider', 'Astrid',
    '--engine', 'openai', '--persona', 'scholar', '--model', 'gpt-4o-mini',
    '--pack', 'git-guru', '--pack', 'polite' );
  is( $died, undef, 'lives' );
  like( $out, qr/Added raider 'Astrid'/, 'confirmation' );

  my $yml = YAML::PP->new->load_string( path($tmp)->child('.raider-hall.yml')->slurp_utf8 );
  is( $yml->{raiders}{Astrid}{engine}, 'openai', 'engine' );
  is( $yml->{raiders}{Astrid}{persona}, 'scholar', 'persona' );
  is( $yml->{raiders}{Astrid}{model}, 'gpt-4o-mini', 'model' );
  is( $yml->{raiders}{Astrid}{packs}, ['git-guru', 'polite'], 'repeated --pack collected in order' );
  ok( !exists $yml->{raiders}{Astrid}{$_}, 'no '.$_.' key' ) for qw( mcp isolated );
  ok( exists $yml->{raiders}{Bjorn}, 'existing raider preserved' );
};

subtest 'add-raider: without --engine, no engine key is written' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.yml')->spew_utf8( YAML::PP->new->dump({ raiders => {} }) );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'add-raider', 'Ivar' );
  is( $died, undef, 'lives' );
  my $yml = YAML::PP->new->load_string( path($tmp)->child('.raider-hall.yml')->slurp_utf8 );
  ok( exists $yml->{raiders}{Ivar}, 'raider added' );
  ok( !exists $yml->{raiders}{Ivar}{engine}, 'no engine: the raider decides itself' );
  is( $yml->{raiders}{Ivar}{persona}, 'caveman', 'default persona' );
};

subtest 'add-raider: dies without an existing hall' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'add-raider', 'Astrid' );
  like( $died, qr/^No \.raider-hall\.yml found/, 'dies' );
};

subtest 'add-raider: dies on a duplicate name' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.yml')->spew_utf8( YAML::PP->new->dump({ raiders => { Bjorn => {} } }) );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'add-raider', 'Bjorn' );
  like( $died, qr/already defined/, 'dies' );
};

# --- status / ps ---

subtest 'status: hall reply pretty-printed as JSON' => sub {
  my $tmp = new_hall_dir();
  no warnings 'redefine';
  local *Langertha::Raider::Hall::CLI::_send_command = sub { return { raiders => 2, uptime => 10 } };
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'status' );
  is( $died, undef, 'lives' );
  is( JSON::MaybeXS->new->decode($out), { raiders => 2, uptime => 10 }, 'decodes back to the hall reply' );
};

subtest 'ps: table of running raiders' => sub {
  my $tmp = new_hall_dir();
  no warnings 'redefine';
  local *Langertha::Raider::Hall::CLI::_send_command = sub {
    return { raiders => [
      { slot => 'bjorn', pid => 111, base_name => 'bjorn' },
      { slot => '1astrid', pid => 222, base_name => 'astrid' },
    ] };
  };
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'ps' );
  is( $died, undef, 'lives' );
  like( $out, qr/^SLOT\s+PID\s+BASE_NAME$/m, 'header row' );
  like( $out, qr/^bjorn\s+111\s+bjorn$/m, 'first raider row' );
  like( $out, qr/^1astrid\s+222\s+astrid$/m, 'second raider row' );
};

subtest 'ps: no raiders prints a plain message, not an empty table' => sub {
  my $tmp = new_hall_dir();
  no warnings 'redefine';
  local *Langertha::Raider::Hall::CLI::_send_command = sub { return { raiders => [] } };
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'ps' );
  is( $out, "No running raiders.\n", 'message only' );
};

# --- stop ---

subtest 'stop: no pidfile' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'stop' );
  like( $died, qr/^No PID file found/, 'dies' );
};

subtest 'stop: invalid pidfile content' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.pid')->spew_utf8('not-a-pid');
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'stop' );
  like( $died, qr/^Invalid PID file/, 'dies' );
};

subtest 'stop: sends TERM to the pid named in the file' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.pid')->spew_utf8("$$\n");    # a pid guaranteed to exist: ourselves
  local $SIG{TERM} = 'IGNORE';                                 # survive our own signal
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'stop' );
  is( $died, undef, 'lives' );
  is( $rv, 0, 'returns 0' );
  like( $out, qr/^Sent TERM to hall PID $$/, 'confirmation names the pid' );
};

# --- start: already-running guard ---

subtest 'start: refuses when the pidfile names a live process' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.pid')->spew_utf8("$$\n");
  no warnings 'redefine';
  local *Langertha::Raider::Hall::new = sub { die "Hall->new reached\n" };
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'start' );
  like( $died, qr/^Hall already running with PID $$/, 'refuses before ever building a Hall' );
};

# --- install ---

subtest 'install --stdout: native unit content' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef,
    'install', '--host', '--stdout', '--acp-port', '4711', '--acp-host', '0.0.0.0' );
  is( $died, undef, 'lives' );
  like( $out, qr/^WorkingDirectory=\Q$tmp\E$/m, 'unit runs in the hall dir' );
  like( $out, qr/^ExecStart=.*hall start.*--acp-port 4711.*--acp-host 0\.0\.0\.0/m, 'acp options passed through' );
  unlike( $out, qr/docker/i, 'not a docker unit' );
};

subtest 'install --docker --stdout: docker unit content' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef,
    'install', '--docker', '--stdout', '--image', 'myimg:tag', '--name', 'myhall', '--acp-port', '4711' );
  is( $died, undef, 'lives' );
  like( $out, qr/docker run --rm --name myhall/, 'docker run invocation' );
  like( $out, qr{-v \Q$tmp\E:/work}, 'bind-mounts the hall dir' );
  like( $out, qr/-p 4711:4711/, 'publishes the acp port out of the container' );
  like( $out, qr/myimg:tag hall start --acp-port 4711 --acp-host 0\.0\.0\.0/,
    'binds to 0.0.0.0 by default so the published port is reachable' );
  like( $out, qr{ExecStop=/usr/bin/docker stop myhall}, 'stop command' );
  like( $out, qr/ -e \Q$_\E /, 'forwards engine key '.$_.' the engine resolver names' )
    for Langertha::Raider::EngineResolver->api_key_env_vars;
  like( $out, qr/ -e $_ /, 'forwards web-search key '.$_ )
    for qw( BRAVE_API_KEY SERPER_API_KEY GOOGLE_API_KEY GOOGLE_CSE_ID );
};

subtest 'install: inside a container, --docker or --host must be chosen' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  local $ENV{container} = 'oci';
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'install', '--stdout' );
  like( $died, qr/^Detected container environment/, 'refuses the ambiguous case' );

  ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'install', '--host', '--stdout' );
  is( $died, undef, '--host overrides the safety check' );
};

subtest 'install: outside a container, writes the unit under XDG_CONFIG_HOME' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my $xdg = tempdir( CLEANUP => 1 );
  local $ENV{XDG_CONFIG_HOME} = $xdg;
  local $ENV{container};
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'install', '--host', '--name', 'myhall2' );
  is( $died, undef, 'lives' );
  my $unit = path($xdg)->child('systemd', 'user', 'myhall2.service');
  ok( -f $unit, 'unit file written' );
  like( $out, qr/^Installed \Q$unit\E$/m, 'confirmation names the file' );
};

subtest 'install: inside a container without --stdout, stages the unit for the host to copy' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  local $ENV{container} = 'oci';
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, undef, 'install', '--host', '--name', 'myhall3' );
  is( $died, undef, 'lives' );
  my $unit = path($tmp)->child('.raider-hall', 'systemd', 'myhall3.service');
  ok( -f $unit, 'unit staged inside the (bind-mounted) hall dir' );
  like( $out, qr/inside a container/, 'explains why it only staged the file' );
  like( $out, qr/cp \.raider-hall\/systemd\/myhall3\.service/, 'gives the host-side copy command' );
};

done_testing;
