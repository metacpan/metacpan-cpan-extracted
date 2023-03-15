######################################################################
#
# t/6004_getcode_sjis.t
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
    'ｶﾅｶﾞﾖﾊﾁﾖﾆﾔﾁﾖﾆｻｻﾞﾚｲｼﾉｲﾜｵﾄﾅﾘﾃｺｹﾉﾑｽﾏﾃﾞ','sjis',
    '０１２３４５','sjis',
    'ＡＢＣＤＥＦ','sjis',
    'いろはにほへとちりぬるをわかよたれそつねならむうゐのおくやまけふこえてあさきゆめみしゑひもせす','sjis',
    'トリナクコヱスユメサマセミヨアケワタルヒンカシヲソライロハエテオキツヘニホフネムレヰヌモヤノウチ','sjis',
    '山川異域風月同天','sjis',
    'このサイトは Perl の公式ドキュメント、モジュールドキュメントを日本語に翻訳したものを表示するサイトです。','sjis',
    'サイト内の翻訳データは、Japanized Perl Resources Project(JPRP)で翻訳されたもの、有志が翻訳しているgithubのリポジトリ、JPAの翻訳文書から取得しています。','sjis',
    '最近の更新 / RSS','sjis',
    'CVS及びgitのcommitログから最新の50件を取得しています。稀に翻訳者とcommitした人が違う場合があります。また、修正のcommit、登録しただけで未翻訳のものも含まれる場合があります。','sjis',
    '彗','sjis',
    '倣','sjis',
    '醒','sjis',
    '彙','sjis',
    '渦','sjis',
    '塵','sjis',
    '隕','sjis',
    '冥','sjis',
    '八','sjis',
    '鷹','sjis',
    '閃','sjis',
    '杉','sjis',
    '六','sjis',
    '九','sjis',
);

print "1..", scalar(@todo)/2, "\n";
if ('あ' ne "\x82\xa0") {
    for $tno (1 .. scalar(@todo)/2) {
        print "ok $tno - SKIP (script '$0' must be 'sjis')\n";
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
