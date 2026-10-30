#!/usr/bin/env perl
# ABSTRACT: NestedMemory appends a subtree's CLAUDE.md to the first file tool result in it, once (ADR 0019 §2, k151)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Context;
use Langertha::Raider::Plugin::NestedMemory;

local %ENV = %ENV;
delete $ENV{CLAUDE_CONFIG_DIR};
$ENV{HOME} = tempdir(CLEANUP => 1);

my $root = path(tempdir(CLEANUP => 1))->realpath;
sub put { my $f = $root->child($_[0]); $f->parent->mkpath; $f->spew_utf8($_[1]); $f }
put('CLAUDE.md', "top\n");
put('a/CLAUDE.md', "rule of a\n");
put('a/b/CLAUDE.md', "rule of b\n");
put('a/b/f.txt', "f\n");
put('c/CLAUDE.md', "rule of c\n");
put('d/CLAUDE.md', "rule of d\n");

my $host = bless {}, 'My::Host';   # the plugin keeps a weak reference to it
sub plugin {
  my ( $context ) = @_;
  return Langertha::Raider::Plugin::NestedMemory->new(host => $host, context => $context);
}
sub result { { content => [ { type => 'text', text => $_[0] } ], ( $_[1] ? ( isError => 1 ) : () ) } }
sub after { my ( $p, @args ) = @_; return $p->plugin_after_tool_call(@args)->get }
sub texts { [ map { $_->{text} } @{ $_[0]{content} } ] }

subtest 'first touch of a subtree: its CLAUDE.md files, top down, as a system reminder' => sub {
  my $p = plugin(Langertha::Raider::Context->new(root => "$root"));
  my $out = after($p, read_file => { path => 'a/b/f.txt' }, result('f'));
  is(scalar @{ $out->{content} }, 2, 'one block added');
  is(texts($out)->[0], 'f', 'the result first, unchanged');
  like(texts($out)->[1], qr{\A<system-reminder>\nContents of \Q$root\E/a/CLAUDE\.md \([^)]+\):\n\nrule of a\n\nContents of \Q$root\E/a/b/CLAUDE\.md \([^)]+\):\n\nrule of b\n</system-reminder>\z},
    'both files, wrapped');
  is(after($p, read_file => { path => 'a/b/f.txt' }, result('f')), result('f'), 'second touch: untouched');
  is(after($p, list_files => { path => 'a' }, result('ls')), result('ls'), 'a/ already delivered');
};

subtest 'which calls count' => sub {
  my $p = plugin(Langertha::Raider::Context->new(root => "$root"));
  is(after($p, read_file => { path => 'CLAUDE.md' }, result('x')), result('x'), 'the root itself: no nested file');
  is(after($p, read_file => { path => '/etc/hostname' }, result('x')), result('x'), 'outside the root');
  is(after($p, bash => { command => 'cat c/x' }, result('x')), result('x'), 'no path argument');
  is(after($p, read_file => { path => 'c/x' }, result('nope', 1)), result('nope', 1), 'an error result is left alone');
  like(texts(after($p, read_file => { path => 'c/x' }, result('x')))->[1], qr/rule of c/,
    '... and used up nothing');
  like(texts(after($p, grep => { file_path => "$root/d/y" }, result('x')))->[1], qr/rule of d/,
    'file_path of any tool, absolute');
  my $cut = { %{ result('x') }, cancelled => 1 };
  is(after(plugin(Langertha::Raider::Context->new(root => "$root")), read_file => { path => 'd/y' }, $cut), $cut,
    'a cancelled call is left alone');
  is(after($p, read_file => undef, 'plain'), 'plain', 'a result that is no hash');
};

subtest 'only in the Claude layout' => sub {
  my $raider = path(tempdir(CLEANUP => 1))->realpath;
  $raider->child('.raider')->mkpath;
  $raider->child('sub')->mkpath;
  $raider->child('sub', 'CLAUDE.md')->spew_utf8("nested\n");
  my $p = plugin(Langertha::Raider::Context->new(root => "$raider"));
  is(after($p, read_file => { path => 'sub/x' }, result('x')), result('x'), 'raider project: nothing');
};

done_testing;
