#!/usr/bin/env perl
# ABSTRACT: MCP server names and the exported Claude skill carry the raider name

use strict;
use warnings;
use Test2::Bundle::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use IO::Async::Loop;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();

use Langertha::Raider::CLI;
use Langertha::Raider::Skill;
use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::WebTools qw( build_web_tools_server );
use Langertha::Raider::PerlTools qw( build_perl_tools_server );
use Langertha::Raider::HallTools qw( build_hall_tools_server );

my $dir = tempdir(CLEANUP => 1);

subtest 'MCP server names' => sub {
  is(build_file_tools_server(root => $dir)->name, 'raider-files', 'files');
  is(build_web_tools_server(loop => IO::Async::Loop->new)->name, 'raider-web', 'web');
  is(build_perl_tools_server(root => $dir)->name, 'raider-perl', 'perl');
  is(build_hall_tools_server(socket => "$dir/hall.sock")->name, 'raider-hall', 'hall');
};

subtest 'Claude skill name and default path' => sub {
  my $app = Langertha::Raider::CLI->new(root => $dir, engine => 'openai', api_key => 'test', model => 'gpt-4o-mini');
  my $skill = Langertha::Raider::Skill->new(app => $app);
  is($skill->name, 'raider', 'default name');
  like($skill->claude_skill, qr/^---\nname: raider\n/, 'frontmatter name');
  my $p = $skill->write_claude_skill;
  is("$p", path($dir)->child('.claude/skills/raider/SKILL.md')->stringify, 'default path');
  ok(-f $p, 'written');
  ok(!$skill->legacy_claude_skill, 'no legacy skill');

  my $old = path($dir)->child('.claude/skills/app-raider/SKILL.md');
  $old->parent->mkpath;
  $old->spew_utf8("old\n");
  is($skill->legacy_claude_skill->stringify, $old->stringify, 'legacy skill found');
};

done_testing;
