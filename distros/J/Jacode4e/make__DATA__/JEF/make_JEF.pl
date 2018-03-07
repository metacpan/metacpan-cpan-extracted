######################################################################
#
# make_JEF.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib $FindBin::Bin;

# JEF
require 'JEF/JEF_by_CP932.pl';
require 'CP932/CP932_by_Unicode.pl';
require 'JIS/JIS78GR_by_JIS83GR.pl';
require 'JIS/JISX0208GR_by_CP932.pl';
require 'JEF/JEF_by_Unicode_CultiCoLtd.pl';

if ($0 eq __FILE__) {
    open(DUMP,">$0.dump") || die;
    binmode(DUMP);
    open(DIFF,">$0.diff") || die;
    binmode(DIFF);
}

my %JEF_by_Unicode_OVERRIDE = (
    '00B6' => '7FEF', # ¶
    '2020' => '7FED', # †
    '2021' => '7FEE', # ‡
    '2030' => '76D3', # ‰
    '212B' => '76D1', # Å
    '21D2' => '7FDA', # ⇒
    '21D4' => '7FDB', # ⇔
    '2200' => '7FDC', # ∀
    '2202' => '7FE1', # ∂
    '2203' => '7FDD', # ∃
    '2207' => '7FE2', # ∇
    '2208' => '7FD0', # ∈
    '220B' => '7FD1', # ∋
    '2211' => '',     # ∑
    '221A' => '7FE5', # √
    '221D' => '7FE7', # ∝
    '221F' => '',     # ∟
    '2220' => '7FDE', # ∠
    '2227' => '7FD8', # ∧
    '2228' => '7FD9', # ∨
    '2229' => '7FD7', # ∩
    '222A' => '7FD6', # ∪
    '222B' => '7FE8', # ∫
    '222C' => '7FE9', # ∬
    '222E' => '',     # ∮
    '2235' => '76A8', # ∵
    '223D' => '7FE6', # ∽
    '2252' => '76A9', # ≒
    '2261' => '76AA', # ≡
    '226A' => '7FE3', # ≪
    '226B' => '7FE4', # ≫
    '2282' => '7FD4', # ⊂
    '2283' => '7FD5', # ⊃
    '2286' => '7FD2', # ⊆
    '2287' => '7FD3', # ⊇
    '22A5' => '7FDF', # ⊥
    '22BF' => '',     # ⊿
    '2312' => '7FE0', # ⌒
    '2500' => '7CD1', # ─
    '2501' => '7CF6', # ━
    '2502' => '7CD2', # │
    '2503' => '7CF7', # ┃
    '250C' => '7CC1', # ┌
    '250F' => '7CE6', # ┏
    '2510' => '7CC2', # ┐
    '2513' => '7CE7', # ┓
    '2514' => '7CC4', # └
    '2517' => '7CE9', # ┗
    '2518' => '7CC3', # ┘
    '251B' => '7CE8', # ┛
    '251C' => '7CC7', # ├
    '251D' => '7FA2', # ┝
    '2520' => '7CCA', # ┠
    '2523' => '7CF3', # ┣
    '2524' => '7CC8', # ┤
    '2525' => '7FA4', # ┥
    '2528' => '7CCC', # ┨
    '252B' => '7CF4', # ┫
    '252C' => '7CC5', # ┬
    '252F' => '7CCB', # ┯
    '2530' => '7FA3', # ┰
    '2533' => '7CF1', # ┳
    '2534' => '7CC6', # ┴
    '2537' => '7CC0', # ┷
    '2538' => '7FA1', # ┸
    '253B' => '7CF2', # ┻
    '253C' => '7CC9', # ┼
    '253F' => '7CCE', # ┿
    '2542' => '7CCD', # ╂
    '254B' => '7CF5', # ╋
    '25EF' => '7FF0', # ◯
    '266A' => '7FEC', # ♪
    '266D' => '7FEB', # ♭
    '266F' => '7FEA', # ♯
    '301C' => 'A1C1', # ～
    '301D' => '',     # 〝
    '301F' => '',     # 〟
    '32A4' => '',     # ㊤
    '32A5' => '',     # ㊥
    '32A6' => '',     # ㊦
    '32A7' => '',     # ㊧
    '32A8' => '',     # ㊨
    '3351' => '',     # ㍑
    '337B' => '',     # ㍻
    '337C' => '',     # ㍼
    '337D' => '',     # ㍽
    '337E' => '',     # ㍾
    '51DC' => '44A4', # 凜
    '582F' => 'B6C6', # 堯
    '5C2D' => '47C8', # 尭
    '69C7' => 'CBEA', # 槇
    '69D9' => '54C4', # 槙
    '7199' => '58A8', # 熙
    '7464' => 'E0F6', # 瑤
    '7476' => '59A2', # 瑶
    '9059' => 'CDDA', # 遙
    '9065' => '70EB', # 遥
    'FF5E' => '',     # ～
    'FFE2' => '76A7', # ￢
);

my %unicode = map { $_ => 1 } (
    keys_of_CP932_by_Unicode(),
    keys_of_JEF_by_Unicode_CultiCoLtd(),
    keys %JEF_by_Unicode_OVERRIDE,
);

my %JEF_by_Unicode = ();
my %done = ();

for my $unicode (sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %unicode) {

    # override (not defined)
    if (exists($JEF_by_Unicode_OVERRIDE{$unicode}) and ($JEF_by_Unicode_OVERRIDE{$unicode} eq '')) {
        $done{$JEF_by_Unicode_OVERRIDE{$unicode}} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s \n", '----', $unicode, '----', '----', '----', '----', '----';
    }

    # override (defined)
    elsif (($JEF_by_Unicode_OVERRIDE{$unicode} ne '') and not $done{$JEF_by_Unicode_OVERRIDE{$unicode}}) {
        $done{$JEF_by_Unicode{$unicode} = $JEF_by_Unicode_OVERRIDE{$unicode}} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s \n", $JEF_by_Unicode{$unicode}, $unicode, $JEF_by_Unicode{$unicode}, '----', '----', '----', '----';
    }

    # CP932
    elsif ((JEF_by_CP932(CP932_by_Unicode($unicode)) ne '') and not $done{JEF_by_CP932(CP932_by_Unicode($unicode))}) {
        $done{$JEF_by_Unicode{$unicode} = JEF_by_CP932(CP932_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s \n", $JEF_by_Unicode{$unicode}, $unicode, '----', $JEF_by_Unicode{$unicode}, '----', '----', '----';
    }

    # JIS78 <-> JIS83
    elsif ((JIS78GR_by_JIS83GR(JISX0208GR_by_CP932(CP932_by_Unicode($unicode))) ne '') and not $done{JIS78GR_by_JIS83GR(JISX0208GR_by_CP932(CP932_by_Unicode($unicode)))}) {
        $done{$JEF_by_Unicode{$unicode} = JIS78GR_by_JIS83GR(JISX0208GR_by_CP932(CP932_by_Unicode($unicode)))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s \n", $JEF_by_Unicode{$unicode}, $unicode, '----', '----', $JEF_by_Unicode{$unicode}, '----', '----';
    }

    # JIS X 0208:1990
    elsif ((JISX0208GR_by_CP932(CP932_by_Unicode($unicode)) ne '') and not $done{JISX0208GR_by_CP932(CP932_by_Unicode($unicode))}) {
        $done{$JEF_by_Unicode{$unicode} = JISX0208GR_by_CP932(CP932_by_Unicode($unicode))} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s \n", $JEF_by_Unicode{$unicode}, $unicode, '----', '----', '----', $JEF_by_Unicode{$unicode}, '----';
    }

    # JIS X 0213:2004
    elsif ((JEF_by_Unicode_CultiCoLtd($unicode) ne '') and not $done{JEF_by_Unicode_CultiCoLtd($unicode)}) {
        $done{$JEF_by_Unicode{$unicode} = JEF_by_Unicode_CultiCoLtd($unicode)} = 1;
printf DUMP "%-4s %-9s %-4s %-4s %-4s %-4s %-4s \n", $JEF_by_Unicode{$unicode}, $unicode, '----', '----', '----', '----', $JEF_by_Unicode{$unicode};
    }

    if (
        ($JEF_by_Unicode{$unicode} ne '') and
        (JEF_by_Unicode_CultiCoLtd($unicode) ne '') and
        ($JEF_by_Unicode{$unicode} ne JEF_by_Unicode_CultiCoLtd($unicode)) and
    1) {
        printf DIFF ("[%s] (%s) (%s) (%s)\n",
            (CP932_by_Unicode($unicode) ne '') ? pack('H*',CP932_by_Unicode($unicode)) : (' ' x 2),
            $unicode || (' ' x 4),
            $JEF_by_Unicode{$unicode} || (' ' x 4),
            JEF_by_Unicode_CultiCoLtd($unicode) || (' ' x 4),
        );
    }

    if ((JEF_by_Unicode_CultiCoLtd($unicode) ne '') and (JEF_by_CP932(CP932_by_Unicode($unicode)) ne '')) {
        if (JEF_by_Unicode_CultiCoLtd($unicode) ne JEF_by_CP932(CP932_by_Unicode($unicode))) {
die sprintf "Unicode=($unicode), CultiCoLtd=(%s) Handmade=(%s)\n", JEF_by_Unicode_CultiCoLtd($unicode), JEF_by_CP932(CP932_by_Unicode($unicode));
        }
    }
}

close(DUMP);
close(DIFF);

sub JEF_by_Unicode {
    my($unicode) = @_;
    return $JEF_by_Unicode{$unicode};
}

sub keys_of_JEF_by_Unicode {
    return keys %JEF_by_Unicode;
}

sub values_of_JEF_by_Unicode {
    return values %JEF_by_Unicode;
}

1;

__END__
