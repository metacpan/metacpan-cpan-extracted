#!/usr/bin/env perl
# ABSTRACT: Refusals and plan reviews in Claude Code's words: the gate's message, the person's no, exit_plan_mode (ADR 0026)
use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider;
use Langertha::Raider::Application;

clear_engine_env();

my $REJECTED = "The user doesn't want to proceed with this tool use. The tool use was rejected "
  ."(eg. if it was a file edit, the new_string was NOT written to the file). ";

sub app {
  my ( %o ) = @_;
  my $root = Path::Tiny->tempdir;
  my $config = delete $o{config};
  $root->child('.raider/config.yml')->touchpath->spew_utf8($config) if defined $config;
  my @events;
  my $app = Langertha::Raider::Application->new(
    root => "$root", engine => 'openai', api_key => 'test', model => 'gpt-4o-mini',
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    %o,
  );
  return ( $app, \@events, $root );
}

my $bash = sub { { name => 'bash', source => 'engine:2', arguments => { command => $_[0] } } };

subtest 'the raider: a verdict with message is the result as it stands' => sub {
  my $raider = Langertha::Raider->new( engine => bless( {}, 'Some::Engine' ) );
  my $r = $raider->_gate_refused_tool_result( 'bash', { verdict => 'deny', reason => 'why', message => 'Exactly this.' } );
  is $r->{content}[0]{text}, 'Exactly this.', 'the message';
  ok $r->{isError}, 'an error result';
  is $raider->_gate_refused_tool_result( 'bash', { verdict => 'deny', reason => 'local policy' } )->{content}[0]{text},
    "Tool call 'bash' was denied: local policy", 'without a message the raider words it, as before';
};

subtest 'deny rule: Claude Code sentence with the command, then the rule' => sub {
  my ( $app, $events, $root ) = app( permission_mode => 'default', config => "permissions:\n  deny: [ 'Bash(rm:*)', 'Edit(secret.txt)' ]\n" );
  my $v = $app->_permission_gate( $bash->('rm -rf build') );
  is $v->{verdict}, 'deny', 'denied';
  like $v->{message},
    qr/\APermission to use bash with command rm -rf build has been denied\. Reason: denied by rule 'Bash\(rm:\*\)' from \S*config\.yml\.\z/,
    'the message';
  like $v->{reason}, qr/\Adenied by rule 'Bash\(rm:\*\)'/, 'the reason of the event stays raider\'s';
  like $events->[-1], { type => 'permission.denied', by => 'rule', reason => qr/\Adenied by rule/ }, 'permission.denied';

  my $w = $app->_permission_gate( { name => 'write_file', source => 'engine:1', arguments => { path => 'secret.txt', content => 'x' } } );
  like $w->{message}, qr/\APermission to use write_file has been denied\. Reason: denied by rule 'Edit\(secret\.txt\)'/,
    'a tool without a command is named alone';
};

subtest 'an ask nobody can approve: Claude Code sentence, then how to allow it' => sub {
  my ( $app, $events, $root ) = app( permission_mode => 'default' );
  my $v = $app->_permission_gate( $bash->('make deploy') );
  is [ @{$v}{qw( verdict by )} ], [ 'deny', 'noninteractive' ], 'refused';
  like $v->{message}, qr/\APermission to use bash with command make deploy has been denied\. Reason: default mode asks before this call: bash runs code; nobody can approve it in this run\. To allow it, add a rule such as 'Bash\(make deploy\)' to \.raider\/config\.yml \(permissions: allow:\), or run raider with --permission-mode bypassPermissions\. Do not retry the same call; go on without it or say what you need\.\z/,
    'Claude Code first, raider\'s hint after';
  unlike $v->{reason}, qr/Permission to use/, 'the event reason has no Claude sentence';

  my ( $free, undef, $free_root ) = app( permission_mode => 'bypassPermissions' );
  my $h = $free->_permission_gate( { %{ $bash->('ls') }, hook => { decision => 'ask', reason => 'a hook wants a human' } } );
  like $h->{message}, qr/\APermission to use bash with command ls has been denied\. Reason: a hook wants a human; nobody can approve it in this run\. Do not retry/,
    'a hook that asks: nothing to configure, no hint';
};

subtest 'the person says no: exactly Claude Code' => sub {
  my ( $app, $events, $root ) = app( permission_mode => 'default' );
  $app->on_permission_request( sub { { answer => 'no' } } );
  my $v = $app->_permission_gate( $bash->('make') );
  is $v->{message}, $REJECTED.'STOP what you are doing and wait for the user to tell you how to proceed.', 'without a reason';
  like $events->[-1], { type => 'permission.denied', by => 'user', reason => $v->{message} }, 'the event carries it';

  $app->on_permission_request( sub { { answer => 'no', reason => "not here\nuse tmp/" } } );
  is $app->_permission_gate( $bash->('make') )->{message},
    $REJECTED."To tell you how to proceed, the user said:\nnot here\nuse tmp/", 'with the reason, as given';

  $app->on_permission_request( sub { { answer => 'no', reason => '' } } );
  like $app->_permission_gate( $bash->('make') )->{message}, qr/STOP what you are doing/, 'an empty reason is none';
};

subtest 'exit_plan_mode' => sub {
  my ( $app, undef, $root ) = app( permission_mode => q{default} );
  is [ $app->_exit_plan_mode('a plan') ],
    [ '<tool_use_error>You are not in plan mode. To enter plan mode, call the enter_plan_mode tool first. If your plan was already approved, continue with implementation.</tool_use_error>', 1 ],
    'outside plan mode: an error result';

  ( $app, undef, $root ) = app( permission_mode => q{plan} );
  is [ $app->_exit_plan_mode('a plan') ],
    [ 'Permission to use exit_plan_mode has been denied. Reason: nobody can approve the plan in this run. '
      .'Stay in plan mode and give the plan as your final answer.', 1 ],
    'nobody to review: refused like any ask nobody can approve';
  is $app->permissions->mode, 'plan', 'still plan';

  my @plans;
  $app->on_plan_review( sub { push @plans, $_[0]; { approve => 0, feedback => 'add a test' } } );
  is [ $app->_exit_plan_mode("1. a\n2. b") ], [ $REJECTED."To tell you how to proceed, the user said:\nadd a test", 1 ],
    'refused with feedback: Claude Code\'s rejection, an error result';
  is $app->permissions->mode, 'plan', 'still plan';
  $app->on_plan_review( sub { { approve => 0 } } );
  is [ $app->_exit_plan_mode('x') ]->[0], $REJECTED.'STOP what you are doing and wait for the user to tell you how to proceed.',
    'refused without feedback';

  $app->on_plan_review( sub { { approve => 1 } } );
  is [ $app->_exit_plan_mode("1. a\n2. b") ],
    [ "User has approved your plan. You can now start coding. Start with updating your todo list if applicable\n\n"
      ."The permission mode is now default.\n\n## Approved Plan:\n1. a\n2. b", 0 ],
    'approved: Claude Code\'s text with the plan, no error';
  is $app->permissions->mode, 'default', 'the mode is default';
  is \@plans, [ "1. a\n2. b" ], 'the plan was put to the person';
};

done_testing;
