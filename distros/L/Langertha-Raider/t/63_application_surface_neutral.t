#!/usr/bin/env perl
# ABSTRACT: The application service names no CLI flags and no CLI in its persona; the CLI puts them in

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::Application;
use Langertha::Raider::CLI;

clear_engine_env();

my $root = tempdir(CLEANUP => 1);
my %args = (
  root              => $root,
  engine            => 'openai',
  model             => 'mm',
  api_key           => 'kk',
  engine_options    => { temperature => 0.1, packs => 'caveman' },
  pack_names        => ['git-guru'],
  no_pack_names     => ['caveman'],
  perl              => 1,
  detect            => 0,
  cli_skill_sources => [ { type => 'dir', path => 'sk' } ],
);
my $json = JSON::MaybeXS->new(canonical => 1, allow_blessed => 1);
sub sources {
  my ( $app ) = @_;
  my $e = $app->explain_config;
  return join ' ', ( map { $_->{source}, @{ $_->{shadowed} } } @{ $e->{values} } ), $e->{detection},
    $e->{perl_tools}{reason}, $json->encode($e->{packs});
}

subtest 'Application: constructor arguments by name' => sub {
  my $app = Langertha::Raider::Application->new(%args);
  my $s = sources($app);
  unlike($s, qr/(?:\A|\s|")-[a-zA-Z]\b|--[a-z]/, 'no command-line flag in the report');
  like($s, qr/\bengine\b.*\bmodel\b.*\bapi_key\b/, 'engine, model and api_key named as arguments');
  like($s, qr/\bpack_names\b/, 'pack_names');
  like($s, qr/\bno_pack_names\b/, 'no_pack_names');
  like($s, qr/\bcli_skill_sources\b/, 'the skill sources');
  is($app->perl_tools_grant->{reason}, 'perl', 'perl tools granted by perl');
  is([ $app->detection_state ], [ 0, 'no_detect' ], 'detection off by detect => 0');
  is(Langertha::Raider::Application->new(root => $root, mission => 'M')->mission_source, 'mission',
    'instructions from mission');
  is([ Langertha::Raider::Application->new(root => $root, bare => 1)->detection_state ], [ 0, 'bare' ], 'bare');

  my $mission = Langertha::Raider::Application->new(root => $root, engine => 'openai', api_key => 'x')->mission;
  unlike($mission, qr/\bCLI\b/, 'the persona does not say CLI');
  like($mission, qr/\AYou are Langertha, viking shield-maiden\. Autonomous agent/, 'but is Langertha');
  like($mission, qr/User\nanswers in the next turn\.\n/, 'and ends the turn without a CLI');
};

subtest 'CLI: its flags and its persona' => sub {
  my $app = Langertha::Raider::CLI->new(%args, trace => 0);
  my $s = sources($app);
  like($s, qr/(?:\A|\s)-e\b.*\s-m\b.*\s-k\b/, '-e, -m, -k');
  like($s, qr/--pack\b/, '--pack');
  like($s, qr/--no-pack\b/, '--no-pack');
  like($s, qr/--claude\/--openai\/--skills/, 'the skill flags');
  like($s, qr/(?:\A|\s)-o\b/, '-o');
  is($app->perl_tools_grant->{reason}, '--perl', 'perl tools by --perl');
  is([ $app->detection_state ], [ 0, '--no-detect' ], '--no-detect');
  is(Langertha::Raider::CLI->new(root => $root, mission => 'M')->mission_source, '-M', '-M');

  my $mission = Langertha::Raider::CLI->new(root => $root, engine => 'openai', api_key => 'x')->mission;
  like($mission, qr/\AYou are Langertha, viking shield-maiden\. Autonomous CLI agent on user's\nlocal machine\. CLI name: "raider"\./,
    'the CLI persona');
  like($mission, qr/Task done: plain text reply\. CLI\nloops back to user\.\n/, 'the CLI loops back');
};

done_testing;
