######################################################################
#
# t/6005_getcode_euc.t
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
    'ｶﾅｶﾞﾖﾊﾁﾖﾆﾔﾁﾖﾆｻｻﾞﾚｲｼﾉｲﾜｵﾄﾅﾘﾃｺｹﾉﾑｽﾏﾃﾞ','euc',
    '０１２３４５','euc',
    'ＡＢＣＤＥＦ','euc',
    'いろはにほへとちりぬるをわかよたれそつねならむうゐのおくやまけふこえてあさきゆめみしゑひもせす','euc',
    'トリナクコヱスユメサマセミヨアケワタルヒンカシヲソライロハエテオキツヘニホフネムレヰヌモヤノウチ','euc',
    '山川異域風月同天','euc',
    'このサイトは Perl の公式ドキュメント、モジュールドキュメントを日本語に翻訳したものを表示するサイトです。','euc',
    'サイト内の翻訳データは、Japanized Perl Resources Project(JPRP)で翻訳されたもの、有志が翻訳しているgithubのリポジトリ、JPAの翻訳文書から取得しています。','euc',
    '最近の更新 / RSS','euc',
    'CVS及びgitのcommitログから最新の50件を取得しています。稀に翻訳者とcommitした人が違う場合があります。また、修正のcommit、登録しただけで未翻訳のものも含まれる場合があります。','euc',
);

print "1..", scalar(@todo)/2, "\n";
if ('あ' ne "\xa4\xa2") {
    for $tno (1 .. scalar(@todo)/2) {
        print "ok $tno - SKIP (script '$0' must be 'euc')\n";
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
