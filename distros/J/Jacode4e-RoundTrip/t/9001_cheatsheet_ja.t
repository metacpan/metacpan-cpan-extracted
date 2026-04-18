######################################################################
#
# 9001_cheatsheet_ja.t
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
#
# Jacode4e::RoundTrip チートシート（日本語）
# このテストは日本語話者向けのクイックリファレンスを兼ねています。
######################################################################

# このファイルはUTF-8でエンコードされています。
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ======================================================================
# Jacode4e::RoundTrip チートシート（日本語）
# ======================================================================
#
# 【基本的な使い方】
#
#   use FindBin;
#   use lib "$FindBin::Bin/lib";
#   use Jacode4e::RoundTrip;
#
#   $char_count = Jacode4e::RoundTrip::convert(\$line, $OUTPUT_encoding, $INPUT_encoding);
#   $char_count = Jacode4e::RoundTrip::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, { %option });
#
#   $line             : 変換対象の文字列（参照渡し・上書き）
#   $OUTPUT_encoding  : 出力エンコーディング名
#   $INPUT_encoding   : 入力エンコーディング名
#   $char_count       : 変換後の文字数
#
# 【エンコーディング名一覧】
#
#   mnemonic    説明
#   ---------   ---------------------------------------------------
#   cp932x      CP932X（JIS X 0213拡張、シングルシフト 0x9C5A使用）
#   cp932       Microsoft CP932（Windows-31J / IANA登録名）
#   cp932ibm    IBM CP932
#   cp932nec    NEC CP932
#   sjis2004    JISC Shift_JIS-2004
#   cp00930     IBM CP00930（CP00290+CP00300、CCSID 5026 カタカナ）
#   keis78      HITACHI KEIS78
#   keis83      HITACHI KEIS83
#   keis90      HITACHI KEIS90
#   jef         FUJITSU JEF（12ポイント、OUTPUT_SHIFTINGオプション使用）
#   jef9p       FUJITSU JEF（9ポイント、OUTPUT_SHIFTINGオプション使用）
#   jipsj       NEC JIPS(J)
#   jipse       NEC JIPS(E)
#   letsj       UNISYS LetsJ
#   utf8        UTF-8.0（通称 UTF-8）
#   utf8.1      UTF-8.1 (CP932ではなくShift_JISとUnicodeの対応をもとにした変換)
#   utf8jp      UTF-8-SPUA-JP（JIS X 0213をSPUAに配置）
#
# 【オプション一覧】
#
#   キー              説明
#   ---------------   ---------------------------------------------------
#   INPUT_LAYOUT      入力レコードレイアウト（'S'=1バイト文字、'D'=2バイト文字）
#                     例: 'SSDDSD' or 'S2D2SD'（繰り返し数指定可）
#   OUTPUT_SHIFTING   真値でシフトコード付き出力（JEF/JIPS/KEIS等）
#   SPACE             DBCS/MBCSスペースコード（バイナリ値）
#   GETA              DBCS/MBCSゲタコード（変換不能文字の代替）
#   OVERRIDE_MAPPING  個別マッピング上書き { "\x12\x34"=>"\x56\x78", ... }
#
# 【Jacode4e と Jacode4e::RoundTrip の違い】
#
#   Jacode4e              : 高速な一方向変換。CP932の398文字など有損変換あり。
#   Jacode4e::RoundTrip   : 往復変換保証。unicode経由で A→B→A の完全一致を確保。
#                           変換速度はJacode4eより遅いが、データ往復が必要な場合に使用。
#
# 【往復変換の注意】
#
#   非可逆変換が存在します（CP932の398文字問題など）。
#   往復変換が必要ない場合は Jacode4e モジュールを使用してください。
#
# ======================================================================

BEGIN {
    use vars qw(@test);
    @test = (

        # --- 基本動作: convert() の戻り値は変換後の文字数 ---
        # CP932の全角スペース(8140) -> JEF(A1A1): 1文字
        ["\x81\x40", 'jef',    'cp932', {},                    "\xA1\xA1", 'cp932(8140)->jef(A1A1) 文字数=1'],

        # CP932の全角スペース(8140) -> KEIS83(A1A1): 1文字
        ["\x81\x40", 'keis83', 'cp932', {},                    "\xA1\xA1", 'cp932(8140)->keis83(A1A1)'],

        # CP932の全角スペース(8140) -> JIPSJ(2121): 1文字
        ["\x81\x40", 'jipsj',  'cp932', {},                    "\x21\x21", 'cp932(8140)->jipsj(2121)'],

        # CP932の全角スペース(8140) -> UTF-8(E38080): 1文字
        ["\x81\x40", 'utf8',   'cp932', {},                    "\xE3\x80\x80", 'cp932(8140)->utf8(E38080)'],

        # --- SPACEオプション: DBCS空白の代替コード指定 ---
        ["\x81\x40", 'jef',    'cp932', {'SPACE'=>"\x40\x40"}, "\x40\x40", 'cp932(8140)->jef, SPACE=4040'],

        # --- GETAオプション: 変換不能文字をゲタ記号に置換 ---
        ["\xFC\xFC", 'jef',    'cp932', {'GETA'=>"\xFE\xFE"},  "\xFE\xFE", 'cp932(FCFC)->jef, GETA=FEFE'],

        # --- OUTPUT_SHIFTINGオプション: シフトコード付き出力 ---
        # CP932(8140+31) -> JEF + OUTPUT_SHIFTING: 28 A1A1 29 F1
        ["\x81\x40\x31", 'jef', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x28\xA1\xA1\x29\xF1",
            'cp932(814031)->jef OUTPUT_SHIFTING(28A1A129F1)'],

        # --- INPUT_LAYOUTオプション: シフトコードなし入力のレイアウト指定 ---
        # JEF(A1A1 F1) DSレイアウト -> CP932(8140 31)
        ["\xA1\xA1\xF1", 'cp932', 'jef', {'INPUT_LAYOUT'=>'DS'}, "\x81\x40\x31",
            'jef(A1A1F1) INPUT_LAYOUT=DS -> cp932(814031)'],

        # --- CP00930(EBCDIC): シフトコードが0E/0F ---
        # CP932(8140) -> CP00930 デフォルト(シフトコードなし): DBCS生データ4040
        ["\x81\x40", 'cp00930', 'cp932', {}, "\x40\x40", 'cp932(8140)->cp00930 no-shift(4040)'],
        # OUTPUT_SHIFTING=>1 を指定するとシフトコード付き: 0E 4040 0F
        ["\x81\x40\x31", 'cp00930', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0E\x40\x40\x0F\xF1",
            'cp932(814031)->cp00930 OUTPUT_SHIFTING(0E40400FF1)'],

        # --- KEIS78/83/90: 日立メインフレーム ---
        # デフォルト(シフトコードなし): DBCS生データのみ
        ["\x81\x40\x31", 'keis83', 'cp932', {}, "\xA1\xA1\xF1",
            'cp932(814031)->keis83 no-shift(A1A1F1)'],
        # OUTPUT_SHIFTING=>1: シフトコード 0A42(開始) / 0A41(終了) 付き
        ["\x81\x40\x31", 'keis83', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0A\x42\xA1\xA1\x0A\x41\xF1",
            'cp932(814031)->keis83 OUTPUT_SHIFTING(0A42A1A10A41F1)'],

        # --- ウェーブダッシュ問題（CP932固有の曖昧な変換）---
        # CP932(8160=波ダッシュ) -> UTF-8: E3809C (U+301C WAVE DASH)
        ["\x81\x60", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE3\x80\x9C",
            'cp932(8160 wave dash)->utf8(E3809C U+301C)'],

        # CP932(8160) -> JEF: A1C1
        ["\x81\x60", 'jef',    'cp932', {'INPUT_LAYOUT'=>'D'}, "\xA1\xC1",
            'cp932(8160)->jef(A1C1)'],

        # --- JIPSE: NEC JIPS(E) ---
        ["\x81\x40", 'jipse',  'cp932', {'INPUT_LAYOUT'=>'D'}, "\x4F\x4F", 'cp932(8140 D-layout)->jipse(4F4F)'],

        # --- LetsJ: UNISYS ---
        # デフォルト(シフトコードなし): DBCS生データ2020
        ["\x81\x40", 'letsj',  'cp932', {}, "\x20\x20", 'cp932(8140)->letsj no-shift(2020)'],
        # OUTPUT_SHIFTING=>1: シフトコード 9370(開始) / 93F1(終了) 付き
        ["\x81\x40\x31", 'letsj', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x93\x70\x20\x20\x93\xF1\x31",
            'cp932(814031)->letsj OUTPUT_SHIFTING(9370202093F131)'],

        # --- UTF-8.1: CP932ではなくShift_JISとUnicodeの対応をもとにした変換 ---
        # utf8 vs utf8.1 の差異: cp932(815C/8161/817C) でマッピングが異なる
        ["\x81\x40", 'utf8.1', 'cp932', {}, "\xE3\x80\x80", 'cp932(8140)->utf8.1(E38080)'],
        # utf8 vs utf8.1: 差異のある3文字 (cp932 815C/8161/817C)
        # cp932(815C)=― : utf8->U+2015 HORIZONTAL BAR, utf8.1->U+2014 EM DASH
        ["\x81\x5C", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x95", 'cp932(815C)->utf8(E28095 U+2015 HORIZONTAL BAR)'],
        ["\x81\x5C", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x94", 'cp932(815C)->utf8.1(E28094 U+2014 EM DASH)'],
        # cp932(8161)=∥ : utf8->U+2225 PARALLEL TO, utf8.1->U+2016 DOUBLE VERTICAL LINE
        ["\x81\x61", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x88\xA5", 'cp932(8161)->utf8(E288A5 U+2225 PARALLEL TO)'],
        ["\x81\x61", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x96", 'cp932(8161)->utf8.1(E28096 U+2016 DOUBLE VERTICAL LINE)'],
        # cp932(817C)=－ : utf8->U+FF0D FULLWIDTH HYPHEN-MINUS, utf8.1->U+2212 MINUS SIGN
        ["\x81\x7C", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xEF\xBC\x8D", 'cp932(817C)->utf8(EFBC8D U+FF0D FULLWIDTH HYPHEN-MINUS)'],
        ["\x81\x7C", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x88\x92", 'cp932(817C)->utf8.1(E28892 U+2212 MINUS SIGN)'],
        # cp932x(9C5A815C/8161/817C): utf8/utf8.1 マッピングがcp932と逆転
        ["\x9C\x5A\x81\x5C", 'utf8',   'cp932x', {}, "\xE2\x80\x94", 'cp932x(9C5A815C)->utf8(E28094 U+2014 EM DASH)'],
        ["\x9C\x5A\x81\x5C", 'utf8.1', 'cp932x', {}, "\xE2\x80\x95", 'cp932x(9C5A815C)->utf8.1(E28095 U+2015 HORIZONTAL BAR)'],
        ["\x9C\x5A\x81\x61", 'utf8',   'cp932x', {}, "\xE2\x80\x96", 'cp932x(9C5A8161)->utf8(E28096 U+2016 DOUBLE VERTICAL LINE)'],
        ["\x9C\x5A\x81\x61", 'utf8.1', 'cp932x', {}, "\xE2\x88\xA5", 'cp932x(9C5A8161)->utf8.1(E288A5 U+2225 PARALLEL TO)'],
        ["\x9C\x5A\x81\x7C", 'utf8',   'cp932x', {}, "\xE2\x88\x92", 'cp932x(9C5A817C)->utf8(E28892 U+2212 MINUS SIGN)'],
        ["\x9C\x5A\x81\x7C", 'utf8.1', 'cp932x', {}, "\xEF\xBC\x8D", 'cp932x(9C5A817C)->utf8.1(EFBC8D U+FF0D FULLWIDTH HYPHEN-MINUS)'],

        # --- UTF-8-SPUA-JP: JIS X 0213をSPUAに配置した内部コード ---
        ["\x81\x40", 'utf8jp', 'cp932', {}, "\xF3\xB0\x84\x80",
            'cp932(8140)->utf8jp(F3B08480 SPUA)'],

    );
    $|=1;
    print "1..",scalar(@test),"\n";
    my $testno=1;
    sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e::RoundTrip;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want,$desc) = @{$test};
    my $got = $give;
    my $return = Jacode4e::RoundTrip::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);
    ok(($return > 0) and ($got eq $want),
        sprintf('%s => return=%d got=(%s) want=(%s)',
            $desc, $return,
            uc unpack('H*',$got),
            uc unpack('H*',$want),
        )
    );
}

__END__
