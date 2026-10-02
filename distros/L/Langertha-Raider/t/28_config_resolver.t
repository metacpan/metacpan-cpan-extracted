use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use Langertha::Raider::Config;

# Langertha::Raider::Config: the one reader/writer of .raider.yml, and its
# origin report. Fixtures are shared with t/27_raider_yml_golden.t.

my $fixtures = path(__FILE__)->absolute->parent->child('fixtures', 'raider-yml');

sub config_for {
  my ( $fixture ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  $fixtures->child($fixture)->copy($root->child('.raider.yml')) if defined $fixture;
  return Langertha::Raider::Config->new(root => "$root");
}

sub config_with {
  my ( $content ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  $root->child('.raider.yml')->spew_utf8($content);
  return Langertha::Raider::Config->new(root => "$root");
}

subtest 'missing and empty file' => sub {
  my $none = config_for(undef);
  ok(!$none->file_exists, 'no file');
  is($none->data, {}, 'no data');
  is($none->engine_options('openai'), {}, 'no options');
  is([ $none->skill_specs('openai') ], [], 'no skills');
  is(config_with('')->data, {}, 'empty file is empty config');
};

subtest 'unusable files croak' => sub {
  like(dies { config_for('broken.yml')->data }, qr/Cannot parse .*\.raider\.yml/, 'parse error');
  like(dies { config_with("- a\n- b\n")->data }, qr/top level must be a mapping/, 'list at top level');
};

subtest 'a mapping under a raider key is an error, not an engine section' => sub {
  for my $key (qw( engine no_detect packs perl preferred_lib_target )) {
    like(dies { config_with($key.":\n  x: 1\n")->data },
      qr/Cannot use .*\.raider\.yml: \Q$key\E: configures raider, not an engine section; must not be a mapping/,
      $key.': croaks naming the key');
  }
  my $ok = config_with("skills:\n  claude: 1\ndetect:\n  rust: false\nanthropic:\n  model: x\n");
  ok(lives { $ok->data }, 'skills:, detect: and engine sections may be mappings');
  is($ok->explain('openai')->{ignored}, [ { key => 'anthropic', reason => 'section of an inactive engine' } ],
    'an inactive engine section is still just ignored');
};

subtest 'a mapping under a raider key inside a section is an error too' => sub {
  for my $section (qw( default openai anthropic )) {
    for my $key (qw( engine no_detect packs perl preferred_lib_target )) {
      like(dies { config_with($section.":\n  ".$key.":\n    x: 1\n")->data },
        qr/Cannot use .*\.raider\.yml: \Q$section.$key\E: configures raider; must not be a mapping/,
        $section.'.'.$key.': croaks naming section and key');
    }
  }
  my $ok = config_with("default:\n  skills:\n    claude: 1\n  detect:\n    rust: false\n"
    ."openai:\n  detect:\n    go: false\n  response_format:\n    type: json_object\n");
  ok(lives { $ok->data }, 'skills:, detect: and engine options may be mappings inside a section');
};

subtest 'a parse error carries no YAML::PP location' => sub {
  my $err = dies { config_with("a: [\n")->data };
  like($err, qr/Cannot parse .*\.raider\.yml: \S/, 'names the file');
  unlike($err, qr/YAML.PP/, 'no YAML::PP source location');
};

subtest 'a detailed parse error is summed up on one line' => sub {
  my $err = dies { config_with("a: b\n c: d\n")->data };
  like($err, qr/Cannot parse .*\.raider\.yml: line 2, column 3: expected EOL, got COLON at /,
    'line, column, expected and got');
  $err = dies { config_with("key: \"unterminated\n")->data };
  like($err, qr/Cannot parse .*\.raider\.yml: line 1, column 1: Missing closing quote <"> at EOF at /,
    'line, column and message');
  unlike($err, qr/YAML.PP|\n./, 'one line, no YAML::PP source location');
  $err = dies { config_with("a: 1\na: 2\n")->data };
  like($err, qr/Cannot parse .*\.raider\.yml: Duplicate key 'a' at /, 'a one-line error stays as it is');
};

subtest 'set_model keeps a flat file flat in meaning' => sub {
  my $config = config_for('flat.yml');
  $config->set_model('gpt-4o');
  my $raw = YAML::PP->new->load_string($config->file->slurp_utf8);
  is($raw->{default}, { model => 'gpt-4o' }, 'model written to default:');
  is($config->options('openai'),
    { temperature => 0.2, packs => ['git-guru'], perl => 1, model => 'gpt-4o' },
    'flat keys and model resolve together');
  $config->set_model('gpt-4.1');
  is($config->options('openai')->{model}, 'gpt-4.1', 'second write re-read');
};

subtest 'add_skills appends once, top level' => sub {
  my $config = config_for('skills-default.yml');
  is([ $config->add_skills('openai', 'claude', 'docs') ], ['claude', 'docs'],
    'openai already in default: is skipped');
  is([ $config->add_skills('claude', 'docs') ], [], 'nothing new on repeat');
  my $raw = YAML::PP->new->load_string($config->file->slurp_utf8);
  is($raw->{skills}, ['claude', 'docs'], 'written to top-level skills');
  is($raw->{default}{skills}, ['openai'], 'default: skills untouched');
  is([ $config->profiles('openai') ], ['claude', 'openai'], 'profiles from every layer');

  my $spec = { type => 'dir', path => 'claude' };
  is([ $config->add_skills($spec) ], [$spec], 'dir spec is not confused with the profile');
  is([ $config->add_skills({ %$spec }) ], [], 'same spec only once');
};

subtest 'add_skills keeps a hash skills entry' => sub {
  my $config = config_for('skills-hash.yml');
  $config->add_skills('openai');
  is([ $config->skill_specs('openai') ],
    [ { type => 'dir', path => 'myskills' }, { type => 'file', path => 'AGENTS.md' } ],
    'hash entry kept, profile appended');
};

subtest 'add_skills does not write keys it did not change' => sub {
  my $config = config_with("# keep me\ndefault:\n  model: x\nperl: 1\n");
  is([ $config->add_skills('claude') ], ['claude'], 'added');
  my $raw = YAML::PP->new->load_string($config->file->slurp_utf8);
  is($raw, { default => { model => 'x' }, perl => 1, skills => ['claude'] },
    'no empty default: skills, other keys kept');

  my $same = config_with("default:\n  model: x\n  skills: [claude]\n");
  my $before = $same->file->slurp_utf8;
  is([ $same->add_skills('claude') ], [], 'nothing to add');
  is($same->file->slurp_utf8, $before, 'file untouched');
};

subtest 'writers refuse a broken file' => sub {
  my $config = config_for('broken.yml');
  my $before = $config->file->slurp_utf8;
  ok(dies { $config->set_model('x') }, 'set_model croaks');
  ok(dies { $config->add_skills('claude') }, 'add_skills croaks');
  is($config->file->slurp_utf8, $before, 'file untouched');
};

subtest 'skill_specs merges layers and CLI, deduplicated' => sub {
  my $config = config_with(YAML::PP->new->dump_string({
    skills  => ['claude'],
    default => { skills => ['openai'] },
    openai  => { skills => [ { type => 'dir', path => 'oa' } ] },
  }));
  is([ $config->skill_specs('openai', { type => 'file', path => 'AGENTS.md' }, { type => 'dir', path => 'cli' }) ],
    [
      { type => 'file',   path => 'CLAUDE.md' },
      { type => 'claude', path => '.claude/skills' },
      { type => 'file',   path => 'AGENTS.md' },
      { type => 'dir',    path => 'oa' },
      { type => 'dir',    path => 'cli' },
    ], 'top, default, engine section, then CLI');
  is(scalar(my @s = $config->skill_specs('anthropic')), 3, 'engine section only when active');
};

subtest 'engine key' => sub {
  is(config_for('engine.yml')->engine, 'openai', 'top-level engine');
  is(config_with("default:\n  engine: groq\n")->engine, 'groq', 'engine under default:');
  is(config_with("openai:\n  engine: groq\n")->engine, undef, 'engine inside an engine section ignored');
  is(config_with("engine: [a]\n")->engine, undef, 'non-string engine ignored');
};

subtest 'explain names the source of every value' => sub {
  my $config = config_with(YAML::PP->new->dump_string({
    perl        => 1,
    temperature => 0.1,
    skills      => ['claude'],
    default     => { temperature => 0.3, response_size => 1024 },
    openai      => { temperature => 0.7, engine => 'groq' },
    anthropic   => { response_size => 8192 },
  }));
  my $report = $config->explain('openai');
  is($report->{file}, $config->file->stringify, 'file');
  is($report->{exists}, 1, 'exists');
  is($report->{engine}, 'openai', 'engine');
  is($report->{values}, [
    { key => 'perl', value => 1, source => 'top', shadowed => [], applies_to => 'raider' },
    { key => 'response_size', value => 1024, source => 'default', shadowed => [], applies_to => 'engine' },
    { key => 'temperature', value => 0.7, source => 'openai', shadowed => ['top', 'default'], applies_to => 'engine' },
    { key => 'skills', value => ['claude'], source => 'top', merged => 1, applies_to => 'raider' },
  ], 'values with source, shadowed layers and target');
  is($report->{ignored}, [
    { key => 'openai.engine', reason => 'engine: inside an engine section' },
    { key => 'anthropic', reason => 'section of an inactive engine' },
  ], 'ignored entries');
};

done_testing;
