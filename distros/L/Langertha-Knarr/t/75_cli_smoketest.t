use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP;
use Capture::Tiny qw( capture );

BEGIN {
  eval { require Capture::Tiny; require YAML::PP; 1 }
    or plan skip_all => 'Capture::Tiny + YAML::PP required';
}

use Langertha::Knarr::CLI::Cmd::Models;
use Langertha::Knarr::CLI::Cmd::Check;
use Langertha::Knarr::CLI::Cmd::Init;

# Build a tiny valid config file in a tempdir.
my $tmp = tempdir( CLEANUP => 1 );
my $cfg_file = "$tmp/knarr.yaml";
my $config_data = {
  listen => ['127.0.0.1:8088'],
  models => {
    'test-model' => {
      engine => 'OpenAI',
      url    => 'https://api.openai.com',
    },
  },
};
path($cfg_file)->spew_utf8( YAML::PP->new->dump_string($config_data) );

# Mock "main" chain entry that the cmd classes look at: ->config returns the file path.
{
  package MockMain;
  sub new { bless { config => $_[1], verbose => 0 }, $_[0] }
  sub config  { $_[0]->{config} }
  sub verbose { $_[0]->{verbose} }
}
my $main = MockMain->new($cfg_file);

# --- knarr check ---
{
  my $cmd = Langertha::Knarr::CLI::Cmd::Check->new;
  my ($stdout, $stderr, $exit) = capture {
    eval { $cmd->execute( [], [ $main ] ); $@ };
  };
  ok( length($stdout) || length($stderr), 'check produced output' );
  unlike( $stderr, qr/error|invalid/i, 'check did not report errors' );
}

# --- knarr models (table) ---
{
  my $cmd = Langertha::Knarr::CLI::Cmd::Models->new( format => 'table' );
  my ($stdout, $stderr) = capture {
    eval { $cmd->execute( [], [ $main ] ); $@ };
  };
  like( $stdout, qr/test-model/, 'models table includes configured model' );
}

# --- knarr models --format json ---
{
  my $cmd = Langertha::Knarr::CLI::Cmd::Models->new( format => 'json' );
  my ($stdout, $stderr) = capture {
    eval { $cmd->execute( [], [ $main ] ); $@ };
  };
  require JSON::MaybeXS;
  my $data = eval { JSON::MaybeXS->new->decode($stdout) };
  ok( $data, 'models json parses' );
  ok( ( grep { ( ref $_ eq 'HASH' ? ($_->{id} // '') : "$_" ) eq 'test-model' } @$data ),
      'json output contains test-model' );
}

# --- knarr init: scans environment, prints YAML to stdout ---
{
  local %ENV = ( OPENAI_API_KEY => 'sk-fake', %ENV );
  my $cmd = Langertha::Knarr::CLI::Cmd::Init->new;
  my ($stdout, $stderr) = capture {
    eval { $cmd->execute( [], [ $main ] ); $@ };
  };
  ok( length $stdout, 'init produced YAML output' );
  like( $stdout, qr/(passthrough|openai|listen)/i, 'init output mentions known config keys' );
}

done_testing;
