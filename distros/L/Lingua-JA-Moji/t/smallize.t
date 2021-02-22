use FindBin '$Bin';
use lib "$Bin";
use LJMT;

is (smallize_kana ('シヤツター'), 'シャッター',
    "Basic operation of smallize_kana");

is (smallize_kana ('ケンブリツジ'), 'ケンブリッジ');

is (smallize_kana ('ツプ'), undef, "Cannot smallize tsu kana at start");
is (smallize_kana ('感ツプ'), undef, "Cannot smallize tsu kana after non-kana");
is (smallize_kana ('サンゼンツプ'), undef, "Cannot smallize tsu kana after n");
is (smallize_kana ('サツプ'), 'サップ', "Can smallize kana after 'sa'");
is (smallize_kana ('シヨツチユウ'), 'ショッチュウ', "Test of smallize shotchuu");
is (smallize_kana ('チヨダ'), 'チョダ', "Test of smallize chiyoda");

#TODO: {
#    local $TODO = 'smallize hui';
is (smallize_kana ('フイラデルヒア'), 'フィラデルヒア', "smallize fui");
is (smallize_kana ('フオング'), 'フォング', "fong");
#};

done_testing ();
