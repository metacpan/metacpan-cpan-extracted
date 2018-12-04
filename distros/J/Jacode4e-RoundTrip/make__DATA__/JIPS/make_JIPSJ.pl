######################################################################
#
# make_JIPSJ.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

# JIPS(J)
require 'JIPS/JIPSJ_by_CP932.pl';
require 'Unicode/Unicode_by_CP932.pl';
require 'JIS/JIS78GL_by_JIS83GL.pl';
require 'JIS/JISX0208GL_by_SJIS.pl';
require 'JIS/JISX0208GL_by_CP932.pl';
require 'JIPS/NEC_CP932_by_Unicode.pl';
require 'JIPS/JIPSJ_by_Unicode_CultiCoLtd.pl';
require 'CP932/CP932_by_Unicode.pl';

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
}

my %JIPSJ_by_Unicode_OVERRIDE = (
    '00B6' => 'A5F0', # ¶
    '2014' => '',     # ―
    '2015' => '213D', # ―
    '2016' => '',     # ∥
    '2020' => 'A5EE', # †
    '2021' => 'A5EF', # ‡
    '2030' => 'A4FE', # ‰
    '212B' => 'A4DF', # Å
    '21D2' => 'A6F6', # ⇒
    '21D4' => 'A6F7', # ⇔
    '2200' => 'A5E7', # ∀
    '2202' => 'A5CA', # ∂
    '2203' => 'A5E8', # ∃
    '2207' => 'A6F9', # ∇
    '2208' => 'A5D4', # ∈
    '220B' => 'A5D5', # ∋
    '2211' => '2D74', # ∑
    '2212' => '',     # －
    '221A' => '2D75', # √
    '221D' => 'A5DC', # ∝
    '221F' => '2D78', # ∟
    '2220' => '2D77', # ∠
    '2225' => '2142', # ∥
    '2227' => 'A5D0', # ∧
    '2228' => 'A5D1', # ∨
    '2229' => '2D7B', # ∩
    '222A' => '2D7C', # ∪
    '222B' => '2D72', # ∫
    '222C' => 'A6FA', # ∬
    '222E' => '2D73', # ∮
    '2235' => '2D7A', # ∵
    '223D' => 'A5DD', # ∽
    '2252' => '2D70', # ≒
    '2261' => '2D71', # ≡
    '226A' => 'A5E1', # ≪
    '226B' => 'A5E2', # ≫
    '2282' => 'A5D2', # ⊂
    '2283' => 'A5D3', # ⊃
    '2286' => 'A6F4', # ⊆
    '2287' => 'A6F5', # ⊇
    '22A5' => '2D76', # ⊥
    '22BF' => '2D79', # ⊿
    '2312' => 'A6F8', # ⌒
    '2460' => '2D21', # ①
    '2461' => '2D22', # ②
    '2462' => '2D23', # ③
    '2463' => '2D24', # ④
    '2464' => '2D25', # ⑤
    '2465' => '2D26', # ⑥
    '2466' => '2D27', # ⑦
    '2467' => '2D28', # ⑧
    '2468' => '2D29', # ⑨
    '2469' => '2D2A', # ⑩
    '246A' => '2D2B', # ⑪
    '246B' => '2D2C', # ⑫
    '246C' => '2D2D', # ⑬
    '246D' => '2D2E', # ⑭
    '246E' => '2D2F', # ⑮
    '246F' => '2D30', # ⑯
    '2470' => '2D31', # ⑰
    '2471' => '2D32', # ⑱
    '2472' => '2D33', # ⑲
    '2473' => '2D34', # ⑳
    '2500' => '',     # ─
    '2501' => '',     # ━
    '2502' => '',     # │
    '2503' => '',     # ┃
    '250C' => '',     # ┌
    '250F' => '',     # ┏
    '2510' => '',     # ┐
    '2513' => '',     # ┓
    '2514' => '',     # └
    '2517' => '',     # ┗
    '2518' => '',     # ┘
    '251B' => '',     # ┛
    '251C' => '',     # ├
    '251D' => '',     # ┝
    '2520' => '',     # ┠
    '2523' => '',     # ┣
    '2524' => '',     # ┤
    '2525' => '',     # ┥
    '2528' => '',     # ┨
    '252B' => '',     # ┫
    '252C' => '',     # ┬
    '252F' => '',     # ┯
    '2530' => '',     # ┰
    '2533' => '',     # ┳
    '2534' => '',     # ┴
    '2537' => '',     # ┷
    '2538' => '',     # ┸
    '253B' => '',     # ┻
    '253C' => '',     # ┼
    '253F' => '',     # ┿
    '2542' => '',     # ╂
    '254B' => '',     # ╋
    '25EF' => 'A6FE', # ◯
    '2642' => '2169', # ♂
    '266A' => 'A6FD', # ♪
    '266D' => 'A6FC', # ♭
    '266F' => 'A6FB', # ♯
    '3007' => '213B', # 〇
    '301C' => '2141', # ～
    '301D' => '2D60', # 〝
    '301F' => '2D61', # 〟
    '3232' => '2D6B', # ㈲
    '3239' => '2D6C', # ㈹
    '32A4' => '2D65', # ㊤
    '32A5' => '2D66', # ㊥
    '32A6' => '2D67', # ㊦
    '32A7' => '2D68', # ㊧
    '32A8' => '2D69', # ㊨
    '3303' => '2D46', # ㌃
    '330D' => '2D4A', # ㌍
    '3314' => '2D41', # ㌔
    '3318' => '2D44', # ㌘
    '3322' => '2D42', # ㌢
    '3323' => '2D4C', # ㌣
    '3326' => '2D4B', # ㌦
    '3327' => '2D45', # ㌧
    '332B' => '2D4D', # ㌫
    '3336' => '2D47', # ㌶
    '333B' => '2D4F', # ㌻
    '3349' => '2D40', # ㍉
    '334A' => '2D4E', # ㍊
    '334D' => '2D43', # ㍍
    '3351' => '2D48', # ㍑
    '3357' => '2D49', # ㍗
    '337B' => '2D5F', # ㍻
    '337C' => '2D6F', # ㍼
    '337D' => '2D6E', # ㍽
    '337E' => '2D6D', # ㍾
    '338E' => '2D53', # ㎎
    '338F' => '2D54', # ㎏
    '339C' => '2D50', # ㎜
    '339D' => '2D51', # ㎝
    '339E' => '2D52', # ㎞
    '33A1' => '2D56', # ㎡
    '33C4' => '2D55', # ㏄
    '33CD' => '2D63', # ㏍
    '51DC' => 'B4A8', # 凜
    '582F' => '3646', # 堯
    '5C2D' => 'B6DA', # 尭
    '69C7' => '4B6A', # 槇
    '69D9' => 'BFCE', # 槙
    '7199' => 'C3BA', # 熙
    '7464' => '6076', # 瑤
    '7476' => 'C4E8', # 瑶
    '9059' => '4D5A', # 遙
    '9065' => 'D0C4', # 遥
    'FF0D' => '215D', # －
    'FF5E' => '',     # ～
    'FFE2' => '',     # ￢
);

my %unicode = map { $_ => 1 } (
    (map { Unicode_by_CP932($_) } keys_of_JIPSJ_by_CP932()),
    keys_of_NEC_CP932_by_Unicode(),
    keys_of_JIPSJ_by_Unicode_CultiCoLtd(),
    keys %JIPSJ_by_Unicode_OVERRIDE,
);

my %JIPSJ_by_Unicode = ();
my %done = ();

for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {
    if (0) {
    }

    my $char = pack('H*',CP932_by_Unicode($unicode));

    # NEC Corporation Standard character set dictionary <BASIC>
    # Document number ZBB10-3
    # NEC Corporation Standard character set dictionary <EXTENSION>
    # Document number ZBB11-2
    if ((JIPSJ_by_CP932(CP932_by_Unicode($unicode)) ne '') and not $done{JIPSJ_by_CP932(CP932_by_Unicode($unicode))}) {
        $done{$JIPSJ_by_Unicode{$unicode} = JIPSJ_by_CP932(CP932_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s %-4s $char\n", JIPSJ_by_CP932(CP932_by_Unicode($unicode)), $unicode, JIPSJ_by_CP932(CP932_by_Unicode($unicode)), '----', '----', '----', '----', '----', '----', '----', '----';
    }

    # override (not defined)
    elsif (exists($JIPSJ_by_Unicode_OVERRIDE{$unicode}) and ($JIPSJ_by_Unicode_OVERRIDE{$unicode} eq '')) {
        $done{$JIPSJ_by_Unicode_OVERRIDE{$unicode}} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s %-4s $char\n", $JIPSJ_by_Unicode{$unicode}, $unicode, '----', $JIPSJ_by_Unicode_OVERRIDE{$unicode}, '----', '----', '----', '----', '----', '----', '----';
    }

    # override (defined)
    elsif (($JIPSJ_by_Unicode_OVERRIDE{$unicode} ne '') and not $done{$JIPSJ_by_Unicode_OVERRIDE{$unicode}}) {
        $done{$JIPSJ_by_Unicode{$unicode} = $JIPSJ_by_Unicode_OVERRIDE{$unicode}} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s %-4s $char\n", $JIPSJ_by_Unicode{$unicode}, $unicode, '----', '----', $JIPSJ_by_Unicode_OVERRIDE{$unicode}, '----', '----', '----', '----', '----', '----';
    }

    # JIS78 <-> JIS83
    elsif ((JIS78GL_by_JIS83GL(JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode))) ne '') and not $done{JIS78GL_by_JIS83GL(JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode)))}) {
        $done{$JIPSJ_by_Unicode{$unicode} = JIS78GL_by_JIS83GL(JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode)))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s %-4s $char\n", $JIPSJ_by_Unicode{$unicode}, $unicode, '----', '----', '----', JIS78GL_by_JIS83GL(JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode))), JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode)), JISX0208GL_by_CP932(NEC_CP932_by_Unicode($unicode)), JIPSJ_by_Unicode_CultiCoLtd($unicode), '----', '----';
    }

    # JIS C 6226-1978 by SJIS
    elsif ((JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode)) ne '') and not $done{JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode))}) {
        $done{$JIPSJ_by_Unicode{$unicode} = JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s %-4s $char\n", $JIPSJ_by_Unicode{$unicode}, $unicode, '----', '----', '----', '----', JIS78GL_by_JIS83GL(JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode))), JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode)), JISX0208GL_by_CP932(NEC_CP932_by_Unicode($unicode)), JIPSJ_by_Unicode_CultiCoLtd($unicode), '----';
    }

    # JIS X 0213:2004
    elsif ((JIPSJ_by_Unicode_CultiCoLtd($unicode) ne '') and not $done{JIPSJ_by_Unicode_CultiCoLtd($unicode)}) {
        $done{$JIPSJ_by_Unicode{$unicode} = JIPSJ_by_Unicode_CultiCoLtd($unicode)} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s %-4s $char\n", $JIPSJ_by_Unicode{$unicode}, $unicode, '----', '----', '----', '----', '----', JIS78GL_by_JIS83GL(JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode))), JISX0208GL_by_SJIS(NEC_CP932_by_Unicode($unicode)), JISX0208GL_by_CP932(NEC_CP932_by_Unicode($unicode)), JIPSJ_by_Unicode_CultiCoLtd($unicode);
    }
}

close(DUMP);

sub JIPSJ_by_Unicode {
    my($unicode) = @_;
    return $JIPSJ_by_Unicode{$unicode};
}

sub keys_of_JIPSJ_by_Unicode {
    return keys %JIPSJ_by_Unicode;
}

sub values_of_JIPSJ_by_Unicode {
    return values %JIPSJ_by_Unicode;
}

1;

__END__
