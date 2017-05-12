
use Test::More tests => 1;
use HTML::StickyQuery;

my $s = HTML::StickyQuery->new;
$s->sticky(
    file => 't/test5.html',
    param => {SID => 'xxx'}
);
like($s->output, qr#<a href="test\.cgi\?SID=xxx" name="&lt;&quot;&amp;foo&gt;">#);
