use strict;
use Test::More tests => 4;
use Locale::Memories;

my $lm = Locale::Memories->new();
my $locale = 'zh_tw';
my @m = <DATA>;
chomp @m;

for my $m (@m) {
    my ($msg_id, $msg_str) = split /\t/, $m;
    $lm->index_msg($locale, $msg_id, $msg_str);
}

for my $m ('edit', 'copy', 'ok', 'copy clipboard') {
    my $translated_msg = $lm->translate_msg($locale, $m);
    ok($translated_msg);
}

__END__
Cut	剪下
Copy	複製
Paste	貼上
Ok	確認
Cancel	取消
Delete	刪除
Done	完成
Undo	復原
Edit	編輯
Export	匯出
Import	匯入
Find	尋找
Format	格式
Font Size	字型大小
Font Color	文字顏色
Copy to Clipboard	複製到剪貼簿
Properties	屬性
Rename	更改名稱
