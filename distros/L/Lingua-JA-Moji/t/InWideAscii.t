use warnings;
use strict;
use Test::More tests => 4;
use Lingua::JA::Moji qw/InWideAscii/;
use utf8;
# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output, ":utf8";
binmode Test::More->builder->failure_output, ":utf8";
ok ('ｱ' !~ /\p{InWideAscii}/, "ｱ is wide ascii\n");
ok ('ア' !~ /\p{InWideAscii}/, "ア　is not wide ascii\n");
ok ('baby chops' !~ /\p{InWideAscii}/, "baby chops is not wide ascii\n");
ok ('ｂａｂｙ　ｃｈｏｐｓ' =~ /\p{InWideAscii}/, "ｂａｂｙ　ｃｈｏｐｓ is wide ascii\n");
