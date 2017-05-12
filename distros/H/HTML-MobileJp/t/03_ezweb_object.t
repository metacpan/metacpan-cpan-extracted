use strict;
use warnings;
use utf8;
use Test::More tests => 1;
use HTML::MobileJp;

is ezweb_object(
    url => 'http://aa.com/movie.amc',
    mime_type => 'application/x-mpeg',
    copyright => 'no',
    standby => 'ダウンロード',
    disposition => 'devdl1q',
    size => '119065',
    title => 'サンプル動画',
), <<'...';
<object data="http://aa.com/movie.amc" type="application/x-mpeg" copyright="no" standby="ダウンロード">
<param name="disposition" value="devdl1q" valuetype="data" />
<param name="size" value="119065" valuetype="data" />
<param name="title" value="サンプル動画" valuetype="data" />
</object>
...

