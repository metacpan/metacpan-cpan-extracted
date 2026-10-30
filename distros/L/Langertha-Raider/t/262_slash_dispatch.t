#!/usr/bin/env perl
# ABSTRACT: /name resolution: catalogue entry beats a built-in, path-like lines are prompts, unknown, render errors, the REPL runs requests (ADR 0030 section 3)
use strict;
use warnings;
use utf8;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
clear_engine_env();
use Encode qw( decode_utf8 );
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;

delete @ENV{qw( RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# A raider CLI whose run answers without a model; it records each prompt
# with the run rules and the files counted as read while it runs.
package My::App {
  use Moose;
  extends 'Langertha::Raider::CLI';
  has calls => ( is => 'ro', default => sub { [] } );
  sub run {
    my ( $self, $text ) = @_;
    push @{ $self->calls }, {
      text  => $text,
      rules => [ map { $_->text.' <'.$_->source.'>' } @{ $self->permissions->run_rules } ],
    };
    return 'answer';
  }
  __PACKAGE__->meta->make_immutable;
}

my @tmp;
sub tmp { push @tmp, Path::Tiny->tempdir; return $tmp[-1]->realpath }

# A Claude-layout project with these files.
sub project {
  my ( %files ) = @_;
  my $root = tmp();
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  $root->child($_)->touchpath->spew_utf8( $files{$_} ) for keys %files;
  return $root;
}

sub app {
  my ( $root, %args ) = @_;
  return My::App->new( root => "$root", engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0, %args );
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; my $t = decode_utf8($buf); $buf = ''; seek $fh, 0, 0; $t } );
}

sub commands {
  my ( $app ) = @_;
  my ( $fh, $read ) = buffer();
  return ( Langertha::Raider::CLI::Commands->new( app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ) ), $read );
}

subtest 'a custom command becomes a run request with the Claude Code frame' => sub {
  my $root = project(
    '.claude/commands/fix.md'                => "---\ndescription: Fix it\n---\nFix issue \$ARGUMENTS now.\n",
    '.claude/commands/frontend/component.md' => "Build the \$0 component.\n",
  );
  my ( $cmds, $read ) = commands( app($root) );
  my $r = $cmds->dispatch('/fix 123  ');
  is ref $r, 'HASH', 'a run request';
  is $r->{prompt},
    "<command-message>fix is running\x{2026}</command-message>\n<command-name>/fix</command-name>\n"
    ."<command-args>123</command-args>\n\nFix issue 123 now.",
    'the frame, then the rendered body';
  is $r->{allow_rules}, [], 'no allowed-tools';
  is $r->{allow_source}, '/fix allowed-tools', 'their source';
  ok !exists $r->{model}, 'no model';
  is $r->{attach_reads}, [], 'nothing attached';
  like $cmds->dispatch('/frontend:component Button')->{prompt}, qr/<command-name>\/frontend:component<\/command-name>.*Build the Button component\.\z/s,
    'a namespaced command';
  is $cmds->dispatch('/fix')->{prompt}, match qr{<command-args></command-args>\n\nFix issue  now\.\z}, 'no arguments';
  is $read->(), '', 'nothing printed';
};

subtest 'the frontmatter rides along: allowed-tools, model, @file' => sub {
  my $root = project(
    '.claude/commands/rev.md' => "---\nallowed-tools: Bash(git diff:*), Read\nmodel: sonnet\n---\nReview \@notes.txt please.\n",
    'notes.txt'               => "NOTE-LINE\n",
  );
  my ( $cmds ) = commands( app($root) );
  my $r = $cmds->dispatch('/rev');
  is $r->{allow_rules}, [ 'Bash(git diff:*)', 'Read' ], 'allowed-tools as rules';
  is $r->{model}, 'sonnet', 'the model as written';
  like $r->{prompt}, qr/Called the read_file tool.*NOTE-LINE/s, 'the file is attached';
  is [ map { $_->{path} } @{ $r->{attach_reads} } ], [ $root->child('notes.txt')->stringify ], 'and to be counted as read';
};

subtest 'an entry beats a built-in, not its aliases; user-invocable: false is no command' => sub {
  my $root = project(
    '.claude/commands/clear.md'   => "MY-CLEAR\n",
    '.claude/skills/hidden/SKILL.md' => "---\nname: hidden\ndescription: h\nuser-invocable: false\n---\nHIDDEN\n",
  );
  my ( $cmds, $read ) = commands( app($root) );
  like $cmds->dispatch('/clear')->{prompt}, qr/MY-CLEAR/, '/clear is the custom command';
  is $cmds->dispatch('/reset'), 1, '/reset is still the built-in';
  is $read->(), "history cleared.\n", 'it cleared';
  is $cmds->dispatch('/stats'), 1, 'other built-ins work';
  $read->();
  is $cmds->dispatch('/hidden'), 0, 'a skill the user may not invoke';
  is $read->(), "error: unknown command: /hidden (try /help)\n", 'is unknown';
};

subtest 'a path is a prompt, anything else unknown' => sub {
  my ( $cmds, $read ) = commands( app( project() ) );
  is $cmds->dispatch('/etc/hosts is broken'), { prompt => '/etc/hosts is broken' }, 'a path-like first word';
  is $cmds->dispatch('/nope x'), 0, 'unknown is false';
  is $read->(), "error: unknown command: /nope (try /help)\n", 'and said so';
  is $cmds->dispatch('/'), 0, 'a bare slash';
  is $cmds->resolve('/skill-claude x'), { kind => 'builtin', name => 'skill-claude', arguments => 'x', method => 'cmd_skill_claude' },
    'resolve names the method';
};

subtest 'a render that aborts is printed, nothing runs' => sub {
  my $root = project( '.claude/commands/wipe.md' => "!`rm -rf build`\n" );
  my ( $cmds, $read ) = commands( app( $root, permission_mode => 'default' ) );
  is $cmds->dispatch('/wipe'), 0, 'false';
  like $read->(), qr/\Aerror: Shell command permission check failed for pattern "!`rm -rf build`" in \/wipe: default mode asks/,
    'the reason';
  ok $root->child('CLAUDE.md')->exists, 'nothing ran';
};

subtest 'a broken config: built-ins still work, unknown says why' => sub {
  my $root = tmp();
  $root->child('.raider.yml')->spew_utf8("- a\n- b\n");
  my ( $cmds, $read ) = commands( app($root) );
  is $cmds->dispatch('/config'), 1, '/config is still the built-in';
  $read->();
  my $help = $cmds->dispatch('/help');
  like $read->(), $help ? qr/\/help/ : qr/^error: \/help: .*mapping/m, '/help works or reports the error, without dying';
  is $cmds->dispatch('/nope'), 0, 'unknown';
  like $read->(), qr/\Aerror: unknown command: \/nope \(try \/help\)\nerror: skills and custom commands not read: .*mapping/,
    'with the catalogue error';
};

subtest 'the REPL runs a request, also as the first prompt; /reset and /new are recorded' => sub {
  my $root = project( '.claude/commands/fix.md' => "---\nallowed-tools: Bash(make:*)\n---\nFix \$ARGUMENTS\n" );
  my $app = app($root);
  my ( $fh, $read ) = buffer();
  my $text = "/fix b\n/etc/passwd looks odd\n/reset\n/new\n/nope\n";
  open my $in, '<', \$text or die $!;
  my $repl = Langertha::Raider::CLI::REPL->new(
    app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ), in => $in,
    session_store => $app->session_store,
  );
  $repl->run( '/fix', 'a' );
  is [ map { $_->{text} =~ /\n\n(.*)\z/s ? $1 : $_->{text} } @{ $app->calls } ], [ "Fix a", "Fix b", '/etc/passwd looks odd' ],
    'first prompt, a command, a path';
  is $app->calls->[0]{rules}, [ 'Bash(make:*) </fix allowed-tools>' ], 'allowed-tools hold during the run';
  is $app->calls->[2]{rules}, [], 'and only for that run';
  is $app->permissions->run_rules, [], 'none left';
  like $read->(), qr/error: unknown command: \/nope/, 'unknown reported, the REPL goes on';
  my $json = JSON::MaybeXS->new;
  my @types = map { $json->decode($_)->{type} } path( $repl->session->path )->lines_raw({ chomp => 1 });
  is scalar( grep { $_ eq 'history.cleared' } @types ), 2, '/reset and /new recorded';
};

done_testing;
