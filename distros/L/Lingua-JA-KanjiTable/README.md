# NAME

Lingua::JA::KanjiTable - User-Defined Character Properties for Joyo Kanji and Jinmeiyo Kanji

# SYNOPSIS

    use Lingua::JA::KanjiTable;
    use utf8;

    '亜'   =~ /^\p{IsJoyoKanji}$/   ? 1 : 0; # => 1
    '亞'   =~ /^\p{IsJoyoKanji}$/   ? 1 : 0; # => 0
    '匁'   =~ /^\p{IsJoyoKanji}$/   ? 1 : 0; # => 0
    '叱'   =~ /^\p{IsJouyouKanji}$/ ? 1 : 0; # => 0
    '𠮟'   =~ /^\p{IsJouyouKanji}$/ ? 1 : 0; # => 1
    '恍惚' =~ /^\p{IsJoyoKanji}+$/  ? 1 : 0; # => 0
    '固唾' =~ /^\p{Lingua::JA::KanjiTable::IsJoyoKanji20101130}+$/ ? 1 : 0; # => 1

    '亞' =~ /^\p{IsJinmeiyoKanji}$/ ? 1 : 0; # => 1
    '匁' =~ /^\p{IsJinmeiyoKanji}$/ ? 1 : 0; # => 1
    '柊' =~ /^\p{IsJinmeiyoKanji}$/ ? 1 : 0; # => 1
    '苺' =~ /^\p{IsJinmeiyoKanji}$/ ? 1 : 0; # => 1
    '姦' =~ /^\p{IsJinmeiyoKanji}$/ ? 1 : 0; # => 0
    '渾' =~ /^\p{IsJinmeiyoKanji}$/ ? 1 : 0; # => 1
    '勒' =~ /^\p{IsJinmeiyoKanji}$/ ? 1 : 0; # => 1

    #Jinmei(名) check:
    '太郎喜左衛門将時能' =~ /^\p{IsJinmei}+$/ ? 1 : 0; # => 1
    '愛子エンジェル'     =~ /^\p{IsJinmei}+$/ ? 1 : 0; # => 1
    'み〜こ'             =~ /^\p{IsJinmei}+$/ ? 1 : 0; # => 0
    'ニャー'             =~ /^\p{IsJinmei}+$/ ? 1 : 0; # => 1
    '奈々'               =~ /^\p{IsJinmei}+$/ ? 1 : 0; # => 1
    '〆子'               =~ /^\p{IsJinmei}+$/ ? 1 : 0; # => 0
    '巫女みこナース'     =~ /^\p{IsJinmei}+$/ ? 1 : 0; # => 1

    sub IsJinmei
    {
        return <<"END";
    +Lingua::JA::KanjiTable::IsJoyoKanji
    +Lingua::JA::KanjiTable::IsJinmeiyoKanji
    3005
    3041\t3096
    309D
    309E
    30A1\t30FA
    30FC\t30FE
    END
    }

# DESCRIPTION

Lingua::JA::KanjiTable provides user-defined character properties for 常用漢字表 and 人名用漢字表.

# EXPORTS

By default Lingua::JA::KanjiTable exports the following user-defined character properties:

- IsJoyoKanji - The latest Jouyou Kanji table（平成22年11月30日内閣告示第2号）
- IsJouyouKanji - ditto
- InJoyoKanji - ditto
- InJouyouKanji - ditto
- IsJinmeiyoKanji - The latest Jinmeiyou Kanji table（2026年6月26日版）
- IsJinmeiyouKanji - ditto
- InJinmeiyoKanji - ditto
- InJinmeiyouKanji - ditto

To avoid potential naming conflicts with 'In', it is recommended to use properties prefixed with 'Is'.

The following properties are exportable (not exported by default):

- IsJoyoKanji20101130 - 常用漢字表（平成22年11月30日内閣告示第2号）
- IsJouyouKanji20101130 - ditto
- InJoyoKanji20101130 - ditto
- InJouyouKanji20101130 - ditto
- IsJinmeiyoKanji20260626 - 人名用漢字表（2026年6月26日版）
- IsJinmeiyouKanji20260626 - ditto
- InJinmeiyoKanji20260626 - ditto
- InJinmeiyouKanji20260626 - ditto
- IsJinmeiyoKanji20170925 - 人名用漢字表（2017年9月25日版）
- IsJinmeiyouKanji20170925 - ditto
- InJinmeiyoKanji20170925 - ditto
- InJinmeiyouKanji20170925 - ditto
- IsJinmeiyoKanji20150107 - 人名用漢字表（2015年1月7日版）
- IsJinmeiyouKanji20150107 - ditto
- InJinmeiyoKanji20150107 - ditto
- InJinmeiyouKanji20150107 - ditto
- IsJinmeiyoKanji20101130 - 人名用漢字表（2010年11月30日版）
- IsJinmeiyouKanji20101130 - ditto
- InJinmeiyoKanji20101130 - ditto
- InJinmeiyouKanji20101130 - ditto

# SEE ALSO

[Jōyō kanji - Wikipedia, the free encyclopedia](http://en.wikipedia.org/wiki/J%C5%8Dy%C5%8D_kanji)

[常用漢字表（平成22年11月30日内閣告示）](http://www.bunka.go.jp/kokugo_nihongo/pdf/jouyoukanjihyou_h22.pdf)

[Jinmeiyō kanji - Wikipedia, the free encyclopedia](http://en.wikipedia.org/wiki/Jinmeiy%C5%8D_kanji)

[人名用漢字表](http://www.moj.go.jp/content/001131003.pdf)

戸籍法 第50条

戸籍法施行規則 第60条

# LICENSE

Copyright (C) pawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

pawa <pawa@pawafuru.com>
