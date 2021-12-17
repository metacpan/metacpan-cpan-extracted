use strict;
use warnings;
use Test::Without::Module 'Unicode::UTF8';
use Test::More;
use Decode::ARGV ();
use Encode::Simple qw(encode encode_utf8);

subtest 'Strict UTF-8 decode' => sub {
  local @ARGV = map { encode_utf8 $_ } 'xyz', "r\N{U+E9}sum\N{U+E9}", "\N{U+2603}";
  Decode::ARGV->import;
  is_deeply \@ARGV, ['xyz', "r\N{U+E9}sum\N{U+E9}", "\N{U+2603}"], 'right characters';

  local @ARGV = ("\xFF\xFF");
  ok !eval { Decode::ARGV->import; 1 }, 'decode failed';
};

subtest 'Lax UTF-8 decode' => sub {
  local @ARGV = map { encode_utf8 $_ } 'xyz', "r\N{U+E9}sum\N{U+E9}", "\N{U+2603}";
  Decode::ARGV->import('lax');
  is_deeply \@ARGV, ['xyz', "r\N{U+E9}sum\N{U+E9}", "\N{U+2603}"], 'right characters';

  local @ARGV = ("\xFF\xFF");
  Decode::ARGV->import('lax');
  is_deeply \@ARGV, ["\N{U+FFFD}\N{U+FFFD}"], 'replacement characters';
};

subtest 'Strict UTF-16LE decode' => sub {
  local @ARGV = map { encode 'UTF-16LE', $_ } 'xyz', "r\N{U+E9}sum\N{U+E9}", "\N{U+2603}";
  Decode::ARGV->import('UTF-16LE');
  is_deeply \@ARGV, ['xyz', "r\N{U+E9}sum\N{U+E9}", "\N{U+2603}"], 'right characters';

  local @ARGV = ("\xFF\xFF");
  ok !eval { Decode::ARGV->import('UTF-16LE'); 1 }, 'decode failed';
};

subtest 'Lax ASCII decode' => sub {
  local @ARGV = ('xyz', "r\N{U+E9}sum\N{U+E9}");
  Decode::ARGV->import(lax => 'ASCII');
  is_deeply \@ARGV, ['xyz', "r\N{U+FFFD}sum\N{U+FFFD}"], 'right characters';

  local @ARGV = ("\xFF\xFF");
  Decode::ARGV->import(lax => 'ASCII');
  is_deeply \@ARGV, ["\N{U+FFFD}\N{U+FFFD}"], 'replacement characters';
};

done_testing;
