use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/katakana_z2h katakana_h2z/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

is(katakana_z2h('ハァハァ'), 'ﾊｧﾊｧ');
is(katakana_h2z('ｽｰﾊｰｽｰﾊｰ'), 'スーハースーハー');

my $normalizer = Lingua::JA::NormalizeText->new(qw/katakana_z2h/);
is($normalizer->normalize('カリカリﾓﾌﾓﾌ'), 'ｶﾘｶﾘﾓﾌﾓﾌ');

$normalizer = Lingua::JA::NormalizeText->new(qw/katakana_h2z/);
is($normalizer->normalize('カリカリﾓﾌﾓﾌ'), 'カリカリモフモフ');

done_testing;
