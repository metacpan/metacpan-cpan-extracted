#!/usr/bin/env perl
# ABSTRACT: raider's machine output: --json, --msgpack, --yaml documents, versions, stdout discipline

use strict;
use warnings;
use utf8;
use Test2::V0;
use Data::MessagePack;
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use Time::HiRes ();
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::CLI::Machine;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;

clear_engine_env();

# A raider CLI whose run answers without a model.
package My::App {
  use Moose;
  extends 'Langertha::Raider::CLI';
  sub run {
    my ( $self, $text ) = @_;
    die "kaputt: ä\n" if $text eq 'fail';
    Time::HiRes::sleep(0.25) if $text eq 'slow';
    return 'Grüße ✓ '.$text;
  }
  __PACKAGE__->meta->make_immutable;
}

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub app_class { 'My::App' }
  __PACKAGE__->meta->make_immutable;
}

# A handle with the :encoding(UTF-8) layer bin/raider puts on STDOUT, and a
# reader for the octets that reached it.
sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; my $b = $buf; $b } );
}

sub decode_as {
  my ( $format, $octets ) = @_;
  return $format eq 'json'    ? JSON::MaybeXS->new(utf8 => 1)->decode($octets)
       : $format eq 'msgpack' ? Data::MessagePack->new->utf8(1)->unpack($octets)
       :                        YAML::PP->new(boolean => 'JSON::PP')->load_string(decode_utf8($octets));
}

# Runs My::Main on @argv; returns exit status, stdout octets, stderr text.
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
my @base = ( '-r', $root, '-e', 'openai', '-k', 'test', '--no-trace' );

subtest 'one model, three encodings' => sub {
  my $n = 3;
  my $doc = {
    version  => 1,
    status   => 'completed',
    response => 'Grüße ✓',
    metrics  => { raids => 1, time_ms => 12.5, label => "$n" },
    elapsed  => 3,
  };
  for my $format (qw( json msgpack yaml )) {
    my $machine = Langertha::Raider::CLI::Machine->new(format => $format);
    is(decode_as($format, $machine->encode($doc)), $doc, $format.': decodes to the model');
  }
  my $mp = Langertha::Raider::CLI::Machine->new(format => 'msgpack')->encode({ k => "\x{e4}", n => $n });
  like($mp, qr/\xa2\xc3\xa4/, 'msgpack: text as a UTF-8 str, also for a Latin-1 string');
  like($mp, qr/\xa1n\x03/, 'msgpack: a number stays a number');
  my $label = Data::MessagePack->new->unpack(
    Langertha::Raider::CLI::Machine->new(format => 'msgpack')->encode({ l => "$n" }));
  is($label->{l}, '3', 'msgpack: a numeric string stays a string');
  like(decode_utf8(Langertha::Raider::CLI::Machine->new(format => 'json')->encode($doc)),
    qr/\A\{\n   "elapsed" : 3,\n/, 'json: pretty and canonical');
  like(decode_utf8(Langertha::Raider::CLI::Machine->new(format => 'yaml')->encode($doc)),
    qr/\A---\nelapsed: 3\n/, 'yaml: one document with sorted keys');
  my $bools = { t => JSON::MaybeXS->true, f => JSON::MaybeXS->false };
  for my $format (qw( json msgpack yaml )) {
    my $got = decode_as($format, Langertha::Raider::CLI::Machine->new(format => $format)->encode($bools));
    ok($got->{t} && !$got->{f}, $format.': booleans');
  }
};

subtest 'document and finish' => sub {
  my ( $fh, $read ) = buffer();
  my $machine = Langertha::Raider::CLI::Machine->new(format => 'json', out => $fh);
  is($machine->document(failed => error => 'x', elapsed => 0),
    { version => 1, status => 'failed', error => 'x', elapsed => 0 }, 'version and status');
  $machine->event('run.state', state => 'running');
  is($read->(), '', 'no events without stream');
  $machine->finish($machine->document(completed => response => 'ä', elapsed => 1));
  is(decode_as(json => $read->()), { version => 1, status => 'completed', response => 'ä', elapsed => 1 },
    'the document, UTF-8 once, through a handle with an encoding layer');
};

subtest 'the three document flags' => sub {
  for my $format (qw( json msgpack yaml )) {
    my ( $exit, $out, $err ) = main_run(@base, '--'.$format, 'hi');
    is($exit, 0, '--'.$format.': exits 0');
    is(decode_as($format, $out),
      { version => 1, status => 'completed', response => 'Grüße ✓ hi', metrics => T(), elapsed => E(),
        session => { id => T(), path => T() } },
      '--'.$format.': the completed document, alone on stdout');
    is($err, '', '--'.$format.': nothing on stderr');
    ( $exit, $out ) = main_run(@base, '--'.$format, 'fail');
    is($exit, 1, '--'.$format.': a failed run exits 1');
    is(decode_as($format, $out), { version => 1, status => 'failed', error => 'kaputt: ä', elapsed => E(),
      session => { id => T(), path => T() } },
      '--'.$format.': the failed document');
    ( $exit, $out ) = main_run(@base, '--'.$format.'=1', 'hi');
    is($exit, 0, '--'.$format.'=1 is version 1');
    is(decode_as($format, $out)->{version}, 1, 'written as version 1');
  }
};

subtest 'usage errors' => sub {
  my ( $exit, $out, $err ) = main_run(@base, '--json=2', 'hi');
  is($exit, 2, 'an unknown version');
  is($err, "unknown --json version '2' (known: 1)\n", 'reported');
  is($out, '', 'no document');
  ( $exit, $out, $err ) = main_run(@base, '--yaml=one', 'hi');
  is($exit, 2, 'a version that is no number');
  is($err, "unknown --yaml version 'one' (known: 1)\n", 'reported');
  ( $exit, $out, $err ) = main_run(@base, '--json', '--msgpack', 'hi');
  is($exit, 2, 'two machine formats');
  is($err, "--json, --msgpack: only one machine output format at a time\n", 'reported');
  is($out, '', 'no document');
  ( $exit, $out, $err ) = main_run(@base, '--json', '-e', 'nope', 'hi');
  is($exit, 3, 'a configuration error');
  is($out, '', 'no document, only stderr');
  for my $flag (qw( --json --stream-yaml )) {
    ( $exit, $out, $err ) = main_run(@base, '-i', $flag, 'hi');
    is($exit, 2, '-i with '.$flag);
    is($err, $flag.": no machine output in the REPL (-i)\n", 'reported');
    is($out, '', 'no REPL, no document');
  }
};

subtest 'elapsed has fractions of a second' => sub {
  my ( $exit, $out ) = main_run(@base, '--json', 'slow');
  my $elapsed = decode_as(json => $out)->{elapsed};
  ok($elapsed >= 0.2 && $elapsed < 5, 'measured: '.$elapsed);
  isnt($elapsed, int $elapsed, 'not whole seconds');
};

subtest 'only the =N form carries a version' => sub {
  my ( $exit, $out ) = main_run(@base, '--json', '2', 'hi');
  is($exit, 0, 'a number after the flag');
  is(decode_as(json => $out)->{response}, 'Grüße ✓ 2 hi', 'is part of the prompt');
  ( $exit, $out ) = main_run(@base, '--json', '--', '--yaml=5');
  is($exit, 0, 'after --');
  is(decode_as(json => $out)->{response}, 'Grüße ✓ --yaml=5', 'a flag-shaped prompt stays a prompt');
};

subtest 'the trace goes to stderr with a machine format' => sub {
  my $main = Langertha::Raider::CLI::Main->new(err => \*STDERR);
  my %args = $main->app_args(($main->parse_options(qw( --yaml --trace hi )))[0]);
  is($args{trace}, 1, '--trace asked for');
  ref_is($args{trace_out}, \*STDERR, 'printed to err');
  %args = $main->app_args(($main->parse_options(qw( --msgpack hi )))[0]);
  is($args{trace}, 0, 'off by default');
  %args = $main->app_args(($main->parse_options(qw( hi )))[0]);
  ok(!exists $args{trace_out}, 'human output keeps the default');
};

my $repo = path(__FILE__)->absolute->parent->parent;
my @cmd = ( $^X, '-I'.$repo->child('lib'), $repo->child('bin', 'raider')->stringify );
my $q = sub { join ' ', map { "'$_'" } @_ };

subtest 'bin/raider --msgpack writes binary stdout' => sub {
  my $out = `@{[ $q->(@cmd, @base, '--msgpack', '-o', 'url=http://127.0.0.1:1', 'hi') ]} 2>/dev/null </dev/null`;
  is($? >> 8, 1, 'unreachable engine: run failed');
  is(decode_as(msgpack => $out), { version => 1, status => 'failed', error => T(), elapsed => E(),
    session => { id => T(), path => T() } },
    'stdout is one MessagePack document');
};

done_testing;
