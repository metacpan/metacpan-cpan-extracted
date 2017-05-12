use strict;
use Test::Base;

use HTTP::MobileAgent;
use HTML::MobileJpCSS;
plan tests => 1 * blocks;

filters {
    html     => 'chomp',
    expected => 'chomp',
};

run {
    my $block = shift;
    my $agent = HTTP::MobileAgent->new('DoCoMo/2.0 D902i(c100;TB;W28H20)');
    my $inliner = HTML::MobileJpCSS->new(agent => $agent, base_dir => 't/');
    my $html = $inliner->apply($block->html);

    is $html, $block->expected, $block->name;
};

__DATA__

===
--- html
<?xml version="1.0" encoding="Shift_JIS"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/2.1) 1.0//EN" "i-xhtml_4ja_10.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<link 
    rel="stylesheet" href="/css/t.css" />
</head>
<body>
<hr
 class="line" />
<img
class="logo" src="" />
<span class="font-small">
buzz</span>
</body>
</html>
--- expected
<?xml version="1.0" encoding="Shift_JIS"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/2.1) 1.0//EN" "i-xhtml_4ja_10.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<style type="text/css">
<![CDATA[
a:link {
	color: #0000ff;
}
]]></style></head>
<body style="background-color:#ffffff;">
<hr style="float:center;border-color:#ff99ff;" />
<img style="float:none;" src="" />
<span style="font-size:xx-small;">
buzz</span>
</body>
</html>
