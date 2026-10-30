#!/usr/bin/env perl
# ABSTRACT: What the prompt puts in front of the model counts as read: the prompt builder's instructions file and the CLAUDE.md files (ADR 0023)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::PromptBuilder;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};
delete $ENV{CLAUDE_CONFIG_DIR};

my @keep;
sub project {
  my ( %files ) = @_;
  push @keep, Path::Tiny->tempdir;
  my $root = $keep[-1]->realpath;
  $root->child($_)->touchpath->spew_utf8( $files{$_} ) for keys %files;
  return $root;
}

subtest 'the prompt builder marks the instructions file it shows as read' => sub {
  my $root = project( '.raider.md' => "Be brief.\n" );
  my $app  = Langertha::Raider::CLI->new(
    root => "$root", engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0, detect => 0,
  );
  my $file = $root->child('.raider.md')->realpath->stringify;
  ok !$app->file_read_state->has_read($file), 'not read before';
  open my $in, '<', \"/cancel\n" or die $!;
  my $out = '';
  open my $fh, '>', \$out or die $!;
  Langertha::Raider::CLI::PromptBuilder->new(
    app => $app, in => $in, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ),
  )->run;
  ok $app->file_read_state->has_read($file), 'the file counts as read';
  is $app->file_read_state->write_problem($file), undef, 'write_file may replace it';
  $root->child('.raider.md')->spew_utf8("Changed behind its back.\n");
  like $app->file_read_state->write_problem($file), qr/modified since read/, 'a change after the show is still caught';
};

subtest 'the prompt builder leaves a missing instructions file alone' => sub {
  my $root = project( 'a.txt' => "x\n" );
  my $app  = Langertha::Raider::CLI->new(
    root => "$root", engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0, detect => 0,
  );
  open my $in, '<', \"/cancel\n" or die $!;
  my $out = '';
  open my $fh, '>', \$out or die $!;
  Langertha::Raider::CLI::PromptBuilder->new(
    app => $app, in => $in, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ),
  )->run;
  is $app->file_read_state->write_problem( $root->child('.raider.md')->stringify ), undef, 'a new file needs no read';
};

subtest 'a run starts with the injected CLAUDE.md files read' => sub {
  my $root = project(
    'CLAUDE.md'       => "Rule one.\n",
    'CLAUDE.local.md' => "Mine.\n",
    'other.txt'       => "not in the prompt\n",
  );
  my $app = mock_app( root => "$root" );
  is $app->context->mode, 'claude', 'Claude layout';
  my $claude = $root->child('CLAUDE.md')->realpath->stringify;
  my $local  = $root->child('CLAUDE.local.md')->realpath->stringify;
  my $other  = $root->child('other.txt')->realpath->stringify;
  ok !$app->file_read_state->has_read($claude), 'nothing before the run';
  $app->begin_run;
  ok $app->file_read_state->has_read($claude), 'CLAUDE.md counts as read';
  ok $app->file_read_state->has_read($local),  'CLAUDE.local.md counts as read';
  ok !$app->file_read_state->has_read($other), 'a file that is not in the prompt does not';
  is $app->file_read_state->write_problem($claude), undef, 'so it may be edited without a read';
  like $app->file_read_state->write_problem($other), qr/has not been read yet/, 'the other file is still refused';
  $app->end_run('completed');
};

subtest 'an edit of CLAUDE.md goes through in the run, a change behind its back does not' => sub {
  my $root = project( 'CLAUDE.md' => "Rule one.\n" );
  my $app  = mock_app(
    root            => "$root",
    permission_mode => "bypassPermissions",
    script => [
      { tool_calls => [ [ edit_file => { path => 'CLAUDE.md', old_string => 'one', new_string => 'two' } ] ] },
      { text => 'edited' },
    ],
  );
  $app->run_prompt('Change the rule.');
  is $root->child('CLAUDE.md')->slurp_utf8, "Rule two.\n", 'edited without a read_file first';

  my $stale = project( 'CLAUDE.md' => "Rule one.\n" );
  my $app2  = mock_app( root => "$stale" );
  $app2->begin_run;
  $stale->child('CLAUDE.md')->spew_utf8("Rule uno.\n");
  like $app2->file_read_state->write_problem( $stale->child('CLAUDE.md')->realpath->stringify ),
    qr/modified since read/, 'a change after the prompt was built is caught';
  $app2->end_run('completed');
};

subtest 'bare and the raider layout seed nothing' => sub {
  my $root = project( 'CLAUDE.md' => "Rule.\n", '.raider/config.yml' => "permissions: {}\n" );
  my $app  = mock_app( root => "$root" );
  isnt $app->context->mode, 'claude', 'raider layout';
  $app->begin_run;
  ok !$app->file_read_state->has_read( $root->child('CLAUDE.md')->realpath->stringify ), 'not in the prompt, not read';
  $app->end_run('completed');
};

done_testing;
