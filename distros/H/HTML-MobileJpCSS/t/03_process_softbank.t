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
    my $agent = HTTP::MobileAgent->new('SoftBank/1.0/911T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1');
    my $inliner = HTML::MobileJpCSS->new(agent => $agent, base_dir => 't/');
    my $html = $inliner->apply($block->html);

    is $html, $block->expected, $block->name;
};

__DATA__

===
--- html
<?xml version="1.0" encoding="Shift_JIS"?>
<!DOCTYPE html PUBLIC "-//J-PHONE//DTD XHTML Basic 1.0 Plus//EN" "xhtml-basic10-plus.dtd">
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
<input istyle="1" type="text" />
<textarea istyle="2"></textarea>
</body>
</html>
--- expected
<?xml version="1.0" encoding="Shift_JIS"?>
<!DOCTYPE html PUBLIC "-//J-PHONE//DTD XHTML Basic 1.0 Plus//EN" "xhtml-basic10-plus.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<style type="text/css">
a:link {
	color: #0000ff;
}
</style></head>
<body style="background-color:#ffffff;">
<div style="text-align:center;font-size:xx-large;">foo</div>
<div style="color:red;">bar</div>
<hr style="float:center;border-color:#ff99ff;" />
<img style="float:none;" src="" />
<span style="font-size:small;">buzz</span>
<input istyle="1" type="text" />
<textarea istyle="2"></textarea>
</body>
</html>
