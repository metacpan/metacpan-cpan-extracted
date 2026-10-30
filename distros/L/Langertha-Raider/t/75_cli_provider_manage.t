#!/usr/bin/env perl
# ABSTRACT: raider provider list, show and remove ALIAS (--yes), the aliases in config explain and the REPL (k150)
use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
my $home = isolate_home();
clear_engine_env();

use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::REPL;

# A person at a terminal.
package My::Terminal {
  use Moose;
  extends 'Langertha::Raider::CLI::Provider';
  has '+interactive' => ( default => 1 );
  __PACKAGE__->meta->make_immutable;
}

our $PROVIDER = 'Langertha::Raider::CLI::Provider';

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub provider_class { $main::PROVIDER }
  __PACKAGE__->meta->make_immutable;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; decode_utf8($buf) } );
}

my $root = Path::Tiny->tempdir;

sub main_run {
  my ( $answer, @argv ) = @_;
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = My::Main->new(
    output => Langertha::Raider::CLI::Output->new( out => $out, color => 0 ),
    err    => $err,
    in     => do { open my $in, '<', \( $answer // '' ) or die $!; $in },
  )->run(@argv);
  return ( $exit, $read_out->(), $read_err->() );
}

my $config_file = path( $home, '.raider', 'config.yml' );
sub stored { $config_file->exists ? YAML::PP->new->load_string( $config_file->slurp_utf8 ) : {} }

my $FP = 'a' x 64;
sub seed {
  $config_file->parent->mkpath;
  $config_file->spew_utf8( YAML::PP->new->dump_string({
    default   => { model => 'gpt-4o' },
    providers => {
      acme => {
        origin => 'https://provider.example:443', issuer => 'https://provider.example',
        auth => ['api_key'], credential_env => 'ACME_API_KEY', allow_internal => 0,
        pinned_at => '2026-10-15T09:30:00Z', fingerprint => $FP,
      },
      lab => {
        origin => 'https://knarr.lan:8443', issuer => 'https://knarr.lan:8443',
        auth => [], allow_internal => 1,
        pinned_at => '2026-10-14T08:00:00Z', fingerprint => 'b' x 64,
      },
      broken => 'https://evil.example',
    },
  }) );
}

my $json = JSON::MaybeXS->new( canonical => 1 );

subtest 'list: nothing fetched, sorted, no secret' => sub {
  seed();
  local $ENV{ACME_API_KEY} = 'sk-must-not-show';
  my ( $exit, $out, $err ) = main_run( '', qw( provider list ) );
  is( $exit, 0, 'exit 0' ) or diag $err;
  like( $out, qr/\Aacme\s+https:\/\/provider\.example:443\s+auth: api_key\s+credential: ACME_API_KEY\n/, 'acme first, its pin and variable name' );
  like( $out, qr/^broken\s+unusable: is not a mapping$/m, 'a broken entry says why' );
  like( $out, qr/^lab\s+https:\/\/knarr\.lan:8443\s+auth: none\s+credential: none\s+internal allowed$/m, 'internal is visible' );
  unlike( $out, qr/sk-must-not-show|\Q$FP\E/, 'neither the value nor the fingerprint' );
  is( [ $out =~ /^(\w+)\s/mg ], [qw( acme broken lab )], 'sorted' );

  ( $exit, $out, $err ) = main_run( '', qw( provider list --json ) );
  is( $exit, 0, '--json: exit 0' );
  my $doc = $json->decode($out);
  is( $doc->{status}, 'completed', 'status' );
  is( [ map { $_->{alias} } @{ $doc->{providers} } ], [qw( acme broken lab )], 'one row per alias' );
  is( $doc->{providers}[0], {
    alias => 'acme', origin => 'https://provider.example:443', issuer => 'https://provider.example',
    auth => ['api_key'], credential_env => 'ACME_API_KEY', allow_internal => 0, pinned_at => '2026-10-15T09:30:00Z',
  }, 'the public fields' );
};

subtest 'list: nothing stored' => sub {
  $config_file->remove;
  my ( $exit, $out, $err ) = main_run( '', qw( provider list ) );
  is( $exit, 0, 'exit 0' );
  like( $out, qr/no provider aliases; bind one with: raider provider add ALIAS HOST/, 'says how to start' );
  seed();
};

subtest 'show: every field' => sub {
  my ( $exit, $out, $err ) = main_run( '', qw( provider show acme ) );
  is( $exit, 0, 'exit 0' );
  like( $out, qr/^credential_env\s+ACME_API_KEY$/m, 'variable name' );
  like( $out, qr/^fingerprint\s+\Q$FP\E$/m, 'the pinned fingerprint' );
  like( $out, qr/^allow_internal\s+no$/m, 'allow_internal' );
  ( $exit, $out, $err ) = main_run( '', qw( provider show acme --json ) );
  my $doc = $json->decode($out);
  is( $doc->{provider}{fingerprint}, $FP, '--json: the fingerprint is there' );
  ( $exit, $out, $err ) = main_run( '', qw( provider show nobody ) );
  is( $exit, 2, 'unknown alias: exit 2' );
  like( $err, qr/^raider provider show: no stored alias 'nobody'/, 'says so' );
  ( $exit, $out, $err ) = main_run( '', qw( provider show ) );
  is( $exit, 2, 'no alias: usage' );
  like( $err, qr/^Usage: raider provider show ALIAS/, 'usage line' );
};

subtest 'remove: headless needs --yes, nothing is removed without it' => sub {
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider remove acme ) );
  is( $exit, 1, 'exit 1' );
  like( $err, qr/^raider provider remove: needs a terminal to ask, or --yes; nothing was removed/, 'says why' );
  ok( exists stored()->{providers}{acme}, 'still stored' );
};

subtest 'remove: a person is asked' => sub {
  local $PROVIDER = 'My::Terminal';
  my ( $exit, $out, $err ) = main_run( "n\n", qw( provider remove acme ) );
  is( $exit, 1, 'a no: exit 1' );
  like( $out, qr/Remove the binding 'acme' \(https:\/\/provider\.example:443\) from .*config\.yml\? \[y\/N\] /, 'the question names the origin' );
  ok( exists stored()->{providers}{acme}, 'still stored' );
  ( $exit, $out, $err ) = main_run( "y\n", qw( provider remove acme ) );
  is( $exit, 0, 'a yes: exit 0' ) or diag $err;
  like( $out, qr/removed 'acme'/, 'reported' );
  ok( !exists stored()->{providers}{acme}, 'gone' );
  is( [ sort keys %{ stored()->{providers} } ], [qw( broken lab )], 'the others stay' );
  is( stored()->{default}{model}, 'gpt-4o', 'the rest of the file stays' );
  ok( path( $home, '.raider', 'config.yml.bak' )->exists, 'through the home writer: a backup' );
};

subtest 'remove --yes: without asking; unknown alias; last one drops the key' => sub {
  my ( $exit, $out, $err ) = main_run( '', qw( provider remove lab --yes ) );
  is( $exit, 0, 'exit 0' ) or diag $err;
  is( [ sort keys %{ stored()->{providers} } ], ['broken'], 'removed' );
  ( $exit, $out, $err ) = main_run( '', qw( provider remove lab --yes ) );
  is( $exit, 2, 'already gone: exit 2' );
  like( $err, qr/no stored alias 'lab'/, 'says so' );
  ( $exit, $out, $err ) = main_run( '', qw( provider remove broken --yes ) );
  is( $exit, 0, 'a broken entry can be removed' );
  ok( !exists stored()->{providers}, 'no empty providers: key is left' );
  ( $exit, $out, $err ) = main_run( '', qw( provider remove --yes ) );
  is( $exit, 2, 'no alias: usage' );
  ( $exit, $out, $err ) = main_run( '', qw( provider remove acme --json ) );
  is( $exit, 2, 'a document format: usage' );
};

subtest 'config explain lists the aliases' => sub {
  seed();
  my ( $exit, $out, $err ) = main_run( '', qw( config explain -r ), "$root", qw( -e openai ) );
  is( $exit, 0, 'exit 0' ) or diag $err;
  like( $out, qr/^providers: .*raider provider list/m, 'a providers section' );
  like( $out, qr/^  acme\s+https:\/\/provider\.example:443\s+auth: api_key\s+credential: ACME_API_KEY$/m, 'the alias with its pin' );
  like( $out, qr/^  broken\s+unusable: is not a mapping$/m, 'an unusable one says why' );
  unlike( $out, qr/\Q$FP\E/, 'no fingerprint' );

  my $report = Langertha::Raider::CLI->new( root => "$root", trace => 0, engine => 'openai' )->explain_config;
  is( [ map { $_->{alias} } @{ $report->{providers} } ], [qw( acme broken lab )], 'in the report data' );
};

subtest 'the REPL banner names the stored alias' => sub {
  my %provider = (
    provider_id => 'example-provider', engine_name => 'openai', engine_class => 'Langertha::Engine::OpenAI',
    url => 'https://provider.example/v1', model => 'm1', endpoint => 'chat', auth => 'api',
  );
  my $banner = sub {
    my $app = Langertha::Raider::CLI->new( root => "$root", trace => 0, mission => 'M', api_key => 'k', @_ );
    my ( $fh, $read ) = buffer();
    Langertha::Raider::CLI::REPL->new(
      app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ),
      in => do { open my $in, '<', \'' or die $!; $in },
    )->banner('none');
    return $read->();
  };
  like( $banner->( provider => { %provider, alias => 'acme' } ),
    qr/^provider: acme \(stored alias, example-provider, endpoint chat, https:\/\/provider\.example\/v1\)$/m, 'alias' );
  like( $banner->( provider => { %provider } ),
    qr/^provider: \(example-provider, endpoint chat, https:\/\/provider\.example\/v1\)$/m, 'a plain HOST: no alias' );
  unlike( $banner->( engine => 'openai' ), qr/^provider:/m, 'no provider line without --provider' );
};

done_testing;
