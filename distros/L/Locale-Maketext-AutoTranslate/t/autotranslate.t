use Test::More tests => 2;
use Locale::Maketext::AutoTranslate;

sub main {
    my $t = Locale::Maketext::AutoTranslate->new();
    
    $t->from('en');
    $t->to('zh-tw');

    $t->translate('t/en.po' => 't/zh_tw.po');
    ok(-f 't/zh_tw.po');
    ok(-s 't/zh_tw.po');
}

main(@ARGV);
