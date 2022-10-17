######################################################################
#
# t/6003_getcode_jis.t
#
# Copyright (c) 2022 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/..";
    >;
}
require 'lib/jacode.pl';

@todo = (
    'ｶﾅｶﾞﾖﾊﾁﾖﾆﾔﾁﾖﾆｻｻﾞﾚｲｼﾉｲﾜｵﾄﾅﾘﾃｺｹﾉﾑｽﾏﾃﾞ','jis',
    '０１２３４５','jis',
    'ＡＢＣＤＥＦ','jis',
    'いろはにほへとちりぬるをわかよたれそつねならむうゐのおくやまけふこえてあさきゆめみしゑひもせす','jis',
    'トリナクコヱスユメサマセミヨアケワタルヒンカシヲソライロハエテオキツヘニホフネムレヰヌモヤノウチ','jis',
    '山川異域風月同天','jis',
    'このサイトは Perl の公式ドキュメント、モジュールドキュメントを日本語に翻訳したものを表示するサイトです。','jis',
    'サイト内の翻訳データは、Japanized Perl Resources Project(JPRP)で翻訳されたもの、有志が翻訳しているgithubのリポジトリ、JPAの翻訳文書から取得しています。','jis',
    '最近の更新 / RSS','jis',
    'CVS及びgitのcommitログから最新の50件を取得しています。稀に翻訳者とcommitした人が違う場合があります。また、修正のcommit、登録しただけで未翻訳のものも含まれる場合があります。','jis',
);

print "1..", scalar(@todo)/2, "\n";
if ('あ' !~ /\x24\x22/) {
    for $tno (1 .. scalar(@todo)/2) {
        print "ok $tno - SKIP (script '$0' must be 'jis')\n";
    }
    exit;
}

$tno = 1;

while (($give,$want) = splice(@todo,0,2)) {
    $got = &jacode'getcode(*give);
    if ($got eq $want) {
        print     "ok $tno - want=($want) got=($got)\n";
    }
    else {
        print "not ok $tno - want=($want) got=($got)\n";
    }
    $tno++;
}

__END__
