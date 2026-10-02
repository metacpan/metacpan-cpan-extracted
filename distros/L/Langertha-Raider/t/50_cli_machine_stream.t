#!/usr/bin/env perl
# ABSTRACT: raider's --stream-json, --stream-msgpack, --stream-yaml: events, framing, a real raid's tool events

use strict;
use warnings;
use utf8;
use Test2::V0;
use Data::MessagePack;
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::SeqEngine;
use Langertha::Raider::CLI::Machine;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider;

clear_engine_env();

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub app_class { 'Test::Raider::SeqEngine::App' }
  __PACKAGE__->meta->make_immutable;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; my $b = $buf; $b } );
}

# Reads every event out of one byte stream, the way a consumer would.
sub read_stream {
  my ( $format, $octets ) = @_;
  if ($format eq 'json') {
    my $json = JSON::MaybeXS->new(utf8 => 1);
    return map { $json->decode($_) } split /\n/, $octets;
  }
  if ($format eq 'msgpack') {
    my $unpacker = Data::MessagePack::Unpacker->new->utf8(1);
    my ( @events, $offset );
    $offset = 0;
    while ($offset < length $octets) {
      $offset = $unpacker->execute($octets, $offset);
      last unless $unpacker->is_finished;
      push @events, $unpacker->data;
      $unpacker->reset;
    }
    return @events;
  }
  return YAML::PP->new(boolean => 'JSON::PP')->load_string(decode_utf8($octets));
}

sub main_run {
  my ( @argv ) = @_;
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  open my $in, '<', \'' or die $!;
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = My::Main->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
    in     => $in,
  )->run(@argv);
  return ( $exit, $read_out->(), decode_utf8($read_err->()) );
}

my $root = tempdir(CLEANUP => 1);
my @base = ( '-r', $root, '-e', 'openai', '-k', 'test', '-m', 'seq-model', '--no-trace' );

subtest 'events: fields, seq, framing in every encoding' => sub {
  for my $format (qw( json msgpack yaml )) {
    my ( $fh, $read ) = buffer();
    my $t = 100;
    my $machine = Langertha::Raider::CLI::Machine->new(format => $format, stream => 1, out => $fh,
      clock => sub { $t += 0.5 });
    $machine->event('run.started', engine => 'openai');
    $machine->event('message', role => 'assistant', content => "zwei\nZeilen ✓");
    $machine->finish($machine->document(completed => response => 'ok', elapsed => 1));
    my @events = read_stream($format, $read->());
    is(\@events, [
      { version => 1, type => 'run.started', seq => 1, time => 100.5, engine => 'openai' },
      { version => 1, type => 'message', seq => 2, time => 101, role => 'assistant', content => "zwei\nZeilen ✓" },
      { version => 1, type => 'run.finished', seq => 3, time => 101.5,
        status => 'completed', response => 'ok', elapsed => 1 },
    ], $format.': three events read back from one byte stream');
  }
  my ( $fh, $read ) = buffer();
  my $machine = Langertha::Raider::CLI::Machine->new(format => 'json', stream => 1, out => $fh);
  $machine->event('message', content => "a\nb");
  $machine->event('message', content => 'c');
  my @lines = split /\n/, $read->();
  is(scalar @lines, 2, 'json: one line per event, newlines in text escaped');
  like(decode_utf8(Langertha::Raider::CLI::Machine->new(format => 'yaml', stream => 1)->encode({ a => 1 })),
    qr/\A---\n/, 'yaml: every event starts a document');
};

subtest 'Events plugin: tool.call and tool.result' => sub {
  my @got;
  my $plugin = Langertha::Raider->new(engine => Test::Raider::SeqEngine::Engine->new, plugins => [ '+Langertha::Raider::Plugin::Events' =>
    { on_event => sub { push @got, [ @_ ] } } ])->plugin_instances->[0];
  my @tc = $plugin->plugin_before_tool_call('bash', { command => 'ls' })->get;
  is(\@tc, [ 'bash', { command => 'ls' } ], 'the call passes through');
  my $result = { content => [ { type => 'text', text => 'abc' }, { type => 'text', text => 'defg' } ] };
  ref_is($plugin->plugin_after_tool_call('bash', {}, $result)->get, $result, 'the result passes through');
  $plugin->plugin_before_tool_call('t', undef)->get;
  $plugin->plugin_after_tool_call('t', {}, { content => [ { type => 'text', text => 'no' } ], isError => 1 })->get;
  $plugin->plugin_before_raid([])->get;
  $plugin->plugin_before_tool_call('t', {})->get;
  $plugin->plugin_after_tool_call('t', {}, 'plain')->get;
  is(\@got, [
    [ 'tool.call', call => 'c1', name => 'bash', arguments => { command => 'ls' }, status => 'dispatched' ],
    [ 'tool.result', call => 'c1', name => 'bash', status => 'succeeded', ok => T(), size => 7, content => 'abcdefg' ],
    [ 'tool.call', call => 'c2', name => 't', arguments => {}, status => 'dispatched' ],
    [ 'tool.result', call => 'c2', name => 't', status => 'failed', ok => F(), size => 2, content => 'no' ],
    [ 'tool.call', call => 'c1', name => 't', arguments => {}, status => 'dispatched' ],
    [ 'tool.result', call => 'c1', name => 't', status => 'succeeded', ok => T(), size => 5, content => 'plain' ],
  ], 'events with call ids counted per raid, outcome and the whole text');

  my ( $fh, $read ) = buffer();
  my $machine = Langertha::Raider::CLI::Machine->new(format => 'json', stream => 1, out => $fh,
    max_content_length => 5);
  $machine->event('tool.result', call => 'c1', content => 'abcdefg', size => 7);
  $machine->event('tool.result', call => 'c2', content => 'abc', size => 3);
  my @events = read_stream(json => $read->());
  like($events[0], { content => 'abcde', truncated => T(), size => 7 }, 'the stream cuts the content');
  like($events[1], { content => 'abc', truncated => F() }, 'and flags whether it did');
};

subtest 'a real raid as a stream' => sub {
  for my $format (qw( json msgpack yaml )) {
    my ( $exit, $out, $err ) = main_run(@base, '--stream-'.$format, 'hi');
    is($exit, 0, '--stream-'.$format.': exits 0');
    my @events = read_stream($format, $out);
    is([ map { $_->{type} } @events ],
      [qw( run.started run.state tool.call tool.result tool.call tool.result message run.state run.finished )],
      '--stream-'.$format.': the events of the run, in order');
    is([ map { $_->{seq} } @events ], [ 1 .. 9 ], 'seq counts up');
    ok(!(grep { ($_->{version} // 0) != 1 || !$_->{time} } @events), 'every event has version and time');
    like($events[0], { engine => 'openai', model => 'seq-model' }, 'run.started');
    is($events[1]{state}, 'running', 'running');
    like($events[2], { name => 'bash', arguments => { command => 'ls' } }, 'tool.call');
    like($events[3], { name => 'bash', size => 1500, truncated => T(), ok => T() }, 'tool.result, cut');
    is(length $events[3]{content}, 1000, 'content cut to 1000 characters');
    like($events[5], { name => 'broken', ok => F(), truncated => F(), content => "nope: ä\nline 2" },
      'a tool error');
    like($events[6], { role => 'assistant', content => 'Fertig ✓' }, 'the final message');
    is($events[7]{state}, 'completed', 'completed');
    like($events[8], { status => 'completed', response => 'Fertig ✓', version => 1,
      metrics => { tool_calls => 2 }, elapsed => E() }, 'run.finished carries the document');
    is($err, '', 'nothing on stderr');
  }
};

subtest 'a failed run still ends in run.finished' => sub {
  my ( $exit, $out ) = main_run(@base, '--stream-json', 'fail');
  is($exit, 1, 'exits 1');
  my @events = read_stream(json => $out);
  is([ map { $_->{type} } @events ], [qw( run.started run.state run.state run.finished )], 'events');
  is($events[2]{state}, 'failed', 'failed');
  like($events[-1], { type => 'run.finished', status => 'failed', error => 'kaputt', elapsed => E() },
    'the failed document last');
};

subtest 'all six flags exclude each other' => sub {
  my ( $exit, $out, $err ) = main_run(@base, '--json', '--stream-json', 'hi');
  is($exit, 2, 'a document and a stream');
  is($err, "--json, --stream-json: only one machine output format at a time\n", 'reported');
  is($out, '', 'no output');
  ( $exit, $out, $err ) = main_run(@base, '--stream-yaml', '--stream-msgpack', 'hi');
  is($exit, 2, 'two streams');
  ( $exit, $out, $err ) = main_run(@base, '--stream-json=2', 'hi');
  is($exit, 2, 'an unknown version');
  is($err, "unknown --stream-json version '2' (known: 1)\n", 'reported');
  ( $exit, $out ) = main_run(@base, '--stream-msgpack=1', 'hi');
  is($exit, 0, 'version 1');
  is((read_stream(msgpack => $out))[-1]{version}, 1, 'written as version 1');
};

subtest 'bin/raider --stream-json' => sub {
  my $repo = path(__FILE__)->absolute->parent->parent;
  my @cmd = ( $^X, '-I'.$repo->child('lib'), $repo->child('bin', 'raider')->stringify );
  my $q = join ' ', map { "'$_'" } @cmd, '-r', $root, '-e', 'openai', '-k', 'test', '--stream-json',
    '-o', 'url=http://127.0.0.1:1', 'hi';
  my $out = `$q 2>/dev/null </dev/null`;
  is($? >> 8, 1, 'unreachable engine: run failed');
  my @events = read_stream(json => $out);
  is($events[0]{type}, 'run.started', 'starts');
  like($events[-1], { type => 'run.finished', status => 'failed', error => T() }, 'ends in run.finished');
};

done_testing;
