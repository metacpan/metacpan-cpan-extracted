#!perl -T

use strict;
use Test::More;
use utf8;

BEGIN { plan tests => 2 }

require Lingua::ZH::Summary;
ok($Lingua::ZH::Summary::VERSION) if $Lingua::ZH::Summary::VERSION or 1;

my $summary = Lingua::ZH::Summary->new();
my $result = $summary->summary(do { local $/; <DATA> });
like($result, qr/紀念的是歷史哦。/);

__DATA__

有個笑話是這樣說的。中正紀念堂紀念已故的蔣中正，國父紀念堂紀念已故的國父孫中山先生。那台灣民主紀念館紀念的是？…

「民主館揭牌 扁斥舊威權禍害」。如果說這是今年，或是這幾年阿扁總統最大的政績，我想所有民進黨員也不會投反對票吧？

紀念已故的台灣民主嗎？這年頭不能空口說白話，尤其最近流行各說各話，當然要有所本了。查部編版國語辭典「紀念館」的釋義為：為紀念重大歷史事件或著名歷史人物而設置的建築物。如：國父紀念館。看到沒？紀念的是歷史哦。我不認為台灣民主到了成熟的階段，相較此刻設立紀念館，我覺得好像在憑弔一樣。阿扁總統真是幹的好，不但每年拼經濟，這年頭連台灣民主都拼下去了。

接下來還有一年的時間，台灣之子陳阿扁來又想要拼什麼呢？
