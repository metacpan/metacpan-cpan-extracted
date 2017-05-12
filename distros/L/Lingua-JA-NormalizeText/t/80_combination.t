use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer1 = Lingua::JA::NormalizeText->new(qw/strip_html nl2space unify_long_spaces ltrim rtrim/);
my $normalizer2 = Lingua::JA::NormalizeText->new(qw/ltrim rtrim strip_html unify_long_spaces nl2space/);
my $normalizer3 = Lingua::JA::NormalizeText->new([qw/strip_html nl2space unify_long_spaces ltrim rtrim/]);
my $normalizer4 = Lingua::JA::NormalizeText->new([qw/ltrim rtrim strip_html unify_long_spaces nl2space/]);

my $html = do { local $/; <DATA> };
is($normalizer1->normalize($html), 'タイトル 見出し ナビゲーション');
like($normalizer2->normalize($html), qr/^\x{0020}+タイトル\x{0020}+見出し\x{0020}+ナビゲーション\x{0020}+$/);
is($normalizer3->normalize($html), 'タイトル 見出し ナビゲーション');
like($normalizer4->normalize($html), qr/^\x{0020}+タイトル\x{0020}+見出し\x{0020}+ナビゲーション\x{0020}+$/);

done_testing;

__DATA__
<!DOCTYPE html>
<html lang="ja">

<head>
    <meta charset="UTF-8">
    <title>タイトル</title>
</head>

<body>
    <h1>見出し</h1>

    <nav>
        <ul>
            <li>ナビゲーション</li>
        </ul>
    </nav>

    <script type="text/javascript">hoge();</script>
</body>

</html>
