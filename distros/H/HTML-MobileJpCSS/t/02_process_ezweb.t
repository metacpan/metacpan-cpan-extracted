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
    my $agent = HTTP::MobileAgent->new('KDDI-HI3A UP.Browser/6.2.0.13.1.4 (GUI) MMP/2.0');
    my $inliner = HTML::MobileJpCSS->new(agent => $agent, base_dir => 't/', inliner_ezweb => 1);
    my $html = $inliner->apply($block->html);

    is $html, $block->expected, $block->name;
};

__DATA__

===
--- html
<?xml version="1.0" encoding="Shift_JIS"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.0//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<link rel="stylesheet" href="/css/t.css" />
</head>
<body>
<div class="title">foo</div>
<div class="color-red">bar</div>
<hr class="line" />
<img class="logo" src="" />
<span class="font-small">buzz</span>
<input type="text" istyle="1" />
<textarea istyle="2"></textarea>
</body>
</html>
--- expected
<?xml version="1.0" encoding="Shift_JIS"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.0//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<style type="text/css">
a:link {
	color: #0000ff;
}
</style></head>
<body style="background-color:#ffffff;">
<div style="text-align:center;font-size:16px;">foo</div>
<div style="color:red;">bar</div>
<hr style="text-align:center;color:#ff99ff;" />
<img style="text-align:center;" src="" />
<span style="font-size:10px;">buzz</span>
<input type="text" istyle="1" />
<textarea istyle="2"></textarea>
</body>
</html>
