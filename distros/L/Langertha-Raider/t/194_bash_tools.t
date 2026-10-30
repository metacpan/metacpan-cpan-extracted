#!/usr/bin/env perl
# ABSTRACT: The bash tool answers like Claude Code's Bash: output, "Exit code N", no output, truncation, timeout to the background, gates
use strict;
use warnings;
use utf8;
use Test2::V0;
use IO::Async::Loop;
use Path::Tiny;
use Langertha::Raider::BashTools;

my $loop = IO::Async::Loop->new;
my @dirs;    # held: a temporary directory goes when its object does

sub shell_tools {
  my ( %arg ) = @_;
  push @dirs, Path::Tiny->tempdir;
  return Langertha::Raider::BashTools->new( loop => $loop, working_directory => $dirs[-1]->stringify, %arg );
}

sub bash {
  my ( $tools, %in ) = @_;
  my ( $text, $is_error ) = $tools->bash( \%in );
  return { text => $text, error => $is_error ? 1 : 0 };
}

subtest 'exit 0: only the output, stdout and stderr in the order written' => sub {
  my $t = shell_tools();
  is( bash( $t, command => 'echo one; echo two >&2; echo three' ),
    { text => "one\ntwo\nthree", error => 0 }, 'combined, no exit code, trailing newline gone' );
};

subtest 'exit 0 without output' => sub {
  is( bash( shell_tools(), command => 'true' ),
    { text => '(Bash completed with no output)', error => 0 }, "Claude Code's text" );
};

subtest 'a failure is an error result that starts with Exit code N' => sub {
  my $t = shell_tools();
  is( bash( $t, command => 'echo half; echo broken >&2; exit 3' ),
    { text => "Exit code 3\nhalf\nbroken", error => 1 }, 'exit code, then the output' );
  is( bash( $t, command => 'exit 2' ), { text => 'Exit code 2', error => 1 }, 'no output: the exit code alone' );
  is( bash( $t, command => 'kill -TERM $$' ), { text => 'Exit code 143', error => 1 }, 'a signal: 128 + its number' );
};

subtest 'runs in the working directory, or the one the call names' => sub {
  my $t = shell_tools();
  my $root = path( $t->working_directory )->realpath;
  is( bash( $t, command => 'pwd -P' )->{text}, "$root", 'the root' );
  is( bash( $t, command => 'true & pwd -P' )->{text}, "$root", 'also after a command sent to the background with &' );
  $root->child('sub')->mkpath;
  is( bash( $t, command => 'pwd -P', working_directory => "$root/sub" )->{text}, "$root/sub", 'working_directory' );
  like( bash( $t, command => 'pwd', working_directory => "$root/nope" ),
    { error => 1, text => qr/\AExit code 1\n.*nope/s }, 'a missing directory fails like cd' );
};

subtest 'output is decoded UTF-8' => sub {
  is( bash( shell_tools(), command => q{printf 'Gr\303\274\303\237e'} )->{text}, 'Grüße', 'characters, not octets' );
};

subtest 'long output keeps its start and its end' => sub {
  my $t = shell_tools( output_limit => 100 );
  my $r = bash( $t, command => q{printf 'A%.0s' $(seq 1 60); printf 'B%.0s' $(seq 1 90)} );
  is( $r->{text}, ( 'A' x 50 )."\n\n... [50 characters truncated] ...\n\n".( 'B' x 50 ), 'first and last half, marker in between' );
  is( bash( $t, command => q{printf 'C%.0s' $(seq 1 100)} )->{text}, 'C' x 100, 'at the limit: untouched' );
  is( Langertha::Raider::BashTools->new( loop => $loop )->output_limit, 30000, "Claude Code's 30000 by default" );
};

subtest 'a command over its timeout goes on in the background' => sub {
  my $t = shell_tools();
  my $marker = path( $t->working_directory )->child('late');
  my $r = bash( $t, command => 'echo early; sleep 2; touch late', timeout => 1 );
  like( $r, { error => 0, text => qr/\ACommand did not complete within its 1s timeout and was moved to the background \(ID: bash_1\)\. .*bash_output \(bash_id: bash_1\).*kill_shell \(shell_id: bash_1\)/ },
    'moved, not killed, with its ID' );
  is( [ $t->background_pids ], [ match qr/\A\d+\z/ ], 'a background shell now' );
  my ( $out ) = $t->bash_output({ bash_id => 'bash_1', block => 1, timeout => 10 });
  is( $out, "<status>completed</status>\n\n<exit_code>0</exit_code>\n\n<stdout>\nearly\n</stdout>", 'it finished there' );
  ok( -e $marker, 'and did its work' );
};

subtest 'timeout: Claude Code limits, in seconds' => sub {
  my $t = shell_tools( max_timeout => 1 );
  like( bash( $t, command => 'sleep 3', timeout => 3600 )->{text}, qr/within its 1s timeout/, 'cut down to max_timeout' );
  $t->stop_all;
  my $d = Langertha::Raider::BashTools->new( loop => $loop );
  is( [ $d->default_timeout, $d->max_timeout ], [ 120, 600 ], 'default 120, at most 600' );
  like( bash( shell_tools( default_timeout => 1 ), command => 'sleep 3', timeout => 0 )->{text}, qr/within its 1s timeout/,
    '0 is no timeout: the default' );
};

subtest 'description is taken and does not change the run' => sub {
  is( bash( shell_tools(), command => 'echo ok', description => 'Say ok' ), { text => 'ok', error => 0 }, 'ok' );
};

subtest 'the gates come first and nothing runs past them' => sub {
  my $t = shell_tools( allowed_commands => ['echo'] );
  my $dir = path( $t->working_directory );
  is( bash( $t, command => 'touch x' ), { text => 'Command not allowed: touch', error => 1 }, 'allowed_commands' );
  ok( !-e $dir->child('x'), 'not run' );
  is( bash( $t, command => 'echo fine' )->{text}, 'fine', 'an allowed command runs' );

  my @seen;
  my $g = shell_tools( validator => sub { push @seen, [@_]; $_[0] =~ /prove/ ? 'refused by loadguard: busy' : 1 } );
  my $gdir = path( $g->working_directory );
  is( bash( $g, command => 'touch y && prove' ), { text => 'Command refused by loadguard: busy', error => 1 }, 'the validator refuses' );
  ok( !-e $gdir->child('y'), 'not run' );
  is( bash( $g, command => 'touch y && prove', run_in_background => 1 ),
    { text => 'Command refused by loadguard: busy', error => 1 }, 'also in the background' );
  ok( !-e $gdir->child('y'), 'not started' );
  is( [ $g->background_pids ], [], 'no background shell' );
  is( $seen[0], [ 'touch y && prove', $g->working_directory ], 'asked with command and directory' );

  is( bash( shell_tools(), command => '  ' ),
    { text => 'No command given: the command parameter must be a non-empty string', error => 1 }, 'an empty command' );
};

subtest 'the command has its own process group, stdin is /dev/null' => sub {
  my $t = shell_tools();
  my ( $pgid, $pid ) = split ' ', bash( $t, command => 'echo $(ps -o pgid= -p $$) $$' )->{text};
  is( $pgid, $pid, 'leads its group' );
  is( bash( $t, command => 'cat' ), { text => '(Bash completed with no output)', error => 0 }, 'reads nothing, does not hang' );
};

done_testing;
