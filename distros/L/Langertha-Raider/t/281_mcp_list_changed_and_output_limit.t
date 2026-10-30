#!/usr/bin/env perl
# ABSTRACT: MCP tools/list_changed, MAX_MCP_OUTPUT_TOKENS, prompts and resources of a server (ADR 0029 Addendum 1, k167)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use FindBin;
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use Time::HiRes ();
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
use Langertha::Raider::MCP::Config;
use Langertha::Raider::MCP::Server;

my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $script = path($FindBin::Bin)->child('lib', 'mcp-test-server.pl')->realpath->stringify;
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $loop = IO::Async::Loop->new;
my $root = path(tempdir(CLEANUP => 1))->realpath;

sub config {
  my ( %env ) = @_;
  $home->child('.claude.json')->spew_raw($json->encode({ mcpServers => { t => { command => $^X, args => [ $script, 'rich' ] } } }));
  return Langertha::Raider::MCP::Config->new( root => "$root", claude_layout => 1, env => { %ENV, %env } );
}

sub server {
  my ( %args ) = @_;
  my $config = config( %{ delete $args{env} // {} } );
  return ( $config, Langertha::Raider::MCP::Server->new( spec => $config->server('t'), loop => $loop, base_env => { %ENV },
    kill_grace => 0.2, max_output_tokens => $config->max_output_tokens, %args ) );
}

sub wait_for { my ( $f ) = @_; $loop->await($f); return $f }

# Spin the loop until $cond is true (at most 5 s).
sub until_true {
  my ( $cond ) = @_;
  my $deadline = Time::HiRes::time() + 5;
  $loop->loop_once(0.05) until $cond->() || Time::HiRes::time() > $deadline;
  return $cond->();
}

subtest 'tools/list_changed: the tools are listed again' => sub {
  my $changed = 0;
  my ( undef, $s ) = server( on_tools_changed => sub { $changed++ } );
  wait_for($s->initialize);
  is($s->status, 'connected', 'connected') or diag $s->reason;
  ok(( grep { $_ eq 'mcp__t__bump' } $s->tool_names ), 'bump is offered');
  ok(!( grep { $_ eq 'mcp__t__added_by_bump' } $s->tool_names ), 'the new tool is not there yet');

  my $r = wait_for($s->call_tool('mcp__t__bump', {}))->get;
  is($r->{content}[0]{text}, 'bumped', 'the call itself is fine');
  ok(until_true(sub { $changed }), 'on_tools_changed fired') or diag join "\n", @{ $s->warnings };
  my $tools = wait_for($s->list_tools)->get;   # waits for the list the server announced
  ok(( grep { $_->{name} eq 'mcp__t__added_by_bump' } @$tools ), 'list_tools shows the new tool');
  ok(( grep { $_ eq 'mcp__t__added_by_bump' } $s->tool_names ), 'tool_names has it');
  is($s->original_name('mcp__t__added_by_bump'), 'added_by_bump', 'and it is callable by its name');
  $r = wait_for($s->call_tool('mcp__t__added_by_bump', {}))->get;
  is($r->{content}[0]{text}, 'new tool', 'the new tool works');

  # A second change is picked up as well (the refresh is repeatable).
  $changed = 0;
  wait_for($s->call_tool('mcp__t__bump', {}))->get;
  ok(until_true(sub { $changed }), 'a later change is handled too');
  $tools = wait_for($s->list_tools)->get;
  is(scalar( grep { $_->{name} eq 'mcp__t__added_by_bump' } @$tools ), 1, 'listed once, not twice');
  wait_for($s->stop_f);
};

subtest 'MAX_MCP_OUTPUT_TOKENS cuts long text, with a note' => sub {
  my ( $config, $s ) = server();
  is($config->max_output_tokens, 25000, 'default 25000 tokens');
  wait_for($s->initialize);

  my $r = wait_for($s->call_tool('mcp__t__big', { n => 1000 }))->get;
  is(length $r->{content}[0]{text}, 1000, 'a short result passes unchanged');
  is(scalar @{ $r->{content} }, 1, 'without a note');

  $r = wait_for($s->call_tool('mcp__t__big', { n => 120000 }))->get;
  is(length $r->{content}[0]{text}, 100000, 'cut to 25000 tokens (4 characters each)');
  like($r->{content}[1]{text}, qr/truncated.*30000 tokens.*limit is 25000.*MAX_MCP_OUTPUT_TOKENS/, 'the note says how much and how to raise');
  wait_for($s->stop_f);

  ( $config, $s ) = server( env => { MAX_MCP_OUTPUT_TOKENS => '50' } );
  is($config->max_output_tokens, 50, 'from the environment');
  wait_for($s->initialize);
  $r = wait_for($s->call_tool('mcp__t__big', { n => 500 }))->get;
  is(length $r->{content}[0]{text}, 200, 'cut to 50 tokens');
  like($r->{content}[1]{text}, qr/about 125 tokens/, 'note names the size');
  wait_for($s->stop_f);

  ( $config ) = server( env => { MAX_MCP_OUTPUT_TOKENS => 'lots' } );
  is($config->max_output_tokens, 25000, 'a bad value keeps the default');
  like(( $config->env_warnings )->[0], qr/MAX_MCP_OUTPUT_TOKENS=lots is not a positive number of tokens/, 'and warns');
};

subtest 'limit_content: images pass, errors are cut in the middle' => sub {
  my ( undef, $s ) = server( max_output_tokens => 10 );
  my $image = [ { type => 'text', text => 'x' x 500 }, { type => 'image', data => 'AAAA', mimeType => 'image/png' } ];
  is($s->limit_content($image), $image, 'a result with an image is not cut');

  my $two = $s->limit_content([ { type => 'text', text => 'a' x 30 }, { type => 'text', text => 'b' x 30 } ]);
  is([ map { length $_->{text} } @$two[0, 1] ], [ 30, 10 ], 'the budget runs across blocks');
  like($two->[2]{text}, qr/truncated/, 'note last');

  my $err = $s->limit_content([ { type => 'text', text => join('', map { chr(97 + $_ % 26) } 0 .. 19999) } ], 1);
  ok(length $err->[0]{text} > 10000 && length $err->[0]{text} < 10100, 'error text: first and last 5000 kept');
  like($err->[0]{text}, qr/\[\.\.\. 10000 characters removed \.\.\.\]/, 'marker says how many were removed');
  my $short = [ { type => 'text', text => 'e' x 9000 } ];
  is($s->limit_content($short, 1), $short, 'a short error is left alone');
};

subtest 'prompts and resources' => sub {
  my ( undef, $s ) = server();
  wait_for($s->initialize);
  ok($s->has_prompts, 'prompts announced');
  ok($s->has_resources, 'resources announced');
  my $prompts = wait_for($s->list_prompts_f)->get;
  is([ map { $_->{name} } @$prompts ], [qw( greet plain )], 'prompts listed');
  is([ map { $_->{name} } @{ $prompts->[0]{arguments} } ], [qw( name style )], 'with their arguments');

  my $p = wait_for($s->get_prompt_f('greet', { name => 'Ada', style => 'Hi' }))->get;
  is($p->{messages}[0]{content}{text}, 'Hi, Ada!', 'prompts/get with arguments');
  is(scalar @{ $p->{messages} }, 2, 'all messages');
  ok(wait_for($s->get_prompt_f('nope', {}))->is_failed, 'an unknown prompt fails');

  my $res = wait_for($s->list_resources_f)->get;
  is([ map { $_->{uri} } @$res ], [qw( file:///a.txt file:///b.txt )], 'ui:// resources are left out');
  my $c = wait_for($s->read_resource_f('file:///b.txt'))->get;
  is($c->[0]{text}, 'contents of b', 'resources/read');
  ok(wait_for($s->read_resource_f('file:///nope'))->is_failed, 'unknown resource fails');
  wait_for($s->stop_f);

  # A server without those capabilities.
  $home->child('.claude.json')->spew_raw($json->encode({ mcpServers => { n => { command => $^X, args => [ $script, 'normal' ] } } }));
  my $config = Langertha::Raider::MCP::Config->new( root => "$root", claude_layout => 1, env => { %ENV } );
  my $n = Langertha::Raider::MCP::Server->new( spec => $config->server('n'), loop => $loop, base_env => { %ENV }, kill_grace => 0.2 );
  wait_for($n->initialize);
  ok(!$n->has_prompts && !$n->has_resources, 'no capability');
  is(wait_for($n->list_prompts_f)->get, [], 'empty prompt list');
  is(wait_for($n->list_resources_f)->get, [], 'empty resource list');
  wait_for($n->stop_f);
};

done_testing;
