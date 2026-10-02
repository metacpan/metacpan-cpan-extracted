use strict;
use warnings;
use Test2::V0;
use Capture::Tiny qw( capture );
use JSON::MaybeXS qw( decode_json );

# Drives the real knarr CLI (MooX::Cmd + MooX::Options argv parsing) in a
# child perl. Each subcommand's execute is replaced by a probe that prints
# what the command would act on, so nothing is started and nothing touches
# the network.

my $harness = <<'PERL';
use strict;
use warnings;
use JSON::MaybeXS qw( encode_json );
use Langertha::Knarr::CLI;
use Langertha::Knarr::CLI::Cmd::Start;
use Langertha::Knarr::CLI::Cmd::Check;
use Langertha::Knarr::CLI::Cmd::Models;
use Langertha::Knarr::CLI::Cmd::Init;
use Langertha::Knarr::CLI::Cmd::Container;
no warnings 'redefine';
for my $cmd (qw( Start Check Models Init )) {
  no strict 'refs';
  *{"Langertha::Knarr::CLI::Cmd::${cmd}::execute"} = sub {
    my ( $self, $args, $chain ) = @_;
    my %seen = ( cmd => lc $cmd, args => $args );
    $seen{config}  = $self->can('config_file')
      ? $self->config_file($chain) : $chain->[0]->config;
    $seen{verbose} = ( $self->can('verbose_enabled')
      ? $self->verbose_enabled($chain) : $chain->[0]->verbose ) ? 1 : 0;
    for my $opt (qw( from_env log_file log_dir trace_name port host format env_file output )) {
      $seen{$opt} = $self->$opt if $self->can($opt);
    }
    print encode_json( \%seen );
  };
}
Langertha::Knarr::CLI->new_with_cmd;
PERL

sub knarr {
  my @argv = @_;
  local $ENV{KNARR_DEBUG} = 0;
  my ( $out, $err, $exit ) = capture {
    system $^X, ( map { '-I'.$_ } grep { !ref } @INC ), '-e', $harness, '--', @argv;
  };
  my $got = $exit == 0 ? eval { decode_json($out) } : undef;
  return ( $got, $err, $exit );
}

sub run_ok {
  my ( $argv, $expect, $name ) = @_;
  my ( $got, $err, $exit ) = knarr(@$argv);
  is( $exit, 0, $name.': exits cleanly' ) or diag $err;
  is( $got, $expect, $name );
}

# --- -c / --config and -v / --verbose, before and after the subcommand ---

for my $cmd (qw( start check models )) {
  run_ok( [ '-c', 'a.yaml', $cmd ],
    hash { field cmd => $cmd; field config => 'a.yaml'; etc },
    "knarr -c FILE $cmd" );
  run_ok( [ $cmd, '-c', 'b.yaml' ],
    hash { field config => 'b.yaml'; etc },
    "knarr $cmd -c FILE" );
  run_ok( [ $cmd, '--config', 'c.yaml' ],
    hash { field config => 'c.yaml'; etc },
    "knarr $cmd --config FILE" );
  run_ok( [ $cmd, '--config=d.yaml' ],
    hash { field config => 'd.yaml'; etc },
    "knarr $cmd --config=FILE" );
  run_ok( [ $cmd ],
    hash { field config => './knarr.yaml'; field verbose => 0; etc },
    "knarr $cmd: default config, not verbose" );
  run_ok( [ '-v', $cmd ],
    hash { field verbose => 1; etc },
    "knarr -v $cmd" );
  run_ok( [ $cmd, '-v' ],
    hash { field verbose => 1; etc },
    "knarr $cmd -v" );
  run_ok( [ $cmd, '--verbose', '-c', 'e.yaml' ],
    hash { field verbose => 1; field config => 'e.yaml'; etc },
    "knarr $cmd --verbose -c FILE" );
}

run_ok( [ '-c', 'outer.yaml', 'check', '-c', 'inner.yaml' ],
  hash { field config => 'inner.yaml'; etc },
  'the subcommand position wins when -c is given twice' );

run_ok( [ '-v', 'start', '--no-verbose' ],
  hash { field verbose => 0; etc },
  'knarr start --no-verbose overrides a global -v' );

run_ok( [ 'start', '-c', 'p.yaml', '-p', '9090' ],
  hash { field config => 'p.yaml'; field port => [9090]; etc },
  'documented: knarr start -c production.yaml -p 9090' );

# --- dashed long options (as documented in bin/knarr) ---

run_ok( [ 'start', '--from-env', '--log-file', 'x.jsonl' ],
  hash { field from_env => 1; field log_file => 'x.jsonl'; etc },
  'knarr start --from-env --log-file X' );
run_ok( [ 'start', '--from-env', '--log-dir', 'logs', '--trace-name', 'tn' ],
  hash { field from_env => 1; field log_dir => 'logs'; field trace_name => 'tn'; etc },
  'knarr start --from-env --log-dir X --trace-name Y' );
run_ok( [ 'start', '--from-env', '--log-file=y.jsonl' ],
  hash { field log_file => 'y.jsonl'; etc },
  'knarr start --from-env --log-file=X' );
run_ok( [ 'start', '--log_file', 'z.jsonl', '--from_env' ],
  hash { field from_env => 1; field log_file => 'z.jsonl'; etc },
  'underscore spellings keep working' );
run_ok( [ 'init', '--env-file', '/nonexistent/.env', '-o', 'out.yaml' ],
  hash { field env_file => ['/nonexistent/.env']; field output => 'out.yaml'; etc },
  'knarr init --env-file X' );

# Option values are never rewritten, even when they look dashed.
run_ok( [ 'start', '-n', 'my-trace-name', '-c', 'my-config.yaml' ],
  hash { field trace_name => 'my-trace-name'; field config => 'my-config.yaml'; etc },
  'dashes in option values are preserved' );

# --- knarr container: the Docker image's own start (k46) ---

run_ok( [ 'container' ],
  hash { field cmd => 'start'; field from_env => 1; field port => [ 8080, 11434 ];
    field host => '0.0.0.0'; etc },
  'knarr container runs start --from-env -p 8080 -p 11434' );
run_ok( [ '-c', 'k.yaml', 'container' ],
  hash { field cmd => 'start'; field config => 'k.yaml'; etc },
  'knarr -c FILE container keeps the global config' );

# --- start --help describes what the options do (k46) ---
{
  my ( $out, $err, $exit ) = capture {
    system $^X, ( map { '-I'.$_ } grep { !ref } @INC ), '-e',
      'use Langertha::Knarr::CLI; Langertha::Knarr::CLI->new_with_cmd', '--', 'start', '--help';
  };
  ( my $help = $out . $err ) =~ s/\s+/ /g;   # usage wraps long lines
  like( $help, qr/-p --port.*replaces the config listen:/, 'start --help: -p replaces listen:' );
  like( $help, qr/-H --host.*no effect without -p/, 'start --help: -H needs -p' );
  like( $help, qr/-w --workers: Int Number of worker processes.*default: the config workers:, else KNARR_WORKERS, else 1, no fork/,
    'start --help: -w forks worker processes (k51)' );
  unlike( $help, qr/without effect/, 'start --help: no "without effect" left' );
  unlike( $help, qr/default: 8080 11434/, 'start --help: no wrong -p default' );
}

# --- unknown options still fail loudly ---
{
  my ( $got, $err, $exit ) = knarr( 'start', '--no-such-option' );
  isnt( $exit, 0, 'unknown option still exits non-zero' );
  like( $err, qr/Unknown option/, 'unknown option still reported' );
}

done_testing;
