#!/usr/bin/env perl
# ABSTRACT: The loadguard gate: which commands are heavy, when they are refused, fail-open, confinement
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Path::Tiny;
use Test::Raider::FakeProc qw( fake_proc );
use Langertha::Raider::Loadguard;

# Offline and without load: every measurement comes from a /proc tree the test
# builds in a temporary directory (Test::Raider::FakeProc), every setting from a
# hash instead of %ENV.

sub guard {
  my ( $proc, %env ) = @_;
  return Langertha::Raider::Loadguard->new( proc_dir => "$proc", env => \%env );
}

my $quiet = fake_proc( memory_full => 0.5, swap => 40, cpus => 8 );

subtest 'heavy commands are found in command position' => sub {
  my $g = guard($quiet);
  my %heavy = (
    'prove -lr t'                              => [ 'prove',        'prove' ],
    '/usr/bin/perl /usr/bin/prove -l t/a.t'   => [ 'prove',        'prove' ],
    'make test'                                => [ 'make test',    'suite' ],
    'make -j4 test'                            => [ 'make test',    'suite' ],
    'dzil test'                                => [ 'dzil test',    'suite' ],
    'dzil build'                               => [ 'dzil build',   'build' ],
    'DZIL_X=1 dzil release'                    => [ 'dzil release', 'suite' ],
    'cpanm -n Foo::Bar'                        => [ 'cpanm',        'build' ],
    'docker build .'                           => [ 'docker build', 'build' ],
    'podman run --rm img'                      => [ 'podman run',   'build' ],
    'cargo +nightly test'                      => [ 'cargo test',   'suite' ],
    'cargo build --release'                    => [ 'cargo build',  'build' ],
    'npm test'                                 => [ 'npm test',     'suite' ],
    'claude -p "go"'                           => [ 'claude -p',    'agent' ],
    'claude --bg task'                         => [ 'claude --bg',  'agent' ],
    'codex exec fix'                           => [ 'codex exec',   'agent' ],
    'cd lib && nice -n 10 prove t'            => [ 'prove',        'prove' ],
    'timeout 5m ionice -c3 make test'          => [ 'make test',    'suite' ],
    'ls; echo a | prove'                       => [ 'prove',        'prove' ],
    "cat <<EOF\nnote\nEOF\nprove t"            => [ 'prove',        'prove' ],
    'if true; then dzil test; fi'              => [ 'dzil test',    'suite' ],
  );
  for my $cmd ( sort keys %heavy ) {
    my @got = $g->heavy($cmd);
    is( \@got, $heavy{$cmd}, 'heavy: ' . ( $cmd =~ s/\n/\\n/gr ) );
  }
  my @light = (
    'ls -la', 'git status', 'cat README.md', 'echo prove', 'echo "dzil test"', "echo 'a; prove'",
    'perl -e "print 1"', 'perl -Ilib t/foo.t', 'bash -c "prove"', 'sudo prove', "# prove\nls",
    "cat <<EOF\nprove\nEOF\nls", 'grep -r prove lib', 'make', 'cargo check', 'docker ps', 'claude --version',
    'codex login', 'prove2 x', '',
  );
  is( [ $g->heavy($_) ], [], 'light: ' . ( $_ =~ s/\n/\\n/gr ) ) for @light;
};

subtest 'thresholds come from the environment, bad values fall back' => sub {
  is( guard($quiet)->limits, { psi_full => 10, swap_used => 90, slots => 4 }, 'defaults: slots are half the cpus' );
  is( guard( fake_proc( cpus => 1 ) )->limits->{slots}, 1, 'at least one slot' );
  is(
    guard( $quiet, LOADGUARD_PSI_FULL => '25%', LOADGUARD_SWAP_USED => 70, LOADGUARD_HEAVY_SLOTS => 2 )->limits,
    { psi_full => 25, swap_used => 70, slots => 2 },
    'set, a trailing % is allowed',
  );
  is(
    guard( $quiet, LOADGUARD_PSI_FULL => 'abc', LOADGUARD_SWAP_USED => 101, LOADGUARD_HEAVY_SLOTS => 0 )->limits,
    { psi_full => 10, swap_used => 90, slots => 4 },
    'not a number or out of range: the default',
  );
};

subtest 'a light command is never refused, however bad the host is' => sub {
  my $thrash = fake_proc( memory_full => 80, swap => 100 );
  is( guard($thrash)->check($_), undef, "allowed: $_" ) for 'ls', 'git status', 'cat /etc/hostname';
};

subtest 'memory pressure refuses a heavy command, with the figures and the advice' => sub {
  my $thrash = fake_proc( memory_full => 59.9, swap => 40 );
  my $why    = guard($thrash)->check('dzil test');
  like( $why, qr/\Arefused by loadguard: heavy command \(dzil test\): memory pressure full=59\.9% \(limit 10%\), swap 40% used \(limit 90%\)\./, 'reason' );
  like( $why, qr/Wait and retry later; light commands \(git status, ls, cat\) still run\./, 'advice: wait' );
  unlike( $why, qr/single test file|fewer tests/, 'no test run advised under pressure' );

  my $swap = fake_proc( memory_full => 0.1, swap => 95 );
  like( guard($swap)->check('prove -l t'), qr/swap 95% used \(limit 90%\)/, 'swap alone refuses' );

  my $mild = fake_proc( memory_full => 12, swap => 10 );
  ok( defined guard($mild)->check('cpanm Foo'), 'full=12 is over the default 10' );
  is( guard( $mild, LOADGUARD_PSI_FULL => 20 )->check('cpanm Foo'), undef, 'under a raised limit it runs' );

  like( guard($thrash)->check('claude -p x'), qr/Do not start new `claude -p`/, 'agent sessions: no new ones' );
};

subtest 'fail-open: a signal the host does not give is no pressure' => sub {
  my $nopsi = fake_proc( swap => 10 );
  is( guard($nopsi)->pressure, { full => undef, swap => 10 }, 'no pressure/memory' );
  is( guard($nopsi)->check('prove t'), undef, 'allowed without PSI' );
  my $noswap = fake_proc( memory_full => 1 );
  is( guard($noswap)->pressure, { full => 1, swap => undef }, 'no swap lines' );
  is( guard($noswap)->check('prove t'), undef, 'allowed without swap' );
  is( guard( path('/nonexistent/proc') )->check('prove t'), undef, 'allowed without any /proc' );
};

subtest 'LOADGUARD_THROTTLE=0 turns the gate off' => sub {
  my $thrash = fake_proc( memory_full => 90, swap => 100 );
  is( guard( $thrash, LOADGUARD_THROTTLE => 0 )->check('prove t'), undef, 'off' );
  ok( defined guard( $thrash, LOADGUARD_THROTTLE => 1 )->check('prove t'), 'only exactly 0 turns it off' );
};

subtest 'heavy slots: the topmost heavy process under a raider holds one' => sub {
  my $raider = { pid => 100, ppid => 1, comm => 'raider', argv => [ '/usr/bin/perl', '/x/bin/raider', 'go' ] };
  my $proc   = fake_proc(
    memory_full => 0.2, swap => 10, cpus => 4,
    processes => [
      $raider,
      { pid => 101, ppid => 100, comm => 'bash', argv => [ 'bash', '-c', "cd '/w/a' && prove -lr t" ] },
      { pid => 102, ppid => 101, comm => 'prove', argv => [ '/usr/bin/perl', '/usr/bin/prove', '-lr', 't' ], cwd => '/w/a' },
      { pid => 103, ppid => 102, comm => 'perl', argv => [ 'perl', 't/a.t' ] },
      { pid => 200, ppid => 1, comm => 'prove', argv => [ '/usr/bin/perl', '/usr/bin/prove', 't' ] },
      { pid => 300, ppid => 100, comm => 'dzil', argv => [ 'dzil', 'test' ] },
      { pid => 301, ppid => 100, comm => 'claude', argv => [ 'claude', '-p', 'x' ] },
      { pid => 302, ppid => 100, comm => 'make', argv => [ 'make', 'test' ], cwd => '/w/b' },
    ],
  );
  my $g = guard( $proc, HOME => '/w' );
  is(
    [ map { $_->{label}.'@'.$_->{pid} } $g->slot_holders ],
    [ 'prove@101', 'dzil test@300', 'make test@302' ],
    'a chain is one slot (the bash -c), outside any raider is none, an agent holds none',
  );
  is( [ $g->slot_holders ]->[2]{cwd}, '/w/b', 'with the directory it runs in' );

  is( guard( $proc, LOADGUARD_HEAVY_SLOTS => 4 )->check('prove t'), undef, '3 of 4 slots busy: room' );
  my $why = guard( $proc, LOADGUARD_HEAVY_SLOTS => 3, HOME => '/w' )->check('prove t');
  like( $why, qr/\Arefused by loadguard: heavy command \(prove\): 3\/3 heavy slots busy \(prove; dzil test; make test in ~\/b\), memory pressure full=0\.2% \(limit 10%\), swap 10% used/, 'all busy' );
  like( $why, qr/Wait for one to finish, then retry; light commands.*When you retry, run fewer tests: `prove -l t\/foo\.t`/s, 'advice for the retry' );
  like( guard( $proc, LOADGUARD_HEAVY_SLOTS => 3 )->check('make test'), qr/run a single test file/, 'advice for a suite' );
  is( guard( $proc, LOADGUARD_HEAVY_SLOTS => 3 )->check('ls'), undef, 'light still runs with all slots busy' );
};

subtest 'more holders than shown are counted' => sub {
  my @many = map { { pid => 400 + $_, ppid => 100, comm => 'prove', argv => [ 'prove', 't' ] } } 1 .. 5;
  my $proc = fake_proc(
    memory_full => 0, swap => 0, cpus => 4,
    processes => [ { pid => 100, ppid => 1, comm => 'raider', argv => ['raider'] }, @many ],
  );
  like( guard( $proc, LOADGUARD_HEAVY_SLOTS => 2 )->check('prove x'), qr/5\/2 heavy slots busy \(prove; prove; prove; \+2 more\)/, '+N more' );
};

subtest 'under pressure the processes are not scanned' => sub {
  # a process directory that cannot be read would break a scan; the refusal
  # still comes, from the memory figures alone
  my $proc = fake_proc( memory_full => 70, swap => 10 );
  $proc->child('999')->mkpath;
  chmod 0, $proc->child('999')->stringify;
  my $why = guard($proc)->check('prove t');
  chmod 0755, $proc->child('999')->stringify;
  like( $why, qr/memory pressure full=70\.0%/, 'refused from pressure' );
  unlike( $why, qr/slots busy/, 'without a slot count' );
};

subtest 'the validator for the bash tool' => sub {
  my $thrash = fake_proc( memory_full => 70, swap => 10 );
  my $v = guard($thrash)->validator;
  is( $v->('ls'), 1, 'a light command: 1 = run' );
  like( $v->('make test'), qr/\Arefused by loadguard:/, 'a heavy one: the reason' );
};

subtest 'confinement is off unless asked for and checks its ground' => sub {
  my $root = Path::Tiny->tempdir;
  my $cg   = $root->child('cgroup');
  my $uid  = 4242;
  $cg->child( 'user.slice', "user-$uid.slice", "user\@$uid.service" )->mkpath;
  $cg->child( 'user.slice', "user-$uid.slice", "user\@$uid.service", 'cgroup.controllers' )->spew("cpu memory pids\n");
  my $bin = $root->child('bin');
  $bin->mkpath;
  $bin->child('systemd-run')->spew("#!/bin/sh\nexit 0\n");
  chmod 0755, $bin->child('systemd-run')->stringify;
  my $run = $root->child('run');
  $run->mkpath;
  require IO::Socket::UNIX;
  my $sock = IO::Socket::UNIX->new( Local => "$run/bus", Listen => 1 ) or skip_all("no unix socket: $!");

  my %env = ( LOADGUARD_CONFINE => 1, XDG_RUNTIME_DIR => "$run" );
  my $make = sub {
    my ( %over ) = @_;
    return Langertha::Raider::Loadguard->new( proc_dir => "$quiet", cgroup_dir => "$cg", env => { %env, %over } );
  };
  local $ENV{PATH} = "$bin:$ENV{PATH}";
  my %arg = ( command => [ 'raider', 'go' ], uid => $uid, pid => 77 );

  my @cmd = $make->()->confine_command(%arg);
  is( $cmd[0], "$bin/systemd-run", 'systemd-run' );
  is( [ @cmd[ 1 .. 6 ] ], [ '--user', '--scope', '--quiet', '--collect', '--slice=app-loadguard.slice', '--unit=loadguard-raider-77' ], 'a transient user scope in the loadguard slice' );
  my %prop = map { /\A(\w+)=(.*)\z/ ? ( $1 => $2 ) : () } @cmd;
  is( $prop{MemoryHigh}, int( 8_000_000 * 1024 * 30 / 100 ), 'MemoryHigh: 30% of MemTotal' );
  is( $prop{MemoryMax},  int( 8_000_000 * 1024 * 40 / 100 ), 'MemoryMax: 40%' );
  is( $prop{MemorySwapMax}, int( 8_000_000 * 1024 * 10 / 100 ), 'MemorySwapMax: 10%' );
  is( $prop{CPUWeight}, 50, 'CPUWeight 50' );
  is( $prop{OOMPolicy}, 'continue', 'a killed runaway does not stop the scope' );
  is( [ @cmd[ -3 .. -1 ] ], [ '--', 'raider', 'go' ], 'the command after --' );

  is( { map { /\A(\w+)=(.*)\z/ ? ( $1 => $2 ) : () } $make->( LOADGUARD_MEMORY_MAX => 25 )->confine_command(%arg) }->{MemoryMax},
    int( 8_000_000 * 1024 * 25 / 100 ), 'limits from the environment' );

  is( [ $make->( LOADGUARD_CONFINE => 0 )->confine_command(%arg) ], [], 'off unless LOADGUARD_CONFINE=1' );
  is( [ $make->( LOADGUARD_CONFINE => undef )->confine_command(%arg) ], [], 'off by default' );
  is( [ $make->( LOADGUARD_CONFINED => 1 )->confine_command(%arg) ], [], 'not again inside the scope' );
  is( [ $make->( XDG_RUNTIME_DIR => "$root/nowhere" )->confine_command(%arg) ], [], 'no user manager bus: nothing' );
  is( [ $make->()->confine_command( %arg, uid => 1 ) ], [], 'memory controller not delegated: nothing' );
  { local $ENV{PATH} = "$root/empty"; is( [ $make->()->confine_command(%arg) ], [], 'no systemd-run: nothing' ); }
};

done_testing;
