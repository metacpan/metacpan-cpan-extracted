#!/usr/bin/env perl
# ABSTRACT: raider -p / --print and one-shot /commands: custom commands run, reports print, REPL-only and unknown commands are usage errors (ADR 0030 section 4)
use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 encode_utf8 );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::SessionStore;

clear_engine_env();
delete @ENV{qw( ANSI_COLORS_DISABLED RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# A raider CLI whose run answers without a model; it records each prompt
# with the run rules active while it runs.
package My::App {
  use Moose;
  extends 'Langertha::Raider::CLI';
  our @CALLS;
  sub run {
    my ( $self, $text ) = @_;
    push @CALLS, { text => $text, rules => [ map { $_->text } @{ $self->permissions->run_rules } ] };
    return 'answer to the run';
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

sub main_run {
  my ( $stdin, @argv ) = @_;
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  open my $in, '<', \$stdin or die $!;
  @My::App::CALLS = ();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = My::Main->new(
    output => Langertha::Raider::CLI::Output->new( out => $out, color => 0 ),
    err    => $err,
    in     => $in,
  )->run(@argv);
  return ( $exit, $read_out->(), $read_err->() );
}

my $tmp  = Path::Tiny->tempdir;
my $root = $tmp->realpath;
$root->child('CLAUDE.md')->spew_utf8("Project.\n");
$root->child('.claude/commands/fix.md')->touchpath->spew_utf8(
  "---\nallowed-tools: Bash(make:*)\n---\nFix \$ARGUMENTS in session \${CLAUDE_SESSION_ID}.\n");
$root->child('.claude/commands/wipe.md')->touchpath->spew_utf8("!`rm -rf build`\n");
my @base = ( '-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace' );
my $sessions = sub { scalar( () = Langertha::Raider::SessionStore->new( root => "$root" )->ids ) };

subtest 'a custom command runs, with its run options' => sub {
  my ( $exit, $out, $err ) = main_run( '', @base, '--no-session', '-p', '/fix', 'the build' );
  is $exit, 0, 'exit 0';
  is scalar @My::App::CALLS, 1, 'one run';
  like $My::App::CALLS[0]{text}, qr{\A<command-message>fix is running\x{2026}</command-message>\n<command-name>/fix</command-name>\n<command-args>the build</command-args>\n\nFix the build in session \.\z},
    'the framed prompt (no session, no id)';
  is $My::App::CALLS[0]{rules}, [ 'Bash(make:*)' ], 'allowed-tools during the run';
  like $out, qr/\Aanswer to the run\n/, 'the answer';
};

subtest '--print reads stdin; a session is made for the run and named in the body' => sub {
  my $before = $sessions->();
  my ( $exit, $out, $err ) = main_run( "/fix stdin\n", @base, '--print' );
  is $exit, 0, 'exit 0';
  is $sessions->(), $before + 1, 'one session';
  my ( $id ) = $err =~ /^session (\S+) /m;
  ok $id, 'announced';
  like $My::App::CALLS[0]{text}, qr/Fix stdin in session \Q$id\E\.\z/, '${CLAUDE_SESSION_ID} is the session';
};

subtest 'a reporting built-in prints and leaves, no run, no session' => sub {
  my $before = $sessions->();
  my ( $exit, $out ) = main_run( '', @base, '-p', '/help' );
  is $exit, 0, 'exit 0';
  like $out, qr/^commands:$/m, 'the help';
  like $out, qr{^  /fix\b}m, 'with the custom commands';
  is \@My::App::CALLS, [], 'nothing ran';
  is $sessions->(), $before, 'no session';
  ( $exit, $out ) = main_run( '', @base, '--json', '/permissions' );
  is $exit, 0, 'with --json too';
  like $out, qr/^permissions: mode default/m, 'the plain report, no document';
};

subtest '/init runs its model turn' => sub {
  my ( $exit ) = main_run( '', @base, '--no-session', '-p', '/init' );
  is $exit, 0, 'exit 0';
  like $My::App::CALLS[0]{text}, qr/CLAUDE\.md/, 'the init request went to the model';
};

subtest 'REPL-only and unknown commands are usage errors; a path is a prompt' => sub {
  for my $cmd ( '/clear', '/model gpt-5', '/reload', '/pack on x' ) {
    my ( $exit, $out, $err ) = main_run( '', @base, '-p', $cmd );
    is $exit, 2, "$cmd: exit 2";
    my ( $name ) = $cmd =~ m{\A/(\S+)};
    is $err, "/$name: not in a one-shot run, only in the REPL\n", "$cmd: said so";
  }
  my ( $exit, $out, $err ) = main_run( '', @base, '-p', '/nope' );
  is $exit, 2, 'unknown: exit 2';
  is $err, "unknown command: /nope\n", 'said so';
  is \@My::App::CALLS, [], 'nothing ran';
  ( $exit ) = main_run( '', @base, '--no-session', '/etc/hosts is broken' );
  is $exit, 0, 'a path';
  is $My::App::CALLS[0]{text}, '/etc/hosts is broken', 'sent as typed';
};

subtest 'a render that aborts: exit 1, nothing sent' => sub {
  my ( $exit, $out, $err ) = main_run( '', @base, '--no-session', '--permission-mode', 'default', '-p', '/wipe' );
  is $exit, 1, 'exit 1';
  like $err, qr/\Aerror: Shell command permission check failed for pattern "!`rm -rf build`" in \/wipe: /, 'the reason';
  is \@My::App::CALLS, [], 'nothing ran';
};

subtest 'a machine format gets the run document' => sub {
  my ( $exit, $out ) = main_run( '', @base, '--no-session', '--json', '-p', '/fix x' );
  is $exit, 0, 'exit 0';
  my $doc = JSON::MaybeXS->new->decode( encode_utf8($out) );
  is $doc->{status}, 'completed', 'completed';
  is $doc->{response}, 'answer to the run', 'the answer';
};

subtest '-p with -i is a usage error' => sub {
  my ( $exit, $out, $err ) = main_run( '', @base, '-p', '-i', 'x' );
  is $exit, 2, 'exit 2';
  like $err, qr/-p\/--print, -i\/--interactive: only one of them at a time/, 'said so';
  like( My::Main->usage, qr/^  -p, --print /m, 'in --help' );
};

done_testing;
