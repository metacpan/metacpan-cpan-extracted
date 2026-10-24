use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( encode_json );
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;

# The realtime: section (skeid k95, ADR 0029): the four limits of a realtime session. Strict
# like uploads: an unknown key or a value that is not an integer of at least 1 fails the load,
# and a reload moves the values, a removed section puts the defaults back.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY SKEID_USAGE_DB )};

my $CFG = {};
sub skeid {
  return Langertha::Skeid->new(config_reload_interval => 0, config_loader => sub { $CFG });
}

my @ATTR = qw( realtime_idle_timeout realtime_max_session_seconds realtime_max_message_bytes
  realtime_max_queued_bytes );

subtest 'defaults without a realtime section' => sub {
  $CFG = {};
  my $s = skeid();
  is $s->realtime_idle_timeout,        300,     'idle_timeout 300 s';
  is $s->realtime_max_session_seconds, 3600,    'max_session_seconds 3600 s';
  is $s->realtime_max_message_bytes,   1048576, 'max_message_bytes 1 MiB';
  is $s->realtime_max_queued_bytes,    4194304, 'max_queued_bytes 4 MiB';
};

subtest 'a declared section sets what it names, the rest stays default' => sub {
  $CFG = { realtime => { idle_timeout => 20, max_queued_bytes => 2048 } };
  my $s = skeid();
  is $s->realtime_idle_timeout,        20,      'idle_timeout set';
  is $s->realtime_max_queued_bytes,    2048,    'max_queued_bytes set';
  is $s->realtime_max_session_seconds, 3600,    'max_session_seconds default';
  is $s->realtime_max_message_bytes,   1048576, 'max_message_bytes default';
};

subtest 'a reload moves the values, removing the section restores the defaults' => sub {
  $CFG = { realtime => { idle_timeout => 20, max_session_seconds => 60, max_message_bytes => 512 } };
  my $s = skeid();
  is $s->realtime_max_message_bytes, 512, 'loaded';
  $CFG = { realtime => { idle_timeout => 45, max_session_seconds => 120, max_message_bytes => 4096,
    max_queued_bytes => 8192 } };
  $s->maybe_reload_config;
  is $s->realtime_idle_timeout,        45,   'idle_timeout follows the reload';
  is $s->realtime_max_session_seconds, 120,  'max_session_seconds follows the reload';
  is $s->realtime_max_message_bytes,   4096, 'max_message_bytes follows the reload';
  is $s->realtime_max_queued_bytes,    8192, 'max_queued_bytes follows the reload';
  $CFG = { realtime => { idle_timeout => 45 } };
  $s->maybe_reload_config;
  is $s->realtime_max_message_bytes, 1048576, 'a key dropped from the section is its default again';
  $CFG = { aliases => {} };
  $s->maybe_reload_config;
  is $s->realtime_idle_timeout, 300, 'a section dropped from the file is the default again';
};

subtest 'a broken section fails the load' => sub {
  for my $bad (
    'idle',
    [],
    { idle_timeout => 0 },
    { idle_timeout => -5 },
    { idle_timeout => 'soon' },
    { idle_timeout => 1.5 },
    { idle_timeout => [300] },
    { max_session_seconds => 0 },
    { max_message_bytes => 0 },
    { max_queued_bytes => '' },
    { idle_timeoout => 10 },
  ) {
    $CFG = { realtime => $bad };
    my $ok = eval { skeid(); 1 };
    ok !$ok, 'refused: ' . encode_json([$bad]);
    like $@, qr/realtime/, 'the error names the section';
  }
};

done_testing;
