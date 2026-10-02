use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env );
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::Packs qw( build_packs );

# Pack discovery from <project>/.raider/packs, ~/.raider/packs, the shipped
# share/packs and $RAIDER_PACK_DIRS: precedence, origin, broken pack
# directories, and what `raider config explain` shows. HOME always points
# at a temp dir, never the real one.

clear_engine_env();
delete @ENV{qw( RAIDER_PACK_DIRS RAIDER_HALL_SOCKET ANSI_COLORS_DISABLED )};

sub dir { path(tempdir(CLEANUP => 1)) }

# A pack under $base/.raider/packs/$name; files => { 'pack.yml' => ..., 'SKILL.md' => ... }.
sub pack_in {
  my ( $base, $name, %files ) = @_;
  my $d = $base->child('.raider', 'packs', $name);
  $d->mkpath;
  $d->child($_)->spew_utf8($files{$_}) for sort keys %files;
  return $d;
}

sub app {
  my ( $root, %args ) = @_;
  return Langertha::Raider::CLI->new(
    root    => "$root",
    engine  => 'openai',
    api_key => 'test',
    model   => 'gpt-4o-mini',
    trace   => 0,
    %args,
  );
}

sub entry {
  my ( $list, $name ) = @_;
  my ($e) = grep { $_->{name} eq $name } @$list;
  return $e;
}

sub buffer {
  my $text = '';
  open my $fh, '>', \$text or die;
  return ( $fh, sub { my $t = $text; $text = ''; seek $fh, 0, 0; return $t } );
}

subtest 'shipped packs, nothing at home or in the project' => sub {
  local $ENV{HOME} = dir()->stringify;
  my $packs = build_packs(root => dir());
  my $caveman = $packs->packs_by_name->{caveman} or return fail('caveman shipped');
  is($caveman->origin, 'shipped', 'origin shipped');
  # The dist's share dir: share/ in a checkout (and next to blib/), or the
  # File::ShareDir copy under auto/share/dist/ once built or installed.
  like($caveman->path, qr{/(?:share|auto/share/dist/Langertha-Raider)/packs/caveman\z},
    'from the shipped share dir');
  is($packs->skipped_packs, [], 'nothing skipped');
};

subtest 'home packs add to and override shipped ones' => sub {
  my $home = dir();
  local $ENV{HOME} = "$home";
  pack_in($home, 'home-only', 'SKILL.md' => "Home only\n");
  pack_in($home, 'caveman', 'SKILL.md' => "Home caveman\n", 'pack.yml' => "exclusive_group: persona\n");

  my $packs = build_packs(root => dir());
  my $only = $packs->packs_by_name->{'home-only'} or return fail('home pack loaded');
  is($only->origin, 'home', 'new name: origin home');
  is($only->exclusive_group, 'power', 'pack.yml is optional');
  my $caveman = $packs->packs_by_name->{caveman};
  is($caveman->origin, 'home', 'same name: home wins over shipped');
  is($caveman->skill_text, "Home caveman\n", 'with the home skill text');
  ok(!$packs->is_active('caveman'), 'home pack.yml replaces the shipped one (no enabled_by_default)');
};

subtest 'the home argument wins over $HOME' => sub {
  local $ENV{HOME} = dir()->stringify;
  my $home = dir();
  pack_in($home, 'arg-home', 'SKILL.md' => "x\n");
  my $packs = build_packs(root => dir(), home => "$home");
  is($packs->packs_by_name->{'arg-home'}->origin, 'home', 'found through home =>');
};

subtest 'project packs win over home and shipped' => sub {
  my $home = dir();
  local $ENV{HOME} = "$home";
  my $root = dir();
  pack_in($home, 'shared', 'SKILL.md' => "Home shared\n");
  pack_in($root, 'shared', 'SKILL.md' => "Project shared\n");
  pack_in($root, 'teacher', 'SKILL.md' => "Project teacher\n", 'pack.yml' => "exclusive_group: persona\n");

  my $packs = build_packs(root => $root);
  is($packs->packs_by_name->{shared}->origin, 'project', 'project over home');
  is($packs->packs_by_name->{shared}->skill_text, "Project shared\n", 'project skill text');
  is($packs->packs_by_name->{teacher}->origin, 'project', 'project over shipped');

  my $other = build_packs(root => dir());
  is($other->packs_by_name->{shared}->origin, 'home', 'another project sees only the home pack');
  is($other->packs_by_name->{teacher}->origin, 'shipped', 'and the shipped teacher');
};

subtest 'a project that is the home directory counts as home' => sub {
  my $home = dir();
  local $ENV{HOME} = "$home";
  pack_in($home, 'here', 'SKILL.md' => "x\n");
  my $packs = build_packs(root => $home);
  is($packs->packs_by_name->{here}->origin, 'home', 'origin home, not project');
};

subtest '$RAIDER_PACK_DIRS comes after the shipped packs' => sub {
  local $ENV{HOME} = dir()->stringify;
  my $env = dir();
  $env->child($_)->mkpath for qw( env-pack caveman );
  $env->child($_, 'SKILL.md')->spew_utf8("env\n") for qw( env-pack caveman );
  local $ENV{RAIDER_PACK_DIRS} = "$env";
  my $packs = build_packs(root => dir());
  is($packs->packs_by_name->{'env-pack'}->origin, 'env', 'origin env');
  is($packs->packs_by_name->{caveman}->origin, 'shipped', 'shipped caveman kept');
};

subtest 'broken pack directories are skipped and reported' => sub {
  my $home = dir();
  local $ENV{HOME} = "$home";
  my $root = dir();
  pack_in($home, 'fallback', 'SKILL.md' => "Home fallback\n");
  pack_in($root, 'fallback', 'SKILL.md' => "x\n", 'pack.yml' => "exclusive_group: [unclosed\n");
  pack_in($root, 'no-skill', 'pack.yml' => "exclusive_group: power\n");
  pack_in($root, 'a-list', 'SKILL.md' => "x\n", 'pack.yml' => "- one\n- two\n");
  pack_in($root, 'bad-type', 'SKILL.md' => "x\n", 'pack.yml' => "exclusive_group: [ a, b ]\n");
  pack_in($root, 'good', 'SKILL.md' => "Good\n");

  my $packs = build_packs(root => $root);
  ok($packs->packs_by_name->{good}, 'the good project pack loads');
  my $no_skill = $packs->packs_by_name->{'no-skill'};
  ok($no_skill && !$no_skill->has_skill_text, 'a pack without SKILL.md is not broken');
  ok(!$packs->packs_by_name->{$_}, $_.' not loaded') for qw( a-list bad-type );
  is($packs->packs_by_name->{fallback}->origin, 'home', 'a broken project pack gives way to the home one');

  my %skipped = map { $_->{name} => $_ } @{$packs->skipped_packs};
  is([ sort keys %skipped ], [qw( a-list bad-type fallback )], 'all three reported');
  like($skipped{fallback}, { name => 'fallback', origin => 'project',
    path => $root->child('.raider', 'packs', 'fallback')->stringify,
    reason => qr/^pack\.yml is not valid YAML: \S/ }, 'bad YAML');
  is($skipped{'a-list'}{reason}, 'pack.yml is not a mapping', 'not a mapping');
  like($skipped{'bad-type'}{reason}, qr/^Attribute \(exclusive_group\) does not pass/, 'wrong type names the attribute');
  unlike($skipped{$_}{reason}, qr/\n| line \d+/, $_.': one line, no code location') for keys %skipped;

  ok(lives { app($root)->packs }, 'the application starts with broken packs');
};

subtest 'removed pack fields' => sub {
  local $ENV{HOME} = dir()->stringify;
  my $root = dir();
  pack_in($root, 'old-fields', 'SKILL.md' => "x\n",
    'pack.yml' => "mcp: [ { name: x } ]\nadd_allowed_commands: [ rm ]\nengine_options: { temperature: 1 }\n");
  my $pack = build_packs(root => $root)->packs_by_name->{'old-fields'};
  ok($pack, 'a pack.yml with the old keys still loads');
  ok(!$pack->can($_), 'no '.$_.' accessor') for qw( extra_mcp add_allowed_commands engine_options );
};

subtest 'project packs activate by detection and by --pack' => sub {
  local $ENV{HOME} = dir()->stringify;
  my $root = dir();
  pack_in($root, 'proj-detect', 'SKILL.md' => "Project detected skill\n",
    'pack.yml' => "detect:\n  must: [ { file: MARKER } ]\n");
  pack_in($root, 'proj-manual', 'SKILL.md' => "Project manual skill\n");
  $root->child('MARKER')->spew_utf8('');

  my $app = app($root, pack_names => ['proj-manual']);
  ok($app->packs->is_active('proj-manual'), '--pack enables a project pack');
  ok($app->packs->is_active('proj-detect'), 'a project pack rule is evaluated (no trust gate yet)');
  like($app->raider->mission, qr/Project detected skill/, 'its skill reaches the mission');
};

subtest 'raider config explain shows the origin and skipped packs' => sub {
  my $home = dir();
  local $ENV{HOME} = "$home";
  my $root = dir();
  pack_in($home, 'home-pack', 'SKILL.md' => "x\n");
  pack_in($root, 'proj-pack', 'SKILL.md' => "x\n");
  pack_in($root, 'broken', 'pack.yml' => "just a string\n");
  my $app = app($root, pack_names => [qw( caveman home-pack proj-pack )]);

  my $report = $app->explain_config;
  like(entry($report->{packs}, 'caveman'),   { origin => 'shipped', active => 1 }, 'shipped');
  like(entry($report->{packs}, 'home-pack'), { origin => 'home',    active => 1 }, 'home');
  like(entry($report->{packs}, 'proj-pack'), { origin => 'project', active => 1 }, 'project');
  like($report->{skipped_packs}, [ { name => 'broken', origin => 'project', reason => 'pack.yml is not a mapping' } ], 'skipped');

  my ( $fh, $read ) = buffer();
  my $out = Langertha::Raider::CLI::Output->new(out => $fh, color => 0);
  $out->config_report($report);
  my $text = $read->();
  like($text, qr/^  caveman\s+active\s+shipped\s+flag: /m, 'shipped column');
  like($text, qr/^  home-pack\s+active\s+home\s+flag: /m, 'home column');
  like($text, qr/^  proj-pack\s+active\s+project\s+flag: /m, 'project column');
  like($text, qr/^  skipped pack broken \(project \Q$root\E\/\.raider\/packs\/broken\): pack\.yml is not a mapping$/m, 'skipped line');

  Langertha::Raider::CLI::Commands->new(app => $app, output => $out)->dispatch('/packs');
  like($read->(), qr/^  skipped pack broken \(project .*\): pack\.yml is not a mapping$/m, '/packs reports it too');
};

done_testing;
