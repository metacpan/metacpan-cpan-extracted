#!/usr/bin/env perl
# ABSTRACT: provider: ALIAS on a hall raider entry -- spawned with --provider ALIAS, never a host, never with engine (ADR 0007, k23)

use strict;
use warnings;
use Test2::V0;
use JSON::PP ();
use Path::Tiny;
use File::Temp qw( tempdir );
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
my $HOME = isolate_home();
use Test::Raider::Hall qw( fake_hall run_spawns );
use Langertha::Raider::CLI::Main;
use Langertha::Raider::Hall::CLI;

clear_engine_env();

# A stored binding, as raider provider add writes it; the hall only asks
# whether the alias is there, the spawned raider verifies the rest.
path($HOME)->child('.raider')->mkpath;
path($HOME)->child( '.raider', 'config.yml' )->spew_utf8( YAML::PP->new->dump_string({
  providers => {
    acme => {
      origin         => 'https://provider.example:443',
      issuer         => 'https://provider.example',
      auth           => ['api_key'],
      credential_env => 'ACME_API_KEY',
      allow_internal => 0,
      pinned_at      => '2026-10-25T00:00:00Z',
      fingerprint    => 'x',
    },
  },
}) );

# A stand-in for bin/raider that records its argv.
my $FAKE = <<'PERL';
use strict;
use warnings;
use JSON::PP;
open my $a, '>>', $ENV{FAKE_ARGV_LOG} or die $!;
print $a JSON::PP->new->canonical->encode([ @ARGV ]), "\n";
close $a;
$| = 1;
print JSON::PP->new->canonical->encode({ version => 1, type => 'run.finished', seq => 1, time => time,
  status => 'completed', response => 'ok' }), "\n";
exit 0;
PERL

sub runs {
  my $log = path( $ENV{FAKE_ARGV_LOG} );
  return [] unless -e $log;
  return [ map { JSON::PP->new->decode($_) } $log->lines ];
}

# The options before the -- of an argv.
sub options_of {
  my ( $argv ) = @_;
  my @o;
  for (@$argv) { last if $_ eq '--'; push @o, $_ }
  return \@o;
}

# A spawn the hall refuses: an error, no raider, a line in the slot log.
sub refused {
  my ( $yml, $match, $name ) = @_;
  my ( $hall, $tmp ) = fake_hall( script => $FAKE, yml => $yml );
  my $res = $hall->spawn( name => 'ivar', mission => 'go' );
  like( $res->{error}, $match, $name.': the spawn answers with the error' );
  ok( !$res->{id}, $name.': no run' );
  is( scalar keys %{ $hall->raiders }, 0, $name.': no raider running' );
  is( runs(), [], $name.': the raider was never started' );
  my $log = $tmp->child( '.raider-hall', 'logs', 'ivar.log' );
  like( ( -e $log ? $log->slurp_utf8 : '' ), qr/^\[hall\] raider ivar refused: .*; mission not run$/m,
    $name.': noted in the slot log' );
}

subtest 'provider: ALIAS is passed as --provider ALIAS, with --model, without --engine' => sub {
  my ( $hall ) = fake_hall( script => $FAKE,
    yml => "raiders:\n  ivar: { provider: acme, model: example-model, persona: caveman }\n" );
  my @done = run_spawns( $hall, 1, { name => 'ivar', mission => 'go' } );
  is( $done[0]{status}, 'completed', 'the raider ran' );
  my $argv = runs()->[0];
  my $opts = options_of($argv);
  my ($i) = grep { $opts->[$_] eq '--provider' } 0 .. $#$opts;
  ok( defined $i, '--provider is passed' );
  is( $opts->[ $i + 1 ], 'acme', 'with the alias' );
  ok( !( grep { $_ eq '--engine' || $_ eq '-e' } @$opts ), 'no --engine' );
  ok( !( grep { $_ eq '--allow-internal' } @$opts ), 'no --allow-internal' );
  ok( ( grep { $_ eq '--model' } @$opts ), '--model next to it' );

  # The raider CLI takes that argv as it is: --provider ALIAS with --model
  # and the hall's -o preferred_lib_target is no usage error.
  my $main = Langertha::Raider::CLI::Main->new;
  my ($opt) = $main->parse_options(@$argv);
  is( $opt->{provider}, 'acme', 'raider CLI: --provider' );
  is( $opt->{model}, 'example-model', 'raider CLI: --model' );
  is( $main->provider_usage_error($opt), undef, 'raider CLI: no usage error' );
};

subtest 'a host or https origin is refused' => sub {
  refused( "raiders:\n  ivar: { provider: $_ }\n", qr/is no alias/, $_ )
    for 'provider.example', 'provider.example:8443', "'https://provider.example'";
};

subtest 'provider and engine on one entry are refused' => sub {
  refused( "raiders:\n  ivar: { provider: acme, engine: anthropic }\n",
    qr/provider and engine exclude each other/, 'provider + engine' );
};

subtest 'an alias that is not stored is refused, not fetched as a host' => sub {
  refused( "raiders:\n  ivar: { provider: intranet }\n",
    qr/provider alias 'intranet' is not stored in .*config\.yml/, 'unknown alias' );
};

subtest 'an entry without provider is unchanged' => sub {
  my ( $hall ) = fake_hall( script => $FAKE, yml => "raiders:\n  ivar: { engine: mock }\n" );
  run_spawns( $hall, 1, { name => 'ivar', mission => 'go' } );
  my $opts = options_of( runs()->[0] );
  ok( !( grep { $_ eq '--provider' } @$opts ), 'no --provider' );
  ok( ( grep { $_ eq '--engine' } @$opts ), '--engine as before' );
};

# --- raider hall add-raider / init --provider ---

my $orig_cwd = path('.')->absolute;

sub run_hall_cli_in {
  my ( $dir, @argv ) = @_;
  chdir $dir or die "chdir $dir: $!";
  my $out = '';
  my ( $rv, $died );
  {
    local *STDOUT;
    open STDOUT, '>', \$out or die $!;
    $died = dies { $rv = Langertha::Raider::Hall::CLI->main(@argv) };
  }
  chdir $orig_cwd or die "chdir $orig_cwd: $!";
  return ( $rv, $out, $died );
}

sub hall_yml { YAML::PP->new->load_string( path( $_[0] )->child('.raider-hall.yml')->slurp_utf8 ) }

sub hall_with_bjorn {
  my $tmp = tempdir( CLEANUP => 1 );
  path($tmp)->child('.raider-hall.yml')->spew_utf8( YAML::PP->new->dump({ raiders => { Bjorn => {} } }) );
  return $tmp;
}

subtest 'add-raider --provider ALIAS writes provider, no engine' => sub {
  my $tmp = hall_with_bjorn();
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, 'add-raider', 'Ivar', '--provider', 'acme', '--model', 'example-model' );
  is( $died, undef, 'lives' );
  my $entry = hall_yml($tmp)->{raiders}{Ivar};
  is( $entry->{provider}, 'acme', 'provider' );
  is( $entry->{model}, 'example-model', 'model' );
  ok( !exists $entry->{engine}, 'no engine' );
};

subtest 'add-raider refuses a host and --provider with --engine, and writes nothing' => sub {
  for my $case (
    [ [ '--provider', 'provider.example' ],                 qr/^raider hall add-raider: provider 'provider\.example' is no alias/ ],
    [ [ '--provider', 'https://provider.example' ],         qr/is no alias/ ],
    [ [ '--provider', 'acme', '--engine', 'anthropic' ],    qr/^raider hall add-raider: provider and engine exclude each other/ ],
  ) {
    my $tmp = hall_with_bjorn();
    my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, 'add-raider', 'Ivar', @{ $case->[0] } );
    like( $died, $case->[1], join(' ', @{ $case->[0] }) );
    ok( !exists hall_yml($tmp)->{raiders}{Ivar}, 'nothing written' );
  }
};

subtest 'init --provider ALIAS writes provider; a host is refused' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my ( $rv, $out, $died ) = run_hall_cli_in( $tmp, 'init', '--name', 'Ivar', '--provider', 'acme' );
  is( $died, undef, 'lives' );
  is( hall_yml($tmp)->{raiders}{Ivar}{provider}, 'acme', 'provider' );
  ok( !exists hall_yml($tmp)->{raiders}{Ivar}{engine}, 'no engine' );

  my $host = tempdir( CLEANUP => 1 );
  ( $rv, $out, $died ) = run_hall_cli_in( $host, 'init', '--name', 'Ivar', '--provider', 'provider.example' );
  like( $died, qr/^raider hall init: provider 'provider\.example' is no alias/, 'host refused' );
  ok( !-e path($host)->child('.raider-hall.yml'), 'no file written' );

  my $both = tempdir( CLEANUP => 1 );
  ( $rv, $out, $died ) = run_hall_cli_in( $both, 'init', '--name', 'Ivar', '--provider', 'acme', '--engine', 'openai' );
  like( $died, qr/provider and engine exclude each other/, 'with --engine refused' );
  ok( !-e path($both)->child('.raider-hall.yml'), 'no file written' );
};

done_testing;
