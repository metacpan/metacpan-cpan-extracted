use strict;
use warnings;
use utf8;
use Test::More tests => 1 + 2;
binmode Test::More->builder->output, ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

BEGIN { use_ok('Lingua::JA::Moji') };

use Lingua::JA::Moji qw/hw2katakana kana2hw/;

my $full = 'ヴァイオリンー';
my $half = 'ｳﾞｧｲｵﾘﾝｰ';

is(kana2hw($full), $half);
is(hw2katakana($half), $full);
