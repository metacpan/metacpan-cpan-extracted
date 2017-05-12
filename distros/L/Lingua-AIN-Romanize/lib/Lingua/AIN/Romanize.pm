package Lingua::AIN::Romanize;

use strict;
use warnings;
use Carp;
use version; our $VERSION = qv('0.0.2');
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Exporter;
@ISA = qw(Exporter);
@EXPORT      = qw(ain_kana2roman ain_roman2kana);
@EXPORT_OK   = qw(ain_setregex %Ain_Roman2Kana %Ain_Kana2Roman @Ain_VplusiuCase);
%EXPORT_TAGS = (setregex => [qw(ain_kana2roman ain_roman2kana ain_setregex %Ain_Roman2Kana %Ain_Kana2Roman @Ain_VplusiuCase)]);

use Lingua::JA::Kana;
use utf8;

# 母音
our $Re_Vowels       = $Lingua::JA::Kana::Re_Vowels;

# 子音
our $Re_Consonants   = qr/[ptksmnwyrhc]/i;

# 撥音用
our $Re_Consonants_t = qr/[ptkcs]/i;


#################################
# ローマ字 -> カナ関連

# ローマ字⇒カナ
our %Ain_Roman2Kana = (
    %Lingua::JA::Kana::Romaji2Kata,
    qw(
        ca チャ ci チ cu チュ ce チェ co チョ
        wo ウォ wu ウ yi イ   ya ヤ
        'a ア   'i イ 'u ウ   'e エ   'o オ
    ),
);

our $Re_Roman2Kata = qr/(?:[aeiou]|s(?:[aeiou]|h[aiou]|y[aou])|d(?:[eiou]|h[aeiou]|y?a)|t(?:[aeio]|y[aeou]|s?u)|x(?:[aeio]|y[aou]|t?u)|c(?:[aeiou]|h[aeiou])|b(?:[aeiou]|y[aou])|h(?:[aeiou]|y[aou])|k(?:[aeiou]|y[aou])|p(?:[aeiou]|y[aou])|'[aeiou]|f[aeiou]|g[aeiou]|l[aeiou]|m[aeiou]|n[aeiou]|r[aeiou]|v[aeiou]|w[aeiou]|y[aeiou]|z[aeiou]|j[aiou])/i;


# 閉音節r
our $Re_R_Close   = qr/($Re_Vowels)r(?!$Re_Vowels)/i;
our %R_Close;
$R_Close{hankaku} = {qw( a ﾗ  i ﾘ  u ﾙ  e ﾚ  o ﾛ )};
$R_Close{unicode} = {qw( a ㇻ i ㇼ u ㇽ e ㇾ o ㇿ )};

# 閉音節h(樺太方言)
our $Re_H_Close   = qr/($Re_Vowels)h(?!$Re_Vowels)/i;
our %H_Close;
$H_Close{hankaku} = {qw( a ﾊ  i ﾋ  u ﾌ  e ﾍ  o ﾎ )};
$H_Close{unicode} = {qw( a ㇵ i ㇶ u ㇷ e ㇸ o ㇹ )};

# 長音化(樺太方言)
our $Re_Long   = qr/($Re_Vowels)\1/i;

# その他の閉音節
our $Re_O_Close   = qr/(([ptkwysn])(?!$Re_Vowels|\2)|m(?!$Re_Vowels|[mp]))/i;
our %O_Close;
$O_Close{hankaku} = {qw( p ﾌﾟ   t ッ k ｸ  w ウ y イ s ｼ  m ﾑ  n ン )};
$O_Close{unicode} = {qw( p ㇷ゚ t ッ k ㇰ w ウ y イ s ㇱ m ㇺ n ン )};

sub ain_roman2kana {
    my $str = shift;
    my $opt = shift || {};
    
    my $code = $opt->{hankaku} ? 'hankaku' : 'unicode'; 
    my $kara = $opt->{karafuto} || 0;
    
    # 人称の区切りの=を削除
    $str =~ s/[=＝]//msxgi;
    
    # r閉音節を置き換える
    my $R_Close = $R_Close{$code};
    $str =~ s{ $Re_R_Close }{
        $1 . $R_Close->{$1};
    }msxgei;
    
    # h閉音節を置き換える(樺太方言)
    my $H_Close = $H_Close{$code};
    $str =~ s{ $Re_H_Close }{
        $1 . $H_Close->{$1};
    }msxgei;
    
    # 長音化(樺太方言)
    if ( $kara ) {
        $str =~ s{ $Re_Long }{
            $1 . 'ー';
        }msxgei;
    }
    
    # その他の閉音節
    my $O_Close = $O_Close{$code};
    $str =~ s{ $Re_O_Close }{
        $O_Close->{$1};
    }msxgei;
    

    local %Lingua::JA::Kana::Romaji2Kata    = %Ain_Roman2Kana;
    local $Lingua::JA::Kana::Re_Romaji2Kata = $Re_Roman2Kata;
    local $Lingua::JA::Kana::Re_Consonants  = $Re_Consonants_t;

    romaji2katakana( $str );
}


#################################
# カナ -> ローマ字関連

# カナ⇒ローマ字
our %Ain_Kana2Roman = (
    %Lingua::JA::Kana::Kata2Hepburn,
    qw(
        ア   'a イ   'i ウ   'u エ   'e オ   'o 
        チャ ca チ   ci チュ cu チェ ce チョ co 
        シ   si トゥ tu
    ),
    qw(
        ﾗ r ﾘ r ﾙ r ﾚ r ﾛ r ㇻ r ㇼ r ㇽ r ㇾ r ㇿ r 
        ﾊ h ﾋ h ﾌ h ﾍ h ﾎ h ㇵ h ㇶ h ㇷ h ㇸ h ㇹ h 
        ㇷ゚ p ﾌﾟ p ッ t ｸ   k ｼ s ﾑ m 
        ㇱ   s ン n ㇰ k  ㇺ m
    ),
);

#our $Re_Kana2Roman = qr/(?-xism:(?:[ァアィゥェエォオカガギクグケゲコゴサザスズセゼソゾタダツヅナニヌネノハバパブプヘベペホボポマミムメモャヤュユョヨラルレロワヰヱヲン]|ウ[ァィェォ]?|チ[ェャュョ]?|ヂ[ェャュョ]?|フ[ァィェォ]?|ヴ[ァィェォ]?|キ[ャュョ]?|シ[ャュョ]?|ジ[ャュョ]?|ヒ[ャュョ]?|ビ[ャュョ]?|ピ[ャュョ]?|リ[ャュョ]?|イェ?|ティ?|ディ?|トゥ?|ドゥ?))/;

our $Re_Kana2Roman = qr/(?-xism:(?:[ァアィゥェエォオカガギクグケゲコゴサザスズセゼソゾタダッツヅナニヌネノハバパブプヘベペホボポマミムメモャヤュユョヨラルレロワヰヱヲンㇰㇱㇵㇶㇸㇹㇺㇻㇼㇽㇾㇿｸｼﾊﾋﾍﾎﾑﾗﾘﾙﾚﾛ]|ウ[ァィェォ]?|チ[ェャュョ]?|ヂ[ェャュョ]?|フ[ァィェォ]?|ヴ[ァィェォ]?|キ[ャュョ]?|シ[ャュョ]?|ジ[ャュョ]?|ヒ[ャュョ]?|ビ[ャュョ]?|ピ[ャュョ]?|リ[ャュョ]?|イェ?|ティ?|ディ?|トゥ?|ドゥ?|ㇷ゚?|ﾌﾟ?))/;

## 閉音節r
#our $Re_R_Close_Rv   = qr/[ﾗﾘﾙﾚﾛㇻㇼㇽㇾㇿ]/;
#
## 閉音節h(樺太方言)
#our $Re_H_Close_Rv   = qr/[ﾊﾋﾌﾍﾎㇵㇶㇷㇸㇹ]/;
#
## その他の閉音節
#our $Re_O_Close_Rv   = qr/(ㇷ゚|ﾌﾟ|[ッｸｼﾑンㇰㇱㇺ])/;
#our %O_Close_Rv      = qw( ㇷ゚ p ﾌﾟ p ッ t ｸ   k ｼ s ﾑ m 
#                           ㇱ   s ン n ㇰ k  ㇺ m );

# 母音+i、母音+uになるケース用
our @Ain_VplusiuCase = qw( \biyairaykere\b );   # とにかくケースを集める

our $Re_VplusiuCase;
our %Hs_VplusiuCase;
&ain_setregex_vc;

sub ain_kana2roman {
    my $str = shift;
    my $opt = shift || {};
    
    my $kara = $opt->{karafuto} || 0;
    
#    # r閉音節を置き換える
#    $str =~ s{ $Re_R_Close_Rv }{
#        'r';
#    }msxgei;
#    
#    # h閉音節を置き換える(樺太方言)
#    $str =~ s{ $Re_H_Close_Rv }{
#        'h';
#    }msxgei;
#    
#    # その他の閉音節
#    $str =~ s{ $Re_O_Close_Rv }{
#        $O_Close_Rv{$1};
#    }msxgei;
    
    local %Lingua::JA::Kana::Kana2Romaji    = %Ain_Kana2Roman;
    local $Lingua::JA::Kana::Re_Kana2Romaji = $Re_Kana2Roman;
    
    $str = kana2romaji( $str );
    
    # 母音＋i => y, 母音＋u => w
    $str =~ s{ ($Re_Vowels)'?([iu]) }{
        my $ret;
        if ( $1 eq $2 ) {
            $ret = $1.$2;
        } else {
            $ret = $1 . ( $2 eq 'i' ? 'y' : 'w' );
        }
        $ret;
    }msxgei;
    
    # 子音後に続かない母音の'を取る
    $str =~ s{(?<!$Re_Consonants)'(?=$Re_Vowels)}{}msgxi;
    
    # 撥音処理
    $str =~ s{t($Re_Consonants)}{$1$1}msgxi;

    # m/p前のンはm
    $str =~ s{n([mp])}{m$1}msgxi;
    
    # 母音+i、母音+uになるケース用
    $str =~ s{$Re_VplusiuCase}{$Hs_VplusiuCase{$1}}msgxei;
    
    $str;
}

sub ain_setregex {

    eval 'require Regexp::Assemble'; ## no critic
    
    croak 'ain_setregex function needs Regexp::Assemble module' if ( $@ );

    $Re_Roman2Kata = do {
        my $ra = Regexp::Assemble->new();
        $ra->add($_) for keys %Ain_Roman2Kana;
        my $str = $ra->re;
        substr( $str, 0,  8, '' );    # remove '(?-xism:'
        substr( $str, -1, 1, '' );    # and ')';
        qr/$str/i;                    # and recompile with i
    };

    $Re_Kana2Roman = do {
        my $ra = Regexp::Assemble->new();
        $ra->add($_) for keys %Ain_Kana2Roman;
        $ra->re;
    };
    
    &ain_setregex_vc;
}

sub ain_setregex_vc {
    $Re_VplusiuCase = '';
    %Hs_VplusiuCase = ();
    foreach my $key ( @Ain_VplusiuCase ) {
        my $from = $key;
        my $to   = $key;
    
        $from   =~ s{($Re_Vowels)([iu])}{ $1 . ($2 eq 'i' ? 'y' : 'w') }ge;

        $Re_VplusiuCase .= $Re_VplusiuCase eq '' ? '(' : '|';
        $Re_VplusiuCase .= $from;

        $from =~ s/\\b//g;
        $to   =~ s/\\b//g;

        $Hs_VplusiuCase{$from} = $to;
    }
    $Re_VplusiuCase .= ')';
    $Re_VplusiuCase = qr/$Re_VplusiuCase/i;
}


1;
__END__

=encoding utf-8

=head1 NAME

Lingua::AIN::Romanize - アイヌ語のローマ字表記とカタカナ表記を相互変換するモジュール

=head1 SYNOPSIS

  use Lingua::AIN::Romanize;
  
  my $kana = ain_roman2kana('aynu itak');
  # アイヌ イタㇰ
  
  my $kana = ain_roman2kana('aynu itak',{ hankaku => 1 });
  # アイヌ イタｸ
  
  my $roman = ain_kana2roman('アイヌ イタㇰ');
  # aynu itak
  
  my $roman = ain_kana2roman('アイヌ イタｸ');
  # aynu itak
  
  
=head1 DESCRIPTION

Lingua::AIN::Romanizeはアイヌ語のローマ字表記とカタカナ表記を相互変換する
モジュールです。

UTF-8での変換を行い、Unicode3.2で定義された小文字カナを利用した変換を行い
ますが、ローマ字→カナ変換はオプションで半角カナへの変換を選択することも
できます。
ト゚(tu)、セ゚(ce)等の半濁音付表記については、開発者が初学者過ぎ、同じローマ
字表記が割り当てられているトゥ(tu)やチェ(ce)の別表記なのか違うものなのか、
という判断がつかなかったため、対応していません。
が、正確な情報が判れば対応可能ですので、情報をお寄せいただければ幸いです。

ベースとなっている変換ロジックはkumanesirさんの公開されている変換ロジック
L<http://sapporo.cool.ne.jp/kumanesir/kanahenkan.htm>をベースに、CDエクス
プレス・アイヌ語での事例等も参考に行いました。

できる限り相互変換がラウンドトリップするように心がけましたが、やはりカナ→
ローマ字変換側で、

  1.母音+イ、ウがi、uとなるケース(イヤイライケレ → ○iyairaykere ×iyayraykere)  
  
  2.人称接辞の分離(エイワンケ → ○e=iwanke ×eiwanke)
  
  3.撥音がtとなるケース(サッケ → ○satke ×sakke)
  
のようなものには、基本対応できていません。

このうち、1.については、主要語であるイヤイライケレ(ありがとう)がいきなり変換
できないのではイマイチなので、事例集を内部に持つ形での対応を一応行っています。
ですので、母音+イ、ウがi、uとなるケースをサンプルとして頂戴できれば、対応は可能
です。

また、1.～3.いずれも、ロジック的な変換規則でよい案をお持ちの方がおられましたら、
教えていただければ対応いたします。
100%の対応は、ヤイライケ→yayrayke(自殺する)yairayke(感謝する)のように不可能なのは
判っていますが、少しでもよくしていきたいと考えています。
作者はプログラムはそれなりですがアイヌ語は初学者ですので、ベテランの方の支援をいた
だければ幸いです。


=head1 Function

=over

=item ain_roman2kana

ローマ字表記をカナ表記に変換します。
第二引数にハッシュリファレンスでオプションを取りますが、hankakuオプションを1にすると、
Unicode3.2での定義文字の代わりに半角カナを用いて変換します。

=item ain_kana2roman

カナ表記をローマ字表記に変換します。

=item ain_setregex

モジュールのロード時に、:setregexタグを指定すると、本関数と%Ain_Roman2Kana、%Ain_Kana2Roman、
@Ain_VplusiuCaseの3変数がエクスポートされます。
これらを使い、独自の変換テーブルを定義できますが、上級利用法なのでソースコードを読んで理解できる
方のみ使っていただければ幸いです。

=back


=head1 Internal Function

=over

=item ain_setregex_vc

=back


=head1 AUTHOR

OHTSUKA Ko-hei E<lt>nene@kokogiko.netE<gt>


=head1 SEE ALSO

=over

=item L<http://sapporo.cool.ne.jp/kumanesir/kanahenkan.htm>

=item L<http://ja.wiktionary.org/wiki/Wiktionary:%E3%82%A2%E3%82%A4%E3%83%8C%E8%AA%9E%E3%81%AE%E3%82%AB%E3%83%8A%E8%A1%A8%E8%A8%98>

=item L<http://www.amazon.co.jp/dp/4560005990>

=item Lingua::JA::Kana

=item Regexp::Assemble

=back


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
