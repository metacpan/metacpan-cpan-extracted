#!/usr/bin/env perl
# ABSTRACT: Extra roots as a CodeRef are read on every call; /reload reaches the mounted tools (ADR 0021 Nachtrag P2, k158)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::SearchTools;

my $tmp  = Path::Tiny->tempdir->realpath;
my $root = $tmp->child('proj');
my ( $a, $b ) = map { $tmp->child($_) } qw( a b );
$_->mkpath for $root, $a, $b;
$a->child('f.txt')->spew("token=a\n");
$b->child('f.txt')->spew("token=b\n");
symlink "$tmp", $root->child('escape')->stringify;    # a symlink out of the root

sub run_tool {
  my ( $server, $name, $args ) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  my $r = $tool->code->( $tool, $args );
  return ( $r->{content}[0]{text}, $r->{isError} ? 1 : 0 );
}

my @roots = ("$a");
my $live  = sub { [@roots] };

subtest 'file tools follow the source' => sub {
  my $files = build_file_tools_server( root => "$root", extra_roots => $live );
  is [ run_tool( $files, read_file => { path => "$a/f.txt" } ) ], [ "1\ttoken=a\n2\t", 0 ], 'a readable';
  is [ ( run_tool( $files, read_file => { path => "$b/f.txt" } ) )[1] ], [1], 'b refused';
  @roots = ("$b");
  is [ run_tool( $files, read_file => { path => "$b/f.txt" } ) ], [ "1\ttoken=b\n2\t", 0 ], 'b readable after the change';
  my ( $text, $err ) = run_tool( $files, read_file => { path => "$a/f.txt" } );
  is $err, 1, 'a refused after the change';
  like $text, qr/Path escapes root/, '... as before';
  @roots = ();
  is [ ( run_tool( $files, read_file => { path => "$b/f.txt" } ) )[1] ], [1], 'no roots: refused';
  @roots = ("$a");
  ( $text, $err ) = run_tool( $files, read_file => { path => "$root/escape/b/f.txt" } );
  is $err, 1, 'a symlink out of the root stays refused';
};

subtest 'search tools follow the source' => sub {
  @roots = ("$a");
  my $s = Langertha::Raider::SearchTools->new( root => "$root", rg => 0, extra_roots => $live );
  like $s->grep( { pattern => 'token', path => "$a", output_mode => 'content' } ), qr/token=a/, 'a searchable';
  like dies { $s->grep( { pattern => 'x', path => "$b" } ) }, qr/path escapes root/, 'b refused';
  @roots = ("$b");
  like $s->grep( { pattern => 'token', path => "$b", output_mode => 'content' } ), qr/token=b/, 'b searchable after the change';
  like dies { $s->grep( { pattern => 'x', path => "$a" } ) }, qr/path escapes root/, 'a refused after the change';
};

done_testing;
