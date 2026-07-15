#!/usr/bin/perl
######################################################################
#
# build_cheatsheets.pl - generate doc/jacode4e_cheatsheet.XX.txt
#
# Regenerates all 21 language cheat sheets from one shared template
# so that the structure, encoding table, option call examples, shift
# table, and sample code are identical in every language, and only
# the translatable prose differs. This keeps every file within the
# t/9080_cheatsheets.t bounds (60..200 lines, 2000..20000 bytes) and
# guarantees the required tokens are present.
#
# Usage:  perl build_cheatsheets.pl          (writes into this doc/ dir)
#
# Compatible with Perl 5.005_03 through the latest Perl.
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W = 1;
use vars qw(%L @ORDER);

######################################################################
# Language order (matches t/9080_cheatsheets.t @LANG_CODES)
######################################################################
@ORDER = qw(BM BN EN FR HI ID JA KM KO MN MY NE SI TH TL TR TW UR UZ VI ZH);

######################################################################
# Language-neutral blocks (identical in every file)
######################################################################

# encoding mnemonic table body (kept in the technical, neutral form)
my $ENC_TABLE = <<'END_ENC';
  mnemonic    description
  ---------   ---------------------------------------------------
  cp932x      CP932X (Extended CP932 to JIS X 0213, single-shift 0x9C5A)
  cp932       Microsoft CP932 (Windows-31J / IANA registered name)
  cp932ibm    IBM CP932
  cp932nec    NEC CP932
  sjis        JISC Shift_JIS (JIS X 0201, JIS X 0208); year editions below
  sjis2004    JISC Shift_JIS-2004 (JIS X 0213:2004)
  euc         JISC EUC-JP (JIS X 0201, JIS X 0208, JIS X 0212); year editions below
  euc2004     JISC EUC-JIS-2004 (JIS X 0213 plane 1 and plane 2)
  jis         JISC ISO-2022-JP (JIS X 0201, JIS X 0208, JIS X 0212); year editions below
  jis2004     JISC ISO-2022-JP-2004 (JIS X 0213 plane 1 and plane 2)
  cp00930     IBM CP00930 (CP00290+CP00300, CCSID 5026 katakana)
  keis78      HITACHI KEIS78
  keis83      HITACHI KEIS83
  keis90      HITACHI KEIS90
  jef         FUJITSU JEF (12pt, use OUTPUT_SHIFTING option for shift codes)
  jef9p       FUJITSU JEF ( 9pt, use OUTPUT_SHIFTING option for shift codes)
  jipsj       NEC JIPS(J)
  jipse       NEC JIPS(E)
  letsj       UNISYS LetsJ
  utf8        UTF-8.0 (aka UTF-8)
  utf8.1      UTF-8.1 (conversion based on Shift_JIS-to-Unicode mapping, not CP932)
  utf8jp      UTF-8-SPUA-JP (JIS X 0213 on SPUA ordered by JIS level/plane/row/cell)
END_ENC

# year edition table (the mnemonic triples; the trailing intro line is translated)
my $ERA_TABLE = <<'END_ERA';
    sjis1978  euc1978  jis1978   JIS C 6226-1978
    sjis1983  euc1983  jis1983   JIS X 0208-1983
    sjis1990  euc1990  jis1990   JIS X 0208-1990  (= sjis / euc / jis)
    sjis2000  euc2000  jis2000   JIS X 0213:2000
    sjis2004  euc2004  jis2004   JIS X 0213:2004
END_ERA

# option call examples (language-neutral Perl); paired with translated prose
my %OPT_EG = (
    'INPUT_LAYOUT'    => q{    e.g. Jacode4e::convert(\$line,'cp932x','cp00930',{'INPUT_LAYOUT'=>'S2D2SD'});},
    'OUTPUT_SHIFTING' => q{    e.g. Jacode4e::convert(\$line,'jef','cp932x',{'OUTPUT_SHIFTING'=>1});},
    'SPACE'           => q{    e.g. Jacode4e::convert(\$line,'cp932x','cp00930',{'SPACE'=>"\x81\xA1"});},
    'GETA'            => q{    e.g. Jacode4e::convert(\$line,'cp932x','cp00930',{'GETA'=>"\x81\xA2"});},
    'OVERRIDE_MAPPING'=> q{    e.g. Jacode4e::convert(\$line,'cp932x','cp00930',{'OVERRIDE_MAPPING'=>{"\x44\x5A"=>"\x81\x7C"}});},
    'JIS_SOSI'        => q{    e.g. Jacode4e::convert(\$line,'utf8','jis',{'JIS_SOSI'=>1});},
    'JIS_X0212'       => q{    e.g. Jacode4e::convert(\$line,'jis','utf8',{'JIS_X0212'=>1,'OUTPUT_SHIFTING'=>1});},
    'JIS_KANA'        => q{    e.g. Jacode4e::convert(\$line,'jis','utf8',{'JIS_KANA'=>'SO','OUTPUT_SHIFTING'=>1});},
    'JIS_DBCS'        => q{    e.g. Jacode4e::convert(\$line,'jis','utf8',{'JIS_DBCS'=>'@'});},
    'JIS_SBCS'        => q{    e.g. Jacode4e::convert(\$line,'jis','utf8',{'JIS_SBCS'=>'J'});},
    'JIS2004_PLANE1'  => q{    e.g. Jacode4e::convert(\$line,'jis2004','utf8',{'JIS2004_PLANE1'=>'O'});},
    'ROUND_TRIP'      => q{    e.g. Jacode4e::convert(\$line,'cp00930','utf8',{'ROUND_TRIP'=>1});},
);
my @OPT_ORDER = qw(INPUT_LAYOUT OUTPUT_SHIFTING SPACE GETA OVERRIDE_MAPPING
                   JIS_SOSI JIS_X0212 JIS_KANA JIS_DBCS JIS_SBCS JIS2004_PLANE1 ROUND_TRIP);

my $SHIFT_TABLE = <<'END_SHIFT';
  encoding  shift-out (DBCS start)  shift-in (DBCS end)
  --------  ---------------------   -------------------
  cp00930   0x0E                    0x0F
  keis78    0x0A 0x42               0x0A 0x41
  keis83    0x0A 0x42               0x0A 0x41
  keis90    0x0A 0x42               0x0A 0x41
  jef       0x28                    0x29
  jef9p     0x38                    0x29
  jipsj     0x1A 0x70               0x1A 0x71
  jipse     0x3F 0x75               0x3F 0x76
  letsj     0x93 0x70               0x93 0xF1
END_SHIFT

######################################################################
# render one file from the translation hash of a language
######################################################################
sub render {
    my ($code) = @_;
    my $t = $L{$code};
    my @o = ();

    push @o, "################################################################################";
    push @o, "# $t->{TITLE2}";
    push @o, "# Jacode4e - Converts Character Encodings for Enterprise in Japan";
    push @o, "# https://metacpan.org/dist/Jacode4e";
    push @o, "# Copyright (c) 2026 INABA Hitoshi <ina.cpan\@gmail.com>";
    push @o, "################################################################################";
    push @o, "";
    push @o, "======================================================================";
    push @o, $t->{TITLE9};
    push @o, "======================================================================";
    push @o, "";

    push @o, "[$t->{H_BASIC}]";
    push @o, "";
    push @o, '  use FindBin;';
    push @o, '  use lib "$FindBin::Bin/lib";';
    push @o, '  use Jacode4e;';
    push @o, "";
    push @o, '  $char_count = Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding);';
    push @o, '  $char_count = Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, { %option });';
    push @o, "";
    push @o, '  $line             : '.$t->{A_LINE};
    push @o, '  $OUTPUT_encoding  : '.$t->{A_OUT};
    push @o, '  $INPUT_encoding   : '.$t->{A_IN};
    push @o, '  $char_count       : '.$t->{A_COUNT};
    push @o, "";

    push @o, "[$t->{H_ENC}]";
    push @o, "";
    chomp(my $enc = $ENC_TABLE); push @o, $enc;
    push @o, "";
    push @o, "  $t->{ERA_INTRO}";
    chomp(my $era = $ERA_TABLE); push @o, $era;
    push @o, "";

    push @o, "[$t->{H_ERA}]";
    push @o, "";
    push @o, "  $t->{ERA_P1}";
    push @o, "";
    push @o, "  1978 (JIS C 6226-1978) : $t->{ERA_1978}";
    push @o, "  1983 (JIS X 0208-1983) : $t->{ERA_1983}";
    push @o, "  1990 (JIS X 0208-1990) : $t->{ERA_1990}";
    push @o, "  2000 (JIS X 0213:2000) : $t->{ERA_2000}";
    push @o, "  2004 (JIS X 0213:2004) : $t->{ERA_2004}";
    push @o, "";

    push @o, "[$t->{H_OPT}]";
    push @o, "";
    push @o, "  $t->{OPT_INTRO}";
    push @o, "";
    for my $k (@OPT_ORDER) {
        push @o, "  $k";
        push @o, "    ".$t->{"O_$k"};
        push @o, $OPT_EG{$k};
        push @o, "";
    }

    push @o, "[$t->{H_SHIFT}]";
    push @o, "";
    chomp(my $sh = $SHIFT_TABLE); push @o, $sh;
    push @o, "";

    push @o, "[$t->{H_SAMPLE}]";
    push @o, "";
    push @o, "  # 1) $t->{S1}";
    push @o, '  use FindBin;';
    push @o, '  use lib "$FindBin::Bin/lib";';
    push @o, '  use Jacode4e;';
    push @o, '  while (<>) {';
    push @o, q!      $char_count = Jacode4e::convert(\$_, 'cp00930', 'utf8', {!;
    push @o, q{          'OUTPUT_SHIFTING' => 1,};
    push @o, q{          'SPACE'           => "\x40\x40",};
    push @o, q{          'GETA'            => "\x44\x4B",};
    push @o, q!      });!;
    push @o, '      print $_;';
    push @o, '  }';
    push @o, "";
    push @o, "  # 2) $t->{S2}";
    push @o, q{  Jacode4e::convert(\$line, 'utf8', 'sjis1978');};
    push @o, "";
    push @o, "  # 3) $t->{S3}";
    push @o, q{  Jacode4e::convert(\$line, 'cp00930', 'utf8', { 'ROUND_TRIP' => 1 });};
    push @o, q{  Jacode4e::convert(\$line, 'utf8', 'cp00930', { 'ROUND_TRIP' => 1 });};
    push @o, "";
    push @o, "======================================================================";

    return join("\n", @o) . "\n";
}

######################################################################
# write all files
######################################################################
for my $code (@ORDER) {
    die "missing translation for $code\n" unless $L{$code};
    my $text = render($code);
    my $file = "jacode4e_cheatsheet.$code.txt";
    open(OUT, ">$file") or die "$file: $!";
    binmode(OUT);
    print OUT $text;
    close(OUT);
    print "wrote $file (", length($text), " bytes)\n";
}

######################################################################
# translations
######################################################################
BEGIN {

$L{'EN'} = {
    TITLE2 => 'Jacode4e Cheat Sheet (EN)',
    TITLE9 => 'Jacode4e Cheatsheet (English)',
    H_BASIC=> 'BASIC USAGE',
    H_ENC  => 'ENCODING MNEMONICS',
    H_ERA  => 'JIS EDITION DIFFERENCES BY YEAR (for beginners)',
    H_OPT  => 'OPTIONS',
    H_SHIFT=> 'SHIFT CODE REFERENCE',
    H_SAMPLE=>'SAMPLES',
    A_LINE => 'string to convert (passed by reference, overwritten in place)',
    A_OUT  => 'output encoding mnemonic',
    A_IN   => 'input encoding mnemonic',
    A_COUNT=> 'character count after conversion',
    ERA_INTRO => 'Year editions of sjis / euc / jis (the year-less name is the 1990 edition):',
    ERA_P1 => 'Japanese kanji were standardized in stages. The same bytes can mean a different character between editions, so pick the edition that matches your data. If you do not know, use the year-less sjis / euc / jis.',
    ERA_1978 => 'the first kanji standard (Level 1 and Level 2).',
    ERA_1983 => 'swapped the code of 22 kanji pairs and changed some printed shapes; the most common cause of garbled old data.',
    ERA_1990 => 'added only 2 kanji (U+51DC, U+7199); the year-less sjis / euc / jis mean this edition.',
    ERA_2000 => 'big expansion; added Level 3 and Level 4 kanji and symbols on a new plane 2.',
    ERA_2004 => 'added 10 kanji and changed the exemplar shape of 168 kanji (same code as 2000, new glyphs).',
    OPT_INTRO => 'Pass options as the 4th argument: { \'KEY\' => value, ... }',
    O_INPUT_LAYOUT   => 'Fixed record layout by \'S\' (1-byte SBCS) and \'D\' (2-byte DBCS); a letter may be followed by a repeat count. Default: auto.',
    O_OUTPUT_SHIFTING=> 'True emits shift-out/shift-in codes around DBCS runs. Default: false.',
    O_SPACE          => 'DBCS/MBCS space fill code (binary string). Default: the encoding space.',
    O_GETA           => 'DBCS/MBCS geta code for characters that cannot be mapped.',
    O_OVERRIDE_MAPPING=>'Hashref of per-character FROM => TO overrides (also overrides SPACE).',
    O_JIS_SOSI       => 'True: on \'jis\' input, SO (0x0E)/SI (0x0F) shift to JIS X 0201 Katakana (JIS7 habit). Default: false; INPUT is \'jis\'.',
    O_JIS_X0212      => 'True: on \'jis\' output, a character in JIS X 0212 but not JIS X 0208 is written as ESC $ ( D. Needs OUTPUT_SHIFTING. Default: false.',
    O_JIS_KANA       => 'Katakana style on \'jis\' output: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, needs OUTPUT_SHIFTING), \'SO\' (SO/GL/SI). Default: \'GR\'.',
    O_JIS_DBCS       => 'DBCS escape on \'jis\' output: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Default: \'B\'; OUTPUT is \'jis\'.',
    O_JIS_SBCS       => 'SBCS escape on \'jis\' output: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H old). Default: \'B\'; OUTPUT is \'jis\'.',
    O_JIS2004_PLANE1 => 'Plane-1 escape on \'jis2004\' output: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Default: \'Q\'; OUTPUT is \'jis2004\'.',
    O_ROUND_TRIP     => 'True: reversible conversion; a character with no native code is placed in the user-defined (GAIJI) area so "A to B" and "B to A" restore the original. Both directions need ROUND_TRIP=>1 and the SAME Jacode4e version. Default: false (unmappable becomes GETA). Built lazily on first use.',
    S1 => 'UTF-8 to a mainframe encoding, with shifting, space, geta',
    S2 => 'old 1978 Shift_JIS to UTF-8 (era-aware)',
    S3 => 'round-trip: UTF-8 -> CP00930 -> UTF-8 restores the original',
};

$L{'JA'} = {
    TITLE2 => 'Jacode4e チートシート (JA)',
    TITLE9 => 'Jacode4e チートシート（日本語）',
    H_BASIC=> '基本的な使い方',
    H_ENC  => 'エンコーディング名一覧',
    H_ERA  => 'JIS規格の年代差分（初心者向け）',
    H_OPT  => 'オプション一覧',
    H_SHIFT=> 'シフトコード早見表',
    H_SAMPLE=>'プログラミングサンプル',
    A_LINE => '変換対象の文字列（参照渡し・その場で上書き）',
    A_OUT  => '出力エンコーディング名',
    A_IN   => '入力エンコーディング名',
    A_COUNT=> '変換後の文字数',
    ERA_INTRO => 'sjis / euc / jis の年代版（年号なしは1990年版）:',
    ERA_P1 => '日本語の漢字は段階的に規格化されました。版が違うと同じバイト列が別の文字を表すことがあるため、データに合った版を選びます。分からない場合は年号なしの sjis / euc / jis を使ってください。',
    ERA_1978 => '最初の漢字規格（第1水準・第2水準）。',
    ERA_1983 => '22組の漢字の符号位置を入れ替え、一部の字形を変更。古いデータ文字化けの最大の原因。',
    ERA_1990 => '漢字を2字だけ追加（U+51DC, U+7199）。年号なしの sjis / euc / jis はこの版。',
    ERA_2000 => '大幅拡張。第3水準・第4水準の漢字と記号を新しい面2に追加。',
    ERA_2004 => '漢字を10字追加し、168字の例示字形を変更（符号位置は2000年版と同一、字形のみ変更）。',
    OPT_INTRO => 'オプションは第4引数に渡します: { \'KEY\' => 値, ... }',
    O_INPUT_LAYOUT   => '\'S\'（1バイトSBCS）と\'D\'（2バイトDBCS）による固定レコードレイアウト。文字の後に繰り返し数を付けられます。既定: 自動。',
    O_OUTPUT_SHIFTING=> '真でDBCS列の前後にシフトアウト/シフトインを出力。既定: 偽。',
    O_SPACE          => 'DBCS/MBCSの空白コード（バイナリ文字列）。既定: そのエンコーディングの空白。',
    O_GETA           => 'マッピングできない文字に使うDBCS/MBCSのゲタコード。',
    O_OVERRIDE_MAPPING=>'文字単位の FROM => TO 上書きのハッシュ参照（SPACEも上書きします）。',
    O_JIS_SOSI       => '真: \'jis\'入力でSO(0x0E)/SI(0x0F)をJIS X 0201カタカナへのシフトとして扱う（JIS7の習慣）。既定: 偽。入力が\'jis\'のとき有効。',
    O_JIS_X0212      => '真: \'jis\'出力で、JIS X 0208になくJIS X 0212にある文字を ESC $ ( D で出力。OUTPUT_SHIFTINGが必要。既定: 偽。',
    O_JIS_KANA       => '\'jis\'出力のカタカナ形式: \'GR\'(0xA1..0xDF)、\'I\'(ESC ( I、OUTPUT_SHIFTING必要)、\'SO\'(SO/GL/SI)。既定: \'GR\'。',
    O_JIS_DBCS       => '\'jis\'出力のDBCSエスケープ: \'B\'(ESC $ B)、\'@\'(ESC $ @)、\'&@B\'、\'(B\'、\'(@\'。既定: \'B\'。出力が\'jis\'のとき有効。',
    O_JIS_SBCS       => '\'jis\'出力のSBCSエスケープ: \'B\'(ESC ( B ASCII)、\'J\'(ESC ( J ローマ字)、\'H\'(ESC ( H 旧)。既定: \'B\'。出力が\'jis\'のとき有効。',
    O_JIS2004_PLANE1 => '\'jis2004\'出力の面1エスケープ: \'Q\'(ESC $ ( Q、:2004)、\'O\'(ESC $ ( O、:2000)。既定: \'Q\'。出力が\'jis2004\'のとき有効。',
    O_ROUND_TRIP     => '真: 可逆変換。ネイティブコードのない文字をユーザー定義（外字）領域に割り当て、「A→B」と「B→A」で元に戻ります。往路・復路とも ROUND_TRIP=>1 と同一バージョンのJacode4eが必要。既定: 偽（変換不能はGETA）。テーブルは初回呼び出し時に遅延構築されます。',
    S1 => 'UTF-8からメインフレーム系へ（シフト・空白・ゲタ指定）',
    S2 => '古い1978年版Shift_JISからUTF-8へ（年代指定）',
    S3 => '往復変換: UTF-8 -> CP00930 -> UTF-8 で元に戻る',
};

$L{'ZH'} = {
    TITLE2 => 'Jacode4e 速查表 (ZH)',
    TITLE9 => 'Jacode4e 快速参考手册（简体中文）',
    H_BASIC=> '基本用法',
    H_ENC  => '编码名称一览',
    H_ERA  => 'JIS 标准各年代差异（面向初学者）',
    H_OPT  => '选项一览',
    H_SHIFT=> '移位码速查',
    H_SAMPLE=>'编程示例',
    A_LINE => '要转换的字符串（按引用传递，就地覆盖）',
    A_OUT  => '输出编码名称',
    A_IN   => '输入编码名称',
    A_COUNT=> '转换后的字符数',
    ERA_INTRO => 'sjis / euc / jis 的年代版本（无年份者为 1990 年版）：',
    ERA_P1 => '日文汉字是分阶段标准化的。不同版本中相同的字节可能表示不同的字符，因此请选择与数据相符的版本。若不确定，请使用无年份的 sjis / euc / jis。',
    ERA_1978 => '最早的汉字标准（第 1 水准与第 2 水准）。',
    ERA_1983 => '交换了 22 对汉字的编码位置并更改了部分字形；旧数据乱码的最常见原因。',
    ERA_1990 => '仅新增 2 个汉字（U+51DC、U+7199）；无年份的 sjis / euc / jis 即此版本。',
    ERA_2000 => '大幅扩充；在新的第 2 面新增第 3、第 4 水准汉字与符号。',
    ERA_2004 => '新增 10 个汉字并更改 168 个汉字的示例字形（编码与 2000 年版相同，仅字形改变）。',
    OPT_INTRO => '选项作为第 4 个参数传入：{ \'KEY\' => 值, ... }',
    O_INPUT_LAYOUT   => '用 \'S\'（1 字节 SBCS）和 \'D\'（2 字节 DBCS）指定固定记录布局；字母后可跟重复次数。默认：自动。',
    O_OUTPUT_SHIFTING=> '为真时在 DBCS 段前后输出移出/移入码。默认：假。',
    O_SPACE          => 'DBCS/MBCS 空格填充码（二进制字符串）。默认：该编码的空格。',
    O_GETA           => '用于无法映射字符的 DBCS/MBCS 填充（geta）码。',
    O_OVERRIDE_MAPPING=>'逐字符 FROM => TO 覆盖的哈希引用（同时覆盖 SPACE）。',
    O_JIS_SOSI       => '为真：\'jis\' 输入时把 SO(0x0E)/SI(0x0F) 视为切换到 JIS X 0201 片假名（JIS7 习惯）。默认：假；输入为 \'jis\' 时有效。',
    O_JIS_X0212      => '为真：\'jis\' 输出时，将属于 JIS X 0212 但不属于 JIS X 0208 的字符写为 ESC $ ( D。需要 OUTPUT_SHIFTING。默认：假。',
    O_JIS_KANA       => '\'jis\' 输出的片假名形式：\'GR\'(0xA1..0xDF)、\'I\'(ESC ( I，需 OUTPUT_SHIFTING)、\'SO\'(SO/GL/SI)。默认：\'GR\'。',
    O_JIS_DBCS       => '\'jis\' 输出的 DBCS 转义：\'B\'(ESC $ B)、\'@\'(ESC $ @)、\'&@B\'、\'(B\'、\'(@\'。默认：\'B\'；输出为 \'jis\' 时有效。',
    O_JIS_SBCS       => '\'jis\' 输出的 SBCS 转义：\'B\'(ESC ( B ASCII)、\'J\'(ESC ( J 罗马字)、\'H\'(ESC ( H 旧式)。默认：\'B\'；输出为 \'jis\' 时有效。',
    O_JIS2004_PLANE1 => '\'jis2004\' 输出的第 1 面转义：\'Q\'(ESC $ ( Q，:2004)、\'O\'(ESC $ ( O，:2000)。默认：\'Q\'；输出为 \'jis2004\' 时有效。',
    O_ROUND_TRIP     => '为真：可逆转换；无本地编码的字符会分配到用户自定义（外字）区，使「A→B」与「B→A」还原原始数据。往返两个方向都须指定 ROUND_TRIP=>1 且使用相同版本的 Jacode4e。默认：假（无法映射者变为 GETA）。表在首次使用时惰性构建。',
    S1 => 'UTF-8 转主机编码（含移位、空格、geta）',
    S2 => '旧的 1978 年版 Shift_JIS 转 UTF-8（指定年代）',
    S3 => '往返：UTF-8 -> CP00930 -> UTF-8 还原原始数据',
};

$L{'TW'} = {
    TITLE2 => 'Jacode4e 速查表 (TW)',
    TITLE9 => 'Jacode4e 快速參考手冊（繁體中文）',
    H_BASIC=> '基本用法',
    H_ENC  => '編碼名稱一覽',
    H_ERA  => 'JIS 標準各年代差異（適合初學者）',
    H_OPT  => '選項一覽',
    H_SHIFT=> '移位碼速查',
    H_SAMPLE=>'程式範例',
    A_LINE => '要轉換的字串（以參照傳遞，就地覆寫）',
    A_OUT  => '輸出編碼名稱',
    A_IN   => '輸入編碼名稱',
    A_COUNT=> '轉換後的字元數',
    ERA_INTRO => 'sjis / euc / jis 的年代版本（無年份者為 1990 年版）：',
    ERA_P1 => '日文漢字是分階段標準化的。不同版本中相同的位元組可能表示不同的字元，因此請選擇與資料相符的版本。若不確定，請使用無年份的 sjis / euc / jis。',
    ERA_1978 => '最早的漢字標準（第 1 水準與第 2 水準）。',
    ERA_1983 => '交換了 22 對漢字的編碼位置並變更部分字形；舊資料亂碼的最常見原因。',
    ERA_1990 => '僅新增 2 個漢字（U+51DC、U+7199）；無年份的 sjis / euc / jis 即此版本。',
    ERA_2000 => '大幅擴充；在新的第 2 面新增第 3、第 4 水準漢字與符號。',
    ERA_2004 => '新增 10 個漢字並變更 168 個漢字的示例字形（編碼與 2000 年版相同，僅字形改變）。',
    OPT_INTRO => '選項作為第 4 個引數傳入：{ \'KEY\' => 值, ... }',
    O_INPUT_LAYOUT   => '用 \'S\'（1 位元組 SBCS）和 \'D\'（2 位元組 DBCS）指定固定記錄佈局；字母後可加重複次數。預設：自動。',
    O_OUTPUT_SHIFTING=> '為真時在 DBCS 段前後輸出移出/移入碼。預設：假。',
    O_SPACE          => 'DBCS/MBCS 空格填充碼（二進位字串）。預設：該編碼的空格。',
    O_GETA           => '用於無法對應字元的 DBCS/MBCS 填充（geta）碼。',
    O_OVERRIDE_MAPPING=>'逐字元 FROM => TO 覆寫的雜湊參照（同時覆寫 SPACE）。',
    O_JIS_SOSI       => '為真：\'jis\' 輸入時把 SO(0x0E)/SI(0x0F) 視為切換到 JIS X 0201 片假名（JIS7 習慣）。預設：假；輸入為 \'jis\' 時有效。',
    O_JIS_X0212      => '為真：\'jis\' 輸出時，將屬於 JIS X 0212 但不屬於 JIS X 0208 的字元寫為 ESC $ ( D。需要 OUTPUT_SHIFTING。預設：假。',
    O_JIS_KANA       => '\'jis\' 輸出的片假名形式：\'GR\'(0xA1..0xDF)、\'I\'(ESC ( I，需 OUTPUT_SHIFTING)、\'SO\'(SO/GL/SI)。預設：\'GR\'。',
    O_JIS_DBCS       => '\'jis\' 輸出的 DBCS 跳脫：\'B\'(ESC $ B)、\'@\'(ESC $ @)、\'&@B\'、\'(B\'、\'(@\'。預設：\'B\'；輸出為 \'jis\' 時有效。',
    O_JIS_SBCS       => '\'jis\' 輸出的 SBCS 跳脫：\'B\'(ESC ( B ASCII)、\'J\'(ESC ( J 羅馬字)、\'H\'(ESC ( H 舊式)。預設：\'B\'；輸出為 \'jis\' 時有效。',
    O_JIS2004_PLANE1 => '\'jis2004\' 輸出的第 1 面跳脫：\'Q\'(ESC $ ( Q，:2004)、\'O\'(ESC $ ( O，:2000)。預設：\'Q\'；輸出為 \'jis2004\' 時有效。',
    O_ROUND_TRIP     => '為真：可逆轉換；無本地編碼的字元會配置到使用者自訂（外字）區，使「A→B」與「B→A」還原原始資料。往返兩個方向都須指定 ROUND_TRIP=>1 且使用相同版本的 Jacode4e。預設：假（無法對應者變為 GETA）。表在首次使用時延遲建立。',
    S1 => 'UTF-8 轉主機編碼（含移位、空格、geta）',
    S2 => '舊的 1978 年版 Shift_JIS 轉 UTF-8（指定年代）',
    S3 => '往返：UTF-8 -> CP00930 -> UTF-8 還原原始資料',
};

$L{'KO'} = {
    TITLE2 => 'Jacode4e 치트시트 (KO)',
    TITLE9 => 'Jacode4e 빠른 참조 (한국어)',
    H_BASIC=> '기본 사용법',
    H_ENC  => '인코딩 이름 목록',
    H_ERA  => 'JIS 표준 연도별 차이 (초보자용)',
    H_OPT  => '옵션 목록',
    H_SHIFT=> '시프트 코드 참조',
    H_SAMPLE=>'프로그래밍 예제',
    A_LINE => '변환할 문자열 (참조 전달, 제자리 덮어씀)',
    A_OUT  => '출력 인코딩 이름',
    A_IN   => '입력 인코딩 이름',
    A_COUNT=> '변환 후 문자 수',
    ERA_INTRO => 'sjis / euc / jis 의 연도판 (연도 없는 이름은 1990년판):',
    ERA_P1 => '일본어 한자는 단계적으로 표준화되었습니다. 판이 다르면 같은 바이트가 다른 문자를 나타낼 수 있으므로 데이터에 맞는 판을 선택하세요. 모르면 연도 없는 sjis / euc / jis 를 사용하세요.',
    ERA_1978 => '최초의 한자 표준 (제1수준, 제2수준).',
    ERA_1983 => '한자 22쌍의 코드 위치를 교환하고 일부 자형을 변경; 옛 데이터 깨짐의 가장 흔한 원인.',
    ERA_1990 => '한자 2자만 추가 (U+51DC, U+7199); 연도 없는 sjis / euc / jis 가 이 판.',
    ERA_2000 => '대폭 확장; 새로운 면 2 에 제3수준·제4수준 한자와 기호 추가.',
    ERA_2004 => '한자 10자 추가, 168자의 예시 자형 변경 (코드는 2000년판과 동일, 자형만 변경).',
    OPT_INTRO => '옵션은 네 번째 인수로 전달합니다: { \'KEY\' => 값, ... }',
    O_INPUT_LAYOUT   => '\'S\'(1바이트 SBCS)와 \'D\'(2바이트 DBCS)로 고정 레코드 레이아웃 지정; 글자 뒤에 반복 횟수를 붙일 수 있음. 기본값: 자동.',
    O_OUTPUT_SHIFTING=> '참이면 DBCS 구간 앞뒤에 시프트아웃/시프트인 코드를 출력. 기본값: 거짓.',
    O_SPACE          => 'DBCS/MBCS 공백 채움 코드 (바이너리 문자열). 기본값: 해당 인코딩의 공백.',
    O_GETA           => '매핑할 수 없는 문자에 쓰는 DBCS/MBCS 게타 코드.',
    O_OVERRIDE_MAPPING=>'문자별 FROM => TO 재정의 해시 참조 (SPACE 도 재정의함).',
    O_JIS_SOSI       => '참: \'jis\' 입력에서 SO(0x0E)/SI(0x0F) 를 JIS X 0201 가타카나 전환으로 취급 (JIS7 관습). 기본값: 거짓; 입력이 \'jis\' 일 때 유효.',
    O_JIS_X0212      => '참: \'jis\' 출력에서 JIS X 0208 에 없고 JIS X 0212 에 있는 문자를 ESC $ ( D 로 출력. OUTPUT_SHIFTING 필요. 기본값: 거짓.',
    O_JIS_KANA       => '\'jis\' 출력의 가타카나 방식: \'GR\'(0xA1..0xDF), \'I\'(ESC ( I, OUTPUT_SHIFTING 필요), \'SO\'(SO/GL/SI). 기본값: \'GR\'.',
    O_JIS_DBCS       => '\'jis\' 출력의 DBCS 이스케이프: \'B\'(ESC $ B), \'@\'(ESC $ @), \'&@B\', \'(B\', \'(@\'. 기본값: \'B\'; 출력이 \'jis\' 일 때 유효.',
    O_JIS_SBCS       => '\'jis\' 출력의 SBCS 이스케이프: \'B\'(ESC ( B ASCII), \'J\'(ESC ( J 로마자), \'H\'(ESC ( H 구식). 기본값: \'B\'; 출력이 \'jis\' 일 때 유효.',
    O_JIS2004_PLANE1 => '\'jis2004\' 출력의 면1 이스케이프: \'Q\'(ESC $ ( Q, :2004), \'O\'(ESC $ ( O, :2000). 기본값: \'Q\'; 출력이 \'jis2004\' 일 때 유효.',
    O_ROUND_TRIP     => '참: 가역 변환; 고유 코드가 없는 문자를 사용자 정의(외자) 영역에 배정하여 "A→B" 와 "B→A" 로 원본을 복원. 양방향 모두 ROUND_TRIP=>1 과 동일한 Jacode4e 버전이 필요. 기본값: 거짓(매핑 불가 시 GETA). 표는 첫 사용 시 지연 생성됨.',
    S1 => 'UTF-8 에서 메인프레임 인코딩으로 (시프트·공백·게타 포함)',
    S2 => '옛 1978년판 Shift_JIS 에서 UTF-8 로 (연도 지정)',
    S3 => '왕복: UTF-8 -> CP00930 -> UTF-8 로 원본 복원',
};

$L{'FR'} = {
    TITLE2 => 'Aide-memoire Jacode4e (FR)',
    TITLE9 => 'Aide-memoire Jacode4e (Francais)',
    H_BASIC=> 'UTILISATION DE BASE',
    H_ENC  => 'NOMS D\'ENCODAGE',
    H_ERA  => 'DIFFERENCES DES EDITIONS JIS PAR ANNEE (pour debutants)',
    H_OPT  => 'OPTIONS',
    H_SHIFT=> 'CODES DE DECALAGE',
    H_SAMPLE=>'EXEMPLES',
    A_LINE => 'chaine a convertir (passee par reference, ecrasee sur place)',
    A_OUT  => 'nom de l\'encodage de sortie',
    A_IN   => 'nom de l\'encodage d\'entree',
    A_COUNT=> 'nombre de caracteres apres conversion',
    ERA_INTRO => 'Editions annuelles de sjis / euc / jis (le nom sans annee est l\'edition 1990) :',
    ERA_P1 => 'Les kanji japonais ont ete normalises par etapes. Les memes octets peuvent designer un caractere different selon l\'edition ; choisissez donc l\'edition correspondant a vos donnees. En cas de doute, utilisez sjis / euc / jis sans annee.',
    ERA_1978 => 'la premiere norme de kanji (niveaux 1 et 2).',
    ERA_1983 => 'a echange le code de 22 paires de kanji et modifie certaines formes ; cause la plus frequente d\'anciennes donnees corrompues.',
    ERA_1990 => 'a ajoute seulement 2 kanji (U+51DC, U+7199) ; sjis / euc / jis sans annee designent cette edition.',
    ERA_2000 => 'grande extension ; ajout des kanji de niveaux 3 et 4 et de symboles sur un nouveau plan 2.',
    ERA_2004 => 'a ajoute 10 kanji et modifie la forme de reference de 168 kanji (meme code qu\'en 2000, nouvelles formes).',
    OPT_INTRO => 'Passez les options en 4e argument : { \'KEY\' => valeur, ... }',
    O_INPUT_LAYOUT   => 'Disposition fixe des enregistrements par \'S\' (SBCS 1 octet) et \'D\' (DBCS 2 octets) ; une lettre peut etre suivie d\'un nombre de repetitions. Defaut : auto.',
    O_OUTPUT_SHIFTING=> 'Vrai : emet les codes shift-out/shift-in autour des sequences DBCS. Defaut : faux.',
    O_SPACE          => 'Code d\'espace de remplissage DBCS/MBCS (chaine binaire). Defaut : l\'espace de l\'encodage.',
    O_GETA           => 'Code geta DBCS/MBCS pour les caracteres non convertibles.',
    O_OVERRIDE_MAPPING=>'Reference de hachage de remplacements FROM => TO par caractere (remplace aussi SPACE).',
    O_JIS_SOSI       => 'Vrai : en entree \'jis\', SO (0x0E)/SI (0x0F) commutent vers le katakana JIS X 0201 (habitude JIS7). Defaut : faux ; entree \'jis\'.',
    O_JIS_X0212      => 'Vrai : en sortie \'jis\', un caractere present dans JIS X 0212 mais absent de JIS X 0208 est ecrit ESC $ ( D. Requiert OUTPUT_SHIFTING. Defaut : faux.',
    O_JIS_KANA       => 'Style katakana en sortie \'jis\' : \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, requiert OUTPUT_SHIFTING), \'SO\' (SO/GL/SI). Defaut : \'GR\'.',
    O_JIS_DBCS       => 'Echappement DBCS en sortie \'jis\' : \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Defaut : \'B\' ; sortie \'jis\'.',
    O_JIS_SBCS       => 'Echappement SBCS en sortie \'jis\' : \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H ancien). Defaut : \'B\' ; sortie \'jis\'.',
    O_JIS2004_PLANE1 => 'Echappement du plan 1 en sortie \'jis2004\' : \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Defaut : \'Q\' ; sortie \'jis2004\'.',
    O_ROUND_TRIP     => 'Vrai : conversion reversible ; un caractere sans code natif est place dans la zone definie par l\'utilisateur (GAIJI) afin que "A vers B" et "B vers A" restaurent l\'original. Les deux sens exigent ROUND_TRIP=>1 et la MEME version de Jacode4e. Defaut : faux (non convertible devient GETA). Table construite paresseusement au premier appel.',
    S1 => 'UTF-8 vers un encodage mainframe (avec decalage, espace, geta)',
    S2 => 'ancien Shift_JIS 1978 vers UTF-8 (selon l\'annee)',
    S3 => 'aller-retour : UTF-8 -> CP00930 -> UTF-8 restaure l\'original',
};

$L{'VI'} = {
    TITLE2 => 'To ghi nho Jacode4e (VI)',
    TITLE9 => 'Tai lieu tham khao nhanh Jacode4e (Tieng Viet)',
    H_BASIC=> 'SU DUNG CO BAN',
    H_ENC  => 'DANH SACH TEN MA HOA',
    H_ERA  => 'KHAC BIET CAC PHIEN BAN JIS THEO NAM (cho nguoi moi)',
    H_OPT  => 'TUY CHON',
    H_SHIFT=> 'BANG MA SHIFT',
    H_SAMPLE=>'VI DU LAP TRINH',
    A_LINE => 'chuoi can chuyen doi (truyen bang tham chieu, ghi de tai cho)',
    A_OUT  => 'ten ma hoa dau ra',
    A_IN   => 'ten ma hoa dau vao',
    A_COUNT=> 'so ky tu sau khi chuyen doi',
    ERA_INTRO => 'Cac phien ban theo nam cua sjis / euc / jis (ten khong co nam la ban 1990):',
    ERA_P1 => 'Kanji Nhat duoc chuan hoa theo tung giai doan. Cung mot chuoi byte co the la ky tu khac nhau giua cac phien ban, vi vay hay chon phien ban khop voi du lieu cua ban. Neu khong ro, hay dung sjis / euc / jis khong co nam.',
    ERA_1978 => 'chuan kanji dau tien (cap 1 va cap 2).',
    ERA_1983 => 'hoan doi ma cua 22 cap kanji va thay doi mot so hinh chu; nguyen nhan pho bien nhat gay loi du lieu cu.',
    ERA_1990 => 'chi them 2 kanji (U+51DC, U+7199); sjis / euc / jis khong co nam la ban nay.',
    ERA_2000 => 'mo rong lon; them kanji cap 3 va cap 4 cung ky hieu tren mat phang 2 moi.',
    ERA_2004 => 'them 10 kanji va thay doi hinh mau cua 168 kanji (cung ma voi ban 2000, chi doi hinh chu).',
    OPT_INTRO => 'Truyen tuy chon lam doi so thu 4: { \'KEY\' => gia_tri, ... }',
    O_INPUT_LAYOUT   => 'Bo cuc ban ghi co dinh bang \'S\' (SBCS 1 byte) va \'D\' (DBCS 2 byte); moi chu co the theo sau boi so lan lap. Mac dinh: tu dong.',
    O_OUTPUT_SHIFTING=> 'Dung: phat ma shift-out/shift-in quanh cac doan DBCS. Mac dinh: sai.',
    O_SPACE          => 'Ma khoang trang DBCS/MBCS (chuoi nhi phan). Mac dinh: khoang trang cua ma hoa.',
    O_GETA           => 'Ma geta DBCS/MBCS cho ky tu khong the anh xa.',
    O_OVERRIDE_MAPPING=>'Tham chieu bam ghi de FROM => TO theo tung ky tu (cung ghi de SPACE).',
    O_JIS_SOSI       => 'Dung: voi dau vao \'jis\', SO (0x0E)/SI (0x0F) chuyen sang katakana JIS X 0201 (thoi quen JIS7). Mac dinh: sai; dau vao la \'jis\'.',
    O_JIS_X0212      => 'Dung: voi dau ra \'jis\', ky tu co trong JIS X 0212 nhung khong co trong JIS X 0208 duoc viet ESC $ ( D. Can OUTPUT_SHIFTING. Mac dinh: sai.',
    O_JIS_KANA       => 'Kieu katakana o dau ra \'jis\': \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, can OUTPUT_SHIFTING), \'SO\' (SO/GL/SI). Mac dinh: \'GR\'.',
    O_JIS_DBCS       => 'Escape DBCS o dau ra \'jis\': \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Mac dinh: \'B\'; dau ra la \'jis\'.',
    O_JIS_SBCS       => 'Escape SBCS o dau ra \'jis\': \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H cu). Mac dinh: \'B\'; dau ra la \'jis\'.',
    O_JIS2004_PLANE1 => 'Escape mat phang 1 o dau ra \'jis2004\': \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Mac dinh: \'Q\'; dau ra la \'jis2004\'.',
    O_ROUND_TRIP     => 'Dung: chuyen doi thuan nghich; ky tu khong co ma goc duoc dat vao vung nguoi dung tu dinh nghia (GAIJI) de "A sang B" va "B sang A" khoi phuc du lieu goc. Ca hai chieu can ROUND_TRIP=>1 va CUNG mot phien ban Jacode4e. Mac dinh: sai (khong anh xa duoc thanh GETA). Bang duoc dung lazy o lan goi dau tien.',
    S1 => 'UTF-8 sang ma hoa mainframe (co shift, khoang trang, geta)',
    S2 => 'Shift_JIS 1978 cu sang UTF-8 (theo nam)',
    S3 => 'khu hoi: UTF-8 -> CP00930 -> UTF-8 khoi phuc du lieu goc',
};

$L{'ID'} = {
    TITLE2 => 'Lembar Contekan Jacode4e (ID)',
    TITLE9 => 'Referensi Cepat Jacode4e (Bahasa Indonesia)',
    H_BASIC=> 'PENGGUNAAN DASAR',
    H_ENC  => 'DAFTAR NAMA PENGKODEAN',
    H_ERA  => 'PERBEDAAN EDISI JIS MENURUT TAHUN (untuk pemula)',
    H_OPT  => 'PILIHAN',
    H_SHIFT=> 'REFERENSI KODE SHIFT',
    H_SAMPLE=>'CONTOH PROGRAM',
    A_LINE => 'string yang akan dikonversi (dilewatkan lewat referensi, ditimpa di tempat)',
    A_OUT  => 'nama pengkodean keluaran',
    A_IN   => 'nama pengkodean masukan',
    A_COUNT=> 'jumlah karakter setelah konversi',
    ERA_INTRO => 'Edisi tahun dari sjis / euc / jis (nama tanpa tahun adalah edisi 1990):',
    ERA_P1 => 'Kanji Jepang dibakukan secara bertahap. Byte yang sama bisa berarti karakter berbeda antaredisi, jadi pilih edisi yang cocok dengan data Anda. Jika tidak tahu, gunakan sjis / euc / jis tanpa tahun.',
    ERA_1978 => 'standar kanji pertama (Tingkat 1 dan Tingkat 2).',
    ERA_1983 => 'menukar kode 22 pasang kanji dan mengubah beberapa bentuk cetak; penyebab paling umum data lama menjadi rusak.',
    ERA_1990 => 'hanya menambah 2 kanji (U+51DC, U+7199); sjis / euc / jis tanpa tahun berarti edisi ini.',
    ERA_2000 => 'perluasan besar; menambah kanji Tingkat 3 dan 4 serta simbol pada bidang 2 baru.',
    ERA_2004 => 'menambah 10 kanji dan mengubah bentuk contoh 168 kanji (kode sama dengan 2000, bentuk baru).',
    OPT_INTRO => 'Berikan pilihan sebagai argumen ke-4: { \'KEY\' => nilai, ... }',
    O_INPUT_LAYOUT   => 'Tata letak rekaman tetap dengan \'S\' (SBCS 1 byte) dan \'D\' (DBCS 2 byte); setiap huruf boleh diikuti jumlah pengulangan. Default: otomatis.',
    O_OUTPUT_SHIFTING=> 'Benar: memancarkan kode shift-out/shift-in di sekitar rentetan DBCS. Default: salah.',
    O_SPACE          => 'Kode isian spasi DBCS/MBCS (string biner). Default: spasi pengkodean itu.',
    O_GETA           => 'Kode geta DBCS/MBCS untuk karakter yang tidak dapat dipetakan.',
    O_OVERRIDE_MAPPING=>'Referensi hash penggantian FROM => TO per karakter (juga menggantikan SPACE).',
    O_JIS_SOSI       => 'Benar: pada masukan \'jis\', SO (0x0E)/SI (0x0F) beralih ke Katakana JIS X 0201 (kebiasaan JIS7). Default: salah; masukan \'jis\'.',
    O_JIS_X0212      => 'Benar: pada keluaran \'jis\', karakter yang ada di JIS X 0212 tetapi tidak di JIS X 0208 ditulis ESC $ ( D. Perlu OUTPUT_SHIFTING. Default: salah.',
    O_JIS_KANA       => 'Gaya Katakana pada keluaran \'jis\': \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, perlu OUTPUT_SHIFTING), \'SO\' (SO/GL/SI). Default: \'GR\'.',
    O_JIS_DBCS       => 'Escape DBCS pada keluaran \'jis\': \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Default: \'B\'; keluaran \'jis\'.',
    O_JIS_SBCS       => 'Escape SBCS pada keluaran \'jis\': \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H lama). Default: \'B\'; keluaran \'jis\'.',
    O_JIS2004_PLANE1 => 'Escape bidang 1 pada keluaran \'jis2004\': \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Default: \'Q\'; keluaran \'jis2004\'.',
    O_ROUND_TRIP     => 'Benar: konversi bolak-balik (reversibel); karakter tanpa kode asli ditempatkan di area buatan pengguna (GAIJI) sehingga "A ke B" dan "B ke A" memulihkan aslinya. Kedua arah perlu ROUND_TRIP=>1 dan versi Jacode4e yang SAMA. Default: salah (tak terpetakan menjadi GETA). Tabel dibangun secara lazy saat pertama dipakai.',
    S1 => 'UTF-8 ke pengkodean mainframe (dengan shift, spasi, geta)',
    S2 => 'Shift_JIS 1978 lama ke UTF-8 (sadar tahun)',
    S3 => 'bolak-balik: UTF-8 -> CP00930 -> UTF-8 memulihkan aslinya',
};

$L{'TR'} = {
    TITLE2 => 'Jacode4e Hizli Basvuru Kilavuzu (TR)',
    TITLE9 => 'Jacode4e Hizli Basvuru Kilavuzu (Turkce)',
    H_BASIC=> 'TEMEL KULLANIM',
    H_ENC  => 'KODLAMA ADLARI LISTESI',
    H_ERA  => 'YILA GORE JIS SURUM FARKLARI (yeni baslayanlar icin)',
    H_OPT  => 'SECENEKLER',
    H_SHIFT=> 'SHIFT KODU REFERANSI',
    H_SAMPLE=>'PROGRAMLAMA ORNEKLERI',
    A_LINE => 'donusturulecek dize (referansla gecirilir, yerinde uzerine yazilir)',
    A_OUT  => 'cikis kodlama adi',
    A_IN   => 'giris kodlama adi',
    A_COUNT=> 'donusumden sonraki karakter sayisi',
    ERA_INTRO => 'sjis / euc / jis yil surumleri (yilsiz ad 1990 surumudur):',
    ERA_P1 => 'Japon kanjileri asamali olarak standartlastirildi. Ayni baytlar surumden surume farkli karakter anlamina gelebilir, bu yuzden verinize uyan surumu secin. Bilmiyorsaniz yilsiz sjis / euc / jis kullanin.',
    ERA_1978 => 'ilk kanji standardi (Seviye 1 ve Seviye 2).',
    ERA_1983 => '22 kanji ciftinin kodunu degistirdi ve bazi bicimleri degistirdi; eski verilerin bozulmasinin en yaygin nedeni.',
    ERA_1990 => 'yalnizca 2 kanji ekledi (U+51DC, U+7199); yilsiz sjis / euc / jis bu surumu belirtir.',
    ERA_2000 => 'buyuk genisleme; yeni bir duzlem 2 uzerine Seviye 3 ve 4 kanji ve sembol ekledi.',
    ERA_2004 => '10 kanji ekledi ve 168 kanjinin ornek bicimini degistirdi (kod 2000 ile ayni, yeni bicimler).',
    OPT_INTRO => 'Secenekleri 4. arguman olarak verin: { \'KEY\' => deger, ... }',
    O_INPUT_LAYOUT   => '\'S\' (1 baytlik SBCS) ve \'D\' (2 baytlik DBCS) ile sabit kayit duzeni; her harfi bir tekrar sayisi izleyebilir. Varsayilan: otomatik.',
    O_OUTPUT_SHIFTING=> 'Dogru: DBCS dizileri cevresinde shift-out/shift-in kodlari uretir. Varsayilan: yanlis.',
    O_SPACE          => 'DBCS/MBCS bosluk dolgu kodu (ikili dize). Varsayilan: kodlamanin boslugu.',
    O_GETA           => 'Eslenemeyen karakterler icin DBCS/MBCS geta kodu.',
    O_OVERRIDE_MAPPING=>'Karakter basina FROM => TO gecersiz kilma hash referansi (SPACE\'i de gecersiz kilar).',
    O_JIS_SOSI       => 'Dogru: \'jis\' girisinde SO (0x0E)/SI (0x0F) JIS X 0201 Katakana\'ya gecis yapar (JIS7 aliskanligi). Varsayilan: yanlis; giris \'jis\'.',
    O_JIS_X0212      => 'Dogru: \'jis\' cikisinda, JIS X 0212\'de olup JIS X 0208\'de olmayan karakter ESC $ ( D olarak yazilir. OUTPUT_SHIFTING gerekir. Varsayilan: yanlis.',
    O_JIS_KANA       => '\'jis\' cikisinda Katakana bicimi: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING gerekir), \'SO\' (SO/GL/SI). Varsayilan: \'GR\'.',
    O_JIS_DBCS       => '\'jis\' cikisinda DBCS kacisi: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Varsayilan: \'B\'; cikis \'jis\'.',
    O_JIS_SBCS       => '\'jis\' cikisinda SBCS kacisi: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H eski). Varsayilan: \'B\'; cikis \'jis\'.',
    O_JIS2004_PLANE1 => '\'jis2004\' cikisinda duzlem 1 kacisi: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Varsayilan: \'Q\'; cikis \'jis2004\'.',
    O_ROUND_TRIP     => 'Dogru: tersinir donusum; yerel kodu olmayan karakter kullanici tanimli (GAIJI) alana yerlestirilir, boylece "A dan B ye" ve "B den A ya" orijinali geri getirir. Her iki yon de ROUND_TRIP=>1 ve AYNI Jacode4e surumunu gerektirir. Varsayilan: yanlis (eslenemeyen GETA olur). Tablo ilk kullanimda tembel olusturulur.',
    S1 => 'UTF-8 ten anabilgisayar kodlamasina (shift, bosluk, geta ile)',
    S2 => 'eski 1978 Shift_JIS ten UTF-8 e (yila duyarli)',
    S3 => 'gidis-donus: UTF-8 -> CP00930 -> UTF-8 orijinali geri getirir',
};

$L{'BM'} = {
    TITLE2 => 'Helaian Panduan Jacode4e (BM)',
    TITLE9 => 'Rujukan Pantas Jacode4e (Bahasa Melayu)',
    H_BASIC=> 'PENGGUNAAN ASAS',
    H_ENC  => 'NAMA PENGEKODAN',
    H_ERA  => 'PERBEZAAN EDISI JIS MENGIKUT TAHUN (untuk pemula)',
    H_OPT  => 'PILIHAN',
    H_SHIFT=> 'RUJUKAN KOD SHIFT',
    H_SAMPLE=>'CONTOH PENGATURCARAAN',
    A_LINE => 'rentetan untuk ditukar (dihantar melalui rujukan, ditimpa di tempat)',
    A_OUT  => 'nama pengekodan keluaran',
    A_IN   => 'nama pengekodan masukan',
    A_COUNT=> 'bilangan aksara selepas penukaran',
    ERA_INTRO => 'Edisi tahun sjis / euc / jis (nama tanpa tahun ialah edisi 1990):',
    ERA_P1 => 'Kanji Jepun dipiawaikan secara berperingkat. Bait yang sama boleh bermaksud aksara berbeza antara edisi, jadi pilih edisi yang sepadan dengan data anda. Jika tidak pasti, gunakan sjis / euc / jis tanpa tahun.',
    ERA_1978 => 'piawai kanji pertama (Tahap 1 dan Tahap 2).',
    ERA_1983 => 'menukar kod 22 pasang kanji dan mengubah beberapa bentuk cetakan; punca paling lazim data lama rosak.',
    ERA_1990 => 'menambah hanya 2 kanji (U+51DC, U+7199); sjis / euc / jis tanpa tahun bermaksud edisi ini.',
    ERA_2000 => 'perluasan besar; menambah kanji Tahap 3 dan 4 serta simbol pada satah 2 baharu.',
    ERA_2004 => 'menambah 10 kanji dan mengubah bentuk contoh 168 kanji (kod sama dengan 2000, bentuk baharu).',
    OPT_INTRO => 'Hantar pilihan sebagai hujah ke-4: { \'KEY\' => nilai, ... }',
    O_INPUT_LAYOUT   => 'Susun atur rekod tetap dengan \'S\' (SBCS 1 bait) dan \'D\' (DBCS 2 bait); setiap huruf boleh diikuti bilangan ulangan. Lalai: automatik.',
    O_OUTPUT_SHIFTING=> 'Benar: memancarkan kod shift-out/shift-in di sekeliling jujukan DBCS. Lalai: palsu.',
    O_SPACE          => 'Kod isian ruang DBCS/MBCS (rentetan binari). Lalai: ruang pengekodan itu.',
    O_GETA           => 'Kod geta DBCS/MBCS untuk aksara yang tidak dapat dipetakan.',
    O_OVERRIDE_MAPPING=>'Rujukan cincang gantian FROM => TO setiap aksara (turut menggantikan SPACE).',
    O_JIS_SOSI       => 'Benar: pada masukan \'jis\', SO (0x0E)/SI (0x0F) beralih ke Katakana JIS X 0201 (tabiat JIS7). Lalai: palsu; masukan \'jis\'.',
    O_JIS_X0212      => 'Benar: pada keluaran \'jis\', aksara yang ada dalam JIS X 0212 tetapi tiada dalam JIS X 0208 ditulis ESC $ ( D. Perlu OUTPUT_SHIFTING. Lalai: palsu.',
    O_JIS_KANA       => 'Gaya Katakana pada keluaran \'jis\': \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, perlu OUTPUT_SHIFTING), \'SO\' (SO/GL/SI). Lalai: \'GR\'.',
    O_JIS_DBCS       => 'Escape DBCS pada keluaran \'jis\': \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Lalai: \'B\'; keluaran \'jis\'.',
    O_JIS_SBCS       => 'Escape SBCS pada keluaran \'jis\': \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H lama). Lalai: \'B\'; keluaran \'jis\'.',
    O_JIS2004_PLANE1 => 'Escape satah 1 pada keluaran \'jis2004\': \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Lalai: \'Q\'; keluaran \'jis2004\'.',
    O_ROUND_TRIP     => 'Benar: penukaran boleh balik; aksara tanpa kod asli diletakkan di kawasan takrif pengguna (GAIJI) supaya "A ke B" dan "B ke A" memulihkan asalnya. Kedua-dua arah perlu ROUND_TRIP=>1 dan versi Jacode4e yang SAMA. Lalai: palsu (tak terpeta menjadi GETA). Jadual dibina secara lazy pada penggunaan pertama.',
    S1 => 'UTF-8 ke pengekodan mainframe (dengan shift, ruang, geta)',
    S2 => 'Shift_JIS 1978 lama ke UTF-8 (mengikut tahun)',
    S3 => 'ulang-alik: UTF-8 -> CP00930 -> UTF-8 memulihkan asalnya',
};

$L{'UZ'} = {
    TITLE2 => 'Jacode4e Tezkor Qo\'llanma (UZ)',
    TITLE9 => 'Jacode4e Tezkor Ma\'lumotnoma (O\'zbekcha)',
    H_BASIC=> 'ASOSIY FOYDALANISH',
    H_ENC  => 'KODLASH NOMLARI RO\'YXATI',
    H_ERA  => 'JIS NASHRLARINING YILLAR BO\'YICHA FARQLARI (yangi boshlovchilar uchun)',
    H_OPT  => 'VARIANTLAR',
    H_SHIFT=> 'SHIFT KODLARI MA\'LUMOTNOMASI',
    H_SAMPLE=>'DASTURLASH NAMUNALARI',
    A_LINE => 'o\'giriladigan satr (havola orqali uzatiladi, joyida qayta yoziladi)',
    A_OUT  => 'chiqish kodlash nomi',
    A_IN   => 'kirish kodlash nomi',
    A_COUNT=> 'o\'girishdan keyingi belgilar soni',
    ERA_INTRO => 'sjis / euc / jis yil nashrlari (yilsiz nom 1990 nashridir):',
    ERA_P1 => 'Yapon kanjilari bosqichma-bosqich standartlashtirilgan. Bir xil baytlar nashrga qarab boshqa belgini anglatishi mumkin, shuning uchun ma\'lumotingizga mos nashrni tanlang. Bilmasangiz, yilsiz sjis / euc / jis dan foydalaning.',
    ERA_1978 => 'birinchi kanji standarti (1- va 2-daraja).',
    ERA_1983 => '22 juft kanjining kodini almashtirgan va ba\'zi shakllarni o\'zgartirgan; eski ma\'lumot buzilishining eng keng tarqalgan sababi.',
    ERA_1990 => 'faqat 2 ta kanji qo\'shgan (U+51DC, U+7199); yilsiz sjis / euc / jis shu nashrni bildiradi.',
    ERA_2000 => 'katta kengaytma; yangi 2-tekislikka 3- va 4-daraja kanji va belgilar qo\'shgan.',
    ERA_2004 => '10 ta kanji qo\'shgan va 168 ta kanjining namunaviy shaklini o\'zgartirgan (kod 2000 bilan bir xil, yangi shakllar).',
    OPT_INTRO => 'Variantlarni 4-argument sifatida bering: { \'KEY\' => qiymat, ... }',
    O_INPUT_LAYOUT   => '\'S\' (1 baytli SBCS) va \'D\' (2 baytli DBCS) bilan qat\'iy yozuv tartibi; har harfdan keyin takror soni kelishi mumkin. Standart: avtomatik.',
    O_OUTPUT_SHIFTING=> 'Rost: DBCS ketma-ketliklari atrofida shift-out/shift-in kodlarini chiqaradi. Standart: yolg\'on.',
    O_SPACE          => 'DBCS/MBCS bo\'sh joy to\'ldirish kodi (ikkilik satr). Standart: shu kodlashning bo\'sh joyi.',
    O_GETA           => 'Moslashtirib bo\'lmaydigan belgilar uchun DBCS/MBCS geta kodi.',
    O_OVERRIDE_MAPPING=>'Har belgi uchun FROM => TO almashtirish hash havolasi (SPACE ni ham almashtiradi).',
    O_JIS_SOSI       => 'Rost: \'jis\' kirishida SO (0x0E)/SI (0x0F) JIS X 0201 Katakana ga o\'tadi (JIS7 odati). Standart: yolg\'on; kirish \'jis\'.',
    O_JIS_X0212      => 'Rost: \'jis\' chiqishida JIS X 0212 da bor, JIS X 0208 da yo\'q belgi ESC $ ( D bilan yoziladi. OUTPUT_SHIFTING kerak. Standart: yolg\'on.',
    O_JIS_KANA       => '\'jis\' chiqishida Katakana uslubi: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING kerak), \'SO\' (SO/GL/SI). Standart: \'GR\'.',
    O_JIS_DBCS       => '\'jis\' chiqishida DBCS escape: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Standart: \'B\'; chiqish \'jis\'.',
    O_JIS_SBCS       => '\'jis\' chiqishida SBCS escape: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H eski). Standart: \'B\'; chiqish \'jis\'.',
    O_JIS2004_PLANE1 => '\'jis2004\' chiqishida 1-tekislik escape: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Standart: \'Q\'; chiqish \'jis2004\'.',
    O_ROUND_TRIP     => 'Rost: teskari o\'girish; o\'z kodiga ega bo\'lmagan belgi foydalanuvchi belgilagan (GAIJI) sohaga joylashtiriladi, shunda "A dan B ga" va "B dan A ga" aslini tiklaydi. Ikkala yo\'nalish ham ROUND_TRIP=>1 va BIR XIL Jacode4e versiyasini talab qiladi. Standart: yolg\'on (moslanmagan GETA bo\'ladi). Jadval birinchi ishlatishda lazy quriladi.',
    S1 => 'UTF-8 dan asosiy kompyuter kodlashiga (shift, bo\'sh joy, geta bilan)',
    S2 => 'eski 1978 Shift_JIS dan UTF-8 ga (yilni hisobga olib)',
    S3 => 'borib-kelish: UTF-8 -> CP00930 -> UTF-8 aslini tiklaydi',
};

$L{'TL'} = {
    TITLE2 => 'Cheat Sheet ng Jacode4e (TL)',
    TITLE9 => 'Mabilis na Sanggunian ng Jacode4e (Filipino/Tagalog)',
    H_BASIC=> 'PANGUNAHING PAGGAMIT',
    H_ENC  => 'LISTAHAN NG MGA PANGALAN NG ENCODING',
    H_ERA  => 'PAGKAKAIBA NG MGA EDISYON NG JIS AYON SA TAON (para sa baguhan)',
    H_OPT  => 'MGA OPSYON',
    H_SHIFT=> 'SANGGUNIAN NG SHIFT CODE',
    H_SAMPLE=>'MGA HALIMBAWANG PROGRAMA',
    A_LINE => 'string na iko-convert (ipinapasa sa pamamagitan ng reference, ino-overwrite sa lugar)',
    A_OUT  => 'pangalan ng output encoding',
    A_IN   => 'pangalan ng input encoding',
    A_COUNT=> 'bilang ng karakter pagkatapos ng conversion',
    ERA_INTRO => 'Mga edisyon ayon sa taon ng sjis / euc / jis (ang walang taon ay edisyong 1990):',
    ERA_P1 => 'Ang mga kanji ng Hapon ay isinapamantayan nang paunti-unti. Ang parehong mga byte ay maaaring ibang karakter sa iba\'t ibang edisyon, kaya piliin ang edisyong tugma sa iyong data. Kung hindi alam, gamitin ang sjis / euc / jis na walang taon.',
    ERA_1978 => 'ang unang pamantayan ng kanji (Antas 1 at Antas 2).',
    ERA_1983 => 'ipinagpalit ang code ng 22 pares ng kanji at binago ang ilang hugis; pinakakaraniwang sanhi ng sirang lumang datos.',
    ERA_1990 => 'nagdagdag lang ng 2 kanji (U+51DC, U+7199); ang sjis / euc / jis na walang taon ay ang edisyong ito.',
    ERA_2000 => 'malaking pagpapalawak; nagdagdag ng Antas 3 at 4 na kanji at simbolo sa bagong plane 2.',
    ERA_2004 => 'nagdagdag ng 10 kanji at binago ang halimbawang hugis ng 168 kanji (parehong code sa 2000, bagong hugis).',
    OPT_INTRO => 'Ipasa ang mga opsyon bilang ika-4 na argumento: { \'KEY\' => halaga, ... }',
    O_INPUT_LAYOUT   => 'Nakapirming record layout sa \'S\' (1-byte SBCS) at \'D\' (2-byte DBCS); ang bawat titik ay maaaring sundan ng bilang ng ulit. Default: awtomatiko.',
    O_OUTPUT_SHIFTING=> 'True: naglalabas ng shift-out/shift-in code sa paligid ng mga DBCS na bahagi. Default: false.',
    O_SPACE          => 'DBCS/MBCS space fill code (binary string). Default: ang space ng encoding.',
    O_GETA           => 'DBCS/MBCS geta code para sa mga karakter na hindi ma-map.',
    O_OVERRIDE_MAPPING=>'Hashref ng per-character na FROM => TO override (ino-override din ang SPACE).',
    O_JIS_SOSI       => 'True: sa input na \'jis\', ang SO (0x0E)/SI (0x0F) ay lumilipat sa JIS X 0201 Katakana (ugali ng JIS7). Default: false; input na \'jis\'.',
    O_JIS_X0212      => 'True: sa output na \'jis\', ang karakter na nasa JIS X 0212 ngunit wala sa JIS X 0208 ay isinusulat bilang ESC $ ( D. Kailangan ng OUTPUT_SHIFTING. Default: false.',
    O_JIS_KANA       => 'Estilo ng Katakana sa output na \'jis\': \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, kailangan ng OUTPUT_SHIFTING), \'SO\' (SO/GL/SI). Default: \'GR\'.',
    O_JIS_DBCS       => 'DBCS escape sa output na \'jis\': \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Default: \'B\'; output na \'jis\'.',
    O_JIS_SBCS       => 'SBCS escape sa output na \'jis\': \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H luma). Default: \'B\'; output na \'jis\'.',
    O_JIS2004_PLANE1 => 'Plane-1 escape sa output na \'jis2004\': \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Default: \'Q\'; output na \'jis2004\'.',
    O_ROUND_TRIP     => 'True: nababaligtad na conversion; ang karakter na walang katutubong code ay inilalagay sa user-defined (GAIJI) na lugar upang ang "A to B" at "B to A" ay maibalik ang orihinal. Kailangan ng magkabilang direksyon ang ROUND_TRIP=>1 at ang PAREHONG bersyon ng Jacode4e. Default: false (nagiging GETA ang hindi ma-map). Ginagawa ang table nang lazy sa unang paggamit.',
    S1 => 'UTF-8 patungong mainframe encoding (may shift, space, geta)',
    S2 => 'lumang 1978 Shift_JIS patungong UTF-8 (batay sa taon)',
    S3 => 'round-trip: UTF-8 -> CP00930 -> UTF-8 ibinabalik ang orihinal',
};

$L{'HI'} = {
    TITLE2 => 'Jacode4e त्वरित संदर्भ पत्र (HI)',
    TITLE9 => 'Jacode4e त्वरित संदर्भ (हिन्दी)',
    H_BASIC=> 'मूल उपयोग',
    H_ENC  => 'एन्कोडिंग नामों की सूची',
    H_ERA  => 'वर्ष के अनुसार JIS संस्करणों के अंतर (शुरुआती लोगों के लिए)',
    H_OPT  => 'विकल्प',
    H_SHIFT=> 'शिफ्ट कोड संदर्भ',
    H_SAMPLE=>'प्रोग्रामिंग उदाहरण',
    A_LINE => 'रूपांतरित की जाने वाली स्ट्रिंग (संदर्भ द्वारा पारित, यथास्थान अधिलेखित)',
    A_OUT  => 'आउटपुट एन्कोडिंग का नाम',
    A_IN   => 'इनपुट एन्कोडिंग का नाम',
    A_COUNT=> 'रूपांतरण के बाद अक्षरों की संख्या',
    ERA_INTRO => 'sjis / euc / jis के वर्ष-संस्करण (बिना वर्ष वाला नाम 1990 संस्करण है):',
    ERA_P1 => 'जापानी कांजी को चरणों में मानकीकृत किया गया। समान बाइट्स संस्करणों के बीच अलग अक्षर दर्शा सकती हैं, इसलिए अपने डेटा से मेल खाता संस्करण चुनें। यदि पता न हो तो बिना वर्ष वाला sjis / euc / jis उपयोग करें।',
    ERA_1978 => 'पहला कांजी मानक (स्तर 1 और स्तर 2)।',
    ERA_1983 => '22 कांजी जोड़ों का कोड बदला और कुछ आकृतियाँ बदलीं; पुराने डेटा के खराब होने का सबसे आम कारण।',
    ERA_1990 => 'केवल 2 कांजी जोड़े (U+51DC, U+7199); बिना वर्ष वाला sjis / euc / jis यही संस्करण है।',
    ERA_2000 => 'बड़ा विस्तार; नए प्लेन 2 पर स्तर 3 और स्तर 4 के कांजी और चिह्न जोड़े।',
    ERA_2004 => '10 कांजी जोड़े और 168 कांजी की उदाहरण आकृति बदली (कोड 2000 जैसा ही, केवल आकृति बदली)।',
    OPT_INTRO => 'विकल्पों को चौथे तर्क के रूप में दें: { \'KEY\' => मान, ... }',
    O_INPUT_LAYOUT   => '\'S\' (1-बाइट SBCS) और \'D\' (2-बाइट DBCS) द्वारा निश्चित रिकॉर्ड लेआउट; प्रत्येक अक्षर के बाद पुनरावृत्ति संख्या दी जा सकती है। डिफ़ॉल्ट: स्वचालित।',
    O_OUTPUT_SHIFTING=> 'सत्य: DBCS अनुक्रमों के आसपास शिफ्ट-आउट/शिफ्ट-इन कोड जोड़ता है। डिफ़ॉल्ट: असत्य।',
    O_SPACE          => 'DBCS/MBCS स्पेस भरण कोड (बाइनरी स्ट्रिंग)। डिफ़ॉल्ट: उस एन्कोडिंग का स्पेस।',
    O_GETA           => 'मैप न हो सकने वाले अक्षरों के लिए DBCS/MBCS गेता कोड।',
    O_OVERRIDE_MAPPING=>'प्रति-अक्षर FROM => TO ओवरराइड का हैश संदर्भ (SPACE को भी ओवरराइड करता है)।',
    O_JIS_SOSI       => 'सत्य: \'jis\' इनपुट में SO (0x0E)/SI (0x0F) को JIS X 0201 कातकाना में शिफ्ट माना जाता है (JIS7 आदत)। डिफ़ॉल्ट: असत्य; इनपुट \'jis\' हो।',
    O_JIS_X0212      => 'सत्य: \'jis\' आउटपुट में, JIS X 0212 में मौजूद पर JIS X 0208 में अनुपस्थित अक्षर ESC $ ( D के रूप में लिखा जाता है। OUTPUT_SHIFTING आवश्यक। डिफ़ॉल्ट: असत्य।',
    O_JIS_KANA       => '\'jis\' आउटपुट में कातकाना शैली: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING आवश्यक), \'SO\' (SO/GL/SI)। डिफ़ॉल्ट: \'GR\'।',
    O_JIS_DBCS       => '\'jis\' आउटपुट में DBCS एस्केप: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'। डिफ़ॉल्ट: \'B\'; आउटपुट \'jis\' हो।',
    O_JIS_SBCS       => '\'jis\' आउटपुट में SBCS एस्केप: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J रोमन), \'H\' (ESC ( H पुराना)। डिफ़ॉल्ट: \'B\'; आउटपुट \'jis\' हो।',
    O_JIS2004_PLANE1 => '\'jis2004\' आउटपुट में प्लेन-1 एस्केप: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000)। डिफ़ॉल्ट: \'Q\'; आउटपुट \'jis2004\' हो।',
    O_ROUND_TRIP     => 'सत्य: प्रतिवर्ती रूपांतरण; जिस अक्षर का मूल कोड नहीं है उसे उपयोगकर्ता-परिभाषित (GAIJI) क्षेत्र में रखा जाता है ताकि "A से B" और "B से A" मूल को बहाल करें। दोनों दिशाओं में ROUND_TRIP=>1 और समान Jacode4e संस्करण आवश्यक। डिफ़ॉल्ट: असत्य (मैप न होने पर GETA)। तालिका पहली बार उपयोग पर आलसी रूप से बनती है।',
    S1 => 'UTF-8 से मेनफ्रेम एन्कोडिंग तक (शिफ्ट, स्पेस, गेता सहित)',
    S2 => 'पुराना 1978 Shift_JIS से UTF-8 तक (वर्ष-सचेत)',
    S3 => 'राउंड-ट्रिप: UTF-8 -> CP00930 -> UTF-8 मूल को बहाल करता है',
};

$L{'NE'} = {
    TITLE2 => 'Jacode4e द्रुत सन्दर्भ पत्र (NE)',
    TITLE9 => 'Jacode4e द्रुत सन्दर्भ (नेपाली)',
    H_BASIC=> 'आधारभूत प्रयोग',
    H_ENC  => 'इन्कोडिङ नामहरूको सूची',
    H_ERA  => 'वर्ष अनुसार JIS संस्करणका भिन्नता (सुरुवातीहरूका लागि)',
    H_OPT  => 'विकल्पहरू',
    H_SHIFT=> 'शिफ्ट कोड सन्दर्भ',
    H_SAMPLE=>'प्रोग्रामिङ उदाहरण',
    A_LINE => 'रूपान्तरण गर्नुपर्ने स्ट्रिङ (सन्दर्भद्वारा पठाइएको, स्थानमै ओभरराइट हुन्छ)',
    A_OUT  => 'आउटपुट इन्कोडिङको नाम',
    A_IN   => 'इनपुट इन्कोडिङको नाम',
    A_COUNT=> 'रूपान्तरणपछिको अक्षर संख्या',
    ERA_INTRO => 'sjis / euc / jis का वर्ष-संस्करण (वर्षविहीन नाम 1990 संस्करण हो):',
    ERA_P1 => 'जापानी कान्जी चरणबद्ध रूपमा मानकीकृत गरिएको थियो। संस्करण फरक हुँदा उही बाइटले फरक अक्षर जनाउन सक्छ, त्यसैले आफ्नो डेटासँग मिल्ने संस्करण छान्नुहोस्। थाहा नभए वर्षविहीन sjis / euc / jis प्रयोग गर्नुहोस्।',
    ERA_1978 => 'पहिलो कान्जी मानक (तह 1 र तह 2)।',
    ERA_1983 => '22 कान्जी जोडीको कोड साटासाट गर्‍यो र केही आकृति परिवर्तन गर्‍यो; पुरानो डेटा बिग्रनुको सबैभन्दा सामान्य कारण।',
    ERA_1990 => 'केवल 2 कान्जी थप्यो (U+51DC, U+7199); वर्षविहीन sjis / euc / jis यही संस्करण हो।',
    ERA_2000 => 'ठूलो विस्तार; नयाँ प्लेन 2 मा तह 3 र तह 4 का कान्जी र चिह्न थप्यो।',
    ERA_2004 => '10 कान्जी थप्यो र 168 कान्जीको उदाहरण आकृति परिवर्तन गर्‍यो (कोड 2000 जस्तै, आकृति मात्र फरक)।',
    OPT_INTRO => 'विकल्पहरू चौथो आर्गुमेन्टको रूपमा दिनुहोस्: { \'KEY\' => मान, ... }',
    O_INPUT_LAYOUT   => '\'S\' (1-बाइट SBCS) र \'D\' (2-बाइट DBCS) द्वारा निश्चित रेकर्ड लेआउट; प्रत्येक अक्षरपछि दोहोर्‍याउने संख्या दिन सकिन्छ। पूर्वनिर्धारित: स्वचालित।',
    O_OUTPUT_SHIFTING=> 'सत्य: DBCS अनुक्रमहरूको वरिपरि शिफ्ट-आउट/शिफ्ट-इन कोड थप्छ। पूर्वनिर्धारित: असत्य।',
    O_SPACE          => 'DBCS/MBCS स्पेस भर्ने कोड (बाइनरी स्ट्रिङ)। पूर्वनिर्धारित: सो इन्कोडिङको स्पेस।',
    O_GETA           => 'म्याप गर्न नसकिने अक्षरहरूका लागि DBCS/MBCS गेता कोड।',
    O_OVERRIDE_MAPPING=>'प्रति-अक्षर FROM => TO ओभरराइडको ह्यास सन्दर्भ (SPACE लाई पनि ओभरराइड गर्छ)।',
    O_JIS_SOSI       => 'सत्य: \'jis\' इनपुटमा SO (0x0E)/SI (0x0F) लाई JIS X 0201 कातकानामा शिफ्ट मानिन्छ (JIS7 बानी)। पूर्वनिर्धारित: असत्य; इनपुट \'jis\' हुँदा।',
    O_JIS_X0212      => 'सत्य: \'jis\' आउटपुटमा, JIS X 0212 मा भएको तर JIS X 0208 मा नभएको अक्षर ESC $ ( D को रूपमा लेखिन्छ। OUTPUT_SHIFTING आवश्यक। पूर्वनिर्धारित: असत्य।',
    O_JIS_KANA       => '\'jis\' आउटपुटमा कातकाना शैली: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING आवश्यक), \'SO\' (SO/GL/SI)। पूर्वनिर्धारित: \'GR\'।',
    O_JIS_DBCS       => '\'jis\' आउटपुटमा DBCS एस्केप: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'। पूर्वनिर्धारित: \'B\'; आउटपुट \'jis\' हुँदा।',
    O_JIS_SBCS       => '\'jis\' आउटपुटमा SBCS एस्केप: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J रोमन), \'H\' (ESC ( H पुरानो)। पूर्वनिर्धारित: \'B\'; आउटपुट \'jis\' हुँदा।',
    O_JIS2004_PLANE1 => '\'jis2004\' आउटपुटमा प्लेन-1 एस्केप: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000)। पूर्वनिर्धारित: \'Q\'; आउटपुट \'jis2004\' हुँदा।',
    O_ROUND_TRIP     => 'सत्य: उल्टाउन मिल्ने रूपान्तरण; मूल कोड नभएको अक्षर प्रयोगकर्ता-परिभाषित (GAIJI) क्षेत्रमा राखिन्छ ताकि "A देखि B" र "B देखि A" ले मूल फिर्ता ल्याऊन्। दुवै दिशामा ROUND_TRIP=>1 र समान Jacode4e संस्करण आवश्यक। पूर्वनिर्धारित: असत्य (म्याप नभए GETA)। तालिका पहिलो प्रयोगमा अल्छी रूपमा बन्छ।',
    S1 => 'UTF-8 बाट मेनफ्रेम इन्कोडिङसम्म (शिफ्ट, स्पेस, गेता सहित)',
    S2 => 'पुरानो 1978 Shift_JIS बाट UTF-8 सम्म (वर्ष-सचेत)',
    S3 => 'राउन्ड-ट्रिप: UTF-8 -> CP00930 -> UTF-8 ले मूल फिर्ता ल्याउँछ',
};

$L{'BN'} = {
    TITLE2 => 'Jacode4e দ্রুত তথ্যপত্র (BN)',
    TITLE9 => 'Jacode4e দ্রুত রেফারেন্স (বাংলা)',
    H_BASIC=> 'মূল ব্যবহার',
    H_ENC  => 'এনকোডিং নামের তালিকা',
    H_ERA  => 'বছর অনুযায়ী JIS সংস্করণের পার্থক্য (নতুনদের জন্য)',
    H_OPT  => 'বিকল্পসমূহ',
    H_SHIFT=> 'শিফট কোড রেফারেন্স',
    H_SAMPLE=>'প্রোগ্রামিং উদাহরণ',
    A_LINE => 'রূপান্তরযোগ্য স্ট্রিং (রেফারেন্সে পাঠানো, স্থানেই ওভাররাইট হয়)',
    A_OUT  => 'আউটপুট এনকোডিংয়ের নাম',
    A_IN   => 'ইনপুট এনকোডিংয়ের নাম',
    A_COUNT=> 'রূপান্তরের পরে অক্ষর সংখ্যা',
    ERA_INTRO => 'sjis / euc / jis এর বছর-সংস্করণ (বছরবিহীন নাম হলো 1990 সংস্করণ):',
    ERA_P1 => 'জাপানি কাঞ্জি ধাপে ধাপে মানকীকৃত হয়েছিল। একই বাইট সংস্করণভেদে ভিন্ন অক্ষর বোঝাতে পারে, তাই আপনার ডেটার সাথে মিল রেখে সংস্করণ বেছে নিন। না জানলে বছরবিহীন sjis / euc / jis ব্যবহার করুন।',
    ERA_1978 => 'প্রথম কাঞ্জি মান (স্তর 1 ও স্তর 2)।',
    ERA_1983 => '22 জোড়া কাঞ্জির কোড বদলে দিয়েছে এবং কিছু আকৃতি পরিবর্তন করেছে; পুরনো ডেটা নষ্ট হওয়ার সবচেয়ে সাধারণ কারণ।',
    ERA_1990 => 'কেবল 2টি কাঞ্জি যোগ করেছে (U+51DC, U+7199); বছরবিহীন sjis / euc / jis এই সংস্করণ।',
    ERA_2000 => 'বড় সম্প্রসারণ; নতুন প্লেন 2-এ স্তর 3 ও স্তর 4 কাঞ্জি ও প্রতীক যোগ করেছে।',
    ERA_2004 => '10টি কাঞ্জি যোগ করেছে ও 168টি কাঞ্জির উদাহরণ আকৃতি বদলেছে (কোড 2000 এর মতোই, শুধু আকৃতি নতুন)।',
    OPT_INTRO => 'বিকল্পগুলো ৪র্থ আর্গুমেন্ট হিসেবে দিন: { \'KEY\' => মান, ... }',
    O_INPUT_LAYOUT   => '\'S\' (1-বাইট SBCS) ও \'D\' (2-বাইট DBCS) দিয়ে নির্দিষ্ট রেকর্ড লেআউট; প্রতিটি অক্ষরের পরে পুনরাবৃত্তি সংখ্যা দেওয়া যায়। ডিফল্ট: স্বয়ংক্রিয়।',
    O_OUTPUT_SHIFTING=> 'সত্য: DBCS ক্রমের চারপাশে শিফট-আউট/শিফট-ইন কোড যুক্ত করে। ডিফল্ট: মিথ্যা।',
    O_SPACE          => 'DBCS/MBCS স্পেস ফিল কোড (বাইনারি স্ট্রিং)। ডিফল্ট: ঐ এনকোডিংয়ের স্পেস।',
    O_GETA           => 'ম্যাপ করা যায় না এমন অক্ষরের জন্য DBCS/MBCS গেতা কোড।',
    O_OVERRIDE_MAPPING=>'প্রতি-অক্ষর FROM => TO ওভাররাইডের হ্যাশ রেফারেন্স (SPACE-ও ওভাররাইড করে)।',
    O_JIS_SOSI       => 'সত্য: \'jis\' ইনপুটে SO (0x0E)/SI (0x0F) কে JIS X 0201 কাতাকানায় শিফট হিসেবে ধরা হয় (JIS7 রীতি)। ডিফল্ট: মিথ্যা; ইনপুট \'jis\' হলে।',
    O_JIS_X0212      => 'সত্য: \'jis\' আউটপুটে, JIS X 0212 তে আছে কিন্তু JIS X 0208 এ নেই এমন অক্ষর ESC $ ( D হিসেবে লেখা হয়। OUTPUT_SHIFTING লাগে। ডিফল্ট: মিথ্যা।',
    O_JIS_KANA       => '\'jis\' আউটপুটে কাতাকানা রীতি: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING লাগে), \'SO\' (SO/GL/SI)। ডিফল্ট: \'GR\'।',
    O_JIS_DBCS       => '\'jis\' আউটপুটে DBCS এস্কেপ: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'। ডিফল্ট: \'B\'; আউটপুট \'jis\' হলে।',
    O_JIS_SBCS       => '\'jis\' আউটপুটে SBCS এস্কেপ: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J রোমান), \'H\' (ESC ( H পুরনো)। ডিফল্ট: \'B\'; আউটপুট \'jis\' হলে।',
    O_JIS2004_PLANE1 => '\'jis2004\' আউটপুটে প্লেন-1 এস্কেপ: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000)। ডিফল্ট: \'Q\'; আউটপুট \'jis2004\' হলে।',
    O_ROUND_TRIP     => 'সত্য: বিপরীতমুখী রূপান্তর; নিজস্ব কোড নেই এমন অক্ষর ব্যবহারকারী-সংজ্ঞায়িত (GAIJI) এলাকায় বসানো হয় যাতে "A থেকে B" ও "B থেকে A" মূল ফিরিয়ে দেয়। উভয় দিকেই ROUND_TRIP=>1 ও একই Jacode4e সংস্করণ দরকার। ডিফল্ট: মিথ্যা (ম্যাপ না হলে GETA)। টেবিল প্রথম ব্যবহারে অলসভাবে তৈরি হয়।',
    S1 => 'UTF-8 থেকে মেইনফ্রেম এনকোডিং (শিফট, স্পেস, গেতা সহ)',
    S2 => 'পুরনো 1978 Shift_JIS থেকে UTF-8 (বছর-সচেতন)',
    S3 => 'রাউন্ড-ট্রিপ: UTF-8 -> CP00930 -> UTF-8 মূল ফিরিয়ে দেয়',
};

$L{'UR'} = {
    TITLE2 => 'Jacode4e فوری حوالہ جاتی کارڈ (UR)',
    TITLE9 => 'Jacode4e فوری حوالہ (اردو)',
    H_BASIC=> 'بنیادی استعمال',
    H_ENC  => 'انکوڈنگ ناموں کی فہرست',
    H_ERA  => 'سال کے لحاظ سے JIS ایڈیشنوں کے فرق (نئے سیکھنے والوں کے لیے)',
    H_OPT  => 'اختیارات',
    H_SHIFT=> 'شفٹ کوڈ حوالہ',
    H_SAMPLE=>'پروگرامنگ مثالیں',
    A_LINE => 'تبدیل کی جانے والی سٹرنگ (حوالے سے دی گئی، اسی جگہ اوور رائٹ ہوتی ہے)',
    A_OUT  => 'آؤٹ پٹ انکوڈنگ کا نام',
    A_IN   => 'ان پٹ انکوڈنگ کا نام',
    A_COUNT=> 'تبدیلی کے بعد حروف کی تعداد',
    ERA_INTRO => 'sjis / euc / jis کے سال ایڈیشن (بغیر سال والا نام 1990 ایڈیشن ہے):',
    ERA_P1 => 'جاپانی کانجی مرحلہ وار معیاری بنائے گئے۔ ایک ہی بائٹس مختلف ایڈیشنوں میں مختلف حرف کا مطلب دے سکتی ہیں، اس لیے اپنے ڈیٹا سے مطابقت رکھنے والا ایڈیشن منتخب کریں۔ معلوم نہ ہو تو بغیر سال والا sjis / euc / jis استعمال کریں۔',
    ERA_1978 => 'پہلا کانجی معیار (سطح 1 اور سطح 2)۔',
    ERA_1983 => '22 کانجی جوڑوں کا کوڈ بدلا اور کچھ شکلیں تبدیل کیں؛ پرانے ڈیٹا کے خراب ہونے کی سب سے عام وجہ۔',
    ERA_1990 => 'صرف 2 کانجی شامل کیے (U+51DC, U+7199)؛ بغیر سال والا sjis / euc / jis یہی ایڈیشن ہے۔',
    ERA_2000 => 'بڑی توسیع؛ نئے پلین 2 پر سطح 3 اور سطح 4 کے کانجی اور علامات شامل کیں۔',
    ERA_2004 => '10 کانجی شامل کیے اور 168 کانجی کی نمونہ شکل بدلی (کوڈ 2000 جیسا ہی، صرف شکل نئی)۔',
    OPT_INTRO => 'اختیارات کو چوتھی دلیل کے طور پر دیں: { \'KEY\' => قدر, ... }',
    O_INPUT_LAYOUT   => '\'S\' (1-بائٹ SBCS) اور \'D\' (2-بائٹ DBCS) سے مقررہ ریکارڈ لے آؤٹ؛ ہر حرف کے بعد دہرانے کی تعداد آ سکتی ہے۔ طے شدہ: خودکار۔',
    O_OUTPUT_SHIFTING=> 'سچ: DBCS تسلسل کے گرد شفٹ آؤٹ/شفٹ اِن کوڈ شامل کرتا ہے۔ طے شدہ: جھوٹ۔',
    O_SPACE          => 'DBCS/MBCS اسپیس فِل کوڈ (بائنری سٹرنگ)۔ طے شدہ: اسی انکوڈنگ کا اسپیس۔',
    O_GETA           => 'جن حروف کو میپ نہ کیا جا سکے ان کے لیے DBCS/MBCS گیتا کوڈ۔',
    O_OVERRIDE_MAPPING=>'فی حرف FROM => TO اووررائیڈ کا ہیش حوالہ (SPACE کو بھی اووررائیڈ کرتا ہے)۔',
    O_JIS_SOSI       => 'سچ: \'jis\' ان پٹ میں SO (0x0E)/SI (0x0F) کو JIS X 0201 کاتاکانا کی طرف شفٹ سمجھا جاتا ہے (JIS7 عادت)۔ طے شدہ: جھوٹ؛ ان پٹ \'jis\' ہو۔',
    O_JIS_X0212      => 'سچ: \'jis\' آؤٹ پٹ میں، وہ حرف جو JIS X 0212 میں ہو مگر JIS X 0208 میں نہ ہو ESC $ ( D کے طور پر لکھا جاتا ہے۔ OUTPUT_SHIFTING درکار۔ طے شدہ: جھوٹ۔',
    O_JIS_KANA       => '\'jis\' آؤٹ پٹ میں کاتاکانا انداز: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING درکار), \'SO\' (SO/GL/SI)۔ طے شدہ: \'GR\'۔',
    O_JIS_DBCS       => '\'jis\' آؤٹ پٹ میں DBCS ایسکیپ: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'۔ طے شدہ: \'B\'؛ آؤٹ پٹ \'jis\' ہو۔',
    O_JIS_SBCS       => '\'jis\' آؤٹ پٹ میں SBCS ایسکیپ: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J رومن), \'H\' (ESC ( H پرانا)۔ طے شدہ: \'B\'؛ آؤٹ پٹ \'jis\' ہو۔',
    O_JIS2004_PLANE1 => '\'jis2004\' آؤٹ پٹ میں پلین-1 ایسکیپ: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000)۔ طے شدہ: \'Q\'؛ آؤٹ پٹ \'jis2004\' ہو۔',
    O_ROUND_TRIP     => 'سچ: الٹ پلٹ کے قابل تبدیلی؛ جس حرف کا مقامی کوڈ نہ ہو اسے صارف کے متعین (GAIJI) علاقے میں رکھا جاتا ہے تاکہ "A سے B" اور "B سے A" اصل بحال کریں۔ دونوں سمتوں میں ROUND_TRIP=>1 اور یکساں Jacode4e ورژن درکار۔ طے شدہ: جھوٹ (میپ نہ ہو تو GETA)۔ ٹیبل پہلی بار استعمال پر سست انداز میں بنتا ہے۔',
    S1 => 'UTF-8 سے مین فریم انکوڈنگ تک (شفٹ، اسپیس، گیتا کے ساتھ)',
    S2 => 'پرانا 1978 Shift_JIS سے UTF-8 تک (سال کے مطابق)',
    S3 => 'راؤنڈ ٹرپ: UTF-8 -> CP00930 -> UTF-8 اصل بحال کرتا ہے',
};

$L{'TH'} = {
    TITLE2 => 'แผ่นสรุป Jacode4e (TH)',
    TITLE9 => 'คู่มืออ้างอิงด่วน Jacode4e (ภาษาไทย)',
    H_BASIC=> 'การใช้งานพื้นฐาน',
    H_ENC  => 'รายชื่อการเข้ารหัส',
    H_ERA  => 'ความแตกต่างของมาตรฐาน JIS ตามปี (สำหรับผู้เริ่มต้น)',
    H_OPT  => 'ตัวเลือก',
    H_SHIFT=> 'ตารางรหัสชิฟต์',
    H_SAMPLE=>'ตัวอย่างการเขียนโปรแกรม',
    A_LINE => 'สตริงที่จะแปลง (ส่งโดยการอ้างอิง เขียนทับในตำแหน่งเดิม)',
    A_OUT  => 'ชื่อการเข้ารหัสขาออก',
    A_IN   => 'ชื่อการเข้ารหัสขาเข้า',
    A_COUNT=> 'จำนวนอักขระหลังการแปลง',
    ERA_INTRO => 'รุ่นตามปีของ sjis / euc / jis (ชื่อที่ไม่มีปีคือรุ่นปี 1990):',
    ERA_P1 => 'คันจิญี่ปุ่นถูกกำหนดมาตรฐานเป็นขั้นตอน ไบต์เดียวกันอาจหมายถึงอักขระต่างกันในแต่ละรุ่น จึงควรเลือกรุ่นที่ตรงกับข้อมูลของคุณ หากไม่ทราบ ให้ใช้ sjis / euc / jis ที่ไม่มีปี',
    ERA_1978 => 'มาตรฐานคันจิรุ่นแรก (ระดับ 1 และระดับ 2)',
    ERA_1983 => 'สลับรหัสของคันจิ 22 คู่และเปลี่ยนรูปพิมพ์บางตัว เป็นสาเหตุที่พบบ่อยที่สุดของข้อมูลเก่าที่เพี้ยน',
    ERA_1990 => 'เพิ่มคันจิเพียง 2 ตัว (U+51DC, U+7199) sjis / euc / jis ที่ไม่มีปีคือรุ่นนี้',
    ERA_2000 => 'ขยายครั้งใหญ่ เพิ่มคันจิระดับ 3 และ 4 และสัญลักษณ์บนระนาบ 2 ใหม่',
    ERA_2004 => 'เพิ่มคันจิ 10 ตัวและเปลี่ยนรูปตัวอย่างของคันจิ 168 ตัว (รหัสเหมือนปี 2000 เปลี่ยนเฉพาะรูป)',
    OPT_INTRO => 'ส่งตัวเลือกเป็นอาร์กิวเมนต์ที่ 4: { \'KEY\' => ค่า, ... }',
    O_INPUT_LAYOUT   => 'เค้าโครงเรกคอร์ดคงที่ด้วย \'S\' (SBCS 1 ไบต์) และ \'D\' (DBCS 2 ไบต์) แต่ละตัวอักษรตามด้วยจำนวนครั้งซ้ำได้ ค่าเริ่มต้น: อัตโนมัติ',
    O_OUTPUT_SHIFTING=> 'จริง: ใส่รหัส shift-out/shift-in รอบช่วง DBCS ค่าเริ่มต้น: เท็จ',
    O_SPACE          => 'รหัสเติมช่องว่าง DBCS/MBCS (สตริงไบนารี) ค่าเริ่มต้น: ช่องว่างของการเข้ารหัสนั้น',
    O_GETA           => 'รหัสเกตะ DBCS/MBCS สำหรับอักขระที่แมปไม่ได้',
    O_OVERRIDE_MAPPING=>'แฮชอ้างอิงการแทนที่ FROM => TO ต่ออักขระ (แทนที่ SPACE ด้วย)',
    O_JIS_SOSI       => 'จริง: ในอินพุต \'jis\' ให้ SO (0x0E)/SI (0x0F) เป็นการชิฟต์ไปยังคาตากานะ JIS X 0201 (ธรรมเนียม JIS7) ค่าเริ่มต้น: เท็จ; อินพุตเป็น \'jis\'',
    O_JIS_X0212      => 'จริง: ในเอาต์พุต \'jis\' อักขระที่อยู่ใน JIS X 0212 แต่ไม่อยู่ใน JIS X 0208 จะเขียนเป็น ESC $ ( D ต้องใช้ OUTPUT_SHIFTING ค่าเริ่มต้น: เท็จ',
    O_JIS_KANA       => 'รูปแบบคาตากานะในเอาต์พุต \'jis\': \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, ต้องใช้ OUTPUT_SHIFTING), \'SO\' (SO/GL/SI) ค่าเริ่มต้น: \'GR\'',
    O_JIS_DBCS       => 'เอสเคป DBCS ในเอาต์พุต \'jis\': \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\' ค่าเริ่มต้น: \'B\'; เอาต์พุตเป็น \'jis\'',
    O_JIS_SBCS       => 'เอสเคป SBCS ในเอาต์พุต \'jis\': \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H เก่า) ค่าเริ่มต้น: \'B\'; เอาต์พุตเป็น \'jis\'',
    O_JIS2004_PLANE1 => 'เอสเคประนาบ 1 ในเอาต์พุต \'jis2004\': \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000) ค่าเริ่มต้น: \'Q\'; เอาต์พุตเป็น \'jis2004\'',
    O_ROUND_TRIP     => 'จริง: การแปลงแบบย้อนกลับได้; อักขระที่ไม่มีรหัสดั้งเดิมจะถูกวางในพื้นที่ผู้ใช้กำหนด (GAIJI) เพื่อให้ "A ไป B" และ "B ไป A" คืนค่าต้นฉบับ ทั้งสองทิศทางต้องใช้ ROUND_TRIP=>1 และ Jacode4e รุ่นเดียวกัน ค่าเริ่มต้น: เท็จ (แมปไม่ได้จะกลายเป็น GETA) ตารางถูกสร้างแบบ lazy เมื่อใช้ครั้งแรก',
    S1 => 'UTF-8 ไปยังการเข้ารหัสเมนเฟรม (พร้อมชิฟต์ ช่องว่าง เกตะ)',
    S2 => 'Shift_JIS ปี 1978 เก่าไปยัง UTF-8 (ตามปี)',
    S3 => 'ไปกลับ: UTF-8 -> CP00930 -> UTF-8 คืนค่าต้นฉบับ',
};

$L{'KM'} = {
    TITLE2 => 'សន្លឹកយោង Jacode4e (KM)',
    TITLE9 => 'ឯកសារយោងរហ័សសម្រាប់ Jacode4e (ភាសាខ្មែរ)',
    H_BASIC=> 'របៀបប្រើប្រាស់មូលដ្ឋាន',
    H_ENC  => 'បញ្ជីឈ្មោះការអ៊ិនកូដ',
    H_ERA  => 'ភាពខុសគ្នានៃស្តង់ដារ JIS តាមឆ្នាំ (សម្រាប់អ្នកចាប់ផ្តើម)',
    H_OPT  => 'ជម្រើស',
    H_SHIFT=> 'តារាងកូដ Shift',
    H_SAMPLE=>'ឧទាហរណ៍កម្មវិធី',
    A_LINE => 'ខ្សែអក្សរដែលត្រូវបំលែង (បញ្ជូនតាមឯកសារយោង សរសេរជាន់ពីលើនៅនឹងកន្លែង)',
    A_OUT  => 'ឈ្មោះការអ៊ិនកូដលទ្ធផល',
    A_IN   => 'ឈ្មោះការអ៊ិនកូដបញ្ចូល',
    A_COUNT=> 'ចំនួនតួអក្សរបន្ទាប់ពីការបំលែង',
    ERA_INTRO => 'កំណែតាមឆ្នាំរបស់ sjis / euc / jis (ឈ្មោះគ្មានឆ្នាំគឺជាកំណែ 1990):',
    ERA_P1 => 'អក្សរកាន់ជីជប៉ុនត្រូវបានធ្វើឱ្យមានស្តង់ដារជាដំណាក់កាល។ បៃដូចគ្នាអាចមានន័យជាតួអក្សរផ្សេងគ្នារវាងកំណែនីមួយៗ ដូច្នេះសូមជ្រើសរើសកំណែដែលត្រូវនឹងទិន្នន័យរបស់អ្នក។ បើមិនដឹង សូមប្រើ sjis / euc / jis ដែលគ្មានឆ្នាំ។',
    ERA_1978 => 'ស្តង់ដារកាន់ជីដំបូង (កម្រិត 1 និងកម្រិត 2)។',
    ERA_1983 => 'បានផ្លាស់ប្តូរកូដនៃគូកាន់ជី 22 គូ និងបានផ្លាស់ប្តូររូបរាងខ្លះ ជាមូលហេតុទូទៅបំផុតនៃទិន្នន័យចាស់ខូច។',
    ERA_1990 => 'បានបន្ថែមកាន់ជីត្រឹមតែ 2 (U+51DC, U+7199); sjis / euc / jis គ្មានឆ្នាំគឺជាកំណែនេះ។',
    ERA_2000 => 'ការពង្រីកធំ; បានបន្ថែមកាន់ជីកម្រិត 3 និង 4 និងនិមិត្តសញ្ញានៅលើផ្ទាំង 2 ថ្មី។',
    ERA_2004 => 'បានបន្ថែមកាន់ជី 10 និងផ្លាស់ប្តូររូបរាងគំរូនៃកាន់ជី 168 (កូដដូច 2000 រូបរាងថ្មី)។',
    OPT_INTRO => 'បញ្ជូនជម្រើសជាអាគុយម៉ង់ទី 4: { \'KEY\' => តម្លៃ, ... }',
    O_INPUT_LAYOUT   => 'ប្លង់កំណត់ត្រាថេរដោយ \'S\' (SBCS 1 បៃ) និង \'D\' (DBCS 2 បៃ); តួអក្សរនីមួយៗអាចមានចំនួនធ្វើម្តងទៀតតាមក្រោយ។ លំនាំដើម: ស្វ័យប្រវត្តិ។',
    O_OUTPUT_SHIFTING=> 'ពិត: បញ្ចេញកូដ shift-out/shift-in ជុំវិញលំដាប់ DBCS។ លំនាំដើម: មិនពិត។',
    O_SPACE          => 'កូដបំពេញដកឃ្លា DBCS/MBCS (ខ្សែអក្សរគោលពីរ)។ លំនាំដើម: ដកឃ្លារបស់ការអ៊ិនកូដនោះ។',
    O_GETA           => 'កូដ geta DBCS/MBCS សម្រាប់តួអក្សរដែលមិនអាចផ្គូផ្គង។',
    O_OVERRIDE_MAPPING=>'ឯកសារយោង hash នៃការជំនួស FROM => TO ក្នុងមួយតួអក្សរ (ជំនួស SPACE ផងដែរ)។',
    O_JIS_SOSI       => 'ពិត: នៅការបញ្ចូល \'jis\' SO (0x0E)/SI (0x0F) ប្តូរទៅ Katakana JIS X 0201 (ទម្លាប់ JIS7)។ លំនាំដើម: មិនពិត; ការបញ្ចូលជា \'jis\'។',
    O_JIS_X0212      => 'ពិត: នៅលទ្ធផល \'jis\' តួអក្សរដែលមានក្នុង JIS X 0212 តែគ្មានក្នុង JIS X 0208 ត្រូវសរសេរជា ESC $ ( D។ ត្រូវការ OUTPUT_SHIFTING។ លំនាំដើម: មិនពិត។',
    O_JIS_KANA       => 'រចនាបថ Katakana នៅលទ្ធផល \'jis\': \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, ត្រូវការ OUTPUT_SHIFTING), \'SO\' (SO/GL/SI)។ លំនាំដើម: \'GR\'។',
    O_JIS_DBCS       => 'Escape DBCS នៅលទ្ធផល \'jis\': \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'។ លំនាំដើម: \'B\'; លទ្ធផលជា \'jis\'។',
    O_JIS_SBCS       => 'Escape SBCS នៅលទ្ធផល \'jis\': \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H ចាស់)។ លំនាំដើម: \'B\'; លទ្ធផលជា \'jis\'។',
    O_JIS2004_PLANE1 => 'Escape ផ្ទាំង 1 នៅលទ្ធផល \'jis2004\': \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000)។ លំនាំដើម: \'Q\'; លទ្ធផលជា \'jis2004\'។',
    O_ROUND_TRIP     => 'ពិត: ការបំលែងអាចត្រឡប់វិញ; តួអក្សរដែលគ្មានកូដដើមត្រូវដាក់ក្នុងតំបន់កំណត់ដោយអ្នកប្រើ (GAIJI) ដើម្បីឱ្យ "A ទៅ B" និង "B ទៅ A" ស្តារទិន្នន័យដើម។ ទាំងពីរទិសត្រូវការ ROUND_TRIP=>1 និងកំណែ Jacode4e ដូចគ្នា។ លំនាំដើម: មិនពិត (មិនអាចផ្គូផ្គងក្លាយជា GETA)។ តារាងត្រូវបង្កើតបែប lazy នៅពេលប្រើលើកដំបូង។',
    S1 => 'UTF-8 ទៅការអ៊ិនកូដ mainframe (មាន shift, ដកឃ្លា, geta)',
    S2 => 'Shift_JIS 1978 ចាស់ ទៅ UTF-8 (តាមឆ្នាំ)',
    S3 => 'ទៅមកវិញ: UTF-8 -> CP00930 -> UTF-8 ស្តារទិន្នន័យដើម',
};

$L{'MN'} = {
    TITLE2 => 'Jacode4e Хуурцаг Лавлах (MN)',
    TITLE9 => 'Jacode4e Хурдан лавлах (Монгол)',
    H_BASIC=> 'ҮНДСЭН ХЭРЭГЛЭЭ',
    H_ENC  => 'КОДЛОЛТЫН НЭРСИЙН ЖАГСААЛТ',
    H_ERA  => 'JIS СТАНДАРТЫН ОНООР ЯЛГАА (эхлэн суралцагчдад)',
    H_OPT  => 'СОНГОЛТУУД',
    H_SHIFT=> 'SHIFT КОДЫН ЛАВЛАХ',
    H_SAMPLE=>'ПРОГРАМЧЛАЛЫН ЖИШЭЭ',
    A_LINE => 'хөрвүүлэх мөр (лавлагаагаар дамжуулна, байрандаа дарж бичнэ)',
    A_OUT  => 'гаралтын кодлолтын нэр',
    A_IN   => 'оролтын кодлолтын нэр',
    A_COUNT=> 'хөрвүүлсний дараах тэмдэгтийн тоо',
    ERA_INTRO => 'sjis / euc / jis-ийн оны хувилбарууд (онгүй нэр нь 1990 оны хувилбар):',
    ERA_P1 => 'Японы ханзыг үе шаттайгаар стандартчилсан. Ижил байт нь хувилбар бүрд өөр тэмдэгт байж болох тул өгөгдөлдөө тохирох хувилбарыг сонго. Мэдэхгүй бол онгүй sjis / euc / jis ашигла.',
    ERA_1978 => 'анхны ханзны стандарт (1-р ба 2-р түвшин).',
    ERA_1983 => '22 хос ханзны кодыг сольж, зарим дүрсийг өөрчилсөн; хуучин өгөгдөл эвдрэх хамгийн түгээмэл шалтгаан.',
    ERA_1990 => 'зөвхөн 2 ханз нэмсэн (U+51DC, U+7199); онгүй sjis / euc / jis нь энэ хувилбар.',
    ERA_2000 => 'том тэлэлт; шинэ 2-р хавтгайд 3, 4-р түвшний ханз, тэмдэг нэмсэн.',
    ERA_2004 => '10 ханз нэмж, 168 ханзны жишиг дүрсийг өөрчилсөн (код 2000-тай ижил, зөвхөн дүрс шинэ).',
    OPT_INTRO => 'Сонголтуудыг 4 дэх аргумент болгон дамжуул: { \'KEY\' => утга, ... }',
    O_INPUT_LAYOUT   => '\'S\' (1 байт SBCS), \'D\' (2 байт DBCS)-аар тогтмол бичлэгийн байрлал; үсэг бүрийн ард давталтын тоо орж болно. Анхдагч: автомат.',
    O_OUTPUT_SHIFTING=> 'Үнэн: DBCS дараалал орчимд shift-out/shift-in код гаргана. Анхдагч: худал.',
    O_SPACE          => 'DBCS/MBCS зайн дүүргэх код (хоёртын мөр). Анхдагч: тухайн кодлолтын зай.',
    O_GETA           => 'Буулгаж чадахгүй тэмдэгтэд зориулсан DBCS/MBCS geta код.',
    O_OVERRIDE_MAPPING=>'Тэмдэгт тус бүрийн FROM => TO дарж бичих hash лавлагаа (SPACE-ийг мөн дарж бичнэ).',
    O_JIS_SOSI       => 'Үнэн: \'jis\' оролтод SO (0x0E)/SI (0x0F)-ийг JIS X 0201 Катаканад шилжих гэж үзнэ (JIS7 зуршил). Анхдагч: худал; оролт \'jis\' үед.',
    O_JIS_X0212      => 'Үнэн: \'jis\' гаралтад JIS X 0212-т байгаа боловч JIS X 0208-д байхгүй тэмдэгтийг ESC $ ( D гэж бичнэ. OUTPUT_SHIFTING шаардлагатай. Анхдагч: худал.',
    O_JIS_KANA       => '\'jis\' гаралтын Катакана хэв маяг: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING шаардлагатай), \'SO\' (SO/GL/SI). Анхдагч: \'GR\'.',
    O_JIS_DBCS       => '\'jis\' гаралтын DBCS escape: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. Анхдагч: \'B\'; гаралт \'jis\' үед.',
    O_JIS_SBCS       => '\'jis\' гаралтын SBCS escape: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H хуучин). Анхдагч: \'B\'; гаралт \'jis\' үед.',
    O_JIS2004_PLANE1 => '\'jis2004\' гаралтын 1-р хавтгайн escape: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). Анхдагч: \'Q\'; гаралт \'jis2004\' үед.',
    O_ROUND_TRIP     => 'Үнэн: эргэх хөрвүүлэлт; уугуул кодгүй тэмдэгтийг хэрэглэгчийн тодорхойлсон (GAIJI) мужид байрлуулснаар "A-аас B" ба "B-ээс A" эх өгөгдлийг сэргээнэ. Хоёр чиглэлд ROUND_TRIP=>1 ба ИЖИЛ Jacode4e хувилбар шаардлагатай. Анхдагч: худал (буулгаж чадахгүй бол GETA). Хүснэгтийг анх ашиглах үед lazy үүсгэнэ.',
    S1 => 'UTF-8-аас mainframe кодлолт руу (shift, зай, geta-тай)',
    S2 => 'хуучин 1978 Shift_JIS-аас UTF-8 руу (оноор)',
    S3 => 'эргэх: UTF-8 -> CP00930 -> UTF-8 эх өгөгдлийг сэргээнэ',
};

$L{'MY'} = {
    TITLE2 => 'Jacode4e အမြန်ကိုးကားစာ (MY)',
    TITLE9 => 'Jacode4e အမြန်ကိုးကားချက် (မြန်မာဘာသာ)',
    H_BASIC=> 'အခြေခံအသုံးပြုပုံ',
    H_ENC  => 'Encoding အမည်များ',
    H_ERA  => 'JIS စံနှုန်းများ၏ နှစ်အလိုက် ကွာခြားချက် (စတင်သူများအတွက်)',
    H_OPT  => 'ရွေးချယ်စရာများ',
    H_SHIFT=> 'Shift ကုဒ် ကိုးကားချက်',
    H_SAMPLE=>'ပရိုဂရမ်ရေးသားမှု နမူနာများ',
    A_LINE => 'ပြောင်းလဲမည့် စာကြောင်း (ကိုးကားချက်ဖြင့် ပေးပို့၊ နေရာတွင်ပင် ထပ်ရေး)',
    A_OUT  => 'output encoding အမည်',
    A_IN   => 'input encoding အမည်',
    A_COUNT=> 'ပြောင်းလဲပြီးနောက် စာလုံးအရေအတွက်',
    ERA_INTRO => 'sjis / euc / jis ၏ နှစ်အလိုက်ဗားရှင်းများ (နှစ်မပါသော အမည်သည် 1990 ဗားရှင်း):',
    ERA_P1 => 'ဂျပန်ခန်ဂျီများကို အဆင့်လိုက် စံသတ်မှတ်ခဲ့သည်။ တူညီသော bytes သည် ဗားရှင်းအလိုက် စာလုံးကွဲပြားနိုင်သဖြင့် သင့်ဒေတာနှင့် ကိုက်ညီသော ဗားရှင်းကို ရွေးပါ။ မသိပါက နှစ်မပါသော sjis / euc / jis ကို သုံးပါ။',
    ERA_1978 => 'ပထမဆုံး ခန်ဂျီစံ (အဆင့် 1 နှင့် အဆင့် 2)။',
    ERA_1983 => 'ခန်ဂျီ 22 တွဲ၏ ကုဒ်ကို လဲလှယ်ကာ အချို့ပုံသဏ္ဌာန်ကို ပြောင်းခဲ့သည်; ဒေတာဟောင်း ပျက်ရသည့် အဖြစ်အများဆုံး အကြောင်းရင်း။',
    ERA_1990 => 'ခန်ဂျီ 2 လုံးသာ ထည့်ခဲ့သည် (U+51DC, U+7199); နှစ်မပါသော sjis / euc / jis သည် ဤဗားရှင်းဖြစ်သည်။',
    ERA_2000 => 'ကြီးမားစွာ ချဲ့ထွင်; plane 2 အသစ်တွင် အဆင့် 3 နှင့် 4 ခန်ဂျီများနှင့် သင်္ကေတများ ထည့်ခဲ့သည်။',
    ERA_2004 => 'ခန်ဂျီ 10 လုံး ထည့်ကာ ခန်ဂျီ 168 လုံး၏ နမူနာပုံသဏ္ဌာန်ကို ပြောင်းခဲ့သည် (ကုဒ်မှာ 2000 နှင့်တူ၊ ပုံသဏ္ဌာန်သာ အသစ်)။',
    OPT_INTRO => 'ရွေးချယ်စရာများကို စတုတ္ထ argument အဖြစ် ပေးပါ: { \'KEY\' => တန်ဖိုး, ... }',
    O_INPUT_LAYOUT   => '\'S\' (SBCS 1 byte) နှင့် \'D\' (DBCS 2 byte) ဖြင့် သတ်မှတ်ထားသော record layout; စာလုံးတစ်ခုစီနောက်တွင် ထပ်ခါအရေအတွက် ပါနိုင်သည်။ မူရင်း: အလိုအလျောက်။',
    O_OUTPUT_SHIFTING=> 'မှန်: DBCS အပိုင်းများ ပတ်လည်တွင် shift-out/shift-in ကုဒ်များ ထုတ်သည်။ မူရင်း: မှား။',
    O_SPACE          => 'DBCS/MBCS space ဖြည့်ကုဒ် (binary string)။ မူရင်း: ထို encoding ၏ space။',
    O_GETA           => 'map မလုပ်နိုင်သော စာလုံးများအတွက် DBCS/MBCS geta ကုဒ်။',
    O_OVERRIDE_MAPPING=>'စာလုံးအလိုက် FROM => TO override hash ကိုးကားချက် (SPACE ကိုပါ override လုပ်သည်)။',
    O_JIS_SOSI       => 'မှန်: \'jis\' input တွင် SO (0x0E)/SI (0x0F) ကို JIS X 0201 Katakana သို့ shift အဖြစ်ယူသည် (JIS7 အလေ့အထ)။ မူရင်း: မှား; input သည် \'jis\' ဖြစ်သောအခါ။',
    O_JIS_X0212      => 'မှန်: \'jis\' output တွင် JIS X 0212 ၌ရှိ၍ JIS X 0208 ၌မရှိသော စာလုံးကို ESC $ ( D အဖြစ် ရေးသည်။ OUTPUT_SHIFTING လိုသည်။ မူရင်း: မှား။',
    O_JIS_KANA       => '\'jis\' output ၏ Katakana ပုံစံ: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING လိုသည်), \'SO\' (SO/GL/SI)။ မူရင်း: \'GR\'။',
    O_JIS_DBCS       => '\'jis\' output ၏ DBCS escape: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'။ မူရင်း: \'B\'; output သည် \'jis\' ဖြစ်သောအခါ။',
    O_JIS_SBCS       => '\'jis\' output ၏ SBCS escape: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H အဟောင်း)။ မူရင်း: \'B\'; output သည် \'jis\' ဖြစ်သောအခါ။',
    O_JIS2004_PLANE1 => '\'jis2004\' output ၏ plane-1 escape: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000)။ မူရင်း: \'Q\'; output သည် \'jis2004\' ဖြစ်သောအခါ။',
    O_ROUND_TRIP     => 'မှန်: ပြန်ပြောင်းနိုင်သော ပြောင်းလဲမှု; မူရင်းကုဒ်မရှိသော စာလုံးကို အသုံးပြုသူသတ်မှတ် (GAIJI) နေရာတွင် ထားသဖြင့် "A မှ B" နှင့် "B မှ A" သည် မူရင်းကို ပြန်ရစေသည်။ နှစ်ဖက်စလုံးတွင် ROUND_TRIP=>1 နှင့် တူညီသော Jacode4e ဗားရှင်း လိုသည်။ မူရင်း: မှား (map မလုပ်နိုင်လျှင် GETA)။ ဇယားကို ပထမဆုံးအသုံးပြုချိန်တွင် lazy တည်ဆောက်သည်။',
    S1 => 'UTF-8 မှ mainframe encoding သို့ (shift, space, geta ဖြင့်)',
    S2 => 'အဟောင်း 1978 Shift_JIS မှ UTF-8 သို့ (နှစ်အလိုက်)',
    S3 => 'အသွားအပြန်: UTF-8 -> CP00930 -> UTF-8 မူရင်းကို ပြန်ရစေသည်',
};

$L{'SI'} = {
    TITLE2 => 'Jacode4e ඉක්මන් යොමු පත්‍රය (SI)',
    TITLE9 => 'Jacode4e ඉක්මන් යොමු (සිංහල)',
    H_BASIC=> 'මූලික භාවිතය',
    H_ENC  => 'කේතනය නාම ලැයිස්තුව',
    H_ERA  => 'වර්ෂය අනුව JIS සංස්කරණවල වෙනස්කම් (ආරම්භකයන් සඳහා)',
    H_OPT  => 'විකල්පයන්',
    H_SHIFT=> 'Shift කේත යොමුව',
    H_SAMPLE=>'ක්‍රමලේඛන උදාහරණ',
    A_LINE => 'පරිවර්තනය කළ යුතු පෙළ (යොමුව මගින් යවනු ලැබේ, ස්ථානයේම උඩින් ලියනු ලැබේ)',
    A_OUT  => 'ප්‍රතිදාන කේතන නාමය',
    A_IN   => 'ආදාන කේතන නාමය',
    A_COUNT=> 'පරිවර්තනයෙන් පසු අක්ෂර ගණන',
    ERA_INTRO => 'sjis / euc / jis හි වර්ෂ සංස්කරණ (වර්ෂය නොමැති නම 1990 සංස්කරණයයි):',
    ERA_P1 => 'ජපන් කන්ජි අදියරෙන් අදියර සම්මත කරන ලදී. එකම බයිට් සංස්කරණ අතර වෙනස් අක්ෂරයක් විය හැකි බැවින්, ඔබේ දත්තවලට ගැළපෙන සංස්කරණය තෝරන්න. නොදන්නේ නම්, වර්ෂය නොමැති sjis / euc / jis භාවිතා කරන්න.',
    ERA_1978 => 'පළමු කන්ජි ප්‍රමිතිය (මට්ටම 1 සහ මට්ටම 2).',
    ERA_1983 => 'කන්ජි යුගල 22ක කේතය හුවමාරු කර සමහර හැඩ වෙනස් කළේය; පැරණි දත්ත විකෘති වීමට වඩාත් පොදු හේතුව.',
    ERA_1990 => 'කන්ජි 2ක් පමණක් එකතු කළේය (U+51DC, U+7199); වර්ෂය නොමැති sjis / euc / jis යනු මෙම සංස්කරණයයි.',
    ERA_2000 => 'විශාල විස්තෘත කිරීමක්; නව තලය 2 මත මට්ටම 3 සහ 4 කන්ජි සහ සංකේත එකතු කළේය.',
    ERA_2004 => 'කන්ජි 10ක් එකතු කර කන්ජි 168ක නිදර්ශන හැඩය වෙනස් කළේය (කේතය 2000ට සමානයි, හැඩ පමණක් අලුත්).',
    OPT_INTRO => 'විකල්ප 4වන පරාමිතිය ලෙස ලබා දෙන්න: { \'KEY\' => අගය, ... }',
    O_INPUT_LAYOUT   => '\'S\' (බයිට් 1 SBCS) සහ \'D\' (බයිට් 2 DBCS) මගින් ස්ථාවර වාර්තා පිරිසැලසුම; සෑම අකුරකට පසුව පුනරාවර්තන ගණනක් තිබිය හැක. පෙරනිමිය: ස්වයංක්‍රීය.',
    O_OUTPUT_SHIFTING=> 'සත්‍ය: DBCS අනුක්‍රම වටා shift-out/shift-in කේත නිකුත් කරයි. පෙරනිමිය: අසත්‍ය.',
    O_SPACE          => 'DBCS/MBCS හිස් තැන පිරවුම් කේතය (ද්විමය පෙළ). පෙරනිමිය: එම කේතනයේ හිස් තැන.',
    O_GETA           => 'සිතියම්ගත කළ නොහැකි අක්ෂර සඳහා DBCS/MBCS geta කේතය.',
    O_OVERRIDE_MAPPING=>'අක්ෂරය අනුව FROM => TO අභිබවා යාමේ hash යොමුව (SPACE ද අභිබවා යයි).',
    O_JIS_SOSI       => 'සත්‍ය: \'jis\' ආදානයේදී SO (0x0E)/SI (0x0F) JIS X 0201 Katakana වෙත මාරු වේ (JIS7 සිරිත). පෙරනිමිය: අසත්‍ය; ආදානය \'jis\' විට.',
    O_JIS_X0212      => 'සත්‍ය: \'jis\' ප්‍රතිදානයේදී, JIS X 0212 හි ඇති නමුත් JIS X 0208 හි නොමැති අක්ෂරය ESC $ ( D ලෙස ලියයි. OUTPUT_SHIFTING අවශ්‍යයි. පෙරනිමිය: අසත්‍ය.',
    O_JIS_KANA       => '\'jis\' ප්‍රතිදානයේ Katakana ශෛලිය: \'GR\' (0xA1..0xDF), \'I\' (ESC ( I, OUTPUT_SHIFTING අවශ්‍යයි), \'SO\' (SO/GL/SI). පෙරනිමිය: \'GR\'.',
    O_JIS_DBCS       => '\'jis\' ප්‍රතිදානයේ DBCS escape: \'B\' (ESC $ B), \'@\' (ESC $ @), \'&@B\', \'(B\', \'(@\'. පෙරනිමිය: \'B\'; ප්‍රතිදානය \'jis\' විට.',
    O_JIS_SBCS       => '\'jis\' ප්‍රතිදානයේ SBCS escape: \'B\' (ESC ( B ASCII), \'J\' (ESC ( J Roman), \'H\' (ESC ( H පැරණි). පෙරනිමිය: \'B\'; ප්‍රතිදානය \'jis\' විට.',
    O_JIS2004_PLANE1 => '\'jis2004\' ප්‍රතිදානයේ තලය-1 escape: \'Q\' (ESC $ ( Q, :2004), \'O\' (ESC $ ( O, :2000). පෙරනිමිය: \'Q\'; ප්‍රතිදානය \'jis2004\' විට.',
    O_ROUND_TRIP     => 'සත්‍ය: ආපසු හැරවිය හැකි පරිවර්තනය; ස්වදේශීය කේතයක් නොමැති අක්ෂරයක් පරිශීලක-නිර්වචිත (GAIJI) ප්‍රදේශයේ තබනු ලැබේ, එවිට "A සිට B" සහ "B සිට A" මුල් දත්ත ප්‍රතිසාධනය කරයි. දෙදිශාවටම ROUND_TRIP=>1 සහ එකම Jacode4e අනුවාදය අවශ්‍යයි. පෙරනිමිය: අසත්‍ය (සිතියම්ගත නොවන විට GETA). වගුව මුල් වරට භාවිතයේදී කම්මැලි ලෙස ගොඩනගයි.',
    S1 => 'UTF-8 සිට mainframe කේතනයට (shift, හිස් තැන, geta සමඟ)',
    S2 => 'පැරණි 1978 Shift_JIS සිට UTF-8 වෙත (වර්ෂය අනුව)',
    S3 => 'ආපසු-යාම: UTF-8 -> CP00930 -> UTF-8 මුල් දත්ත ප්‍රතිසාධනය කරයි',
};

} # end BEGIN translations
