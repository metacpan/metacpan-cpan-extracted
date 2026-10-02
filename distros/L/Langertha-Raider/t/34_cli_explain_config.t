use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::CLI;

# explain_config: every effective setting with its source, command-line
# flags included; `raider config explain` prints it without side effects.

clear_engine_env();

my $YML = {
  temperature => 0.2,
  skills      => ['claude'],
  default     => { model => 'yml-model' },
  openai      => { temperature => 0.5 },
  anthropic   => { model => 'other' },
};

sub root_with {
  my ( $yml ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  $root->child('.raider.yml')->spew_utf8(YAML::PP->new->dump_string($yml));
  return "$root";
}

sub entry {
  my ( $report, $key ) = @_;
  my @hits = grep { $_->{key} eq $key } @{ $report->{values} };
  return wantarray ? @hits : $hits[0];
}

subtest 'file layers only' => sub {
  local $ENV{OPENAI_API_KEY} = 'sk-secret';
  my $report = Langertha::Raider::CLI->new(root => root_with($YML))->explain_config;
  is($report->{engine}, 'openai', 'engine picked from the environment');
  like(entry($report, 'engine'), { value => 'openai', source => 'env OPENAI_API_KEY' }, 'engine source');
  like(entry($report, 'model'), { value => 'yml-model', source => '.raider.yml default:',
    applies_to => 'engine' }, 'model from default:');
  like(entry($report, 'temperature'), { value => 0.5, source => '.raider.yml openai:',
    shadowed => ['.raider.yml'] }, 'engine section over top level');
  like(entry($report, 'api_key'), { value => '(set)', source => 'env OPENAI_API_KEY' }, 'key source');
  like([ entry($report, 'skills') ], [ { value => ['claude'], source => '.raider.yml', merged => 1 } ],
    'skills layer');
  like($report->{ignored}, [ { key => 'anthropic' } ], 'inactive section reported');
  unlike(YAML::PP->new->dump_string($report), qr/sk-secret/, 'no secret in the report');
};

subtest 'flags as sources' => sub {
  my $app = Langertha::Raider::CLI->new(
    root              => root_with($YML),
    engine            => 'openai',
    model             => 'flag-model',
    api_key           => 'sk-flag',
    perl              => 1,
    pack_names        => ['polite'],
    engine_options    => { seed => 4, temperature => 0.9 },
    cli_skill_sources => [ { type => 'file', path => 'AGENTS.md' } ],
  );
  my $report = $app->explain_config;
  like(entry($report, 'engine'), { source => '-e' }, '-e');
  like(entry($report, 'model'), { value => 'flag-model', source => '-m',
    shadowed => ['.raider.yml default:'] }, '-m over .raider.yml');
  like(entry($report, 'api_key'), { value => '(set)', source => '-k' }, '-k, value hidden');
  like(entry($report, 'seed'), { value => 4, source => '-o', applies_to => 'engine' }, '-o');
  like(entry($report, 'temperature'), { value => 0.9, source => '-o',
    shadowed => [ '.raider.yml openai:', '.raider.yml' ] }, '-o over both layers');
  like(entry($report, 'packs'), { value => ['polite'], source => '--pack', applies_to => 'raider' }, '--pack');
  like(entry($report, 'perl'), { value => 1, source => '--perl' }, '--perl');
  like([ entry($report, 'skills') ], [
    { source => '.raider.yml' },
    { source => '--claude/--openai/--skills', value => [ { path => 'AGENTS.md' } ] },
  ], 'skill flags listed after the file layers');
  unlike(YAML::PP->new->dump_string($report), qr/sk-flag/, 'no secret in the report');
};

subtest '-o model= and the engine default' => sub {
  my $root = root_with({});
  my $opt = Langertha::Raider::CLI->new(root => $root, engine => 'openai',
    engine_options => { model => 'opt-model' })->explain_config;
  like(entry($opt, 'model'), { value => 'opt-model', source => '-o' }, '-o model=');
  my $none = Langertha::Raider::CLI->new(root => $root, engine => 'openai')->explain_config;
  like(entry($none, 'model'), { value => 'gpt-4o-mini', source => 'default' }, 'engine default');
  is(entry($none, 'api_key'), undef, 'no key anywhere: no entry');
};

subtest 'raider config explain' => sub {
  my $root = root_with($YML);
  my $before = path($root)->child('.raider.yml')->slurp_utf8;
  my $repo = path(__FILE__)->absolute->parent->parent;
  my @cmd = ($^X, '-I'.$repo->child('lib'), $repo->child('bin', 'raider'),
    'config', 'explain', '--no-color', '-r', $root, '-e', 'openai', '-m', 'flag-model',
    '-k', 'sk-flag', '--claude');
  my $out = `@{[ join ' ', map { "'$_'" } @cmd ]} 2>&1 </dev/null`;
  is($?, 0, 'exits cleanly') or diag $out;
  like($out, qr/^\s+model\s+flag-model\s+\(from -m, overrides \.raider\.yml default:; engine\)$/m,
    'model line names the flag');
  like($out, qr/ignored anthropic: section of an inactive engine/, 'ignored section shown');
  unlike($out, qr/sk-flag/, 'key not printed');
  is(path($root)->child('.raider.yml')->slurp_utf8, $before, '--claude not persisted');

  my $bad = `'$^X' '-I@{[ $repo->child('lib') ]}' '@{[ $repo->child('bin', 'raider') ]}' config nope 2>&1`;
  isnt($?, 0, 'unknown config subcommand fails');
  like($bad, qr/Usage: raider config explain/, 'with usage');
};

done_testing;
