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
    local $HTML::MobileJpCSS::StyleMap->{hr}->{color}->{I} = 'background-color';
    my $inliner = HTML::MobileJpCSS->new(
        agent    => $agent,
        css_file => 't/css/t.css',
        css      => {'.color-red' => { color => 'blue' },},
    );
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
</head>
<body>
<div class="color-red">bar</div>
<hr class="line" />
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
<div style="color:blue;">bar</div>
<hr style="float:center;background-color:#ff99ff;" />
</body>
</html>
