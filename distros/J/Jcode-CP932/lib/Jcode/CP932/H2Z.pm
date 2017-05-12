package Jcode::CP932::H2Z;
use strict;

our %_H2Z = (
          "\x{ff61}" => "\x{3002}",	#。
          "\x{ff62}" => "\x{300c}",	#「
          "\x{ff63}" => "\x{300d}",	#」
          "\x{ff64}" => "\x{3001}",	#、
          "\x{ff65}" => "\x{30fb}",	#・
          "\x{ff66}" => "\x{30f2}",	#ヲ
          "\x{ff67}" => "\x{30a1}",	#ァ
          "\x{ff68}" => "\x{30a3}",	#ィ
          "\x{ff69}" => "\x{30a5}",	#ゥ
          "\x{ff6a}" => "\x{30a7}",	#ェ
          "\x{ff6b}" => "\x{30a9}",	#ォ
          "\x{ff6c}" => "\x{30e3}",	#ャ
          "\x{ff6d}" => "\x{30e5}",	#ュ
          "\x{ff6e}" => "\x{30e7}",	#ョ
          "\x{ff6f}" => "\x{30c3}",	#ッ
          "\x{ff70}" => "\x{30fc}",	#ー
          "\x{ff71}" => "\x{30a2}",	#ア
          "\x{ff72}" => "\x{30a4}",	#イ
          "\x{ff73}" => "\x{30a6}",	#ウ
          "\x{ff74}" => "\x{30a8}",	#エ
          "\x{ff75}" => "\x{30aa}",	#オ
          "\x{ff76}" => "\x{30ab}",	#カ
          "\x{ff77}" => "\x{30ad}",	#キ
          "\x{ff78}" => "\x{30af}",	#ク
          "\x{ff79}" => "\x{30b1}",	#ケ
          "\x{ff7a}" => "\x{30b3}",	#コ
          "\x{ff7b}" => "\x{30b5}",	#サ
          "\x{ff7c}" => "\x{30b7}",	#シ
          "\x{ff7d}" => "\x{30b9}",	#ス
          "\x{ff7e}" => "\x{30bb}",	#セ
          "\x{ff7f}" => "\x{30bd}",	#ソ
          "\x{ff80}" => "\x{30bf}",	#タ
          "\x{ff81}" => "\x{30c1}",	#チ
          "\x{ff82}" => "\x{30c4}",	#ツ
          "\x{ff83}" => "\x{30c6}",	#テ
          "\x{ff84}" => "\x{30c8}",	#ト
          "\x{ff85}" => "\x{30ca}",	#ナ
          "\x{ff86}" => "\x{30cb}",	#ニ
          "\x{ff87}" => "\x{30cc}",	#ヌ
          "\x{ff88}" => "\x{30cd}",	#ネ
          "\x{ff89}" => "\x{30ce}",	#ノ
          "\x{ff8a}" => "\x{30cf}",	#ハ
          "\x{ff8b}" => "\x{30d2}",	#ヒ
          "\x{ff8c}" => "\x{30d5}",	#フ
          "\x{ff8d}" => "\x{30d8}",	#ヘ
          "\x{ff8e}" => "\x{30db}",	#ホ
          "\x{ff8f}" => "\x{30de}",	#マ
          "\x{ff90}" => "\x{30df}",	#ミ
          "\x{ff91}" => "\x{30e0}",	#ム
          "\x{ff92}" => "\x{30e1}",	#メ
          "\x{ff93}" => "\x{30e2}",	#モ
          "\x{ff94}" => "\x{30e4}",	#ヤ
          "\x{ff95}" => "\x{30e6}",	#ユ
          "\x{ff96}" => "\x{30e8}",	#ヨ
          "\x{ff97}" => "\x{30e9}",	#ラ
          "\x{ff98}" => "\x{30ea}",	#リ
          "\x{ff99}" => "\x{30eb}",	#ル
          "\x{ff9a}" => "\x{30ec}",	#レ
          "\x{ff9b}" => "\x{30ed}",	#ロ
          "\x{ff9c}" => "\x{30ef}",	#ワ
          "\x{ff9d}" => "\x{30f3}",	#ン
          "\x{ff9e}" => "\x{309b}",	#゛
          "\x{ff9f}" => "\x{309c}",	#゜
);

our %_D2Z = (
          "\x{ff76}\x{ff9e}" => "\x{30ac}",	#ガ
          "\x{ff77}\x{ff9e}" => "\x{30ae}",	#ギ
          "\x{ff78}\x{ff9e}" => "\x{30b0}",	#グ
          "\x{ff79}\x{ff9e}" => "\x{30b2}",	#ゲ
          "\x{ff7a}\x{ff9e}" => "\x{30b4}",	#ゴ
          "\x{ff7b}\x{ff9e}" => "\x{30b6}",	#ザ
          "\x{ff7c}\x{ff9e}" => "\x{30b8}",	#ジ
          "\x{ff7d}\x{ff9e}" => "\x{30ba}",	#ズ
          "\x{ff7e}\x{ff9e}" => "\x{30bc}",	#ゼ
          "\x{ff7f}\x{ff9e}" => "\x{30be}",	#ゾ
          "\x{ff80}\x{ff9e}" => "\x{30c0}",	#ダ
          "\x{ff81}\x{ff9e}" => "\x{30c2}",	#ヂ
          "\x{ff82}\x{ff9e}" => "\x{30c5}",	#ヅ
          "\x{ff83}\x{ff9e}" => "\x{30c7}",	#デ
          "\x{ff84}\x{ff9e}" => "\x{30c9}",	#ド
          "\x{ff8a}\x{ff9e}" => "\x{30d0}",	#バ
          "\x{ff8a}\x{ff9f}" => "\x{30d1}",	#ビ
          "\x{ff8b}\x{ff9e}" => "\x{30d3}",	#ブ
          "\x{ff8b}\x{ff9f}" => "\x{30d4}",	#ベ
          "\x{ff8c}\x{ff9e}" => "\x{30d6}",	#ボ
          "\x{ff8c}\x{ff9f}" => "\x{30d7}",	#パ
          "\x{ff8d}\x{ff9e}" => "\x{30d9}",	#ピ
          "\x{ff8d}\x{ff9f}" => "\x{30da}",	#プ
          "\x{ff8e}\x{ff9e}" => "\x{30dc}",	#ペ
          "\x{ff8e}\x{ff9f}" => "\x{30dd}",	#ポ
          "\x{ff73}\x{ff9e}" => "\x{30f4}",	#ヴ
          #"\x{ff9c}\x{ff9e}" => "\x{30f7}",	#ワ゛
          #"\x{ff66}\x{ff9e}" => "\x{30fa}",	#ヲ゛
);

# init only once;

our %_Z2H = reverse %_H2Z;
our %_Z2D = reverse %_D2Z;

sub h2z {
    no warnings qw(uninitialized);
    my $r_str = shift;
    my ($keep_dakuten) = @_;
    my $n = 0;
    unless ($keep_dakuten) {
        $n = (
            $$r_str =~ s{
                ([\x{ff61}-\x{ff9f}][\x{ff9e}\x{ff9f}]?)
            } {
                my $str = $1;
                $_D2Z{$str} || $_H2Z{$str} || 
                # in case dakuten and handakuten are side-by-side!
                $_H2Z{substr($str,0,1)} . $_H2Z{substr($str,1,1)};
            }eogx
        );
    }
    else {
        $n = (
            $$r_str =~ s{
                ([\x{ff61}-\x{ff9f}])
            } {
                $_H2Z{$1};
            }eogx
        );
    }
    $n;
}

sub z2h {
    no warnings qw(uninitialized);
    my $r_str = shift;
    my $n = (
        $$r_str =~ s{
            ([\x{3001}\x{3002}\x{300c}\x{300d}\x{309b}\x{309c}\x{30a1}-\x{30fc}])
        } {
            $_Z2D{$1} || $_Z2H{$1} || $1;
        }eogx
    );
    $n;
}

1;
__END__

