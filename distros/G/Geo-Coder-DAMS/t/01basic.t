use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::LeakTrace;

use Encode;

use_ok("Geo::Coder::DAMS", ":all");

{
    dams_init();
    dams_init("/usr/local/lib/dams/dams");

    # Caught C++ exception of type or derived from 'std::exception': Can't open file: /usr/local/lib/dams/damsa
    throws_ok( sub { dams_init("/usr/local/lib/dams/FILE_NOT_FOUND") }, qr/std::exception/ );

    my $h = dams_retrieve("東京都渋谷区千駄ヶ谷5-24-55 NEWoMan");
    is ref($h), 'HASH';
    is $h->{score}, 5;
    is $h->{tail}, "55 NEWoMan";
    is @{$h->{candidates}}, 1;
    ok utf8::is_utf8( $h->{candidates}[0][0]{name} );

    like dams_elapsedtime(), qr/^-?\d+$/;

    # use YAML::Syck;
    # diag Dump($h);
}

{
    # コンパイル済み住所データを読み込み、初期化
    dams_init();

    # デバッグ表示の設定
    dams_debugmode(0); # デフォルト値

    # 最大表示件数の設定
    dams_set_limit(10); # デフォルト値

    # 部分一致を検索しない住所レベルの設定
    dams_set_exact_match_level(5); # デフォルト値

    # 住所を検索	
    my $result = dams_retrieve("駒場4-6-1");

    # 結果を表示
    diag sprintf("score=%d\n", $result->{score});
    diag sprintf("tail=%s\n", $result->{tail});
    my $count = 0;
    diag 0+@{$result->{candidates}};
    for my $candidate (@{$result->{candidates}}) {
        diag sprintf("candidates[%d]:\n", $count);
        for my $element (@$candidate) {
            diag encode_utf8 sprintf("  name=%s, level=%d, x=%f, y=%f\n", @{$element}{qw(name level x y)});
        }
        $count++;
    }
    
    diag sprintf("\n実行時間: %d（ミリ秒）\n", dams_elapsedtime());
}

leaktrace {
    my $result = dams_retrieve("駒場4-6-1");
};

done_testing;
