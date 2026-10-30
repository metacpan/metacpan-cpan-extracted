#!/usr/bin/env perl
# ABSTRACT: The REPL approves tool calls and reviews plans; /permissions shows and switches the policy (ADR 0021, k154)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

sub cli {
  return Langertha::Raider::CLI->new(
    root => tempdir( CLEANUP => 1 ), engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0, detect => 0,
    @_,
  );
}

# A REPL on $input; returns it and a reader of what it printed.
sub repl {
  my ( $app, $input, %o ) = @_;
  open my $in, '<', \$input or die $!;
  my $out = '';
  open my $fh, '>', \$out or die $!;
  my $repl = Langertha::Raider::CLI::REPL->new(
    app => $app, in => $in, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ), can_ask => 1, %o,
  );
  return ( $repl, sub { $out } );
}

my $REQ = { tool => 'bash', arguments => { command => 'make test' },
  reason => 'default mode asks before this call: bash runs code', rule => 'Bash(make test)' };

subtest 'permission_request: the question and the three answers' => sub {
  my $app = cli();
  my ( $r, $out ) = repl( $app, "1\n" );
  is $r->permission_request($REQ), { answer => 'once' }, '1: once';
  is $out->(), "? allow bash: make test\n  (default mode asks before this call: bash runs code)\n"
    ."  1) yes, once\n  2) yes, for this session: Bash(make test)\n  3) no, and tell the model why\nchoice> ",
    'tool, what it does, why, the rule before the choice';
  is [ repl( $app, "y\n" ) ]->[0]->permission_request($REQ), { answer => 'once' }, 'y: once';
  is [ repl( $app, "2\n" ) ]->[0]->permission_request($REQ), { answer => 'session' }, '2: session';
  is [ repl( $app, "3\nnot now, run the tests later\n" ) ]->[0]->permission_request($REQ),
    { answer => 'no', reason => 'not now, run the tests later' }, '3: no, with the reason';
  is [ repl( $app, "n\n\n" ) ]->[0]->permission_request($REQ), { answer => 'no' }, 'n: no, the reason is optional';
  is [ repl( $app, "" ) ]->[0]->permission_request($REQ), { answer => 'no' }, 'closed input: no';
  is [ repl( $app, "maybe\n1\n" ) ]->[0]->permission_request($REQ), { answer => 'once' }, 'anything else asks again';

  my ( $nr, $nout ) = repl( $app, "2\n3\n" );
  is $nr->permission_request( { %$REQ, rule => undef } ), { answer => 'no' }, 'without a rule 2 is no choice';
  unlike $nout->(), qr/for this session/, '... and not offered';
};

subtest 'call_summary' => sub {
  my ( $r ) = repl( cli(), '' );
  is $r->call_summary( { arguments => { path => 'lib/A.pm', content => 'x' } } ), 'lib/A.pm', 'a path';
  is $r->call_summary( { arguments => { url => 'https://x.org/' } } ), 'https://x.org/', 'a url';
  is $r->call_summary( { arguments => { b => 1, a => 2 } } ), '{"a":2,"b":1}', 'else JSON';
  like $r->call_summary( { arguments => { command => 'x' x 300 } } ), qr/\Ax{200}\.\.\.\z/, 'cut at 200';
};

subtest 'plan_review' => sub {
  my ( $r, $out ) = repl( cli(), "y\n" );
  is $r->plan_review("1. do it"), { approve => 1 }, 'y accepts';
  like $out->(), qr/\A\? the plan:\n1\. do it\naccept the plan\? \[y\/n\]> \z/, 'the plan is shown';
  is [ repl( cli(), "n\nsmaller steps\n" ) ]->[0]->plan_review('p'), { approve => 0, feedback => 'smaller steps' },
    'n asks for feedback';
  is [ repl( cli(), '' ) ]->[0]->plan_review('p'), { approve => 0 }, 'closed input does not accept';
};

subtest 'the REPL registers itself only where a person is' => sub {
  my $run = sub {
    my $app = cli();
    my ( $r ) = repl( $app, "/quit\n", @_ );
    $r->run;
    return $app;
  };
  my $none = $run->( can_ask => 0 );
  ok !$none->on_permission_request, 'no person: no approval';
  ok !$none->on_plan_review, '... and no plan review';
  my $app = $run->();
  ok $app->on_permission_request, 'can_ask: approval registered';
  ok $app->on_plan_review, '... and plan review';
};

subtest 'the gate asks through on_permission_request' => sub {
  my $app = cli( permission_mode => 'default' );
  my @asked;
  $app->on_permission_request( sub { push @asked, $_[0]; { answer => 'once' } } );
  my $call = { name => 'bash', source => 'engine:2', arguments => { command => 'make' } };
  is $app->_permission_gate($call)->{verdict}, 'allow', 'approved once: allowed';
  like \@asked, [ { tool => 'bash', rule => 'Bash(make)', reason => qr/bash runs code/ } ], 'asked with the rule';
  is $app->_permission_gate($call)->{verdict}, 'allow', 'asked again next time';
  is scalar @asked, 2, 'twice';

  $app->on_permission_request( sub { { answer => 'session' } } );
  is $app->_permission_gate($call)->{verdict}, 'allow', 'for the session';
  $app->on_permission_request( sub { die 'not asked again' } );
  is $app->_permission_gate($call)->{verdict}, 'allow', 'the session rule allows it without asking';
  is [ map { $_->text } @{ $app->permissions->session_rules } ], [ 'Bash(make)' ], 'one session rule';

  $app->on_permission_request( sub { { answer => 'no', reason => 'no network' } } );
  my $v = $app->_permission_gate( { name => 'web_fetch', source => 'engine:3', arguments => { url => 'https://x.org' } } );
  is [ @{$v}{qw( verdict by )} ], [ 'deny', 'user' ], 'no: refused by the user';
  is $v->{message}, "The user doesn't want to proceed with this tool use. The tool use was rejected "
    ."(eg. if it was a file edit, the new_string was NOT written to the file). To tell you how to proceed, the user said:\nno network",
    'with the reason, in the words of Claude Code';
  is $v->{reason}, $v->{message}, 'the event reason is what the model reads';
};

subtest '/permissions' => sub {
  my $app = cli( permission_mode => 'default' );
  $app->permissions->add_session_rule('Bash(make)');
  my $out = '';
  open my $fh, '>', \$out or die $!;
  my $c = Langertha::Raider::CLI::Commands->new( app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ) );
  ok $c->dispatch('/permissions'), 'known command';
  like $out, qr/^permissions: mode default \(from --permission-mode\)$/m, 'mode with its source';
  like $out, qr/^  allow  Bash\(make\)  \(session\)$/m, 'session rules with their source';
  $out = '';
  my @events;
  $app->begin_run( on_event => sub { push @events, [@_] } );
  $c->dispatch('/permissions mode plan');
  $app->end_run('completed');
  is $app->permissions->mode, 'plan', 'switched';
  like $out, qr/permission mode: default -> plan/, 'said so';
  my ($mode_event) = grep { $_->[0] eq 'permission.mode' } @events;
  is { @{$mode_event}[ 1 .. $#$mode_event ] }, { from => 'default', to => 'plan', why => '/permissions' }, 'permission.mode event';
  ok( ( grep { $_->name eq 'exit_plan_mode' } $app->_mounted_tools ), 'entering plan mode mounts exit_plan_mode' );
  $out = '';
  $c->dispatch('/permissions mode yolo');
  like $out, qr/usage: \/permissions mode MODE \(default, acceptEdits, auto, plan, bypassPermissions\)/, 'an unknown mode';
  is $app->permissions->mode, 'plan', 'unchanged';
};

subtest 'exit_plan_mode is only mounted once plan mode was entered' => sub {
  ok !( grep { $_->name eq 'exit_plan_mode' } cli( permission_mode => 'default' )->_mounted_tools ), 'default: not mounted';
  ok( ( grep { $_->name eq 'exit_plan_mode' } cli( permission_mode => 'plan' )->_mounted_tools ), 'plan: mounted' );
};

subtest '/reload keeps session rules and a mode switched in the session' => sub {
  my $app = cli();
  my $root = path( $app->root );
  $app->permissions->add_session_rule('Bash(make)');
  $app->set_permission_mode( 'acceptEdits', '/permissions' );
  $root->child('.raider/config.yml')->touchpath->spew_utf8("permissions:\n  deny: [ WebSearch ]\n");
  is $app->permissions->report->{rules}{deny}, [], 'not read yet';
  $app->reload_permissions;
  is $app->permissions->report->{rules}{deny}, [ { rule => 'WebSearch', source => '.raider/config.yml' } ], 'read again';
  is [ map { $_->text } @{ $app->permissions->session_rules } ], [ 'Bash(make)' ], 'session rule kept';
  is $app->permissions->mode, 'acceptEdits', 'mode kept';
};

done_testing;
