use strict;
use warnings;
use Path::Tiny;
use lib 't/lib';
use Test::More;
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::Hall;
use JSON::MaybeXS ();
use IO::Async::Loop;
use File::Temp qw( tempdir );

use Langertha::Raider::CLI;  # for pack discovery path
use Langertha::Raider::CLI::Main;

BEGIN {
  my $repo = Path::Tiny::path(__FILE__)->parent->parent->absolute;
  my $bin = $repo->child('bin', 'raider');
  $ENV{RAIDER_HALL_RAIDER_BIN} = $bin->stringify if -x $bin;
}

# 'spawn result structure' below has the hall exec the real bin/raider
# (RAIDER_HALL_RAIDER_BIN above); it never reaches an engine because its
# .raider-hall.yml names an unknown engine, but clear the env anyway so
# that stays true if the fixture ever changes.
clear_engine_env();

subtest 'Hall new + config' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  isa_ok($hall, 'Langertha::Raider::Hall');
  is($hall->root->stringify, $tmp, 'root set');
  ok(!exists($hall->config->{raiders}), 'empty config when no yml');
};

subtest 'Hall with config file' => sub {
  my $tmp = tempdir(CLEANUP => 1);

  path("$tmp/.raider-hall.yml")->spew_utf8(YAML::PP->new->dump({
    longhouse => 0,
    raiders => {
      Bjorn => {
        engine => 'anthropic',
        persona => 'caveman',
        packs => [],
        mcp => [],
        isolated => 0,
      },
    },
  }));

  my $hall = Langertha::Raider::Hall->new(root => path($tmp));
  is($hall->config->{raiders}{Bjorn}{engine}, 'anthropic', 'config loaded');
  is($hall->config->{longhouse}, 0, 'longhouse false');
};

subtest 'ps returns empty initially' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  my @list = $hall->ps;
  is_deeply(\@list, [], 'ps empty');
};

subtest 'kill returns error for unknown id' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  my $result = $hall->kill_raider('nonexistent');
  ok($result->{error}, 'kill returns error');
};

subtest 'attach returns error for unknown id' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  my $result = $hall->attach('nonexistent');
  ok($result->{error}, 'attach returns error');
};

subtest 'logs returns error for unknown id' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  my $result = $hall->logs(id => 'nonexistent');
  ok($result->{error}, 'logs returns error');
};

subtest '1name singleton parsing' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  my ($slot, $base) = $hall->_parse_name('1bjorn');
  is($slot, '1bjorn', 'slot is 1bjorn');
  is($base, 'bjorn', 'base is bjorn');

  my ($slot2, $base2) = $hall->_parse_name('bjorn');
  ok(!defined($slot2), 'no slot for plain name');
  is($base2, 'bjorn', 'base is bjorn');
};

subtest 'state_dir is created' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  my $sd = $hall->state_dir;
  ok(-d $sd, 'state_dir created');
  like($sd->stringify, qr/\.raider-hall\/state$/, 'state dir path correct');
};

subtest 'longhouse_lib_path' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  my $lp = $hall->longhouse_lib_path;
  like($lp->stringify, qr/longhouse\/lib$/, 'longhouse lib path');
};

subtest 'same-file lazy components build without require side files' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  isa_ok($hall->cron_scheduler, 'Langertha::Raider::Hall::Cron');
  isa_ok($hall->telegram, 'Langertha::Raider::Hall::Telegram');
  isa_ok($hall->mcp_adapter, 'Langertha::Raider::Hall::MCP');
};

subtest 'queued singleton mission is replayed as text' => sub {
  my $tmp = tempdir(CLEANUP => 1);
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  $hall->raiders->{old} = Langertha::Raider::Hall::Raider->new({
    id => 'old',
    pid => 12345,
    slot_name => '1bjorn',
    base_name => 'bjorn',
    log_path => path($tmp)->child('old.log'),
    mission => 'old mission',
  });

  my $queued = $hall->spawn(name => '1bjorn', mission => 'next mission');
  ok($queued->{queued}, 'second singleton spawn queued');

  my @spawned;
  no warnings 'redefine';
  local *Langertha::Raider::Hall::_spawn_raider = sub {
    my ($self, $slot, $base, $mission) = @_;
    push @spawned, [$slot, $base, $mission];
    return { id => 'new', pid => 999, slot => $slot };
  };

  $hall->_reap_raider(12345, 0);
  is_deeply($spawned[0], ['1bjorn', 'bjorn', 'next mission'],
    'queued entry unpacked before spawning next raider');
};

subtest 'raider cli accepts pack option used by hall' => sub {
  my ($opt) = Langertha::Raider::CLI::Main->new->parse_options(qw( --pack git-guru --pack polite ));
  is_deeply($opt->{packs}, [qw( git-guru polite )], 'raider accepts repeated --pack');
};

subtest 'spawn result structure' => sub {
  my $tmp = tempdir(CLEANUP => 1);

  path("$tmp/.raider-hall.yml")->spew_utf8(YAML::PP->new->dump({
    raiders => {
      TestR => {
        engine => 'shell',
        persona => 'caveman',
        packs => [],
        mcp => [],
        isolated => 0,
      },
    },
  }));

  my $hall = Langertha::Raider::Hall->new(root => path($tmp));

  # Use a simple shell command so we don't actually make API calls
  my $result = $hall->spawn(name => 'TestR', mission => 'echo hello');
  ok($result->{id}, 'spawn returned id');
  ok($result->{pid}, 'spawn returned pid');
  ok($result->{slot}, 'spawn returned slot');
};

done_testing;
