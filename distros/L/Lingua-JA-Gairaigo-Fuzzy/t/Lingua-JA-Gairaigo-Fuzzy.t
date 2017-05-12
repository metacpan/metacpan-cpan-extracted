# This is a test for module Lingua::JA::Gairaigo::Fuzzy.

use warnings;
use strict;
use Test::More;
use Lingua::JA::Gairaigo::Fuzzy 'same_gairaigo';
use utf8;

binmode STDOUT, ":utf8";
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";


#
#  ____           _ _   _                
# |  _ \ ___  ___(_) |_(_)_   _____  ___ 
# | |_) / _ \/ __| | __| \ \ / / _ \/ __|
# |  __/ (_) \__ \ | |_| |\ V /  __/\__ \
# |_|   \___/|___/_|\__|_| \_/ \___||___/
#                                       
#

# Test with hei versus he- (chouon).

ok (same_gairaigo ('ヘイホ', 'ヘーホ'));
ok (same_gairaigo ('メインフレーム', 'メーンフレーム'));

# Test with sokuon versus chouon.

ok (same_gairaigo ('ガーベッジコレクション', 'ガベジコレクション'));
ok (same_gairaigo ('ガーベッジコレクション', 'ガーベジコレクション'));

# Test with dot/no dot.

ok (same_gairaigo ('ジャーマン・シェパード', 'ジャーマンシェパード'));

# Test with chouon/no chouon

ok (same_gairaigo ('ローンダリング', 'ロンダリング'));

# Fake test (do not have a real example).

ok (same_gairaigo ('ハート', 'ハット'), "ハート/ハット");

# Test イイ versus イー

ok (same_gairaigo ('ヤッピー', 'ヤッピイ'), "i + chouon == ii");

# Test ヨウ versus ヨー

ok (same_gairaigo ('ヨーク', 'ヨウク'), "ヨーク / ヨウク");
ok (same_gairaigo ('ヨー', 'ヨウ'));

#
#  _   _                  _   _                
# | \ | | ___  __ _  __ _| |_(_)_   _____  ___ 
# |  \| |/ _ \/ _` |/ _` | __| \ \ / / _ \/ __|
# | |\  |  __/ (_| | (_| | |_| |\ V /  __/\__ \
# |_| \_|\___|\__, |\__,_|\__|_| \_/ \___||___/
#             |___/                            
#

# Test for a false positive.

ok (! same_gairaigo ('メインフレーム', 'フレームメーン'));
ok (! same_gairaigo ('プリン', 'プリンタ'));

ok (same_gairaigo ('バープス', 'バープス'), "バープス/バープス");

TODO: {
    local $TODO='known bugs';
};


done_testing ();

# Local variables:
# mode: perl
# End:
