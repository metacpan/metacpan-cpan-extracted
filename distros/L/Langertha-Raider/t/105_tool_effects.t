#!/usr/bin/env perl
# ABSTRACT: Static effect classes per built-in tool, shown by config explain (k123)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Langertha::Engine::OpenAI;
use Langertha::Raider;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::HallTools qw( build_hall_tools_server );
use Langertha::Raider::ToolEffects;

# ADR 0005: what a tool can do (read, write, network, code, message) is one
# static table for the built-in tools -- information only, nothing is
# enforced. Tools the table does not know are "unknown", never guessed from
# their names. Offline.

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

my $table = 'Langertha::Raider::ToolEffects';
my %valid = map { $_ => 1 } $table->classes;

sub app {
  my ( %args ) = @_;
  return Langertha::Raider::CLI->new(
    root    => tempdir(CLEANUP => 1),
    engine  => 'openai',
    api_key => 'test',
    model   => 'gpt-4o-mini',
    trace   => 0,
    %args,
  );
}

subtest 'the table only names the five classes' => sub {
  for my $name ($table->tool_names) {
    my $fx = $table->effects_for($name);
    is([ grep { !$valid{$_} } @$fx ], [], $name.': valid classes');
  }
  is($table->effects_for('write_file'), ['write'], 'write_file');
  is($table->effects_for('read_file'),  ['read'],  'read_file: read and write are separate');
  is($table->effects_for('bash'),       ['code'],  'bash');
  is($table->effects_for('perl_check'), ['code'],  'perl -c runs BEGIN/use');
  is($table->effects_for('perl_cpanm'), [qw( network code )], 'perl_cpanm');
  is($table->effects_for('web_fetch'),  ['network'], 'web_fetch');
  is($table->effects_for('telegram_reply'), ['message'], 'hall message tool');
  is($table->effects_for('raider_pause'), [], 'pure control flow: none, but known');
  is($table->effects_for('nope'), undef, 'not in the table: undef');
  my $copy = $table->effects_for('bash');
  push @$copy, 'write';
  is($table->effects_for('bash'), ['code'], 'callers get a copy');
};

subtest 'every built-in tool of the active tool set has a class' => sub {
  my $app = app(perl => 1);
  my @names = map { $_->name } $app->_mounted_tools;
  ok(scalar(@names) >= 8, 'stock + perl tools are mounted') or diag "@names";
  is([ grep { !defined $table->effects_for($_) } @names ], [], 'no mounted built-in tool without an effect class');

  my $hall = build_hall_tools_server(socket => '/nonexistent');
  is([ grep { !defined $table->effects_for($_->name) } @{ $hall->tools } ], [], 'hall tools have classes');
};

subtest 'every raider self-tool has a class' => sub {
  my $engine = Langertha::Engine::OpenAI->new(api_key => 'x', model => 'gpt-4o-mini');
  my $raider = Langertha::Raider->new(
    engine         => $engine,
    raider_mcp     => 1,
    engine_catalog => { other => $engine },
  );
  my @names = map { $_->{name} } @{ $raider->_self_tool_definitions };
  is(scalar(@names), 8, 'all eight self-tools offered');
  is([ grep { !defined $table->effects_for($_) } @names ], [], 'all have a class');
};

subtest 'explain_config carries the tools with source and classes' => sub {
  my $report = app()->explain_config;
  my %tool = map { $_->{name} => $_ } @{ $report->{tools} };
  is($tool{write_file}, { name => 'write_file', source => 'engine:1', effects => ['write'] }, 'files server is engine:1');
  is($tool{bash}{source}, 'engine:2', 'bash is the second server');
  is($tool{bash}{effects}, ['code'], 'bash: code');
  is($tool{web_fetch}{effects}, ['network'], 'web');
  ok(!exists $tool{perl_eval}, 'no perl tools unless granted');
  is([ grep { !defined $_->{effects} } @{ $report->{tools} } ], [], 'no unknown among the built-ins');

  my $perl = app(perl => 1)->explain_config;
  my %ptool = map { $_->{name} => $_ } @{ $perl->{tools} };
  is($ptool{perl_eval}{effects}, ['code'], 'perl_eval: code');
  is($ptool{perl_cpanm}{source}, 'engine:4', 'perl server is engine:4');
};

{
  package K123::App;
  use Moose;
  extends 'Langertha::Raider::CLI';
  sub _tool_effects_class { 'K123::Table' }
  __PACKAGE__->meta->make_immutable;
  package K123::Table;
  sub effects_for { $_[1] eq 'write_file' ? undef : Langertha::Raider::ToolEffects->effects_for($_[1]) }
}

subtest 'a tool the table does not know is unknown, whatever its name' => sub {
  my $app = K123::App->new(root => tempdir(CLEANUP => 1), engine => 'openai', api_key => 'test', trace => 0);
  my %tool = map { $_->{name} => $_ } @{ $app->explain_config->{tools} };
  ok(exists $tool{write_file} && !defined $tool{write_file}{effects}, 'unknown = undef effects');
  is($tool{read_file}{effects}, ['read'], 'others keep theirs');
};

subtest 'config explain prints the classes next to the source' => sub {
  my $report = app(perl => 1)->explain_config;
  push @{ $report->{tools} }, { name => 'weird', source => 'engine:9', effects => undef },
    { name => 'raider_wait', source => 'raider', effects => [] };
  my $buf = '';
  open my $fh, '>', \$buf or die $!;
  Langertha::Raider::CLI::Output->new(out => $fh, color => 0)->config_report($report);
  close $fh;
  like($buf, qr/^tools:  /m, 'tools section');
  like($buf, qr/^  write_file\s+engine:1\s+write$/m, 'write_file');
  like($buf, qr/^  bash\s+engine:2\s+code$/m, 'bash');
  like($buf, qr/^  perl_cpanm\s+engine:4\s+network, code$/m, 'two classes');
  like($buf, qr/^  weird\s+engine:9\s+unknown$/m, 'unknown');
  like($buf, qr/^  raider_wait\s+raider\s+none$/m, 'known without effect');
};

done_testing;
