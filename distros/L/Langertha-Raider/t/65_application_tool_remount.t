#!/usr/bin/env perl
# ABSTRACT: /pack perl after the tool servers were built remounts them (ADR 0005, k100)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;

clear_engine_env();
delete @ENV{ grep { /^RAIDER_HALL_|^RAIDER_PACK_DIRS$/ } keys %ENV };

sub app {
  my ( %args ) = @_;
  return Langertha::Raider::CLI->new(
    root    => tempdir(CLEANUP => 1),
    engine  => 'openai',
    api_key => 'test',
    model   => 'gpt-4o-mini',
    trace   => 0,
    detect  => 0,
    %args,
  );
}

sub commands {
  my ( $app ) = @_;
  open my $fh, '>', \my $buf or die $!;
  return Langertha::Raider::CLI::Commands->new(
    app    => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0),
  );
}

# The tool names the engine's MCP clients answer with -- what the raider
# gathers for the model on its next raid.
sub engine_tools {
  my ( $app ) = @_;
  my @names;
  for my $mcp (@{ $app->raider->engine->mcp_servers }) {
    $app->loop->await($mcp->initialize);
    push @names, map { $_->{name} } @{ $app->loop->await($mcp->list_tools)->get };
  }
  return \@names;
}

sub described { [ $_[0]->raider->mission =~ /^  - (\w+)\(/mg ] }

sub has_perl { scalar grep { $_ eq 'perl_eval' } @{ $_[0] } }

subtest '/pack on perl after the raider was built mounts the Perl tools' => sub {
  my $app = app();
  ok(!has_perl(engine_tools($app)), 'built without the Perl tools');
  ok(!$app->perl_tools_enabled, 'not granted');

  commands($app)->dispatch('/pack on perl');
  ok($app->perl_tools_enabled, 'grant reports perl on');
  is($app->explain_config->{perl_tools}{enabled}, 1, 'explain_config agrees');
  ok(has_perl(engine_tools($app)), 'engine now answers with perl_eval');
  ok(has_perl(described($app)), 'the raider mission describes perl_eval');
  is(described($app), engine_tools($app), 'prompt and catalogue stay one tool set');
  is(scalar @{ $app->_tool_servers }, 4, 'files, bash, web + perl');
};

subtest '/pack off perl unmounts them again' => sub {
  my $app = app(pack_names => ['perl']);
  ok(has_perl(engine_tools($app)), 'built with the Perl tools');

  commands($app)->dispatch('/pack off perl');
  ok(!$app->perl_tools_enabled, 'grant reports perl off');
  ok(!has_perl(engine_tools($app)), 'engine no longer answers with perl_eval');
  ok(!has_perl(described($app)), 'mission no longer describes it');
  is(described($app), engine_tools($app), 'one tool set');

  commands($app)->dispatch('/pack perl');
  ok(has_perl(engine_tools($app)), 'toggled back on: mounted again');
  is(scalar(grep { $_ eq 'perl_eval' } @{ engine_tools($app) }), 1, 'mounted once, not twice');
};

subtest 'an unchanged grant leaves the mounted servers alone' => sub {
  my $app = app(perl => 1);
  $app->raider;
  my @before = @{ $app->_tool_servers };
  commands($app)->dispatch('/pack off perl');
  ok($app->perl_tools_enabled, '--perl keeps the grant');
  is($app->_tool_servers, \@before, 'same server objects');
};

subtest 'a pending continuation re-gathers its tools' => sub {
  my $app = app();
  my $raider = $app->raider;
  $raider->_tools_dirty(0);
  commands($app)->dispatch('/pack on perl');
  ok($raider->_tools_dirty, 'raider told to re-gather on its next iteration');
};

done_testing;
