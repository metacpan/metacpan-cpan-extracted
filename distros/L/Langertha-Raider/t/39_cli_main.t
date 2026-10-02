#!/usr/bin/env perl
# ABSTRACT: raider's command line, REPL, one-shot and --json runs, exit statuses

use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::CLI::Machine;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;
use Langertha::Raider::CLI::Runner;

clear_engine_env();
delete $ENV{ANSI_COLORS_DISABLED};

# A raider CLI whose run answers without a model.
package My::App {
  use Moose;
  extends 'Langertha::Raider::CLI';
  has calls => ( is => 'ro', default => sub { [] } );
  sub run {
    my ( $self, $text ) = @_;
    push @{ $self->calls }, $text;
    die "boom\n" if $text eq 'fail';
    return 'answer to '.$text;
  }
  __PACKAGE__->meta->make_immutable;
}

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub app_class { 'My::App' }
  __PACKAGE__->meta->make_immutable;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; decode_utf8($buf) } );
}

sub input { my ( $text ) = @_; open my $fh, '<', \$text or die $!; $fh }

# Runs My::Main (or $class) on @argv with $stdin; returns exit status,
# stdout and stderr.
sub main_run {
  my ( $stdin, @argv ) = @_;
  my $class = ref $argv[0] eq 'SCALAR' ? ${ shift @argv } : 'My::Main';
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = $class->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
    in     => input($stdin),
  )->run(@argv);
  return ( $exit, $read_out->(), $read_err->() );
}

my $root = tempdir(CLEANUP => 1);
my @base = ( '-r', $root, '-e', 'openai', '-k', 'test', '--no-trace' );

subtest 'Runner: human and machine' => sub {
  my $app = My::App->new(root => $root, engine => 'openai', api_key => 'test', trace => 0);
  my ( $fh, $read ) = buffer();
  my $runner = Langertha::Raider::CLI::Runner->new(app => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0));
  ok($runner->run_prompt('hi'), 'finished');
  like($read->(), qr/\Aanswer to hi\n\d+s \| history 0 msgs, 0\/40000 tok \(0%\)\n\z/, 'answer and status line');
  ok($runner->run_prompt(''), 'empty prompt runs nothing');
  is($app->calls, ['hi'], 'one run');

  my ( $jfh, $jread ) = buffer();
  my $json = Langertha::Raider::CLI::Runner->new(app => $app,
    output => Langertha::Raider::CLI::Output->new(out => $jfh, color => 0));
  ok($json->run_prompt('grüß', machine => Langertha::Raider::CLI::Machine->new(format => 'json', out => $jfh)),
    'json finished');
  is(JSON::MaybeXS->new->decode($jread->()),
    { version => 1, status => 'completed', response => 'answer to grüß', metrics => hash { field raids => E(); etc() },
      elapsed => E() }, 'json document');
  my ( $efh, $eread ) = buffer();
  ok(!Langertha::Raider::CLI::Runner->new(app => $app,
    output => Langertha::Raider::CLI::Output->new(out => $efh, color => 0))
      ->run_prompt('fail', machine => Langertha::Raider::CLI::Machine->new(format => 'json', out => $efh)),
    'failure');
  is(JSON::MaybeXS->new->decode($eread->()), { version => 1, status => 'failed', error => 'boom', elapsed => E() },
    'json error document');
};

subtest 'REPL reads piped lines to their end' => sub {
  my $app = My::App->new(root => $root, engine => 'openai', api_key => 'test', trace => 0, mission => 'M');
  my ( $fh, $read ) = buffer();
  Langertha::Raider::CLI::REPL->new(
    app    => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0),
    in     => input("hello\n\n  /nope \nfail\n/help\n"),
    active_profiles => ['claude'],
    saved_profiles  => { claude => 1 },
  )->run(qw( first words ));
  my $text = $read->();
  like($text, qr/^persona:  from -M \(\.raider\.md not used\)$/m, 'banner names -M');
  like($text, qr/^profiles: claude \(saved\)$/m, 'banner profiles');
  like($text, qr/^readline: none \(input is not a terminal\)$/m, 'plain reader');
  like($text, qr/^answer to first words\n.*^answer to hello\n/ms, 'argv prompt first, then lines');
  like($text, qr/^error: unknown command: \/nope/m, 'slash command dispatched');
  like($text, qr/^error: boom$/m, 'failed run reported, REPL goes on');
  like($text, qr/^  \/pack NAME/m, '/help after the failure');
  is($app->calls, [ 'first words', 'hello', 'fail' ], 'runs');

  my ( $qfh, $qread ) = buffer();
  my $quit = My::App->new(root => $root, engine => 'openai', api_key => 'test', trace => 0);
  Langertha::Raider::CLI::REPL->new(app => $quit,
    output => Langertha::Raider::CLI::Output->new(out => $qfh, color => 0),
    in => input("/quit\nnot run\n"))->run;
  like($qread->(), qr/^bye\.\n\z/m, '/quit leaves');
  is($quit->calls, [], 'nothing after /quit');
};

subtest 'usage errors exit 2' => sub {
  my ( $exit, $out, $err ) = main_run('', '--bogus');
  is($exit, 2, 'unknown option');
  like($err, qr/Unknown option: bogus.*Bad options/s, 'reported');
  ( $exit, $out, $err ) = main_run('', @base, '-o', 'temperature');
  is($exit, 2, 'bad -o');
  like($err, qr/bad -o spec 'temperature'/, 'reported');
  ( $exit, $out, $err ) = main_run('', 'config', 'nope');
  is($exit, 2, 'unknown config subcommand');
  ( $exit, $out, $err ) = main_run('', @base);
  is($exit, 2, 'no prompt');
  is($err, "No prompt given.\n", 'reported');
};

subtest 'configuration errors exit 3' => sub {
  my $broken = tempdir(CLEANUP => 1);
  path($broken)->child('.raider.yml')->spew_utf8("- a\n");
  my ( $exit, $out, $err ) = main_run('', '-r', $broken, '-e', 'openai', 'hi');
  is($exit, 3, 'broken .raider.yml');
  like($err, qr/\.raider\.yml/, 'names the file');
  path($broken)->child('.raider.yml')->spew_utf8("packs:\n  git-guru: 1\n");
  ( $exit, $out, $err ) = main_run('', 'config', 'explain', '-r', $broken, '-e', 'openai');
  is($exit, 3, 'a mapping under a raider key');
  like($err, qr/\.raider\.yml: packs: .*must not be a mapping\n\z/, 'names file and key');
  unlike($err, qr/ line \d+/, 'no Perl source location');
  path($broken)->child('.raider.yml')->spew_utf8("default:\n  packs:\n    git-guru: 1\n");
  ( $exit, $out, $err ) = main_run('', 'config', 'explain', '-r', $broken, '-e', 'openai');
  is($exit, 3, 'a mapping under a raider key in default:');
  is($err, 'Cannot use '.path($broken)->child('.raider.yml')
    .": default.packs: configures raider; must not be a mapping\n", 'one clean line');
  path($broken)->child('.raider.yml')->spew_utf8("a: [\n");
  ( $exit, $out, $err ) = main_run('', 'config', 'explain', '-r', $broken, '-e', 'openai');
  is($exit, 3, 'a parse error');
  like($err, qr/\ACannot parse .*\.raider\.yml: [^\n]+\n\z/, 'one line naming the file');
  unlike($err, qr/ line \d+/, 'no Perl source location');
  path($broken)->child('.raider.yml')->spew_utf8("key: \"unterminated\n");
  ( $exit, $out, $err ) = main_run('', 'config', 'explain', '-r', $broken, '-e', 'openai');
  is($exit, 3, 'a detailed parse error');
  is($err, 'Cannot parse '.path($broken)->child('.raider.yml')
    .": line 1, column 1: Missing closing quote <\"> at EOF\n", 'summed up on one clean line');
  path($broken)->child('.raider.yml')->spew_utf8("detect: [ perl ]\n");
  ( $exit, $out, $err ) = main_run('', 'config', 'explain', '-r', $broken, '-e', 'openai');
  is($exit, 3, 'an invalid detect setting');
  is($err, "Invalid detect setting detect: must be a map of pack name to rule, or false\n", 'one clean line');
  ( $exit, $out, $err ) = main_run('', '-r', $root, '-e', 'nope', 'hi');
  is($exit, 3, 'unknown engine');
  like($err, qr/Unknown engine: nope/, 'reported');
};

subtest 'success exits 0, a failed run 1' => sub {
  my ( $exit, $out, $err ) = main_run('', '--help');
  is($exit, 0, '--help');
  like($out, qr/^Usage: raider .*^Exit status: 0 success, 1 the run failed, 2 usage error,$/ms, 'usage');
  ( $exit, $out ) = main_run('', @base, 'hello', 'there');
  is($exit, 0, 'one-shot from argv');
  like($out, qr/\Aanswer to hello there\n/, 'answer');
  ( $exit, $out ) = main_run("from stdin\n", @base);
  is($exit, 0, 'one-shot from stdin');
  like($out, qr/\Aanswer to from stdin\n/, 'answer');
  ( $exit, $out ) = main_run('', @base, '--json', 'hi');
  is($exit, 0, '--json');
  like(JSON::MaybeXS->new->decode($out), { version => 1, status => 'completed', response => 'answer to hi' },
    'only the JSON document on stdout');
  ( $exit, $out ) = main_run('', @base, '--json', 'fail');
  is($exit, 1, 'failed run');
  is(JSON::MaybeXS->new->decode($out), { version => 1, status => 'failed', error => 'boom', elapsed => E(),
      session => { id => T(), path => T() } },
    'JSON error document');
  ( $exit, $out ) = main_run('', @base, 'fail');
  is($exit, 1, 'failed run without --json');
  is($out, "error: boom\n", 'error line');
  ( $exit, $out ) = main_run("hi\n/quit\n", @base, '-i');
  is($exit, 0, 'REPL');
  like($out, qr/^answer to hi\n.*^bye\.$/ms, 'REPL ran');
  ( $exit, $out ) = main_run('', @base, 'config', 'explain');
  is($exit, 0, 'config explain');
};

subtest '--version: raider and Langertha, exit 0 (k108)' => sub {
  my ( $exit, $out, $err ) = main_run('', '--version');
  is($exit, 0, 'exits 0');
  is($out, 'raider '.$Langertha::Raider::VERSION.' (Langertha '.$Langertha::VERSION.")\n",
    'one line: raider, then Langertha core');
  is($err, '', 'nothing on stderr');
  ( $exit, $out ) = main_run('', @base, '--version', 'hello');
  is($exit, 0, 'with options and a prompt');
  like($out, qr/\Araider \S+ \(Langertha \S+\)\n\z/, 'only the version, no run');
};

subtest 'config explain after the options' => sub {
  my ( $exit, $out, $err ) = main_run('', @base, 'config', 'explain');
  is($exit, 0, 'exits 0');
  like($out, qr/^file:   .*\.raider\.yml.*^engine: openai$/ms, 'the config report');
  unlike($out, qr/answer to/, 'no prompt run');
  ( $exit, $out, $err ) = main_run('', '-r', $root, '-e', 'openai', 'config', 'explain', '--no-color');
  is($exit, 0, 'options on both sides');
  like($out, qr/^engine: openai$/m, 'the config report');
  ( $exit, $out ) = main_run('', @base, 'config', 'the', 'build');
  is($exit, 0, 'a prompt starting with config');
  like($out, qr/\Aanswer to config the build\n/, 'runs as a prompt');
  ( $exit, $out ) = main_run('', @base, 'config', 'explain', 'the', 'build');
  like($out, qr/\Aanswer to config explain the build\n/, 'more words: still a prompt');
};

subtest '--json keeps the trace off unless asked' => sub {
  my $main = Langertha::Raider::CLI::Main->new;
  my %args = $main->app_args(($main->parse_options(qw( --json hi )))[0]);
  is($args{trace}, 0, '--json');
  %args = $main->app_args(($main->parse_options(qw( --json --trace hi )))[0]);
  is($args{trace}, 1, '--json --trace');
  %args = $main->app_args(($main->parse_options(qw( hi )))[0]);
  ok(!exists $args{trace}, 'default left to the terminal');
};

subtest 'bin/raider' => sub {
  my $repo = path(__FILE__)->absolute->parent->parent;
  my @cmd = ($^X, '-I'.$repo->child('lib'), $repo->child('bin', 'raider'));
  my $q = sub { join ' ', map { "'$_'" } @_ };
  `@{[ $q->(@cmd, '--bogus') ]} 2>&1 </dev/null`;
  is($? >> 8, 2, 'usage error');
  my $out = `@{[ $q->(@cmd, @base, '--json', '-o', 'url=http://127.0.0.1:1', 'hi') ]} 2>/dev/null </dev/null`;
  is($? >> 8, 1, 'unreachable engine: run failed');
  like(JSON::MaybeXS->new->decode($out), { version => 1, status => 'failed', error => T(), elapsed => E() },
    'stdout is the JSON error document');
  `printf '/quit\\n' | @{[ $q->(@cmd, @base, '-i') ]} >/dev/null 2>&1`;
  is($? >> 8, 0, 'piped REPL ends');
};

subtest '--help lists every option the parser takes (k104)' => sub {
  my $usage = Langertha::Raider::CLI::Main->usage;
  my ($spec) = path($INC{'Langertha/Raider/CLI/Main.pm'})->slurp_utf8
    =~ /getoptionsfromarray\(\\\@argv,\n(.*?)\n    \);/s;
  ok($spec, 'found the Getopt spec') or return;
  my @long;
  for my $entry ( $spec =~ /^\s+('[^']+')\s+=>/mg ) {
    # names, an optional =/: type spec, an optional ! (negatable)
    my ( $names, $neg ) = $entry =~ /\A'([A-Za-z|-]+)(?:[=:][^'!]*)?(!)?'\z/;
    ok(defined $names, 'spec entry '.$entry.' parses') or next;
    my @n = grep { length > 1 } split /\|/, $names;
    push @long, @n, $neg ? ( map { 'no-'.$_ } @n ) : ();
  }
  push @long, qw( json msgpack yaml stream-json stream-msgpack stream-yaml );   # %MACHINE_FLAG
  ok(scalar(@long) > 25, 'options collected');
  for my $name (@long) {
    like($usage, qr/(?<![\w-])--\Q$name\E(?![\w-])/, '--'.$name.' in --help');
  }
};

done_testing;
