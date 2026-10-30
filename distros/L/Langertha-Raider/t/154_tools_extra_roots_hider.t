#!/usr/bin/env perl
# ABSTRACT: File and search tools: additional directories, and files a permission rule hides from a search (ADR 0021, k154)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::SearchTools;

my $tmp   = Path::Tiny->tempdir;
my $root  = $tmp->child('proj');
my $extra = $tmp->child('extra');
my $other = $tmp->child('other');
$root->child('lib')->mkpath;
$root->child('secrets')->mkpath;
$extra->mkpath;
$other->mkpath;
$root->child('lib/a.txt')->spew("token=public\n");
$root->child('secrets/key')->spew("token=abc\n");
$extra->child('notes.txt')->spew("token=extra\n");
$other->child('x.txt')->spew("token=other\n");

sub run_tool {
  my ( $server, $name, $args ) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  my $r = $tool->code->( $tool, $args );
  return ( $r->{content}[0]{text}, $r->{isError} ? 1 : 0 );
}

subtest 'file tools: extra roots' => sub {
  my $files = build_file_tools_server( root => "$root", extra_roots => [ "$extra", "$tmp/missing" ] );
  my ( $text, $err ) = run_tool( $files, read_file => { path => $extra->child('notes.txt')->stringify } );
  is [ $text, $err ], [ "1\ttoken=extra\n2\t", 0 ], 'reads in an extra root';
  ( $text, $err ) = run_tool( $files, write_file => { path => $extra->child('new.txt')->stringify, content => 'n' } );
  is $err, 0, 'writes in an extra root';
  is $extra->child('new.txt')->slurp, 'n', '... really';
  ( $text, $err ) = run_tool( $files, read_file => { path => $other->child('x.txt')->stringify } );
  is $err, 1, 'another directory is still refused';
  like $text, qr/Path escapes root/, '... as before';
  ( $text, $err ) = run_tool( $files, read_file => { path => 'lib/a.txt' } );
  is $text, "1\ttoken=public\n2\t", 'relative paths stay under the root';
};

subtest 'search tools: extra roots' => sub {
  my $s = Langertha::Raider::SearchTools->new( root => "$root", rg => 0, extra_roots => ["$extra"] );
  my $real_extra = $extra->realpath;
  like $s->grep( { pattern => 'token', path => "$extra", output_mode => 'content' } ),
    qr/\A\Q$real_extra\E\/notes\.txt:1:token=extra\z/, 'results in an extra root are absolute';
  like $s->glob( { pattern => '*.txt', path => "$extra" } ), qr/\Q$real_extra\E\/notes\.txt/, 'glob as well';
  like dies { $s->grep( { pattern => 'x', path => "$other" } ) }, qr/path escapes root/, 'another directory is refused';
};

subtest 'search tools: the hider' => sub {
  my @asked;
  my $hide = sub { push @asked, $_[0]; $_[0] =~ m{/secrets/} };
  my $on = 1;
  for my $rg ( 0, 'rg-that-must-not-run' ) {
    my $s = Langertha::Raider::SearchTools->new( root => "$root", rg => $rg, hider => sub { $on ? $hide : undef } );
    my $text = $s->grep( { pattern => 'token', output_mode => 'content' } );
    is $text, "lib/a.txt:1:token=public\n\n(1 path hidden by permission rules)", 'grep: hidden file left out, counted'
      .( $rg ? ' (in Perl, whatever rg says)' : '' );
    is $s->glob( { pattern => '**/*' } ) =~ s/\n\n.*//sr, 'lib/a.txt', 'glob: left out';
    like $s->glob( { pattern => '**/*' } ), qr/\(1 path hidden by permission rules\)\z/, '... counted';
    is $s->grep( { pattern => 'nothing-matches' } ), "No matches found\n\n(1 path hidden by permission rules)",
      'counted without a match too';
  }
  ok( ( grep { m{/secrets/key\z} } @asked ), 'the hider gets real absolute paths' );
  $on = 0;
  my $s = Langertha::Raider::SearchTools->new( root => "$root", rg => 0, hider => sub { $on ? $hide : undef } );
  like $s->grep( { pattern => 'token', output_mode => 'content' } ), qr{secrets/key:1:token=abc}, 'no hider in force: all files';
  unlike $s->grep( { pattern => 'token' } ), qr/hidden/, 'and no note';
};

done_testing;
