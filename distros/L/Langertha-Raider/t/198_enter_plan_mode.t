#!/usr/bin/env perl
# ABSTRACT: enter_plan_mode: the policy asks before plan mode is entered, the application switches the mode (ADR 0025)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Permissions;
use Langertha::Raider::PlanTools;
use Langertha::Raider::CLI;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

my $tmp = Path::Tiny->tempdir;
sub policy {
  my ( %arg ) = @_;
  return Langertha::Raider::Permissions->new( root => "$tmp", home => "$tmp", %arg );
}
my $call = { name => 'enter_plan_mode', source => 'engine:8', arguments => {} };

subtest 'the policy: asks in every mode but plan and bypassPermissions' => sub {
  for my $mode (qw( default acceptEdits auto )) {
    my $v = policy( mode => $mode )->decide($call);
    is( $v->{verdict}, 'ask', "$mode asks" );
    like( $v->{reason}, qr/\A\Q$mode\E mode asks before this call: enter_plan_mode switches the session to plan mode/,
      "$mode: the reason says what it does" );
  }
  is( policy( mode => 'bypassPermissions' )->decide($call)->{verdict}, 'allow', 'bypassPermissions: no question' );
  is( policy( mode => 'plan' )->decide($call)->{verdict}, 'allow', 'plan: allowed (it changes nothing)' );
  my $foreign = { %$call, source => 'catalog:other' };
  is( policy( mode => 'default' )->decide($foreign)->{reason}, 'default mode asks before this call: enter_plan_mode is not a tool of raider (MCP server \'other\')',
    'a foreign tool of that name asks as any foreign tool' );
};

subtest 'the policy: rules under Claude Code\'s name' => sub {
  my $allow = policy( mode => 'default', rules => { allow => [ { rule => 'EnterPlanMode', source => 'test' } ] } );
  is( $allow->decide($call)->{verdict}, 'allow', 'an EnterPlanMode allow rule lifts the question' );
  my $deny = policy( mode => 'bypassPermissions', rules => { deny => [ { rule => 'EnterPlanMode', source => 'test' } ] } );
  is( $deny->decide($call)->{verdict}, 'deny', 'a deny rule holds even in bypassPermissions' );
  is( policy()->suggest_rule($call), 'EnterPlanMode', '"for this session" adds EnterPlanMode' );
};

subtest 'PlanTools: enter_plan_mode takes no arguments and answers what its handler says' => sub {
  my $calls = 0;
  my $plan = Langertha::Raider::PlanTools->new( handler => sub { ( 'x', 0 ) }, enter_handler => sub { $calls++; ( 'entered', 0 ) } );
  my ($tool) = @{ $plan->enter_server->tools };
  is( $tool->name, 'enter_plan_mode', 'the tool' );
  is( $tool->input_schema, { type => 'object', properties => {} }, 'no arguments' );
  my $r = $tool->code->( $tool, {} );
  is( [ $r->{content}[0]{text}, !!$r->{isError}, $calls ], [ 'entered', '', 1 ], 'the handler answers' );
  like( dies { Langertha::Raider::PlanTools->new( handler => sub { } )->enter_server }, qr/needs an enter_handler/,
    'enter_server without a handler croaks' );
};

sub cli {
  my ( %arg ) = @_;
  return Langertha::Raider::CLI->new(
    root => tempdir( CLEANUP => 1 ), engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0, detect => 0,
    %arg,
  );
}

subtest 'the application: mounted always, the handler switches to plan and mounts exit_plan_mode' => sub {
  my $app = cli( permission_mode => 'default' );
  my %have = map { $_->name => 1 } $app->_mounted_tools;
  ok( $have{enter_plan_mode}, 'enter_plan_mode is mounted' );
  ok( !$have{exit_plan_mode}, 'exit_plan_mode not yet' );
  my @events;
  $app->begin_run( on_event => sub { push @events, [@_] } );
  my ( $text, $err ) = $app->_enter_plan_mode;
  ok( !$err, 'not an error' );
  like( $text, qr/\AEntered plan mode\. You should now focus on exploring the codebase and designing an implementation approach\.\n\n/,
    "Claude Code's answer" );
  like( $text, qr/use exit_plan_mode to present your plan for approval\n\nRemember: DO NOT write or edit any files yet\./,
    'with raider\'s tool names' );
  is( $app->permissions->mode, 'plan', 'the mode is plan' );
  my @mode = grep { $_->[0] eq 'permission.mode' } @events;
  is( { @{ $mode[0] }[ 1 .. $#{ $mode[0] } ] }, { from => 'default', to => 'plan', why => 'enter_plan_mode' }, 'permission.mode' );
  %have = map { $_->name => 1 } $app->_mounted_tools;
  ok( $have{exit_plan_mode}, 'exit_plan_mode is mounted now' );
  my ( $again ) = $app->_enter_plan_mode;
  is( $again, $text, 'in plan mode already: the same answer' );
  is( scalar( grep { $_->[0] eq 'permission.mode' } @events ), 1, 'and no second switch' );
  $app->end_run('completed');
};

subtest 'the application: through the gate -- the person, nobody, a session rule' => sub {
  my $nobody = cli( permission_mode => 'default' );
  my $v = $nobody->_permission_gate($call);
  is( $v->{verdict}, 'deny', 'nobody can agree: refused' );
  like( $v->{reason}, qr/nobody can approve it in this run.*a rule such as 'EnterPlanMode'/s, 'with how to allow it' );
  is( $nobody->permissions->mode, 'default', 'the mode stays' );

  my @asked;
  my $app = cli( permission_mode => 'default' );
  $app->on_permission_request( sub { push @asked, $_[0]; { answer => 'session' } } );
  is( $app->_permission_gate($call)->{verdict}, 'allow', 'the person agrees for the session' );
  is( $asked[0]{tool}, 'enter_plan_mode', 'asked about enter_plan_mode' );
  is( $asked[0]{rule}, 'EnterPlanMode', 'offering the rule EnterPlanMode' );
  is( $app->_permission_gate($call)->{verdict}, 'allow', 'the next call' );
  is( scalar @asked, 1, 'is not asked about again' );
};

done_testing;
