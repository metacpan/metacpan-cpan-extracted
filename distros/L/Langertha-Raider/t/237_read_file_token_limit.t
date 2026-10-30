#!/usr/bin/env perl
# ABSTRACT: read_file refuses a read that returns more than 25000 tokens, as Claude Code does (ADR 0023)
use strict;
use warnings;
use utf8;
use Test2::V0;
use Path::Tiny;

use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::FileTools::ReadState;

my $tmp  = Path::Tiny->tempdir;
my $root = $tmp->realpath;
my $state  = Langertha::Raider::FileTools::ReadState->new;
my $server = build_file_tools_server( root => "$root", read_state => $state );

sub read_file {
  my ($tool) = grep { $_->name eq 'read_file' } @{ $server->tools };
  my $r = $tool->code->( $tool, @_ );
  return ( join( "\n", map { $_->{text} // '' } @{ $r->{content} } ), $r->{isError} ? 1 : 0 );
}

# 1000 lines of 80 characters: ~83 KB with the line numbers, ~20800 tokens;
# 1300 of them go over the limit but stay under 256 KB.
sub lines { join '', map { ( 'x' x 79 )."\n" } 1 .. $_[0] }

subtest 'a read under the limit goes through' => sub {
  $root->child('small.txt')->spew_utf8( lines(1000) );
  my ( $text, $err ) = read_file( { path => 'small.txt' } );
  ok !$err, 'no error';
  like $text, qr/^1000\t/m, 'all lines';
};

subtest 'a read over the limit is refused with the way out' => sub {
  $root->child('big.txt')->spew_utf8( lines(1300) );
  ok -s $root->child('big.txt') < 256 * 1024, 'under the size limit, so the token limit decides';
  my ( $text, $err ) = read_file( { path => 'big.txt' } );
  is $err, 1, 'an error';
  like $text, qr/\AFile content \((\d+) tokens\) exceeds maximum allowed tokens \(25000\)\. Use offset and limit parameters to read specific portions of the file, or search for specific content instead of reading the whole file\.\z/,
    'Claude Code words';
  my ($tokens) = $text =~ /\((\d+) tokens\)/;
  ok $tokens > 25000 && $tokens < 40000, 'the count is a size in tokens, not bytes: '.$tokens;
  ok !$state->has_read( $root->child('big.txt')->stringify ), 'a refused read does not count as read';
};

subtest 'offset and limit read the same file in parts' => sub {
  my ( $text, $err ) = read_file( { path => 'big.txt', offset => 1, limit => 500 } );
  ok !$err, 'a part goes through';
  like $text, qr/^500\t/m, 'the part';
  ok $state->has_read( $root->child('big.txt')->stringify ), 'and counts as read';
};

subtest 'a part over the limit is refused as well' => sub {
  $root->child('wide.txt')->spew_utf8( join '', ( ( 'y' x 1990 )."\n" ) x 80 );
  my ( $text, $err ) = read_file( { path => 'wide.txt', offset => 1, limit => 80 } );
  is $err, 1, 'refused';
  like $text, qr/\AFile content \(\d+ tokens\) exceeds maximum allowed tokens \(25000\)/, 'by tokens';
  ( $text, $err ) = read_file( { path => 'wide.txt', offset => 1, limit => 20 } );
  ok !$err, 'fewer lines are fine';
};

subtest 'bytes are counted, not characters' => sub {
  # 40 lines of 1300 two-byte characters: ~52000 characters (13000 tokens if
  # characters were counted), ~104000 bytes (over 25000 tokens when bytes are).
  $root->child('wideutf.txt')->spew_utf8( join '', ( ( 'ä' x 1300 )."\n" ) x 40 );
  my ( $text, $err ) = read_file( { path => 'wideutf.txt' } );
  is $err, 1, 'refused: the size is the UTF-8 bytes, a quarter of them';
  like $text, qr/\AFile content \(\d+ tokens\) exceeds/, 'by tokens';
};

done_testing;
