######################################################################
#
# 9004_cheatsheet_ko.t
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
#
# Jacode4e::RoundTrip 빠른 참조 (한국어)
# 이 테스트는 한국어 사용자를 위한 빠른 참조 가이드를 겸합니다.
######################################################################

# 이 파일은 UTF-8로 인코딩되어 있습니다.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ======================================================================
# Jacode4e::RoundTrip 빠른 참조 (한국어)
# ======================================================================
#
# 【기본 사용법】
#
#   use FindBin;
#   use lib "$FindBin::Bin/lib";
#   use Jacode4e::RoundTrip;
#
#   $char_count = Jacode4e::RoundTrip::convert(\$line, $OUTPUT_encoding, $INPUT_encoding);
#   $char_count = Jacode4e::RoundTrip::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, { %option });
#
#   $line             : 변환 대상 문자열 (참조 전달, 제자리 덮어씀)
#   $OUTPUT_encoding  : 출력 인코딩 이름
#   $INPUT_encoding   : 입력 인코딩 이름
#   $char_count       : 변환 후 문자 수
#
# 【인코딩 이름 목록】
#
#   니모닉      설명
#   ---------   ---------------------------------------------------
#   cp932x      CP932X (JIS X 0213 확장, 단일 시프트 0x9C5A)
#   cp932       Microsoft CP932 (Windows-31J / IANA 등록명)
#   cp932ibm    IBM CP932
#   cp932nec    NEC CP932
#   sjis2004    JISC Shift_JIS-2004
#   cp00930     IBM CP00930 (CP00290+CP00300, CCSID 5026 가타카나)
#   keis78      HITACHI KEIS78
#   keis83      HITACHI KEIS83
#   keis90      HITACHI KEIS90
#   jef         FUJITSU JEF (12pt, OUTPUT_SHIFTING 옵션으로 시프트 코드 출력)
#   jef9p       FUJITSU JEF ( 9pt, OUTPUT_SHIFTING 옵션으로 시프트 코드 출력)
#   jipsj       NEC JIPS(J)
#   jipse       NEC JIPS(E)
#   letsj       UNISYS LetsJ
#   utf8        UTF-8.0 (일반적으로 말하는 UTF-8)
#   utf8.1      UTF-8.1 (CP932가 아닌 Shift_JIS와 Unicode 대응에 기반한 변환)
#   utf8jp      UTF-8-SPUA-JP (JIS X 0213을 Unicode SPUA에 배치)
#
# 【옵션 목록】
#
#   키                값 / 설명
#   ---------------   ---------------------------------------------------
#   INPUT_LAYOUT      입력 레코드 레이아웃 ('S'=SBCS, 'D'=DBCS, 반복 수 지정 가능)
#   OUTPUT_SHIFTING   참이면 DBCS 앞뒤에 시프트 코드 출력
#   SPACE             출력 DBCS/MBCS 스페이스 코드 (바이너리 문자열)
#   GETA              매핑 불가 문자 대체 코드 (게타 기호)
#   OVERRIDE_MAPPING  문자별 매핑 재정의 해시 참조
#
# 【왕복 변환 주의사항】
#
#   손실 변환이 존재합니다 (예: CP932에는 398개의 비왕복 매핑 문자가 있습니다).
# 【Jacode4e와 Jacode4e::RoundTrip의 차이】
#
#   Jacode4e              : 빠른 단방향 변환. 일부 문자는 손실 변환
#                           (예: CP932에 398개의 비왕복 매핑 문자가 있음).
#   Jacode4e::RoundTrip   : Unicode 경유로 왕복 충실성을 보장.
#                           A→B→A가 항상 일치. Jacode4e보다 느리지만
#                           데이터가 왕복해야 할 때 사용.
#
#   왕복 변환이 필요하지 않은 경우 Jacode4e 모듈을 사용하십시오.
#
# ======================================================================

BEGIN {
    use vars qw(@test);
    @test = (

        # --- 기본 변환: 반환값은 변환 후 문자 수 ---
        ["\x81\x40", 'jef',    'cp932', {},                    "\xA1\xA1", 'cp932(8140)->jef(A1A1)'],
        ["\x81\x40", 'keis83', 'cp932', {},                    "\xA1\xA1", 'cp932(8140)->keis83(A1A1)'],
        ["\x81\x40", 'jipsj',  'cp932', {},                    "\x21\x21", 'cp932(8140)->jipsj(2121)'],
        ["\x81\x40", 'utf8',   'cp932', {},                    "\xE3\x80\x80", 'cp932(8140)->utf8(E38080)'],

        # --- SPACE 옵션 ---
        ["\x81\x40", 'jef',    'cp932', {'SPACE'=>"\x40\x40"}, "\x40\x40", 'cp932(8140)->jef SPACE=4040'],

        # --- GETA 옵션: 매핑 불가 문자 대체 ---
        ["\xFC\xFC", 'jef',    'cp932', {'GETA'=>"\xFE\xFE"},  "\xFE\xFE", 'cp932(FCFC)->jef GETA=FEFE'],

        # --- OUTPUT_SHIFTING 옵션: 시프트 코드 출력 ---
        ["\x81\x40\x31", 'jef', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x28\xA1\xA1\x29\xF1",
            'cp932(814031)->jef OUTPUT_SHIFTING(28A1A129F1)'],

        # --- INPUT_LAYOUT 옵션: 시프트 코드 없는 입력의 레이아웃 지정 ---
        ["\xA1\xA1\xF1", 'cp932', 'jef', {'INPUT_LAYOUT'=>'DS'}, "\x81\x40\x31",
            'jef(A1A1F1) INPUT_LAYOUT=DS->cp932(814031)'],

        # --- CP00930 (IBM 일본어 EBCDIC): 기본값은 시프트 코드 없음 ---
        ["\x81\x40", 'cp00930', 'cp932', {}, "\x40\x40", 'cp932(8140)->cp00930 no-shift(4040)'],
        # OUTPUT_SHIFTING=>1: 시프트 코드 0E(개시) / 0F(종료)
        ["\x81\x40\x31", 'cp00930', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0E\x40\x40\x0F\xF1",
            'cp932(814031)->cp00930 OUTPUT_SHIFTING(0E40400FF1)'],

        # --- KEIS83 (Hitachi 메인프레임): 기본값은 시프트 코드 없음 ---
        ["\x81\x40\x31", 'keis83', 'cp932', {}, "\xA1\xA1\xF1",
            'cp932(814031)->keis83 no-shift(A1A1F1)'],
        # OUTPUT_SHIFTING=>1: 시프트 코드 0A42(개시) / 0A41(종료)
        ["\x81\x40\x31", 'keis83', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0A\x42\xA1\xA1\x0A\x41\xF1",
            'cp932(814031)->keis83 OUTPUT_SHIFTING(0A42A1A10A41F1)'],

        # --- UTF-8-SPUA-JP: JIS X 0213을 SPUA에 배치한 내부 코드 ---
        # utf8 vs utf8.1: cp932(815C/8161/817C) differ between MS-CP932 and JIS-Shift_JIS mapping
        # cp932(815C)=― : utf8->U+2015 HORIZONTAL BAR, utf8.1->U+2014 EM DASH
        ["\x81\x5C", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x95", 'cp932(815C)->utf8(E28095 U+2015 HORIZONTAL BAR)'],
        ["\x81\x5C", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x94", 'cp932(815C)->utf8.1(E28094 U+2014 EM DASH)'],
        # cp932(8161)=∥ : utf8->U+2225 PARALLEL TO, utf8.1->U+2016 DOUBLE VERTICAL LINE
        ["\x81\x61", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x88\xA5", 'cp932(8161)->utf8(E288A5 U+2225 PARALLEL TO)'],
        ["\x81\x61", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x96", 'cp932(8161)->utf8.1(E28096 U+2016 DOUBLE VERTICAL LINE)'],
        # cp932(817C)=－ : utf8->U+FF0D FULLWIDTH HYPHEN-MINUS, utf8.1->U+2212 MINUS SIGN
        ["\x81\x7C", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xEF\xBC\x8D", 'cp932(817C)->utf8(EFBC8D U+FF0D FULLWIDTH HYPHEN-MINUS)'],
        ["\x81\x7C", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x88\x92", 'cp932(817C)->utf8.1(E28892 U+2212 MINUS SIGN)'],
        # cp932x(9C5A815C/8161/817C): utf8/utf8.1 mapping is inverted compared to cp932
        ["\x9C\x5A\x81\x5C", 'utf8',   'cp932x', {}, "\xE2\x80\x94", 'cp932x(9C5A815C)->utf8(E28094 U+2014 EM DASH)'],
        ["\x9C\x5A\x81\x5C", 'utf8.1', 'cp932x', {}, "\xE2\x80\x95", 'cp932x(9C5A815C)->utf8.1(E28095 U+2015 HORIZONTAL BAR)'],
        ["\x9C\x5A\x81\x61", 'utf8',   'cp932x', {}, "\xE2\x80\x96", 'cp932x(9C5A8161)->utf8(E28096 U+2016 DOUBLE VERTICAL LINE)'],
        ["\x9C\x5A\x81\x61", 'utf8.1', 'cp932x', {}, "\xE2\x88\xA5", 'cp932x(9C5A8161)->utf8.1(E288A5 U+2225 PARALLEL TO)'],
        ["\x9C\x5A\x81\x7C", 'utf8',   'cp932x', {}, "\xE2\x88\x92", 'cp932x(9C5A817C)->utf8(E28892 U+2212 MINUS SIGN)'],
        ["\x9C\x5A\x81\x7C", 'utf8.1', 'cp932x', {}, "\xEF\xBC\x8D", 'cp932x(9C5A817C)->utf8.1(EFBC8D U+FF0D FULLWIDTH HYPHEN-MINUS)'],
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
