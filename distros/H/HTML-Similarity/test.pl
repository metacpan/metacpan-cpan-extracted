use strict;
use Test::More tests => 6;

use_ok 'HTML::Similarity';

{
    my $hs = new HTML::Similarity;
    
    my $a = "<html><body></body></html>";
    my $b = "<html><body><h1>HOMEPAGE</h1><h2>Details</h2></body></html>";
    my $score = $hs->calculate_similarity($a, $b);
    cmp_ok($score, '>', 0, 'score > 0');
    cmp_ok($score, '<', 1, 'score < 1');
}

use_ok 'XML::Similarity';

{
    my $xs = new XML::Similarity;
    my $a = <<'XML';
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">

<channel>
<title>RSS Example</title>
<description>This is an example of an RSS feed</description>
<link>http://www.domain.com/link.htm</link>
<lastBuildDate>Mon, 28 Aug 2006 11:12:55 -0400 </lastBuildDate>
<pubDate>Tue, 29 Aug 2006 09:00:00 -0400</pubDate>

<item>
<title>Item Example</title>
<description>This is an example of an Item</description>
<link>http://www.domain.com/link.htm</link>
<guid isPermaLink="false"> 1102345</guid>
<pubDate>Tue, 29 Aug 2006 09:00:00 -0400</pubDate>
</item>

</channel>
</rss>
XML

    my $b = << 'XML';
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">

<channel>
<title>RSS Example</title>
<description>This is an example of an RSS feed</description>
<link>http://www.domain.com/link.htm</link>
<lastBuildDate>Mon, 28 Aug 2006 11:12:55 -0400 </lastBuildDate>
<pubDate>Tue, 29 Aug 2006 09:00:00 -0400</pubDate>

<item>
<title>Item Example</title>
<description>This is an example of an Item</description>
<link>http://www.domain.com/link.htm</link>
<guid isPermaLink="false"> 1102345</guid>
<pubDate>Tue, 29 Aug 2006 09:00:00 -0400</pubDate>
</item>

<item>
<title>Item Example</title>
<description>This is an example of an Item</description>
<link>http://www.domain.com/link.htm</link>
<guid isPermaLink="false"> 1102345</guid>
<pubDate>Tue, 29 Aug 2006 09:00:00 -0400</pubDate>
</item>

</channel>
</rss>
XML

    my $score = $xs->calculate_similarity($a, $b);
    cmp_ok($score, '>', 0, 'score > 0');
    cmp_ok($score, '<', 1, 'score < 1');
}
